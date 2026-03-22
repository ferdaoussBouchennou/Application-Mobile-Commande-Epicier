/**
 * dashboardSeeder.js
 * Seeds realistic data for the admin dashboard:
 *   - 5 CLIENT users (this month)
 *   - 2 EPICIER users (this month)
 *   - 7 orders spread over the last 7 days (various statuses)
 *   - 3 open reclamations
 *   - DetailCommande rows to populate top-categories chart
 *
 * PRE-REQUISITES: At least one Store and one Category+Product must exist.
 * Run the productSeeder.js first if needed.
 */

const sequelize = require('../config/db');
const { Op } = require('sequelize');
const bcrypt = require('bcrypt');

const User        = require('../models/User');
const Store       = require('../models/Store');
const Order       = require('../models/Order');
const Reclamation = require('../models/Reclamation');
const Category    = require('../models/Category');
const Product     = require('../models/Product');
const DetailCommande = require('../models/DetailCommande');

// ── helpers ──────────────────────────────────────────────────────────────────
const daysAgo = (n) => {
  const d = new Date();
  d.setDate(d.getDate() - n);
  d.setHours(10 + Math.floor(Math.random() * 8), Math.floor(Math.random() * 60), 0, 0);
  return d;
};

const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];

// ── main ──────────────────────────────────────────────────────────────────────
const seedDashboard = async () => {
  try {
    await sequelize.authenticate();
    console.log('📦 Dashboard seeder starting…');

    // ── 1. Fetch existing stores & products ──────────────────────────────────
    const stores = await Store.findAll({ where: { is_active: true }, limit: 5 });
    if (stores.length === 0) {
      console.error('❌ No active stores found. Run storeSeeder first.');
      return;
    }

    const products = await Product.findAll({ limit: 20 });
    if (products.length === 0) {
      console.error('❌ No products found. Run productSeeder first.');
      return;
    }

    // ── 2. Create CLIENT users (to simulate growth this month) ───────────────
    const passwordHash = await bcrypt.hash('password123', 10);
    const clientEmails = [
      'client.test1@epicier.dz',
      'client.test2@epicier.dz',
      'client.test3@epicier.dz',
      'client.test4@epicier.dz',
      'client.test5@epicier.dz',
    ];

    const clients = [];
    for (const email of clientEmails) {
      const [user] = await User.findOrCreate({
        where: { email },
        defaults: {
          nom: 'ClientTest',
          prenom: email.split('.')[1].split('@')[0],
          email,
          mdp: passwordHash,
          role: 'CLIENT',
          statut_inscription: 'ACCEPTE',
          is_active: true,
          date_creation: daysAgo(Math.floor(Math.random() * 20)),
        },
      });
      clients.push(user);
    }
    console.log(`  ✅ ${clients.length} clients ready`);

    // ── 3. Create EPICIER users this month ───────────────────────────────────
    const epicierEmails = ['new.epicier1@epicier.dz', 'new.epicier2@epicier.dz'];
    for (const email of epicierEmails) {
      await User.findOrCreate({
        where: { email },
        defaults: {
          nom: 'EpicierTest',
          prenom: 'Nouveau',
          email,
          mdp: passwordHash,
          role: 'EPICIER',
          statut_inscription: 'ACCEPTE',
          is_active: true,
          date_creation: daysAgo(Math.floor(Math.random() * 15)),
        },
      });
    }
    console.log('  ✅ 2 new epiciers ready');

    // ── 4. Create Orders (last 7 days) ────────────────────────────────────────
    const statuses = ['livrée', 'livrée', 'livrée', 'prête', 'reçue', 'refusée', 'annulée'];

    const ordersToCreate = [];
    for (let day = 0; day < 7; day++) {
      const orderCount = 3 + Math.floor(Math.random() * 5); // 3-7 orders per day
      for (let j = 0; j < orderCount; j++) {
        const store = pick(stores);
        const client = pick(clients);
        const statut = pick(statuses);
        const montant = 200 + Math.floor(Math.random() * 800);
        const date = daysAgo(day);

        ordersToCreate.push({
          client_id: client.id,
          epicier_id: store.utilisateur_id,
          statut,
          montant_total: montant,
          date_commande: date,
        });
      }
    }

    const createdOrders = await Order.bulkCreate(ordersToCreate);
    console.log(`  ✅ ${createdOrders.length} orders created (last 7 days)`);

    // ── 5. Create DetailCommande (for top-categories chart) ──────────────────
    const details = [];
    for (const order of createdOrders) {
      const numItems = 1 + Math.floor(Math.random() * 3);
      const shuffled = [...products].sort(() => 0.5 - Math.random()).slice(0, numItems);
      for (const product of shuffled) {
        const qty = 1 + Math.floor(Math.random() * 5);
        const prix = parseFloat(product.prix || 50);
        details.push({
          commande_id: order.id,
          produit_id: product.id,
          quantite: qty,
          prix_unitaire: prix,
          total_ligne: +(prix * qty).toFixed(2),
        });
      }
    }
    await DetailCommande.bulkCreate(details);
    console.log(`  ✅ ${details.length} order details created`);

    // ── 6. Add Reclamations (open disputes) ──────────────────────────────────
    const disputeStatuses = ['Litige ouvert', 'En médiation', 'Litige ouvert'];
    const deliveredOrders = createdOrders.filter(o => o.statut === 'livrée').slice(0, 3);

    if (deliveredOrders.length > 0) {
      const reclamations = disputeStatuses.slice(0, deliveredOrders.length).map((statut, i) => ({
        description: [
          'Commande non reçue malgré le statut "livrée"',
          'Produit manquant dans la commande',
          'Article endommagé à la livraison',
        ][i],
        statut,
        client_id: deliveredOrders[i].client_id,
        commande_id: deliveredOrders[i].id,
        date_creation: new Date(),
      }));

      await Reclamation.bulkCreate(reclamations);
      console.log(`  ✅ ${reclamations.length} reclamations created`);
    }

    console.log('\n🎉 Dashboard seed complete! Refresh the admin dashboard to see results.');
  } catch (err) {
    console.error('❌ Dashboard seeder error:', err.message);
    console.error(err);
  } finally {
    await sequelize.close();
  }
};

module.exports = seedDashboard;

// Allow running directly: node dashboardSeeder.js
if (require.main === module) {
  seedDashboard();
}
