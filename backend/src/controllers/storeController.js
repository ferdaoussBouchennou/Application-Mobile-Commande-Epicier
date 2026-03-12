const sequelize = require('../config/db');
const { QueryTypes } = require('sequelize');
const Store = require('../models/Store');
const Availability = require('../models/Availability');
const User = require('../models/User');

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

  // Détails d'un épicier spécifique avec ses disponibilités (uniquement si COMPLETE et actif)
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

      res.status(200).json(store);
    } catch (error) {
      console.error('Erreur getStoreById:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération des détails de l\'épicier', error: error.message });
    }
  }
};

module.exports = storeController;