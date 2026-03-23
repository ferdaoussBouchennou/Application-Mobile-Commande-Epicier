const sequelize = require('../config/db');
const Commande = require('../models/Commande');
const Reclamation = require('../models/Reclamation');

const seedOrders = async () => {
  try {
    // Orders
    const orders = await Commande.bulkCreate([
      { client_id: 2, epicier_id: 1, statut: 'livrée', montant_total: 120.00, date_commande: new Date(Date.now() - 7200000) }, // 2h ago
      { client_id: 2, epicier_id: 2, statut: 'prête', montant_total: 85.00, date_commande: new Date(Date.now() - 3600000) },  // 1h ago
      { client_id: 2, epicier_id: 1, statut: 'reçue', montant_total: 67.00, date_commande: new Date() },
      { client_id: 2, epicier_id: 3, statut: 'livrée', montant_total: 134.00, date_commande: new Date(Date.now() - 86400000) }, // 1 day ago
      { client_id: 2, epicier_id: 4, statut: 'livrée', montant_total: 45.00, date_commande: new Date(Date.now() - 90000000) }  // 25h ago
    ]);

    // Reclamations
    await Reclamation.bulkCreate([
      { 
        motif: 'Commande non reçue',
        description: 'Commande non reçue alors que marquée livrée', 
        statut: 'Litige ouvert', 
        client_id: 2, 
        commande_id: orders[0].id,
        epicier_id: orders[0].epicier_id,
        date_creation: new Date(Date.now() - 7200000) 
      },
      { 
        motif: 'Produit manquant',
        description: 'Produit manquant (Lait)', 
        statut: 'En médiation', 
        client_id: 2, 
        commande_id: orders[1].id,
        epicier_id: orders[1].epicier_id,
        date_creation: new Date(Date.now() - 3600000) 
      },
      { 
        motif: 'Retard livraison',
        description: 'Retard important sur la livraison', 
        statut: 'Remboursé', 
        client_id: 2, 
        commande_id: orders[3].id,
        epicier_id: orders[3].epicier_id,
        date_creation: new Date(Date.now() - 172800000) // 2 days ago
      },
      { 
        motif: 'Qualité produits',
        description: 'Problème de qualité sur les légumes', 
        statut: 'Résolu', 
        client_id: 2, 
        commande_id: orders[4].id,
        epicier_id: orders[4].epicier_id,
        date_creation: new Date(Date.now() - 259200000) // 3 days ago
      }
    ]);

    console.log('Seeding orders and reclamations successful!');
  } catch (error) {
    console.error('Error seeding orders:', error);
    throw error;
  }
};

module.exports = seedOrders;

if (require.main === module) {
  seedOrders()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}
