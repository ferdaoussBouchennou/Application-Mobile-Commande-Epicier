const sequelize = require('../config/db');
const { QueryTypes } = require('sequelize');
const Store = require('../models/Store');
const Availability = require('../models/Availability');
const User = require('../models/User');
const Avis = require('../models/Avis');

const storeController = {
  // Liste de tous les épiciers, avec calcul de distance si lat/lng client fournis
  getAllStores: async (req, res) => {
    try {
      const { lat, lng } = req.query;
      const clientLat = parseFloat(lat);
      const clientLng = parseFloat(lng);
      const hasClientLocation = !isNaN(clientLat) && !isNaN(clientLng);

      let stores;

      if (hasClientLocation) {
        stores = await sequelize.query(`
          SELECT e.*,
            u.nom AS utilisateur_nom, u.prenom AS utilisateur_prenom,
            CASE
              WHEN e.latitude IS NOT NULL AND e.longitude IS NOT NULL THEN
                ROUND(6371 * acos(
                  LEAST(1, cos(radians(:clientLat)) * cos(radians(e.latitude)) *
                  cos(radians(e.longitude) - radians(:clientLng)) +
                  sin(radians(:clientLat)) * sin(radians(e.latitude)))
                ), 2)
              ELSE NULL
            END AS distance_km
          FROM epiciers e
          LEFT JOIN utilisateurs u ON u.id = e.utilisateur_id
          WHERE e.is_active = 1 AND e.statut_inscription = 'COMPLETE'
          ORDER BY distance_km IS NULL, distance_km ASC
        `, {
          replacements: { clientLat, clientLng },
          type: QueryTypes.SELECT
        });

        const storeIds = stores.map(s => s.id);
        const availabilities = storeIds.length > 0
          ? await Availability.findAll({ where: { epicier_id: storeIds } })
          : [];
        const availByStore = {};
        availabilities.forEach(a => {
          if (!availByStore[a.epicier_id]) availByStore[a.epicier_id] = [];
          availByStore[a.epicier_id].push(a);
        });

        stores = stores.map(s => ({
          ...s,
          utilisateur: { nom: s.utilisateur_nom, prenom: s.utilisateur_prenom },
          disponibilites: availByStore[s.id] || [],
        }));
      } else {
        const result = await Store.findAll({
          where: { is_active: true, statut_inscription: 'COMPLETE' },
          include: [
            { model: User, as: 'utilisateur', attributes: ['nom', 'prenom'] },
            { model: Availability, as: 'disponibilites' }
          ]
        });
        stores = result.map(s => s.toJSON());
      }

      res.status(200).json(stores);
    } catch (error) {
      console.error('Erreur getAllStores:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération des épiciers', error: error.message });
    }
  },

  // Détails d'un épicier spécifique avec ses disponibilités + note moyenne (avis)
  getStoreById: async (req, res) => {
    try {
      const { id } = req.params;
      const storeId = parseInt(id, 10);
      if (isNaN(storeId)) {
        return res.status(400).json({ message: 'Identifiant invalide' });
      }
      const store = await Store.findOne({
        where: { id: storeId, is_active: true, statut_inscription: 'COMPLETE' },
        include: [
          {
            model: User,
            as: 'utilisateur',
            attributes: ['nom', 'prenom']
          },
          {
            model: Availability,
            as: 'disponibilites'
          }
        ]
      });

      if (!store) {
        return res.status(404).json({ message: 'Épicier introuvable' });
      }

      let rating = 0;
      try {
        const rows = await sequelize.query(
          'SELECT COALESCE(AVG(note), 0) AS note_moyenne FROM avis WHERE epicier_id = :id',
          { replacements: { id }, type: QueryTypes.SELECT }
        );
        rating = Number(Number((rows && rows[0] && rows[0].note_moyenne) || 0).toFixed(1));
      } catch (_) {}
      const storeJson = store.toJSON();
      storeJson.rating = rating;

      res.status(200).json(storeJson);
    } catch (error) {
      console.error('Erreur getStoreById:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération des détails de l\'épicier', error: error.message });
    }
  },

  // Créneaux de récupération pour un épicier (basés sur les disponibilités).
  // Query: ?date=YYYY-MM-DD (optionnel). Si absent, utilise aujourd'hui.
  getCreneaux: async (req, res) => {
    try {
      const { id: storeId } = req.params;
      const store = await Store.findByPk(storeId, {
        include: [{ model: Availability, as: 'disponibilites' }]
      });
      if (!store) {
        return res.status(404).json({ message: 'Épicier introuvable' });
      }

      const jours = ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];
      const creneaux = [];

      let d;
      const dateParam = req.query.date;
      if (dateParam && /^\d{4}-\d{2}-\d{2}$/.test(dateParam)) {
        d = new Date(dateParam + 'T12:00:00');
        if (isNaN(d.getTime())) {
          d = new Date();
        } else {
          const today = new Date();
          today.setHours(0, 0, 0, 0);
          d.setHours(0, 0, 0, 0);
          if (d < today) {
            return res.status(200).json({ creneaux, nom_boutique: store.nom_boutique });
          }
        }
      } else {
        d = new Date();
      }

      const jourName = jours[d.getDay()];
      const disp = store.disponibilites?.find((av) => av.jour === jourName);
      if (disp) {
        const heureDebut = disp.heure_debut;
        const heureFin = disp.heure_fin;
        const toMinutes = (t) => {
          if (typeof t === 'string') {
            const [h, m] = t.split(':').map(Number);
            return (h || 0) * 60 + (m || 0);
          }
          if (t && typeof t.getMinutes === 'function') {
            return t.getHours() * 60 + t.getMinutes();
          }
          return 0;
        };
        const endMin = toMinutes(heureFin);
        const now = new Date();
        const toLocalDateStr = (date) =>
          date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0') + '-' + String(date.getDate()).padStart(2, '0');
        const todayStr = toLocalDateStr(now);
        const selectedDateStr = dateParam && /^\d{4}-\d{2}-\d{2}$/.test(dateParam)
          ? dateParam
          : toLocalDateStr(d);
        const isToday = selectedDateStr === todayStr;
        const dateStr = selectedDateStr;
        // Pour aujourd'hui : uniquement les créneaux à partir de l'heure courante (heure pleine suivante).
        // Pour les jours suivants : tous les créneaux depuis l'ouverture.
        const nowMinutes = now.getHours() * 60 + now.getMinutes();
        const firstSlotStartMin = isToday ? Math.ceil(nowMinutes / 60) * 60 : 0;
        let startMin = Math.max(toMinutes(heureDebut), firstSlotStartMin);

        while (startMin + 60 <= endMin) {
          const h = Math.floor(startMin / 60);
          const m = startMin % 60;
          const label = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')} – ${String(h + 1).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
          const value = `${dateStr}T${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:00`;
          creneaux.push({ label, value });
          startMin += 60;
        }
      }

      res.status(200).json({ creneaux, nom_boutique: store.nom_boutique });
    } catch (error) {
      console.error('Erreur getCreneaux:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération des créneaux', error: error.message });
    }
  },

  // Liste des avis d'un épicier (note moyenne + commentaires avec nom du client)
  getAvisByStore: async (req, res) => {
    try {
      const { id: storeId } = req.params;
      const store = await Store.findByPk(storeId);
      if (!store) {
        return res.status(404).json({ message: 'Épicier introuvable' });
      }
      const rows = await sequelize.query(
        'SELECT COALESCE(AVG(note), 0) AS note_moyenne FROM avis WHERE epicier_id = :storeId',
        { replacements: { storeId }, type: QueryTypes.SELECT }
      );
      const note_moyenne = Number(Number((rows && rows[0] && rows[0].note_moyenne) || 0).toFixed(1));
      const avisList = await Avis.findAll({
        where: { epicier_id: storeId },
        include: [{ model: User, as: 'client', attributes: ['nom', 'prenom'] }],
        order: [['date_avis', 'DESC']],
      });
      const avis = avisList.map((a) => ({
        id: a.id,
        note: a.note,
        commentaire: a.commentaire || '',
        client_nom: a.client ? `${a.client.prenom || ''} ${a.client.nom || ''}`.trim() : 'Client',
        date_avis: a.date_avis,
      }));
      res.status(200).json({ note_moyenne, avis });
    } catch (error) {
      console.error('Erreur getAvisByStore:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération des avis', error: error.message });
    }
  },
};

module.exports = storeController;