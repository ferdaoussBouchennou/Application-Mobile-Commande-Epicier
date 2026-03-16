const { DataTypes } = require("sequelize");
const sequelize = require("../config/db");
const bcrypt = require("bcrypt");

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
  id_facebook: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  id_instagram: {
    type: DataTypes.STRING(100),
    allowNull: true,
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
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  fcm_token: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
}, {
  tableName: 'utilisateurs',
  timestamps: true,
  createdAt: 'date_creation',
  updatedAt: false, 
  validate: {
    checkEpicierDoc() {
      if (this.role === 'EPICIER' && !this.doc_verf) {
        throw new Error("Un document de vérification est obligatoire pour s'inscrire en tant qu'épicier.");
      }
    }
  },
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
