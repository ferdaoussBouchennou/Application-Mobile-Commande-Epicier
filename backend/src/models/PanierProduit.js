const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Panier = require('./Panier');
const Product = require('./Product');

const PanierProduit = sequelize.define('PanierProduit', {
  panier_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    primaryKey: true,
    references: {
      model: 'paniers',
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
  quantite: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
  },
}, {
  tableName: 'panier_produits',
  timestamps: false,
});

Panier.belongsToMany(Product, {
  through: PanierProduit,
  foreignKey: 'panier_id',
  otherKey: 'produit_id',
  as: 'produits',
});
Product.belongsToMany(Panier, {
  through: PanierProduit,
  foreignKey: 'produit_id',
  otherKey: 'panier_id',
  as: 'paniers',
});
Panier.hasMany(PanierProduit, { foreignKey: 'panier_id' });
PanierProduit.belongsTo(Panier, { foreignKey: 'panier_id' });
Product.hasMany(PanierProduit, { foreignKey: 'produit_id' });
PanierProduit.belongsTo(Product, { foreignKey: 'produit_id' });

module.exports = PanierProduit;
