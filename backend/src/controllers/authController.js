const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const User = require('../models/User');
const Store = require('../models/Store');

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_jwt_key_314159';

const authController = {
  // Inscription Client
  registerClient: async (req, res) => {
    try {
      const { nom, prenom, email, mdp, adresse, telephone } = req.body;

      // Vérifier si l'email existe
      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        return res.status(400).json({ message: 'Cet email est déjà utilisé.' });
      }

      // Créer le client
      const newUser = await User.create({
        nom,
        prenom,
        email,
        mdp,
        adresse,
        telephone,
        role: 'CLIENT',
        is_active: true
      });

      res.status(201).json({
        message: 'Client créé avec succès',
        user: { id: newUser.id, nom: newUser.nom, prenom: newUser.prenom, email: newUser.email, role: newUser.role }
      });
    } catch (error) {
      console.error('Erreur registerClient:', error);
      res.status(500).json({ message: 'Erreur lors de l\'inscription du client', error: error.message });
    }
  },

  // Inscription Epicier
  registerEpicier: async (req, res) => {
    try {
      const { nom, prenom, email, mdp, adresse, telephone, doc_verf, nom_boutique, description_boutique } = req.body;

      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        return res.status(400).json({ message: 'Cet email est déjà utilisé.' });
      }

      // Créer l'utilisateur avec le rôle EPICIER
      const newUser = await User.create({
        nom,
        prenom,
        email,
        mdp,
        adresse,
        telephone,
        role: 'EPICIER',
        doc_verf,
        is_active: true
      });

      // Créer l'entrée dans la table epiciers
      const newStore = await Store.create({
        utilisateur_id: newUser.id,
        nom_boutique: nom_boutique || `Epicerie de ${prenom}`,
        adresse, // Même adresse que l'utilisateur par défaut, sinon on peut la demander séparément
        telephone,
        description: description_boutique,
      });

      res.status(201).json({
        message: 'Epicier créé avec succès',
        user: { id: newUser.id, nom: newUser.nom, email: newUser.email, role: newUser.role },
        store: newStore
      });
    } catch (error) {
      console.error('Erreur registerEpicier:', error);
      res.status(500).json({ message: 'Erreur lors de l\'inscription de l\'épicier', error: error.message });
    }
  },

  // Connexion (Client et Epicier)
  login: async (req, res) => {
    try {
      const { email, mdp } = req.body;

      const user = await User.findOne({ where: { email } });
      if (!user) {
        return res.status(404).json({ message: 'Utilisateur non trouvé' });
      }

      const isMatch = await bcrypt.compare(mdp, user.mdp);
      if (!isMatch) {
        return res.status(401).json({ message: 'Mot de passe incorrect' });
      }

      if (!user.is_active) {
        return res.status(403).json({ message: 'Ce compte est inactif.' });
      }

      let storeInfo = null;
      if (user.role === 'EPICIER') {
        const store = await Store.findOne({ where: { utilisateur_id: user.id } });
        storeInfo = store ? { id: store.id, nom_boutique: store.nom_boutique } : null;
      }

      const token = jwt.sign(
        { id: user.id, email: user.email, role: user.role, storeId: storeInfo ? storeInfo.id : null },
        JWT_SECRET,
        { expiresIn: '30d' }
      );

      res.status(200).json({
        message: 'Connexion réussie',
        token,
        user: {
          id: user.id,
          nom: user.nom,
          prenom: user.prenom,
          email: user.email,
          role: user.role,
        },
        store: storeInfo
      });
    } catch (error) {
      console.error('Erreur login:', error);
      res.status(500).json({ message: 'Erreur lors de la connexion', error: error.message });
    }
  }
};

module.exports = authController;
