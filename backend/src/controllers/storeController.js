const Store = require('../models/Store');
const Availability = require('../models/Availability');
const User = require('../models/User');

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

  // Détails d'un épicier spécifique avec ses disponibilités
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

      res.status(200).json(store);
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

      for (let dayOffset = 0; dayOffset <= 1; dayOffset++) {
        const d = new Date();
        d.setDate(d.getDate() + dayOffset);
        const jourName = jours[d.getDay()];
        const disp = store.disponibilites?.find((av) => av.jour === jourName);
        if (!disp) continue;

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
        let startMin = toMinutes(heureDebut);
        const endMin = toMinutes(heureFin);
        const dateStr = d.toISOString().slice(0, 10);

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
  }
};

module.exports = storeController;