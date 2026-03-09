const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Store = require('./Store');

const Availability = sequelize.define('Availability', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  epicier_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'epiciers',
      key: 'id'
    }
  },
  jour: {
    type: DataTypes.ENUM('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
    allowNull: false,
  },
  heure_debut: {
    type: DataTypes.TIME,
    allowNull: false,
  },
  heure_fin: {
    type: DataTypes.TIME,
    allowNull: false,
  },
}, {
  tableName: 'disponibilites',
  timestamps: false,
});

// Associations
Store.hasMany(Availability, { foreignKey: 'epicier_id', as: 'disponibilites', onDelete: 'CASCADE' });
Availability.belongsTo(Store, { foreignKey: 'epicier_id' });

module.exports = Availability;
