const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const Store = sequelize.define('Store', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  utilisateur_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true,
    references: {
      model: 'utilisateurs',
      key: 'id'
    }
  },
  nom_boutique: {
    type: DataTypes.STRING(200),
    allowNull: false,
  },
  adresse: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  telephone: {
    type: DataTypes.STRING(20),
    allowNull: true,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  image_url: {
    type: DataTypes.STRING(500),
    allowNull: true,
  },
  rating: {
    type: DataTypes.DECIMAL(2, 1),
    defaultValue: 0.0,
  },
  statut_inscription: {
    type: DataTypes.ENUM('EN_ATTENTE', 'ACCEPTE', 'REFUSE'),
    allowNull: false,
    defaultValue: 'EN_ATTENTE',
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
}, {
  tableName: 'epiciers',
  timestamps: true,
  createdAt: 'date_creation',
  updatedAt: false,
});

// Associations
User.hasOne(Store, { foreignKey: 'utilisateur_id', as: 'epicier', onDelete: 'CASCADE' });
Store.belongsTo(User, { foreignKey: 'utilisateur_id', as: 'utilisateur' });

module.exports = Store;
