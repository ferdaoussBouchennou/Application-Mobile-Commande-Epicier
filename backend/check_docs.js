const { Sequelize, DataTypes } = require('sequelize');
require('dotenv').config();

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASS || '',
  {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    logging: false,
  }
);

const User = sequelize.define('User', {
  id: { type: DataTypes.INTEGER, primaryKey: true },
  email: DataTypes.STRING,
  role: DataTypes.STRING,
  doc_verf: DataTypes.STRING,
}, {
  tableName: 'utilisateurs',
  timestamps: true,
  createdAt: 'date_creation',
  updatedAt: false,
});

async function checkDocs() {
  try {
    const users = await User.findAll({
      where: { role: 'EPICIER' },
      attributes: ['id', 'email', 'doc_verf']
    });
    console.log('Epicier Users and their doc_verf:');
    users.forEach(u => {
      console.log(`ID: ${u.id}, Email: ${u.email}, doc_verf: ${u.doc_verf}`);
    });
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await sequelize.close();
  }
}

checkDocs();
