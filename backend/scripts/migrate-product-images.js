/**
 * Migration : déplacer les images de uploads/categories/<id>/ vers uploads/<nom_catégorie>/<nom_produit>.<ext>
 * et mettre à jour image_principale en base.
 * À lancer depuis la racine backend : node scripts/migrate-product-images.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const path = require('path');
const fs = require('fs');

const sequelize = require('../src/config/db');
const Product = require('../src/models/Product');
const Category = require('../src/models/Category');

const UPLOADS_ROOT = path.join(__dirname, '..', 'uploads');
const CATEGORIES_LEGACY_DIR = path.join(UPLOADS_ROOT, 'categories');

function sanitizeName(str) {
  if (!str || typeof str !== 'string') return 'image';
  return str
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .replace(/[\s]+/g, '_')
    .replace(/[^a-zA-Z0-9_-]/g, '')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '')
    .slice(0, 80) || 'image';
}

async function run() {
  if (!fs.existsSync(CATEGORIES_LEGACY_DIR)) {
    console.log('Aucun dossier uploads/categories trouvé. Rien à migrer.');
    process.exit(0);
  }

  const subdirs = fs.readdirSync(CATEGORIES_LEGACY_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name);

  if (subdirs.length === 0) {
    console.log('Aucun sous-dossier dans uploads/categories.');
    process.exit(0);
  }

  console.log('Dossiers à migrer (IDs catégorie):', subdirs.join(', '));

  for (const categoryIdStr of subdirs) {
    const categoryDir = path.join(CATEGORIES_LEGACY_DIR, categoryIdStr);
    const files = fs.readdirSync(categoryDir).filter((f) => {
      const p = path.join(categoryDir, f);
      return fs.statSync(p).isFile();
    });

    const category = await Category.findByPk(categoryIdStr);
    const folderName = category ? sanitizeName(category.nom) : `categorie_${categoryIdStr}`;
    const targetDir = path.join(UPLOADS_ROOT, folderName);

    for (const filename of files) {
      const legacyRelative = `uploads/categories/${categoryIdStr}/${filename}`.replace(/\\/g, '/');
      const oldPath = path.join(categoryDir, filename);
      const ext = path.extname(filename);

      const products = await Product.findAll({ where: { image_principale: legacyRelative } });
      if (products.length === 0) {
        console.log(`  Fichier orphelin (aucun produit) : ${filename} → déplacé avec nom générique`);
      }

      const product = products[0];
      const baseName = product ? sanitizeName(product.nom) : path.basename(filename, ext) || 'image';
      let newFilename = `${baseName}${ext}`;
      let newPath = path.join(targetDir, newFilename);
      let suffix = 0;
      while (fs.existsSync(newPath)) {
        suffix += 1;
        newFilename = `${baseName}-${suffix}${ext}`;
        newPath = path.join(targetDir, newFilename);
      }

      fs.mkdirSync(targetDir, { recursive: true });
      fs.copyFileSync(oldPath, newPath);

      const newRelative = path.join('uploads', folderName, newFilename).replace(/\\/g, '/');
      if (product) {
        await product.update({ image_principale: newRelative });
        console.log(`  ${filename} → ${newRelative} (produit: ${product.nom})`);
      } else {
        console.log(`  ${filename} → ${newRelative} (sans produit)`);
      }
    }

    for (const filename of files) {
      const oldPath = path.join(categoryDir, filename);
      fs.unlinkSync(oldPath);
    }
  }

  for (const categoryIdStr of subdirs) {
    const categoryDir = path.join(CATEGORIES_LEGACY_DIR, categoryIdStr);
    if (fs.existsSync(categoryDir) && fs.readdirSync(categoryDir).length === 0) {
      fs.rmdirSync(categoryDir);
      console.log(`Dossier vide supprimé : categories/${categoryIdStr}`);
    }
  }

  try {
    if (fs.existsSync(CATEGORIES_LEGACY_DIR) && fs.readdirSync(CATEGORIES_LEGACY_DIR).length === 0) {
      fs.rmdirSync(CATEGORIES_LEGACY_DIR);
      console.log('Dossier uploads/categories supprimé (vide).');
    }
  } catch (_) {}

  console.log('Migration terminée.');
  process.exit(0);
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
