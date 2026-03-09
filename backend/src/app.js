const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const sequelize = require('./config/db');
const routes = require('./routes/index');
const authRoutes = require('./routes/authRoutes');
const storeRoutes = require('./routes/storeRoutes');

const app = express();

// Middlewares
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'API is running 🚀', env: process.env.NODE_ENV || 'development' });
});

// Routes principales de l'API
app.use('/api', routes);
app.use('/api/auth', authRoutes);
app.use('/api/stores', storeRoutes);

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

sequelize.sync({ alter: true }).then(() => {
  console.log('Base de données synchronisée.');
  app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}).catch((error) => {
  console.error('Erreur lors de la synchronisation de la base de données:', error);
});

module.exports = app;
