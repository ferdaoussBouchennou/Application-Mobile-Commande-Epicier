const sequelize = require('../config/db');
const { QueryTypes } = require('sequelize');
const Store = require('../models/Store');
const Availability = require('../models/Availability');
const User = require('../models/User');
const Avis = require('../models/Avis');

const storeController = {
  // Liste de tous les épiciers
  getAllStores: async (req, res) => {
    try {
      const stores = await Store.findAll({
        where: {
          is_active: true,
          statut_inscription: 'ACCEPTE'
        },
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
      const store = await Store.findByPk(id, {
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

  // Créneaux de récupération pour un épicier (basés sur les disponibilités)
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
      // Un seul jour (aujourd'hui) pour éviter d'afficher deux plages 8h–22h (aujourd'hui + demain)
      const d = new Date();
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
        const dateStr = d.toISOString().slice(0, 10);
        // Ne proposer que les créneaux à partir de l'heure courante (pas les heures passées)
        const nowMinutes = d.getHours() * 60 + d.getMinutes();
        const firstSlotStartMin = Math.ceil(nowMinutes / 60) * 60; // début du prochain créneau (heure pleine)
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