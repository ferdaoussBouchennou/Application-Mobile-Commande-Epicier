const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config();

const sequelize = require('./config/db');
const routes = require('./routes/index');
const authRoutes = require('./routes/authRoutes');
const storeRoutes = require('./routes/storeRoutes');
const grocerRoutes = require('./routes/grocerRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const productRoutes = require('./routes/productRoutes');
// const panierRoutes = require('./routes/panierRoutes');
const commandeRoutes = require('./routes/commandeRoutes');
const avisRoutes = require('./routes/avisRoutes');
const notificationsRoutes = require('./routes/notifications_routes');
const reclamationRoutes = require('./routes/reclamationRoutes');


const app = express();

// Middlewares
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(
  helmet({
    crossOriginResourcePolicy: false,
    contentSecurityPolicy: false, // Optionnel, mais aide en dev web
  })
);
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'API is running ', env: process.env.NODE_ENV || 'development' });
});

// Routes principales de l'API
app.use('/api', routes);
app.use('/api/auth', authRoutes);
app.use('/api/stores', storeRoutes);
app.use('/api/epicier', grocerRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/products', productRoutes);
// app.use('/api/panier', panierRoutes);
app.use('/api/commandes', commandeRoutes);
app.use('/api/avis', avisRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/reclamations', reclamationRoutes);


// 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error Handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

const PORT = process.env.PORT || 3000;

/**
 * Sequelize sync({ alter }) ajoute/aligne les colonnes des modèles, mais ne supprime en général
 * pas les colonnes déjà présentes en base qui ne sont plus dans le modèle. D'où des champs
 * « fantômes » (ex. unite, type_unite, prix sur produits — le prix vit dans epicier_produits).
 */
async function dropLegacyProduitColumnsIfPresent() {
  if (sequelize.getDialect() !== 'mysql') return;
  try {
    const [rows] = await sequelize.query(
      `SELECT COLUMN_NAME FROM information_schema.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'produits'
       AND COLUMN_NAME IN ('unite', 'type_unite', 'prix')`,
    );
    const names = (rows || []).map((r) => r.COLUMN_NAME || r.column_name).filter(Boolean);
    if (names.length === 0) return;
    const dropSql = names.map((n) => `DROP COLUMN \`${n}\``).join(', ');
    await sequelize.query(`ALTER TABLE produits ${dropSql}`);
    console.log(`Colonnes obsolètes retirées (produits): ${names.join(', ')}`);
  } catch (e) {
    console.warn('Nettoyage colonnes produits (legacy):', e.message);
  }
}

async function dropLegacyCategoryColumnsIfPresent() {
  if (sequelize.getDialect() !== 'mysql') return;
  try {
    const [rows] = await sequelize.query(
      `SELECT COLUMN_NAME FROM information_schema.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'categories'
       AND COLUMN_NAME IN ('display_order', 'is_active', 'image_url')`,
    );
    const names = (rows || []).map((r) => r.COLUMN_NAME || r.column_name).filter(Boolean);
    if (names.length === 0) return;
    const dropSql = names.map((n) => `DROP COLUMN \`${n}\``).join(', ');
    await sequelize.query(`ALTER TABLE categories ${dropSql}`);
    console.log(`Colonnes obsolètes retirées (categories): ${names.join(', ')}`);
  } catch (e) {
    console.warn('Nettoyage colonnes categories (legacy):', e.message);
  }
}

sequelize.query('SET FOREIGN_KEY_CHECKS = 0')
  .then(() => sequelize.query('DROP TABLE IF EXISTS notifications'))
  .then(() => sequelize.query('SET FOREIGN_KEY_CHECKS = 1'))
  .then(() => sequelize.sync({ alter: { drop: false } }))
  .then(() => dropLegacyProduitColumnsIfPresent())
  .then(() => dropLegacyCategoryColumnsIfPresent())
  .then(() => {
    console.log('Base de données synchronisée (notifications réinitialisées).');
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on port ${PORT}`);
    });
  }).catch((error) => {
    console.error('Erreur lors de la synchronisation:', error);
  });

module.exports = app;
