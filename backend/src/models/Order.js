const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');
const Store = require('./Store');

const Order = sequelize.define('Order', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  client_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'utilisateurs',
      key: 'id'
    }
  },
  epicier_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'epiciers',
      key: 'id'
    }
  },
  date_commande: {
    type: DataTypes.DATE,
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
    defaultValue: 0.00,
  },
}, {
  tableName: 'commandes',
  timestamps: false,
});

// Associations
Order.belongsTo(User, { foreignKey: 'client_id', as: 'client' });
Order.belongsTo(Store, { foreignKey: 'epicier_id', as: 'epicier' });
User.hasMany(Order, { foreignKey: 'client_id', as: 'commandes' });
Store.hasMany(Order, { foreignKey: 'epicier_id', as: 'commandes' });

module.exports = Order;
