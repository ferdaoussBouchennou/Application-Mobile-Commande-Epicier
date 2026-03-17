/**
 * Renomme les fichiers image des produits qui ont un nom générique (image.png, image-1.webp, ...)
 * en le nom du produit stocké en base.
 * À lancer depuis la racine backend : node scripts/rename-existing-product-images.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const path = require('path');
const fs = require('fs');
const { Op } = require('sequelize');

const Product = require('../src/models/Product');

function sanitizeName(str) {
  if (!str || typeof str !== 'string') return '';
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
  const products = await Product.findAll({
    where: { image_principale: { [Op.ne]: null } },
    attributes: ['id', 'nom', 'image_principale'],
  });

  let count = 0;
  for (const product of products) {
    const img = product.image_principale;
    if (!img || typeof img !== 'string' || !img.startsWith('uploads/')) continue;
    const base = path.basename(img);
    const ext = path.extname(base);
    const nameWithoutExt = base.slice(0, -ext.length);
    const isGeneric = nameWithoutExt === 'image' || /^image-\d+$/.test(nameWithoutExt) || nameWithoutExt.startsWith('temp_');
    if (!isGeneric) continue;

    const fullPath = path.join(__dirname, '..', img.replace(/\//g, path.sep));
    if (!fs.existsSync(fullPath)) {
      console.log(`  Fichier introuvable: ${img}`);
      continue;
    }

    const dir = path.dirname(fullPath);
    const folderName = path.basename(dir);
    const baseName = sanitizeName(product.nom) || 'produit';
    const newFilename = `${baseName}${ext}`;
    const newPath = path.join(dir, newFilename);
    if (newPath === fullPath) continue;
    if (fs.existsSync(newPath)) {
      fs.unlinkSync(newPath);
    }
    fs.renameSync(fullPath, newPath);
    const newRelative = path.join('uploads', folderName, newFilename).replace(/\\/g, '/');
    await product.update({ image_principale: newRelative });
    console.log(`  ${img} → ${newRelative} (produit: ${product.nom})`);
    count += 1;
  }

  console.log(`Terminé: ${count} image(s) renommée(s) selon le nom du produit.`);

  const uploadsRoot = path.join(__dirname, '..', 'uploads');
  const allPaths = await Product.findAll({
    where: { image_principale: { [Op.ne]: null } },
    attributes: ['image_principale'],
  }).then((rows) => new Set(rows.map((r) => (r.image_principale || '').replace(/\\/g, '/'))));

  let orphansRemoved = 0;
  function scanDir(dir) {
    if (!fs.existsSync(dir)) return;
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const e of entries) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) {
        scanDir(full);
        continue;
      }
      const base = e.name;
      const ext = path.extname(base);
      const nameWithoutExt = base.slice(0, -ext.length);
      const isGeneric = nameWithoutExt === 'image' || /^image-\d+$/.test(nameWithoutExt) || nameWithoutExt.startsWith('temp_');
      if (!isGeneric) continue;
      const relative = path.relative(uploadsRoot, full).replace(/\\/g, '/');
      const withUploads = 'uploads/' + relative;
      if (allPaths.has(withUploads)) continue;
      try {
        fs.unlinkSync(full);
        console.log(`  Orphelin supprimé: ${withUploads}`);
        orphansRemoved += 1;
      } catch (err) {
        console.warn(`  Impossible de supprimer ${full}:`, err.message);
      }
    }
  }
  scanDir(uploadsRoot);
  if (orphansRemoved > 0) {
    console.log(`Fichiers orphelins supprimés: ${orphansRemoved}`);
  }
  process.exit(0);
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
