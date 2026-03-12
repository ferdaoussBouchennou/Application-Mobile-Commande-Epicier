const User = require('../models/User');
const Store = require('../models/Store');
const Category = require('../models/Category');
const Product = require('../models/Product');
const { Op } = require('sequelize');

exports.getStats = async (req, res) => {
  try {
    const pendingCount = await User.count({ where: { statut_inscription: 'EN_ATTENTE', role: 'EPICIER' } });
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
      where.statut_inscription = 'EN_ATTENTE';
    } else if (status === 'Actif') {
      where.is_active = true;
      where.statut_inscription = 'ACCEPTE';
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

    if (statut_inscription) user.statut_inscription = statut_inscription;
    if (is_active !== undefined) user.is_active = is_active;

    await user.save();
    res.json({ message: 'Statut mis à jour avec succès', user });
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

    // Créer l'utilisateur (Accepté par défaut car créé par l'admin)
    const newUser = await User.create({
      nom,
      prenom,
      email,
      mdp,
      role: 'EPICIER',
      statut_inscription: 'ACCEPTE',
      is_active: true
    });

    // Créer la boutique
    const newStore = await Store.create({
      utilisateur_id: newUser.id,
      nom_boutique: nom_boutique || `Épicerie de ${prenom}`,
      adresse,
      telephone,
      description: description_boutique,
      is_active: true
    });

    // Ajouter des disponibilités par défaut
    const Availability = require('../models/Availability');
    const jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    for (const jour of jours) {
      await Availability.create({
        epicier_id: newStore.id,
        jour: jour,
        heure_debut: '08:00:00',
        heure_fin: '22:00:00'
      });
    }

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
        return { id: c.id, nom: c.nom, productCount: count };
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
    const productCount = await Product.count({ where: { categorie_id: id } });
    if (productCount > 0) {
      return res.status(400).json({
        message: `Impossible de supprimer : ${productCount} produit(s) utilisent cette catégorie. Supprimez ou déplacez les produits d'abord.`
      });
    }
    await category.destroy();
    res.json({ message: 'Catégorie supprimée.' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
