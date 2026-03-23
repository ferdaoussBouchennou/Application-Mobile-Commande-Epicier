const path = require("path");
const fs = require("fs");
const sequelize = require("../config/db");
const User = require("../models/User");
const Store = require("../models/Store");
const Category = require("../models/Category");
const Product = require("../models/Product");
const EpicierProduct = require("../models/EpicierProduct");
const Commande = require("../models/Commande");
const Avis = require("../models/Avis");
const Reclamation = require("../models/Reclamation");
const { Op } = require("sequelize");
const { sendNotificationToEpicier } = require("../utils/notificationEpicier");

function sanitizeName(str) {
  if (!str || typeof str !== "string") return "";
  return (
    str
      .normalize("NFD")
      .replace(/\p{Diacritic}/gu, "")
      .replace(/[\s]+/g, "_")
      .replace(/[^a-zA-Z0-9_-]/g, "")
      .replace(/_+/g, "_")
      .replace(/^_|_$/g, "")
      .slice(0, 80) || "image"
  );
}

exports.getStats = async (req, res) => {
  try {
    const { role } = req.query;
    let userWhere = { role: { [Op.ne]: "ADMIN" } };
    let storeWhere = {};

    if (role) {
      userWhere.role = role;
      storeWhere["$utilisateur.role$"] = role;
    }

    const pendingCount = await Store.count({
      where: { ...storeWhere, statut_inscription: "EN_ATTENTE" },
      include: role
        ? [{ model: User, as: "utilisateur", where: { role } }]
        : [],
    });

    const activeCount = await User.count({
      where: { ...userWhere, is_active: true },
    });

    const suspendedCount = await User.count({
      where: { ...userWhere, is_active: false },
    });

    res.json({
      pending: pendingCount,
      active: activeCount,
      suspended: suspendedCount,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getUsers = async (req, res) => {
  try {
    const { role, status, search } = req.query;
    let where = { role: { [Op.ne]: "ADMIN" } };

    if (role) where.role = role;

    if (search) {
      where[Op.or] = [
        { nom: { [Op.like]: `%${search}%` } },
        { prenom: { [Op.like]: `%${search}%` } },
        { "$epicier.nom_boutique$": { [Op.like]: `%${search}%` } },
      ];
    }

    if (status === "EN_ATTENTE") {
      where["$epicier.statut_inscription$"] = "EN_ATTENTE";
    } else if (status === "Actif") {
      where.is_active = true;
    } else if (status === "Suspendu") {
      where.is_active = false;
    }

    const users = await User.findAll({
      where: where,
      include: [
        {
          model: Store,
          as: "epicier",
          required: false,
          attributes: {
            include: [
              [
                sequelize.literal(`(
                SELECT COUNT(*)
                FROM epicier_produits AS ep
                WHERE ep.epicier_id = epicier.id AND ep.is_active = 1
              )`),
                "produits_count",
              ],
              [
                sequelize.literal(`(
                SELECT COUNT(*)
                FROM commandes AS c
                WHERE c.epicier_id = epicier.id
              )`),
                "commandes_count",
              ],
              [
                sequelize.literal(`(
                SELECT COUNT(*)
                FROM epicier_produits AS ep
                WHERE ep.epicier_id = epicier.id AND ep.rupture_stock = 1 AND ep.is_active = 1
              )`),
                "rupture_count",
              ],
            ],
          },
        },
      ],
      subQuery: false, // Required for Op.or on included model attributes
      order: [["date_creation", "DESC"]],
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
    if (!user) return res.status(404).json({ error: "Utilisateur non trouvé" });

    if (is_active !== undefined) {
      user.is_active = is_active;
      await user.save();
    }

    if (statut_inscription && user.role === "EPICIER") {
      const store = await Store.findOne({ where: { utilisateur_id: id } });
      if (store) {
        store.statut_inscription = statut_inscription;
        await store.save();
      }
    }

    const updatedUser = await User.findByPk(id, {
      include: [{ model: Store, as: "epicier", required: false }],
    });

    res.json({ message: "Statut mis à jour avec succès", user: updatedUser });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateUserDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const { nom, prenom, email } = req.body;
    const user = await User.findByPk(id);
    if (!user) return res.status(404).json({ error: "Utilisateur non trouvé" });

    if (nom) user.nom = nom.trim();
    if (prenom) user.prenom = prenom.trim();
    if (email) {
      const existing = await User.findOne({
        where: { email, id: { [Op.ne]: id } },
      });
      if (existing)
        return res.status(400).json({ error: "Email déjà utilisé" });
      user.email = email.trim();
    }

    // Gestion du document de vérification si uploadé
    if (
      req.files &&
      req.files.document_verification &&
      req.files.document_verification[0]
    ) {
      const file = req.files.document_verification[0];
      const filename = `doc-${Date.now()}${path.extname(file.originalname)}`;
      const dir = path.join(__dirname, "../../uploads/documents");
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(path.join(dir, filename), file.buffer);
      user.doc_verf = `uploads/documents/${filename}`;
    }

    await user.save();
    res.json({ message: "Utilisateur mis à jour", user });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateStoreDetails = async (req, res) => {
  try {
    const { id } = req.params; // storeId
    const { nom_boutique, telephone, adresse, description } = req.body;
    const store = await Store.findByPk(id);
    if (!store) return res.status(404).json({ error: "Boutique non trouvée" });

    if (nom_boutique) store.nom_boutique = nom_boutique.trim();
    if (telephone) store.telephone = telephone.trim();
    if (adresse) store.adresse = adresse.trim();
    if (description !== undefined) store.description = description?.trim();

    await store.save();
    res.json({ message: "Boutique mise à jour", store });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.registerEpicier = async (req, res) => {
  try {
    const {
      nom,
      prenom,
      email,
      mdp,
      adresse,
      telephone,
      nom_boutique,
      description_boutique,
    } = req.body;

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: "Cet email est déjà utilisé." });
    }

    // Gestion des fichiers
    let imagePath = null;
    let docPath = null;

    if (req.files) {
      if (req.files.image_boutique && req.files.image_boutique[0]) {
        const file = req.files.image_boutique[0];
        const filename = `shop-${Date.now()}${path.extname(file.originalname)}`;
        const dir = path.join(__dirname, "../../uploads/shops");
        if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
        fs.writeFileSync(path.join(dir, filename), file.buffer);
        imagePath = `uploads/shops/${filename}`;
      }
      if (
        req.files.document_verification &&
        req.files.document_verification[0]
      ) {
        const file = req.files.document_verification[0];
        const filename = `doc-${Date.now()}${path.extname(file.originalname)}`;
        const dir = path.join(__dirname, "../../uploads/documents");
        if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
        fs.writeFileSync(path.join(dir, filename), file.buffer);
        docPath = `uploads/documents/${filename}`;
      }
    }

    const newUser = await User.create({
      nom,
      prenom,
      email,
      mdp,
      role: "EPICIER",
      doc_verf: docPath,
      is_active: true,
    });

    const newStore = await Store.create({
      utilisateur_id: newUser.id,
      nom_boutique: nom_boutique || `Épicerie de ${prenom}`,
      adresse,
      telephone,
      description: description_boutique,
      image_url: imagePath,
      statut_inscription: "ACCEPTE",
      is_active: true,
    });

    res.status(201).json({
      message: "Épicier créé manuellement avec succès",
      user: { id: newUser.id, nom: newUser.nom, email: newUser.email },
      store: newStore,
    });
  } catch (error) {
    console.error("Error registerEpicier:", error);
    res.status(500).json({ error: error.message });
  }
};

// --- Gestion des catégories (plateforme) ---

exports.getCategories = async (req, res) => {
  try {
    const { storeId } = req.query;
    const categories = await Category.findAll({
      order: [["nom", "ASC"]],
    });
    const list = await Promise.all(
      categories.map(async (c) => {
        let productCount = 0;
        let deactivatedProductCount = 0;
        if (storeId) {
          productCount = await EpicierProduct.count({
            where: { epicier_id: storeId, is_active: true },
            include: [
              {
                model: Product,
                as: "produit",
                where: { categorie_id: c.id },
                attributes: [],
              },
            ],
          });
          deactivatedProductCount = await EpicierProduct.count({
            where: { epicier_id: storeId, is_active: false },
            include: [
              {
                model: Product,
                as: "produit",
                where: { categorie_id: c.id },
                attributes: [],
              },
            ],
          });
        } else {
          productCount = await Product.count({ where: { categorie_id: c.id } });
        }

        const storeCount = await EpicierProduct.count({
          distinct: true,
          col: "epicier_id",
          include: [
            {
              model: Product,
              as: "produit",
              where: { categorie_id: c.id },
              attributes: [],
            },
          ],
        });
        const ruptureCount = await EpicierProduct.count({
          where: { rupture_stock: true },
          include: [
            {
              model: Product,
              as: "produit",
              where: { categorie_id: c.id },
              attributes: [],
            },
          ],
        });
        return {
          ...c.toJSON(),
          productCount,
          deactivatedProductCount,
          storeCount,
          ruptureCount,
        };
      }),
    );
    res.json(list);
  } catch (error) {
    console.error("Error in getCategories admin:", error);
    res.status(500).json({ error: error.message });
  }
};

exports.createCategory = async (req, res) => {
  try {
    const { nom, description } = req.body;
    if (!nom || typeof nom !== "string" || !nom.trim()) {
      return res
        .status(400)
        .json({ message: "Le nom de la catégorie est requis." });
    }
    const existing = await Category.findOne({ where: { nom: nom.trim() } });
    if (existing) {
      return res
        .status(400)
        .json({ message: "Une catégorie avec ce nom existe déjà." });
    }
    const category = await Category.create({
      nom: nom.trim(),
      description: description?.trim(),
    });
    res.status(201).json(category);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { nom, description, image_url } = req.body;
    const category = await Category.findByPk(id);
    if (!category) {
      return res.status(404).json({ message: "Catégorie non trouvée." });
    }
    if (nom) {
      const existing = await Category.findOne({
        where: { nom: nom.trim(), id: { [Op.ne]: id } },
      });
      if (existing) {
        return res
          .status(400)
          .json({ message: "Une autre catégorie avec ce nom existe déjà." });
      }
      category.nom = nom.trim();
    }
    if (description !== undefined) category.description = description?.trim();
    if (image_url !== undefined) category.image_url = image_url?.trim();

    await category.save();
    res.json(category);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const category = await Category.findByPk(id);
    if (!category) {
      return res.status(404).json({ message: "Catégorie non trouvée." });
    }
    const productIds = await Product.findAll({
      where: { categorie_id: id },
      attributes: ["id"],
    }).then((rows) => rows.map((r) => r.id));
    const productCount = productIds.length;
    if (productCount > 0) {
      await EpicierProduct.update(
        { is_active: false },
        { where: { produit_id: productIds } },
      );
      return res.json({
        message: `${productCount} produit(s) de cette catégorie ont été retirés du catalogue pour tous les épiciers. La catégorie n’a pas été supprimée (des produits y sont encore rattachés).`,
        deactivated: true,
        productCount,
      });
    }
    await category.destroy();
    res.json({ message: "Catégorie supprimée." });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// --- Gestion des produits par catégorie (admin) ---

exports.getStores = async (req, res) => {
  try {
    const stores = await Store.findAll({
      where: {
        statut_inscription: { [Op.in]: ["ACCEPTE", "COMPLETE"] },
        is_active: true,
      },
      attributes: ["id", "nom_boutique"],
      order: [["nom_boutique", "ASC"]],
    });
    res.json(stores.map((s) => ({ id: s.id, nom_boutique: s.nom_boutique })));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getCategoryProducts = async (req, res) => {
  try {
    const categoryId = parseInt(req.params.categoryId, 10);
    if (Number.isNaN(categoryId)) {
      return res
        .status(400)
        .json({ message: "Identifiant de catégorie invalide." });
    }
    const category = await Category.findByPk(categoryId);
    if (!category) {
      return res.status(404).json({ message: "Catégorie non trouvée." });
    }
    const linkList = await EpicierProduct.findAll({
      // On inclut aussi les liens inactifs pour pouvoir afficher le toggle "off"
      // dans l'UI admin.
      where: {},
      include: [
        { model: Product, as: "produit", where: { categorie_id: categoryId } },
        { model: Store, as: "epicier", attributes: ["id", "nom_boutique"] },
      ],
      order: [[{ model: Product, as: "produit" }, "nom", "ASC"]],
    });
    const list = linkList
      .filter((ep) => ep.produit)
      .map((ep) => ({
        id: ep.produit.id,
        nom: ep.produit.nom,
        prix: parseFloat(ep.prix),
        description: ep.produit.description,
        epicier_id: ep.epicier_id,
        categorie_id: ep.produit.categorie_id,
        image_principale: ep.produit.image_principale,
        is_active: !!ep.is_active,
        rupture_stock: !!ep.rupture_stock,
        store_name: ep.epicier?.nom_boutique ?? null,
      }));
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.createProduct = async (req, res) => {
  try {
    const {
      epicier_id,
      categorie_id,
      nom,
      prix,
      description,
      image_principale,
    } = req.body;
    if (!nom || !nom.trim() || prix == null || !categorie_id || !epicier_id) {
      return res
        .status(400)
        .json({ message: "Nom, prix, catégorie et épicier sont requis." });
    }
    const category = await Category.findByPk(categorie_id);
    if (!category) {
      return res.status(404).json({ message: "Catégorie non trouvée." });
    }
    const store = await Store.findByPk(epicier_id);
    if (!store) {
      return res
        .status(404)
        .json({ message: "Épicier (boutique) non trouvé." });
    }
    console.log(`[CREATE PRODUCT] Request for store ${epicier_id}, category ${categorie_id}, name ${nom}`);
    const [product] = await Product.findOrCreate({
      where: { nom: nom.trim(), categorie_id: parseInt(categorie_id, 10) },
      defaults: {
        nom: nom.trim(),
        description: description?.trim() || null,
        categorie_id: parseInt(categorie_id, 10),
        image_principale: image_principale?.trim() || null,
      },
    });
    console.log(`[CREATE PRODUCT] Product ID: ${product.id}`);
    const [epicierProduct, created] = await EpicierProduct.findOrCreate({
      where: { epicier_id: parseInt(epicier_id, 10), produit_id: product.id },
      defaults: {
        epicier_id: parseInt(epicier_id, 10),
        produit_id: product.id,
        prix: parseFloat(prix),
        is_active: true,
      },
    });
    console.log(`[CREATE PRODUCT] Link created: ${created}, is_active: true`);
    if (!created) {
      epicierProduct.prix = parseFloat(prix);
      epicierProduct.is_active = true;
      await epicierProduct.save();
    }
    const withCategory = await Product.findByPk(product.id, {
      include: [{ model: Category, as: 'categorie', attributes: ['id', 'nom'] }],
    });

    res.status(201).json({
      id: withCategory.id,
      nom: withCategory.nom,
      prix: parseFloat(epicierProduct.prix),
      description: withCategory.description,
      epicier_id: epicierProduct.epicier_id,
      categorie_id: withCategory.categorie_id,
      categorie_nom: withCategory.categorie?.nom ?? null,
      image_principale: withCategory.image_principale,
      rupture_stock: !!epicierProduct.rupture_stock,
      is_active: true,
      store_name: store.nom_boutique,
    });
  } catch (error) {
    console.error('Erreur createProduct:', error);
    res.status(500).json({ message: 'Erreur lors de la création du produit', error: error.message });
  }
};


/**
 * Récupère les produits d'un magasin spécifique.
 */
exports.getStoreProducts = async (req, res) => {
  try {
    const { storeId } = req.params;
    const { categoryId, search, includeInactive } = req.query;

    const where = { epicier_id: storeId };
    if (includeInactive !== 'true') {
      where.is_active = true;
    }
    const productWhere = {};
    if (categoryId) productWhere.categorie_id = categoryId;
    if (search) productWhere.nom = { [require('sequelize').Op.like]: `%${search}%` };

    const epicierProducts = await EpicierProduct.findAll({
      where,
      include: [{
        model: Product,
        as: 'produit',
        where: Object.keys(productWhere).length ? productWhere : null,
        include: [{
          model: Category,
          as: 'categorie',
          attributes: ['id', 'nom']
        }]
      }],
      order: [[{ model: Product, as: 'produit' }, 'nom', 'ASC']]
    });

    const products = epicierProducts.map((ep) => ({
      id: ep.produit.id,
      nom: ep.produit.nom,
      prix: parseFloat(ep.prix),
      description: ep.produit.description,
      epicier_id: ep.epicier_id,
      categorie_id: ep.produit.categorie_id,
      categorie_nom: ep.produit.categorie?.nom,
      image_principale: ep.produit.image_principale,
      is_active: !!ep.is_active,
      rupture_stock: !!ep.rupture_stock,
    }));

    console.log(`Fetched ${products.length} products for storeId: ${storeId}`);
    res.json(products);
  } catch (error) {
    console.error("Error getStoreProducts admin:", error);
    res.status(500).json({ error: error.message });
  }
};

exports.updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { nom, prix, description, image_principale, epicier_id, is_active } = req.body;
    const product = await Product.findByPk(id);
    if (!product) {
      return res.status(404).json({ message: "Produit non trouvé." });
    }
    if (nom != null && typeof nom === "string") product.nom = nom.trim();
    if (image_principale !== undefined)
      product.image_principale = image_principale?.trim() || null;
    
    await product.save();

    if (epicier_id != null) {
      const link = await EpicierProduct.findOne({
        where: { epicier_id: parseInt(epicier_id, 10), produit_id: product.id },
      });
      if (link) {
        if (prix != null) link.prix = parseFloat(prix);
        if (is_active !== undefined) link.is_active = !!is_active;
        await link.save();
      }
    }
    
    const epicierId = epicier_id != null ? parseInt(epicier_id, 10) : null;
    const finalLink = epicierId 
      ? await EpicierProduct.findOne({ where: { epicier_id: epicierId, produit_id: product.id } })
      : null;
    
    const store = epicierId
      ? await Store.findByPk(epicierId, { attributes: ["nom_boutique"] })
      : null;

    res.json({
      id: product.id,
      nom: product.nom,
      prix: finalLink ? parseFloat(finalLink.prix) : 0,
      description: product.description,
      epicier_id: epicierId,
      categorie_id: product.categorie_id,
      image_principale: product.image_principale,
      is_active: finalLink ? !!finalLink.is_active : false,
      store_name: store?.nom_boutique ?? null,
    });
  } catch (error) {
    console.error('Error updateProduct:', error);
    res.status(500).json({ error: error.message });
  }
};

exports.deactivateProduct = async (req, res) => {
  try {
    const produitId = parseInt(req.params.id, 10);
    const epicierId =
      req.body?.epicier_id != null ? parseInt(req.body.epicier_id, 10) : null;
    if (Number.isNaN(produitId)) {
      return res
        .status(400)
        .json({ message: "Identifiant de produit invalide." });
    }
    if (epicierId == null || Number.isNaN(epicierId)) {
      return res.status(400).json({
        message:
          "epicier_id est requis pour désactiver un produit pour un épicier spécifique.",
      });
    }
    const product = await Product.findByPk(produitId);
    if (!product) {
      return res.status(404).json({ message: "Produit non trouvé." });
    }
    const [updated] = await EpicierProduct.update(
      { is_active: false },
      { where: { produit_id: produitId, epicier_id: epicierId } },
    );
    res.json({
      message: "Produit retiré du catalogue pour cet épicier.",
      updatedCount: updated,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deactivateStoreCategory = async (req, res) => {
  try {
    const { storeId, categoryId } = req.params;
    const sId = parseInt(storeId, 10);
    const cId = parseInt(categoryId, 10);

    if (Number.isNaN(sId) || Number.isNaN(cId)) {
      return res
        .status(400)
        .json({
          message: "Identifiants de magasin ou de catégorie invalides.",
        });
    }

    // Trouver tous les produits de cette catégorie
    const productIds = await Product.findAll({
      where: { categorie_id: cId },
      attributes: ["id"],
    }).then((rows) => rows.map((r) => r.id));

    if (productIds.length > 0) {
      // Désactiver le lien épicier-produit pour ce magasin uniquement
      await EpicierProduct.update(
        { is_active: false },
        { where: { epicier_id: sId, produit_id: productIds } },
      );
    }

    res.json({
      message:
        "La catégorie et ses produits ont été retirés de ce catalogue (désactivés).",
      deactivatedCount: productIds.length,
    });
  } catch (error) {
    console.error("Error deactivateStoreCategory:", error);
    res.status(500).json({ error: error.message });
  }
};

exports.activateProduct = async (req, res) => {
  try {
    const produitId = parseInt(req.params.id, 10);
    const epicierId =
      req.body?.epicier_id != null ? parseInt(req.body.epicier_id, 10) : null;
    if (Number.isNaN(produitId)) {
      return res
        .status(400)
        .json({ message: "Identifiant de produit invalide." });
    }
    if (epicierId == null || Number.isNaN(epicierId)) {
      return res.status(400).json({
        message:
          "epicier_id est requis pour activer un produit pour un épicier spécifique.",
      });
    }
    const product = await Product.findByPk(produitId);
    if (!product) {
      return res.status(404).json({ message: "Produit non trouvé." });
    }
    const [updated] = await EpicierProduct.update(
      { is_active: true },
      { where: { produit_id: produitId, epicier_id: epicierId } },
    );
    res.json({
      message: "Produit réactivé dans le catalogue pour cet épicier.",
      updatedCount: updated,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.toggleRuptureStock = async (req, res) => {
  try {
    const produitId = parseInt(req.params.id, 10);
    const epicierId =
      req.body?.epicier_id != null ? parseInt(req.body.epicier_id, 10) : null;
    if (Number.isNaN(produitId)) {
      return res
        .status(400)
        .json({ message: "Identifiant de produit invalide." });
    }
    if (epicierId == null || Number.isNaN(epicierId)) {
      return res
        .status(400)
        .json({ message: "epicier_id est requis pour la rupture de stock." });
    }
    const epicierProduct = await EpicierProduct.findOne({
      where: { produit_id: produitId, epicier_id: epicierId },
      include: [{ model: Product, as: "produit", attributes: ["id", "nom"] }],
    });
    if (!epicierProduct || !epicierProduct.produit) {
      return res
        .status(404)
        .json({ message: "Lien épicier-produit non trouvé." });
    }
    epicierProduct.rupture_stock = !epicierProduct.rupture_stock;
    await epicierProduct.save();
    res.json({
      message: epicierProduct.rupture_stock
        ? "Produit marqué en rupture de stock."
        : "Produit remis en stock.",
      rupture_stock: epicierProduct.rupture_stock,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.uploadProductImage = async (req, res) => {
  try {
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({ message: "Aucun fichier image envoyé." });
    }
    const categorieId = req.body.categorie_id;
    if (!categorieId) {
      return res.status(400).json({ message: "categorie_id est requis." });
    }
    const category = await Category.findByPk(categorieId);
    if (!category) {
      return res.status(400).json({ message: "Catégorie introuvable." });
    }
    const folderName = sanitizeName(category.nom) || "categorie";
    const dir = path.join(__dirname, "..", "..", "uploads", folderName);
    fs.mkdirSync(dir, { recursive: true });
    const ext = path.extname(req.file.originalname) || ".jpg";
    const safeExt = [".jpg", ".jpeg", ".png", ".gif", ".webp"].includes(
      ext.toLowerCase(),
    )
      ? ext
      : ".jpg";
    const productName = req.body.nom ? String(req.body.nom).trim() : "";
    const baseName =
      sanitizeName(productName) ||
      `temp_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
    let filename = `${baseName}${safeExt}`;
    let filePath = path.join(dir, filename);
    let suffix = 0;
    while (fs.existsSync(filePath)) {
      suffix += 1;
      filename = `${baseName}-${suffix}${safeExt}`;
      filePath = path.join(dir, filename);
    }
    fs.writeFileSync(filePath, req.file.buffer);
    const relativePath = path
      .join("uploads", folderName, filename)
      .replace(/\\/g, "/");
    res.status(200).json({ image_principale: relativePath });
  } catch (error) {
    console.error("Erreur uploadProductImage admin:", error);
    res.status(500).json({
      message: "Erreur lors de l'upload de l'image",
      error: error.message,
    });
  }
};

// --- Gestion des commandes et litiges ---

exports.getOrderStats = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const totalToday = await Commande.count({
      where: {
        date_commande: { [Op.gte]: today },
      },
    });

    const ongoingCount = await Commande.count({
      where: {
        statut: { [Op.in]: ["reçue", "prête"] },
      },
    });

    const disputeCount = await Reclamation.count({
      where: { statut: { [Op.in]: ["Litige ouvert", "En médiation"] } },
    });

    res.json({
      totalToday,
      ongoing: ongoingCount,
      disputes: disputeCount,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getRecentOrders = async (req, res) => {
  try {
    const orders = await Commande.findAll({
      limit: 50,
      order: [["date_commande", "DESC"]],
      include: [{ model: User, as: "client", attributes: ["nom", "prenom"] },
        { model: Store, as: 'epicier', attributes: ['nom_boutique'] }],
    });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getDisputes = async (req, res) => {
  try {
    const disputes = await Reclamation.findAll({
      order: [["date_creation", "DESC"]],
      include: [
        { model: User, as: "client", attributes: ["nom", "prenom"] },
        {
          model: Commande,
          as: "commande",
          required: false,
          include: [
            { model: Store, as: "epicier", attributes: ["nom_boutique"] },
          ],
        },
        {
          model: Avis,
          as: "avis",
          required: false,
          attributes: ["id", "note", "commentaire", "date_avis", "epicier_id"],
          include: [
            { model: User, as: "client", attributes: ["nom", "prenom"], required: false },
            { model: Store, attributes: ["id", "nom_boutique"], required: false },
          ],
        },
      ],
    });
    res.json(disputes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.resolveDispute = async (req, res) => {
  try {
    const { id } = req.params;
    const { statut } = req.body; // Expecting 'Résolu', 'En médiation', 'Remboursé', 'Litige ouvert'

    console.log(
      `Tentative de mise à jour du litige ${id} vers le statut: ${statut}`,
    );

    const dispute = await Reclamation.findByPk(id);
    if (!dispute)
      return res.status(404).json({ error: "Réclamation non trouvée" });

    // Validation basique
    const validStatuses = [
      "En attente",
      "Résolu",
      "En médiation",
      "Remboursé",
      "Litige ouvert",
    ];
    if (statut && !validStatuses.includes(statut)) {
      console.warn(`Statut invalide reçu: ${statut}`);
    }

    const previousStatus = dispute.statut;
    dispute.statut = statut || "Résolu";
    await dispute.save();

    if (previousStatus !== dispute.statut) {
      let epicierIdToNotify = null;
      if (dispute.type === "AVIS") {
        epicierIdToNotify = dispute.epicier_id || null;
      } else if (dispute.commande_id) {
        const order = await Commande.findByPk(dispute.commande_id);
        epicierIdToNotify = order?.epicier_id || null;
      }

      if (epicierIdToNotify) {
        const typeLabel = dispute.type === "AVIS" ? "avis" : "commande";
        const msg = `Statut réclamation (${typeLabel}) #${dispute.id} : ${dispute.statut}`;
        sendNotificationToEpicier(
          epicierIdToNotify,
          msg,
          "Mise à jour réclamation",
        ).catch(() => {});
      }
    }

    console.log(`Litige ${id} mis à jour avec succès: ${dispute.statut}`);

    res.json({ message: "Réclamation mise à jour", dispute });
  } catch (error) {
    console.error(`Erreur resolveDispute: ${error.message}`);
    res.status(500).json({ error: error.message });
  }
};

exports.getDashboardStats = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(23, 59, 59, 999);
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(today.getDate() - 7);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(today.getDate() - 30);
    thirtyDaysAgo.setHours(0, 0, 0, 0);

    // 1. Summary Cards
    const totalClients = await User.count({
      where: { role: "CLIENT", is_active: true },
    });
    const totalEpiciers = await Store.count({ where: { is_active: true } });
    const disputesOpen = await Reclamation.count({
      where: { statut: { [Op.ne]: "Résolu" } },
    });

    // Growth (this month)
    const firstOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    const clientsThisMonth = await User.count({
      where: { role: "CLIENT", date_creation: { [Op.gte]: firstOfMonth } },
    });
    const epiciersThisMonth = await User.count({
      where: { role: "EPICIER", date_creation: { [Op.gte]: firstOfMonth } },
    });

    // 2. Orders Trend (Last 7 Days)
    const orderTrend = await Commande.findAll({
      attributes: [
        [sequelize.fn("DATE", sequelize.col("date_commande")), "day"],
        "statut",
        [sequelize.fn("COUNT", sequelize.col("Commande.id")), "count"],
      ],
      where: { date_commande: { [Op.gte]: sevenDaysAgo } },
      group: [sequelize.fn("DATE", sequelize.col("date_commande")), "statut"],
      order: [[sequelize.literal("day"), "ASC"]],
    });

    // 3. Status Distribution
    const statusDist = await Commande.findAll({
      attributes: [
        "statut",
        [sequelize.fn("COUNT", sequelize.col("id")), "count"],
      ],
      group: ["statut"],
    });

    // 4. Top Categories
    const topCategories = await sequelize.query(
      `
      SELECT c.nom, SUM(dc.quantite) as total_qty
      FROM detailscommande dc
      JOIN produits p ON dc.produit_id = p.id
      JOIN categories c ON p.categorie_id = c.id
      GROUP BY c.id
      ORDER BY total_qty DESC
      LIMIT 6
    `,
      { type: sequelize.QueryTypes.SELECT },
    );

    // 5. Top Stores (Last 30 Days)
    const topStores = await Commande.findAll({
      attributes: [
        "epicier_id",
        [sequelize.fn("COUNT", sequelize.col("Commande.id")), "orderCount"],
      ],
      include: [
        {
          model: Store,
          as: "epicier",
          attributes: ["nom_boutique", "rating"],
        },
      ],
      where: { date_commande: { [Op.gte]: thirtyDaysAgo } },
      group: ["epicier_id", "epicier.id"],
      order: [[sequelize.literal("orderCount"), "DESC"]],
      limit: 5,
    });

    // 6. Registration trend (30 days)
    const regTrend = await User.findAll({
      attributes: [
        [sequelize.fn("DATE", sequelize.col("date_creation")), "day"],
        "role",
        [sequelize.fn("COUNT", sequelize.col("id")), "count"],
      ],
      where: {
        date_creation: { [Op.gte]: thirtyDaysAgo },
        role: { [Op.ne]: "ADMIN" },
      },
      group: [sequelize.fn("DATE", sequelize.col("date_creation")), "role"],
      order: [[sequelize.literal("day"), "ASC"]],
    });

    res.json({
      summary: {
        clients: { total: totalClients, growth: clientsThisMonth },
        epiciers: { total: totalEpiciers, growth: epiciersThisMonth },
        disputes: disputesOpen,
        ordersPerDay: Math.round(
          (await Commande.count({
            where: { date_commande: { [Op.gte]: sevenDaysAgo } },
          })) / 7,
        ),
      },
      orderTrend: orderTrend.map((t) => ({
        ...t.toJSON(),
        count: Number(t.get("count")),
      })),
      statusDist: statusDist.map((s) => ({
        ...s.toJSON(),
        count: Number(s.get("count")),
      })),
      topCategories: topCategories.map((c) => ({
        ...c,
        total_qty: Number(c.total_qty),
      })),
      topStores: topStores.map((ts) => ({
        ...ts.toJSON(),
        orderCount: Number(ts.get("orderCount")),
      })),
      regTrend: regTrend.map((r) => ({
        ...r.toJSON(),
        count: Number(r.get("count")),
      })),
    });
  } catch (error) {
    console.error("Error getDashboardStats:", error);
    res.status(500).json({ error: error.message });
  }
};
