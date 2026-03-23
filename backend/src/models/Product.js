const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Category = require('./Category');
const EpicierProduct = require('./EpicierProduct');
const Store = require('./Store');

/** Table produit : uniquement les infos du produit (catalogue global). */
const Product = sequelize.define('Product', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  nom: {
    type: DataTypes.STRING(200),
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  categorie_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'categories',
      key: 'id',
    },
  },
  image_principale: {
    type: DataTypes.STRING(500),
    allowNull: true,
  },
}, {
  tableName: 'produits',
  timestamps: true,
  createdAt: 'date_ajout',
  updatedAt: 'date_modif',
});

Category.hasMany(Product, { foreignKey: 'categorie_id', as: 'produits' });
Product.belongsTo(Category, { foreignKey: 'categorie_id', as: 'categorie' });

Product.belongsToMany(Store, { through: EpicierProduct, foreignKey: 'produit_id', otherKey: 'epicier_id', as: 'epiciers' });
Store.belongsToMany(Product, { through: EpicierProduct, foreignKey: 'epicier_id', otherKey: 'produit_id', as: 'produits' });
Product.hasMany(EpicierProduct, { foreignKey: 'produit_id', as: 'epicierProduits' });
EpicierProduct.belongsTo(Product, { foreignKey: 'produit_id', as: 'produit' });

module.exports = Product;
