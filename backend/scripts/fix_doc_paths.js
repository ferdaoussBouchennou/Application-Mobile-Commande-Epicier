const { Sequelize, DataTypes } = require('sequelize');
const path = require('path');
const fs = require('fs');
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

async function fixPaths() {
  try {
    const users = await User.findAll({
      where: { role: 'EPICIER' }
    });

    console.log(`Analyse de ${users.length} épiciers...`);

    const uploadsDir = path.join(__dirname, '..', 'uploads', 'documents');
    
    for (const user of users) {
      const currentPath = user.doc_verf;
      
      if (!currentPath) {
        console.log(`[ID ${user.id}] Aucun document configuré.`);
        continue;
      }

      // Si le chemin est déjà correct, on passe
      if (currentPath.startsWith('uploads/')) {
        console.log(`[ID ${user.id}] Chemin correct: ${currentPath}`);
        continue;
      }

      // Si c'est juste un nom de fichier, on essaie de le trouver dans uploads/documents
      const fileName = path.basename(currentPath);
      const possiblePath = path.join(uploadsDir, fileName);

      if (fs.existsSync(possiblePath)) {
        const newPath = `uploads/documents/${fileName}`;
        console.log(`[ID ${user.id}] Correction: ${currentPath} -> ${newPath}`);
        
        await User.update(
          { doc_verf: newPath },
          { where: { id: user.id } }
        );
      } else {
        console.warn(`[ID ${user.id}] ATTENTION: Fichier introuvable sur le disque: ${fileName}`);
        // On pourrait aussi essayer de chercher dans le dossier parent uploads/ au cas où
        const altPath = path.join(__dirname, '..', 'uploads', fileName);
        if (fs.existsSync(altPath)) {
            const newPath = `uploads/${fileName}`;
            console.log(`[ID ${user.id}] Correction (alt): ${currentPath} -> ${newPath}`);
            await User.update({ doc_verf: newPath }, { where: { id: user.id } });
        }
      }
    }

    console.log('Correction terminée !');
  } catch (error) {
    console.error('Erreur lors de la correction:', error);
  } finally {
    await sequelize.close();
  }
}

fixPaths();
