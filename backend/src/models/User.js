const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const bcrypt = require('bcrypt');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  nom: {
    type: DataTypes.STRING(100),
    allowNull: false,
  },
  prenom: {
    type: DataTypes.STRING(100),
    allowNull: false,
  },
  email: {
    type: DataTypes.STRING(150),
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true,
    },
  },
  mdp: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  id_google: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  telephone: {
    type: DataTypes.STRING(20),
    allowNull: true,
  },
  adresse: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  role: {
    type: DataTypes.ENUM('CLIENT', 'ADMIN', 'EPICIER'),
    allowNull: false,
    defaultValue: 'CLIENT',
  },
  doc_verf: {
    type: DataTypes.STRING(255), // Augmenté pour laisser place aux noms de fichiers longs
    allowNull: true,
  },
  statut_inscription: {
    type: DataTypes.ENUM('EN_ATTENTE', 'ACCEPTE', 'REFUSE'),
    allowNull: false,
    defaultValue: 'ACCEPTE', // Par défaut pour le CLIENT. Pour l'épicier, on forcera EN_ATTENTE.
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
}, {
  tableName: 'utilisateurs',
  timestamps: true,
  createdAt: 'date_creation',
  updatedAt: false, 
  hooks: {
    beforeCreate: async (user) => {
      if (user.mdp) {
        const salt = await bcrypt.genSalt(10);
        user.mdp = await bcrypt.hash(user.mdp, salt);
      }
    },
    beforeUpdate: async (user) => {
      if (user.changed('mdp')) {
        const salt = await bcrypt.genSalt(10);
        user.mdp = await bcrypt.hash(user.mdp, salt);
      }
    }
  }
});

module.exports = User;
