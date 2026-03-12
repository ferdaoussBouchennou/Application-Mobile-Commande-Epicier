const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Commande = sequelize.define('Commande', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  client_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'utilisateurs', key: 'id' },
  },
  epicier_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'epiciers', key: 'id' },
  },
  date_commande: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  date_recuperation: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  statut: {
    type: DataTypes.ENUM('reçue', 'prête', 'livrée'),
    allowNull: false,
    defaultValue: 'reçue',
  },
  montant_total: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    defaultValue: 0,
  },
}, {
  tableName: 'commandes',
  timestamps: false,
});

module.exports = Commande;
