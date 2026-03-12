const path = require('path');
const fs = require('fs');
const User = require('../models/User');
const Store = require('../models/Store');
const Category = require('../models/Category');
const Product = require('../models/Product');
const EpicierProduct = require('../models/EpicierProduct');
const Order = require('../models/Order');
const Reclamation = require('../models/Reclamation');
const { Op } = require('sequelize');

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

exports.getStats = async (req, res) => {
  try {
    const pendingCount = await Store.count({ where: { statut_inscription: 'EN_ATTENTE' } });
    const activeCount = await User.count({ where: { is_active: true, role: { [Op.in]: ['CLIENT', 'EPICIER'] } } });
    const suspendedCount = await User.count({ where: { is_active: false, role: { [Op.in]: ['CLIENT', 'EPICIER'] } } });

    res.json({
      pending: pendingCount,
      active: activeCount,
      suspended: suspendedCount
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getUsers = async (req, res) => {
  try {
    const { role, status } = req.query;
    let where = { role: { [Op.ne]: 'ADMIN' } };

    if (role) where.role = role;

    if (status === 'EN_ATTENTE') {
      where['$epicier.statut_inscription$'] = 'EN_ATTENTE';
    } else if (status === 'Actif') {
      where.is_active = true;
    } else if (status === 'Suspendu') {
      where.is_active = false;
    }

    const users = await User.findAll({
      where: where,
      include: [{
        model: Store,
        as: 'epicier',
        required: false
      }],
      order: [['date_creation', 'DESC']]
    });

    res.json(users);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { statut_inscription, is_active } = req.body;

    const user = await User.findByPk(id);
    if (!user) return res.status(404).json({ error: 'Utilisateur non trouvé' });

    if (is_active !== undefined) {
      user.is_active = is_active;
      await user.save();
    }

    if (statut_inscription && user.role === 'EPICIER') {
      const store = await Store.findOne({ where: { utilisateur_id: id } });
      if (store) {
        store.statut_inscription = statut_inscription;
        await store.save();
      }
    }

    const updatedUser = await User.findByPk(id, {
      include: [{ model: Store, as: 'epicier', required: false }],
    });

    res.json({ message: 'Statut mis à jour avec succès', user: updatedUser });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.registerEpicier = async (req, res) => {
  try {
    const { nom, prenom, email, mdp, adresse, telephone, nom_boutique, description_boutique } = req.body;

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'Cet email est déjà utilisé.' });
    }

    const newUser = await User.create({
      nom,
      prenom,
      email,
      mdp,
      role: 'EPICIER',
      is_active: true
    });

    const newStore = await Store.create({
      utilisateur_id: newUser.id,
      nom_boutique: nom_boutique || `Épicerie de ${prenom}`,
      adresse,
      telephone,
      description: description_boutique,
      statut_inscription: 'ACCEPTE',
      is_active: true
    });

    res.status(201).json({
      message: 'Épicier créé manuellement avec succès',
      user: { id: newUser.id, nom: newUser.nom, email: newUser.email },
      store: newStore
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// --- Gestion des catégories (plateforme) ---

exports.getCategories = async (req, res) => {
  try {
    const categories = await Category.findAll({
      order: [['nom', 'ASC']],
      attributes: ['id', 'nom']
    });
    const list = await Promise.all(
      categories.map(async (c) => {
        const count = await Product.count({ where: { categorie_id: c.id } });
        const activeCount = await EpicierProduct.count({
          include: [{ model: Product, as: 'produit', where: { categorie_id: c.id }, attributes: [] }],
          where: { is_active: true }
        });
        return {
          id: c.id,
          nom: c.nom,
          productCount: count,
          activeProductCount: activeCount
        };
      })
    );
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.createCategory = async (req, res) => {
  try {
    const { nom } = req.body;
    if (!nom || typeof nom !== 'string' || !nom.trim()) {
      return res.status(400).json({ message: 'Le nom de la catégorie est requis.' });
    }
    const existing = await Category.findOne({ where: { nom: nom.trim() } });
    if (existing) {
      return res.status(400).json({ message: 'Une catégorie avec ce nom existe déjà.' });
    }
    const category = await Category.create({ nom: nom.trim() });
    res.status(201).json({ id: category.id, nom: category.nom });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { nom } = req.body;
    if (!nom || typeof nom !== 'string' || !nom.trim()) {
      return res.status(400).json({ message: 'Le nom de la catégorie est requis.' });
    }
    const category = await Category.findByPk(id);
    if (!category) {
      return res.status(404).json({ message: 'Catégorie non trouvée.' });
    }
    const existing = await Category.findOne({ where: { nom: nom.trim(), id: { [Op.ne]: id } } });
    if (existing) {
      return res.status(400).json({ message: 'Une autre catégorie avec ce nom existe déjà.' });
    }
    category.nom = nom.trim();
    await category.save();
    res.json({ id: category.id, nom: category.nom });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const category = await Category.findByPk(id);
    if (!category) {
      return res.status(404).json({ message: 'Catégorie non trouvée.' });
    }
    const productIds = await Product.findAll({ where: { categorie_id: id }, attributes: ['id'] }).then((rows) => rows.map((r) => r.id));
    const productCount = productIds.length;
    if (productCount > 0) {
      await EpicierProduct.update(
        { is_active: false },
        { where: { produit_id: productIds } }
      );
      return res.json({
        message: `Catégorie désactivée : ${productCount} produit(s) ont été retirés du catalogue pour tous les épiciers.`,
        deactivated: true,
        productCount
      });
    }
    await category.destroy();
    res.json({ message: 'Catégorie supprimée.' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.activateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const category = await Category.findByPk(id);
    if (!category) {
      return res.status(404).json({ message: 'Catégorie non trouvée.' });
    }
    const productIds = await Product.findAll({ where: { categorie_id: id }, attributes: ['id'] }).then((rows) => rows.map((r) => r.id));
    const [updatedCount] = productIds.length
      ? await EpicierProduct.update({ is_active: true }, { where: { produit_id: productIds } })
      : [0];
    res.json({
      message: `Catégorie réactivée : ${updatedCount} produit(s) remis au catalogue.`,
      productCount: updatedCount
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// --- Gestion des produits par catégorie (admin) ---

exports.getStores = async (req, res) => {
  try {
    const stores = await Store.findAll({
      where: { statut_inscription: { [Op.in]: ['ACCEPTE', 'COMPLETE'] }, is_active: true },
      attributes: ['id', 'nom_boutique'],
      order: [['nom_boutique', 'ASC']]
    });
    res.json(stores.map(s => ({ id: s.id, nom_boutique: s.nom_boutique })));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getCategoryProducts = async (req, res) => {
  try {
    const categoryId = parseInt(req.params.categoryId, 10);
    if (Number.isNaN(categoryId)) {
      return res.status(400).json({ message: 'Identifiant de catégorie invalide.' });
    }
    const category = await Category.findByPk(categoryId);
    if (!category) {
      return res.status(404).json({ message: 'Catégorie non trouvée.' });
    }
    const linkList = await EpicierProduct.findAll({
      include: [
        { model: Product, as: 'produit', where: { categorie_id: categoryId } },
        { model: Store, as: 'epicier', attributes: ['id', 'nom_boutique'] }
      ],
      order: [[{ model: Product, as: 'produit' }, 'nom', 'ASC']]
    });
    const list = linkList.filter(ep => ep.produit).map(ep => ({
      id: ep.produit.id,
      nom: ep.produit.nom,
      prix: parseFloat(ep.prix),
      description: ep.produit.description,
      epicier_id: ep.epicier_id,
      categorie_id: ep.produit.categorie_id,
      image_principale: ep.produit.image_principale,
      is_active: !!ep.is_active,
      rupture_stock: !!ep.rupture_stock,
      store_name: ep.epicier?.nom_boutique ?? null
    }));
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.createProduct = async (req, res) => {
  try {
    const { epicier_id, categorie_id, nom, prix, description, image_principale } = req.body;
    if (!nom || !nom.trim() || prix == null || !categorie_id || !epicier_id) {
      return res.status(400).json({ message: 'Nom, prix, catégorie et épicier sont requis.' });
    }
    const category = await Category.findByPk(categorie_id);
    if (!category) {
      return res.status(404).json({ message: 'Catégorie non trouvée.' });
    }
    const store = await Store.findByPk(epicier_id);
    if (!store) {
      return res.status(404).json({ message: 'Épicier (boutique) non trouvé.' });
    }
    const [product] = await Product.findOrCreate({
      where: { nom: nom.trim(), categorie_id: parseInt(categorie_id, 10) },
      defaults: {
        nom: nom.trim(),
        description: description?.trim() || null,
        categorie_id: parseInt(categorie_id, 10),
        image_principale: image_principale?.trim() || null
      }
    });
    const [epicierProduct, created] = await EpicierProduct.findOrCreate({
      where: { epicier_id: parseInt(epicier_id, 10), produit_id: product.id },
      defaults: { epicier_id: parseInt(epicier_id, 10), produit_id: product.id, prix: parseFloat(prix), is_active: true }
    });
    if (!created) {
      epicierProduct.prix = parseFloat(prix);
      epicierProduct.is_active = true;
      await epicierProduct.save();
    }
    res.status(201).json({
      id: product.id,
      nom: product.nom,
      prix: parseFloat(epicierProduct.prix),
      description: product.description,
      epicier_id: parseInt(epicier_id, 10),
      categorie_id: product.categorie_id,
      image_principale: product.image_principale,
      is_active: true,
      store_name: store.nom_boutique
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { nom, prix, description, image_principale, epicier_id } = req.body;
    const product = await Product.findByPk(id);
    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé.' });
    }
    if (nom != null && typeof nom === 'string') product.nom = nom.trim();
    if (description !== undefined) product.description = description?.trim() || null;
    if (image_principale !== undefined) product.image_principale = image_principale?.trim() || null;
    await product.save();
    if (epicier_id != null && prix != null) {
      const link = await EpicierProduct.findOne({ where: { epicier_id: parseInt(epicier_id, 10), produit_id: product.id } });
      if (link) {
        link.prix = parseFloat(prix);
        await link.save();
      }
    }
    const epicierId = epicier_id != null ? parseInt(epicier_id, 10) : (await EpicierProduct.findOne({ where: { produit_id: product.id } }))?.epicier_id;
    const store = epicierId ? await Store.findByPk(epicierId, { attributes: ['nom_boutique'] }) : null;
    const link = epicierId ? await EpicierProduct.findOne({ where: { epicier_id: epicierId, produit_id: product.id } }) : null;
    res.json({
      id: product.id,
      nom: product.nom,
      prix: link ? parseFloat(link.prix) : 0,
      description: product.description,
      epicier_id: epicierId ?? null,
      categorie_id: product.categorie_id,
      image_principale: product.image_principale,
      is_active: link ? !!link.is_active : false,
      store_name: store?.nom_boutique ?? null
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deactivateProduct = async (req, res) => {
  try {
    const produitId = parseInt(req.params.id, 10);
    const epicierId = req.body?.epicier_id != null ? parseInt(req.body.epicier_id, 10) : null;
    if (Number.isNaN(produitId)) {
      return res.status(400).json({ message: 'Identifiant de produit invalide.' });
    }
    if (epicierId == null || Number.isNaN(epicierId)) {
      return res.status(400).json({ message: 'epicier_id est requis pour désactiver un produit pour un épicier spécifique.' });
    }
    const product = await Product.findByPk(produitId);
    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé.' });
    }
    const [updated] = await EpicierProduct.update(
      { is_active: false },
      { where: { produit_id: produitId, epicier_id: epicierId } }
    );
    res.json({ message: 'Produit retiré du catalogue pour cet épicier.', updatedCount: updated });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.activateProduct = async (req, res) => {
  try {
    const produitId = parseInt(req.params.id, 10);
    const epicierId = req.body?.epicier_id != null ? parseInt(req.body.epicier_id, 10) : null;
    if (Number.isNaN(produitId)) {
      return res.status(400).json({ message: 'Identifiant de produit invalide.' });
    }
    if (epicierId == null || Number.isNaN(epicierId)) {
      return res.status(400).json({ message: 'epicier_id est requis pour activer un produit pour un épicier spécifique.' });
    }
    const product = await Product.findByPk(produitId);
    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé.' });
    }
    const [updated] = await EpicierProduct.update(
      { is_active: true },
      { where: { produit_id: produitId, epicier_id: epicierId } }
    );
    res.json({ message: 'Produit réactivé dans le catalogue pour cet épicier.', updatedCount: updated });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.toggleRuptureStock = async (req, res) => {
  try {
    const produitId = parseInt(req.params.id, 10);
    const epicierId = req.body?.epicier_id != null ? parseInt(req.body.epicier_id, 10) : null;
    if (Number.isNaN(produitId)) {
      return res.status(400).json({ message: 'Identifiant de produit invalide.' });
    }
    if (epicierId == null || Number.isNaN(epicierId)) {
      return res.status(400).json({ message: 'epicier_id est requis pour la rupture de stock.' });
    }
    const epicierProduct = await EpicierProduct.findOne({
      where: { produit_id: produitId, epicier_id: epicierId },
      include: [{ model: Product, as: 'produit', attributes: ['id', 'nom'] }],
    });
    if (!epicierProduct || !epicierProduct.produit) {
      return res.status(404).json({ message: 'Lien épicier-produit non trouvé.' });
    }
    epicierProduct.rupture_stock = !epicierProduct.rupture_stock;
    await epicierProduct.save();
    res.json({
      message: epicierProduct.rupture_stock ? 'Produit marqué en rupture de stock.' : 'Produit remis en stock.',
      rupture_stock: epicierProduct.rupture_stock,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.uploadProductImage = async (req, res) => {
  try {
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({ message: 'Aucun fichier image envoyé.' });
    }
    const categorieId = req.body.categorie_id;
    if (!categorieId) {
      return res.status(400).json({ message: 'categorie_id est requis.' });
    }
    const category = await Category.findByPk(categorieId);
    if (!category) {
      return res.status(400).json({ message: 'Catégorie introuvable.' });
    }
    const folderName = sanitizeName(category.nom) || 'categorie';
    const dir = path.join(__dirname, '..', '..', 'uploads', folderName);
    fs.mkdirSync(dir, { recursive: true });
    const ext = path.extname(req.file.originalname) || '.jpg';
    const safeExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext.toLowerCase()) ? ext : '.jpg';
    const productName = req.body.nom ? String(req.body.nom).trim() : '';
    const baseName = sanitizeName(productName) || `temp_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
    let filename = `${baseName}${safeExt}`;
    let filePath = path.join(dir, filename);
    let suffix = 0;
    while (fs.existsSync(filePath)) {
      suffix += 1;
      filename = `${baseName}-${suffix}${safeExt}`;
      filePath = path.join(dir, filename);
    }
    fs.writeFileSync(filePath, req.file.buffer);
    const relativePath = path.join('uploads', folderName, filename).replace(/\\/g, '/');
    res.status(200).json({ image_principale: relativePath });
  } catch (error) {
    console.error('Erreur uploadProductImage admin:', error);
    res.status(500).json({ message: 'Erreur lors de l\'upload de l\'image', error: error.message });
  }
};

// --- Gestion des commandes et litiges ---

exports.getOrderStats = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const totalToday = await Order.count({
      where: {
        date_commande: { [Op.gte]: today }
      }
    });

    const ongoingCount = await Order.count({
      where: {
        statut: { [Op.in]: ['reçue', 'prête'] }
      }
    });

    const disputeCount = await Reclamation.count({
      where: { statut: { [Op.in]: ['non resolut', 'en attente'] } }
    });

    res.json({
      totalToday,
      ongoing: ongoingCount,
      disputes: disputeCount
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getRecentOrders = async (req, res) => {
  try {
    const orders = await Order.findAll({
      limit: 10,
      order: [['date_commande', 'DESC']],
      include: [
        { model: User, as: 'client', attributes: ['nom', 'prenom'] }
      ]
    });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getDisputes = async (req, res) => {
  try {
    const disputes = await Reclamation.findAll({
      order: [['date_creation', 'DESC']],
      include: [
        { model: User, as: 'client', attributes: ['nom', 'prenom'] },
        { 
          model: Order, 
          as: 'commande',
          include: [{ model: Store, as: 'epicier', attributes: ['nom_boutique'] }]
        }
      ]
    });
    res.json(disputes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.resolveDispute = async (req, res) => {
  try {
    const { id } = req.params;
    const { statut } = req.body; // Expecting 'resolut', 'en attente', 'rembourser', 'non resolut'

    const dispute = await Reclamation.findByPk(id);
    if (!dispute) return res.status(404).json({ error: 'Réclamation non trouvée' });

    dispute.statut = statut || 'resolut';
    await dispute.save();

    res.json({ message: 'Réclamation mise à jour', dispute });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
