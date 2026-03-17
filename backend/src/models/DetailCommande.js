const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Commande = require('./Commande');
const Product = require('./Product');

const DetailCommande = sequelize.define('DetailCommande', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  commande_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'commandes', key: 'id' },
  },
  produit_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'produits', key: 'id' },
  },
  quantite: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
  },
  prix_unitaire: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  total_ligne: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
}, {
  tableName: 'detailsCommande',
  timestamps: false,
});

Commande.hasMany(DetailCommande, { foreignKey: 'commande_id' });
DetailCommande.belongsTo(Commande, { foreignKey: 'commande_id' });
Product.hasMany(DetailCommande, { foreignKey: 'produit_id' });
DetailCommande.belongsTo(Product, { foreignKey: 'produit_id' });

module.exports = DetailCommande;
