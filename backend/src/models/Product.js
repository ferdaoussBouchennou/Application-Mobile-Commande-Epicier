const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Store = require('./Store');
const Category = require('./Category');

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
  prix: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  epicier_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'epiciers',
      key: 'id',
    },
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

// Associations
Store.hasMany(Product, { foreignKey: 'epicier_id', as: 'produits' });
Product.belongsTo(Store, { foreignKey: 'epicier_id', as: 'epicier' });

Category.hasMany(Product, { foreignKey: 'categorie_id', as: 'produits' });
Product.belongsTo(Category, { foreignKey: 'categorie_id', as: 'categorie' });

module.exports = Product;
