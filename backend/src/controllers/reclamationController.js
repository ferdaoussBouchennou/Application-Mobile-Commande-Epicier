const path = require('path');
const fs = require('fs');
const Reclamation = require('../models/Reclamation');
const Order = require('../models/Order');
const User = require('../models/User');
const { notifyAdmins } = require('../utils/notification');

/** Sanitise une chaîne pour en faire un nom de fichier. */
function sanitizeName(str) {
  if (!str || typeof str !== 'string') return '';
  return str.replace(/[^a-zA-Z0-9_-]/g, '_').slice(0, 50);
}

exports.createReclamation = async (req, res) => {
  try {
    const { commande_id, motif, description } = req.body;
    const client_id = req.user.id;
    let photoPath = null;

    // Optional: Check if order belongs to client
    if (commande_id) {
      const order = await Order.findOne({ where: { id: commande_id, client_id } });
      if (!order) return res.status(403).json({ message: "Cette commande ne vous appartient pas." });
    }

    // Handle File Upload if present
    if (req.file) {
      const dir = path.join(__dirname, '..', '..', 'uploads', 'reclamations');
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      
      const ext = path.extname(req.file.originalname) || '.jpg';
      const filename = `rec_${client_id}_${Date.now()}${ext}`;
      const filePath = path.join(dir, filename);
      
      fs.writeFileSync(filePath, req.file.buffer);
      photoPath = `uploads/reclamations/${filename}`;
    }

    const reclamation = await Reclamation.create({
      client_id,
      commande_id: commande_id || null,
      motif,
      description,
      photo: photoPath,
      statut: 'Ouverte'
    });

    // Notifier les admins
    try {
      const client = await User.findByPk(client_id);
      notifyAdmins('Nouveau Litige', `Un client (${client?.prenom} ${client?.nom}) a ouvert une réclamation : ${motif}`, { 
        type: 'NEW_DISPUTE',
        reclamation_id: reclamation.id.toString()
      });
    } catch (err) {
      console.error('Erreur notification admin litige:', err);
    }

    res.status(201).json(reclamation);
  } catch (error) {
    console.error('Erreur createReclamation:', error);
    res.status(500).json({ message: error.message });
  }
};

exports.getClientReclamations = async (req, res) => {
  try {
    const reclamations = await Reclamation.findAll({
      where: { client_id: req.user.id },
      order: [['date_creation', 'DESC']]
    });
    res.json(reclamations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getStoreReclamations = async (req, res) => {
  try {
    const storeId = req.user.storeId;
    if (!storeId) return res.status(403).json({ message: "Store ID manquant" });

    const reclamations = await Reclamation.findAll({
      include: [{
        model: Order,
        as: 'commande',
        where: { epicier_id: storeId },
        required: true
      }],
      order: [['date_creation', 'DESC']]
    });
    res.json(reclamations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateReclamation = async (req, res) => {
  try {
    const { id } = req.params;
    const { statut, reponse_epicier } = req.body;

    const rec = await Reclamation.findByPk(id);
    if (!rec) return res.status(404).json({ message: "Réclamation non trouvée" });

    if (statut) rec.statut = statut;
    if (reponse_epicier !== undefined) rec.reponse_epicier = reponse_epicier;

    await rec.save();
    res.json(rec);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
