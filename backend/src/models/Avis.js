const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');
const Store = require('./Store');
const Commande = require('./Commande');

const Avis = sequelize.define('Avis', {
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
  note: {
    type: DataTypes.TINYINT,
    allowNull: false,
    validate: { min: 1, max: 5 },
  },
  commentaire: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  date_avis: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'avis',
  timestamps: false,
});

User.hasMany(Avis, { foreignKey: 'client_id' });
Avis.belongsTo(User, { foreignKey: 'client_id', as: 'client' });
Store.hasMany(Avis, { foreignKey: 'epicier_id' });
Avis.belongsTo(Store, { foreignKey: 'epicier_id' });


module.exports = Avis;
