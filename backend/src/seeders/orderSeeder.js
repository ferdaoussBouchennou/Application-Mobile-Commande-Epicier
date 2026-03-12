const sequelize = require('../config/db');
const Order = require('../models/Order');
const Reclamation = require('../models/Reclamation');

const seedOrders = async () => {
  try {
    // Orders
    const orders = await Order.bulkCreate([
      { client_id: 2, epicier_id: 1, statut: 'livrée', montant_total: 120.00, date_commande: new Date(Date.now() - 7200000) }, // 2h ago
      { client_id: 2, epicier_id: 2, statut: 'prête', montant_total: 85.00, date_commande: new Date(Date.now() - 3600000) },  // 1h ago
      { client_id: 2, epicier_id: 1, statut: 'reçue', montant_total: 67.00, date_commande: new Date() },
      { client_id: 2, epicier_id: 3, statut: 'livrée', montant_total: 134.00, date_commande: new Date(Date.now() - 86400000) }, // 1 day ago
      { client_id: 2, epicier_id: 4, statut: 'livrée', montant_total: 45.00, date_commande: new Date(Date.now() - 90000000) }  // 25h ago
    ]);

    // Reclamations
    await Reclamation.bulkCreate([
      { 
        description: 'Commande non reçue alors que marquée livrée', 
        statut: 'non resolut', 
        client_id: 2, 
        commande_id: orders[0].id, 
        date_creation: new Date(Date.now() - 7200000) 
      },
      { 
        description: 'Produit manquant (Lait)', 
        statut: 'en attente', 
        client_id: 2, 
        commande_id: orders[1].id, 
        date_creation: new Date(Date.now() - 3600000) 
      },
      { 
        description: 'Retard important sur la livraison', 
        statut: 'rembourser', 
        client_id: 2, 
        commande_id: orders[3].id, 
        date_creation: new Date(Date.now() - 172800000) // 2 days ago
      },
      { 
        description: 'Problème de qualité sur les légumes', 
        statut: 'resolut', 
        client_id: 2, 
        commande_id: orders[4].id, 
        date_creation: new Date(Date.now() - 259200000) // 3 days ago
      }
    ]);

    console.log('Seeding orders and reclamations successful!');
  } catch (error) {
    console.error('Error seeding orders:', error);
  }
};

module.exports = seedOrders;
