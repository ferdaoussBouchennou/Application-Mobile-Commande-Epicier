const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Store = require('./Store');

/**
 * Table associative entre épicier et produit (catalogue par épicier).
 * Contient les infos spécifiques à la relation : prix, rupture de stock, visibilité.
 */
const EpicierProduct = sequelize.define('EpicierProduct', {
  epicier_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    primaryKey: true,
    references: {
      model: 'epiciers',
      key: 'id',
    },
  },
  produit_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    primaryKey: true,
    references: {
      model: 'produits',
      key: 'id',
    },
  },
  prix: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  rupture_stock: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
  stock: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
}, {
  tableName: 'epicier_produits',
  timestamps: true,
  createdAt: 'date_ajout',
  updatedAt: 'date_modif',
});

EpicierProduct.belongsTo(Store, { foreignKey: 'epicier_id', as: 'epicier' });
Store.hasMany(EpicierProduct, { foreignKey: 'epicier_id', as: 'epicierProduits' });

module.exports = EpicierProduct;
