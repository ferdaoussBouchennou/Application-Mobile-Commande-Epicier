const Store = require('../models/Store');
const Availability = require('../models/Availability');
const User = require('../models/User');

const storeController = {
  // Liste de tous les épiciers
  getAllStores: async (req, res) => {
    try {
      const stores = await Store.findAll({
        where: { is_active: true, statut_inscription: 'ACCEPTE' },
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
  }
};

module.exports = storeController;
