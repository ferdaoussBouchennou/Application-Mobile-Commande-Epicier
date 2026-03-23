const { DataTypes } = require("sequelize");
const sequelize = require("../config/db");
const User = require("./User");
const Order = require("./Order");

const Reclamation = sequelize.define(
  "Reclamation",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    motif: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    photo: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    statut: {
      type: DataTypes.ENUM(
        "En attente",
        "Résolu",
        "En médiation",
        "Remboursé",
        "Litige ouvert",
      ),
      allowNull: false,
      defaultValue: "En attente",
    },
    reponse_epicier: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    client_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: "utilisateurs",
        key: "id",
      },
    },
    commande_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: "commandes",
        key: "id",
      },
    },
    date_creation: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
  },
  {
    tableName: "reclamations",
    timestamps: false,
  },
);

// Associations
Reclamation.belongsTo(User, { foreignKey: "client_id", as: "client" });
Reclamation.belongsTo(Order, { foreignKey: "commande_id", as: "commande" });
User.hasMany(Reclamation, { foreignKey: "client_id", as: "reclamations" });
Order.hasMany(Reclamation, { foreignKey: "commande_id", as: "reclamations" });

module.exports = Reclamation;
