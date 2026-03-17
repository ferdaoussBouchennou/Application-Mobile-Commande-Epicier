const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const Panier = sequelize.define('Panier', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  client_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true,
    references: {
      model: 'utilisateurs',
      key: 'id',
    },
  },
  date_creation: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
}, {
  tableName: 'paniers',
  timestamps: false,
});

User.hasOne(Panier, { foreignKey: 'client_id' });
Panier.belongsTo(User, { foreignKey: 'client_id' });

module.exports = Panier;
