const User = require('../models/User');
const Store = require('../models/Store');
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
