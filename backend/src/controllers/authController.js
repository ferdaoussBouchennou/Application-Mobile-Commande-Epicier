const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { OAuth2Client } = require('google-auth-library');
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
        role: 'CLIENT',
        telephone: telephone || null,
        adresse: adresse || null,
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
      const { nom, prenom, email, mdp, adresse, telephone, doc_verf, nom_boutique, description_boutique, image_url } = req.body;

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
        role: 'EPICIER',
        doc_verf,
        is_active: true
      });

      // Créer l'entrée dans la table epiciers (statut_inscription sur la boutique)
      const newStore = await Store.create({
        utilisateur_id: newUser.id,
        nom_boutique: nom_boutique || `Epicerie de ${prenom}`,
        adresse: adresse || 'À configurer',
        telephone: telephone || null,
        description: description_boutique,
        image_url: image_url || null,
        statut_inscription: 'EN_ATTENTE',
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

      if (user.role === 'EPICIER') {
        const store = await Store.findOne({ where: { utilisateur_id: user.id } });
        if (store && store.statut_inscription !== 'ACCEPTE') {
          const message = store.statut_inscription === 'EN_ATTENTE'
            ? 'Votre compte Epicier est en attente de validation par un administrateur.'
            : 'Votre demande d\'inscription a été refusée par un administrateur.';
          return res.status(403).json({ message });
        }
      }

      let storeInfo = null;
      if (user.role === 'EPICIER') {
        const store = await Store.findOne({ where: { utilisateur_id: user.id } });
        if (!store) {
          return res.status(403).json({ message: 'Profil épicier introuvable.' });
        }
        if (store.statut_inscription !== 'ACCEPTE') {
          const message = store.statut_inscription === 'EN_ATTENTE'
            ? 'Votre compte Epicier est en attente de validation par un administrateur.'
            : 'Votre demande d\'inscription a été refusée par un administrateur.';
          return res.status(403).json({ message });
        }
        storeInfo = { id: store.id, nom_boutique: store.nom_boutique };
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
  },

  // Validation Epicier par l'Administrateur (statut sur la table epiciers)
  validateEpicier: async (req, res) => {
    try {
      const { userId, action } = req.body; // action: 'ACCEPTER' ou 'REFUSER'

      // Ici on devrait théoriquement vérifier que req.user (issu du JWT) est un ADMIN

      const user = await User.findByPk(userId);
      if (!user || user.role !== 'EPICIER') {
        return res.status(404).json({ message: 'Epicier introuvable.' });
      }

      const store = await Store.findOne({ where: { utilisateur_id: userId } });
      if (!store) {
        return res.status(404).json({ message: 'Boutique épicier introuvable.' });
      }

      if (action === 'ACCEPTER') {
        store.statut_inscription = 'ACCEPTE';
      } else if (action === 'REFUSER') {
        store.statut_inscription = 'REFUSE';
      } else {
        return res.status(400).json({ message: 'Action invalide.' });
      }

      await store.save();
      res.status(200).json({ message: `Le compte Epicier a été ${action === 'ACCEPTER' ? 'accepté' : 'refusé'}.` });

    } catch (error) {
      console.error('Erreur validateEpicier:', error);
      res.status(500).json({ message: 'Erreur lors de la validation', error: error.message });
    }
  },

  // Connexion via Google
  googleLogin: async (req, res) => {
    try {
      const { idToken } = req.body;
      const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

      // Vérification du token auprès de Google
      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });

      const payload = ticket.getPayload();
      const { email, name, given_name, family_name, sub: googleId } = payload;

      // Chercher ou créer l'utilisateur
      let user = await User.findOne({ 
        where: { 
          [require('sequelize').Op.or]: [
            { email },
            { id_google: googleId }
          ]
        } 
      });

      if (!user) {
        // Créer un nouvel utilisateur (rôle CLIENT par défaut)
        user = await User.create({
          nom: family_name || name,
          prenom: given_name || '',
          email,
          mdp: await bcrypt.hash(Math.random().toString(36), 10),
          id_google: googleId,
          adresse: 'Google Auth',
          role: 'CLIENT',
          is_active: true
        });
      } else if (!user.id_google) {
        // Si l'utilisateur existait déjà par email mais n'avait pas d'ID Google lié
        user.id_google = googleId;
        await user.save();
      }

      if (!user.is_active) {
        return res.status(403).json({ message: 'Ce compte est inactif.' });
      }

      // Générer le JWT MyHanut
      const token = jwt.sign(
        { id: user.id, email: user.email, role: user.role },
        JWT_SECRET,
        { expiresIn: '30d' }
      );

      res.status(200).json({
        message: 'Connexion Google réussie',
        token,
        user: {
          id: user.id,
          nom: user.nom,
          prenom: user.prenom,
          email: user.email,
          role: user.role,
        }
      });

    } catch (error) {
      console.error('Erreur googleLogin:', error);
      res.status(401).json({ message: 'Échec de l\'authentification Google', error: error.message });
    }
  }
};

module.exports = authController;
