const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');
const Store = require('./Store');

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
    type: DataTypes.ENUM('reçue', 'prête', 'refusee', 'livrée'),
    allowNull: false,
    defaultValue: 'reçue',
  },
  message_refus: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  lu_epicier: {
    type: DataTypes.TINYINT,
    allowNull: true,
    defaultValue: 0,
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

User.hasMany(Commande, { foreignKey: 'client_id' });
Commande.belongsTo(User, { foreignKey: 'client_id', as: 'client' });
Store.hasMany(Commande, { foreignKey: 'epicier_id' });
Commande.belongsTo(Store, { foreignKey: 'epicier_id', as: 'store' });

module.exports = Commande;
