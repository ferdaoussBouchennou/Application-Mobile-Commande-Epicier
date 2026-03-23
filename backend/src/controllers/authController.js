const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');
const Store = require('../models/Store');
const { generateOTP, sendOTP } = require('../utils/emailService');
const { notifyAdmins } = require('../utils/notification');
const path = require('path');
const fs = require('fs');

const JWT_SECRET = process.env.JWT_SECRET;

const authController = {
  // Inscription Client
  registerClient: async (req, res) => {
    try {
      let { nom, prenom, email, mdp, adresse, telephone } = req.body;
      email = email ? email.trim().toLowerCase() : '';

      console.log(`Tentative d'inscription client: ${email}`);

      // Vérifier si l'email existe
      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        console.log(`Échec inscription: l'email ${email} existe déjà.`);
        return res.status(400).json({ message: 'EMAIL_EXISTS: Cet email est déjà utilisé.' });
      }

      const otp = generateOTP();
      const otpExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

      // Créer le client
      const newUser = await User.create({
        nom,
        prenom,
        email,
        mdp,
        role: 'CLIENT',
        telephone: telephone || null,
        adresse: adresse || null,
        is_active: true,
        email_verified: false,
        otp_code: otp,
        otp_expires_at: otpExpires,
      });

      // Envoyer l'email de vérification
      await sendOTP(email, otp, 'verify');

      res.status(201).json({
        message: 'Client créé avec succès. Vérifiez votre email.',
        requiresVerification: true,
        email: newUser.email,
      });
    } catch (error) {
      console.error('Erreur registerClient:', error);
      res.status(500).json({ message: 'Erreur lors de l\'inscription du client', error: error.message });
    }
  },

  // Inscription Epicier
  registerEpicier: async (req, res) => {
    try {
      let { nom, prenom, email, mdp, adresse, telephone, doc_verf, nom_boutique, description_boutique, image_url } = req.body;
      email = email ? email.trim().toLowerCase() : '';

      console.log(`Tentative d'inscription épicier: ${email}`);

      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        console.log(`Échec inscription épicier: l'email ${email} existe déjà.`);
        return res.status(400).json({ message: 'EMAIL_EXISTS: Cet email est déjà utilisé.' });
      }

      // Gestion du document de vérification si uploadé via multer
      if (req.files && req.files.document_verification && req.files.document_verification[0]) {
        const file = req.files.document_verification[0];
        const filename = `doc-${Date.now()}${path.extname(file.originalname)}`;
        const dir = path.join(__dirname, '../../uploads/documents');
        
        if (!fs.existsSync(dir)) {
          fs.mkdirSync(dir, { recursive: true });
        }
        
        fs.writeFileSync(path.join(dir, filename), file.buffer);
        doc_verf = `uploads/documents/${filename}`;
        console.log(`Document enregistré pour inscription standard: ${doc_verf}`);
      }

      const otp = generateOTP();
      const otpExpires = new Date(Date.now() + 15 * 60 * 1000);

      // Créer l'utilisateur avec le rôle EPICIER
      const newUser = await User.create({
        nom,
        prenom,
        email,
        mdp,
        role: 'EPICIER',
        doc_verf,
        is_active: true,
        email_verified: false,
        otp_code: otp,
        otp_expires_at: otpExpires,
      });

      // Créer l'entrée dans la table epiciers (statut_inscription sur la boutique)
      await Store.create({
        utilisateur_id: newUser.id,
        nom_boutique: nom_boutique || `Epicerie de ${prenom}`,
        adresse: adresse || 'À configurer',
        telephone: telephone || null,
        description: description_boutique,
        image_url: image_url || null,
        statut_inscription: 'EN_ATTENTE',
        is_active: true
      });

      // Envoyer l'email de vérification
      await sendOTP(email, otp, 'verify');

      // Notifier les admins
      notifyAdmins('Nouvelle Inscription', `Un nouvel épicier (${prenom} ${nom}) est en attente de validation.`, { type: 'NEW_REGISTRATION' });

      res.status(201).json({
        message: 'Epicier créé avec succès. Vérifiez votre email.',
        requiresVerification: true,
        email: newUser.email,
      });
    } catch (error) {
      console.error('Erreur registerEpicier:', error);
      res.status(500).json({ message: 'Erreur lors de l\'inscription de l\'épicier', error: error.message });
    }
  },

  // Vérification de l'email via OTP
  verifyEmail: async (req, res) => {
    try {
      const { email, otp } = req.body;

      const user = await User.findOne({ where: { email } });
      if (!user) {
        return res.status(404).json({ message: 'Utilisateur non trouvé.' });
      }

      if (user.email_verified) {
        return res.status(400).json({ message: 'Email déjà vérifié.' });
      }

      if (!user.otp_code || user.otp_code !== otp) {
        return res.status(400).json({ message: 'Code OTP invalide.' });
      }

      if (!user.otp_expires_at || new Date() > new Date(user.otp_expires_at)) {
        return res.status(400).json({ message: 'Code OTP expiré. Veuillez en demander un nouveau.' });
      }

      user.email_verified = true;
      user.otp_code = null;
      user.otp_expires_at = null;
      await user.save();

      res.status(200).json({ message: 'Email vérifié avec succès. Vous pouvez maintenant vous connecter.' });
    } catch (error) {
      console.error('Erreur verifyEmail:', error);
      res.status(500).json({ message: 'Erreur lors de la vérification', error: error.message });
    }
  },

  // Renvoyer le code OTP
  resendOTP: async (req, res) => {
    try {
      const { email } = req.body;

      const user = await User.findOne({ where: { email } });
      if (!user) {
        return res.status(404).json({ message: 'Utilisateur non trouvé.' });
      }

      if (user.email_verified) {
        return res.status(400).json({ message: 'Email déjà vérifié.' });
      }

      const otp = generateOTP();
      const otpExpires = new Date(Date.now() + 15 * 60 * 1000);

      user.otp_code = otp;
      user.otp_expires_at = otpExpires;
      await user.save();

      await sendOTP(email, otp, 'verify');

      res.status(200).json({ message: 'Code OTP renvoyé avec succès.' });
    } catch (error) {
      console.error('Erreur resendOTP:', error);
      res.status(500).json({ message: 'Erreur lors du renvoi du code', error: error.message });
    }
  },

  // Mot de passe oublié – envoi OTP
  forgotPassword: async (req, res) => {
    try {
      const { email } = req.body;

      const user = await User.findOne({ where: { email } });
      // Toujours répondre 200 pour ne pas exposer si l'email existe
      if (!user) {
        return res.status(200).json({ message: 'Si cet email existe, un code vous sera envoyé.' });
      }

      const otp = generateOTP();
      const otpExpires = new Date(Date.now() + 15 * 60 * 1000);

      user.otp_code = otp;
      user.otp_expires_at = otpExpires;
      await user.save();

      await sendOTP(email, otp, 'reset');

      res.status(200).json({ message: 'Si cet email existe, un code vous sera envoyé.' });
    } catch (error) {
      console.error('Erreur forgotPassword:', error);
      res.status(500).json({ message: 'Erreur lors de l\'envoi du code', error: error.message });
    }
  },

  // Réinitialisation du mot de passe via OTP
  resetPassword: async (req, res) => {
    try {
      const { email, otp, newPassword } = req.body;

      if (!email || !otp || !newPassword) {
        return res.status(400).json({ message: 'Email, code OTP et nouveau mot de passe requis.' });
      }

      const user = await User.findOne({ where: { email } });
      if (!user) {
        return res.status(404).json({ message: 'Utilisateur non trouvé.' });
      }

      if (!user.otp_code || user.otp_code !== otp) {
        return res.status(400).json({ message: 'Code OTP invalide.' });
      }

      if (!user.otp_expires_at || new Date() > new Date(user.otp_expires_at)) {
        return res.status(400).json({ message: 'Code OTP expiré. Veuillez en demander un nouveau.' });
      }

      // Assigning triggers the beforeUpdate hook to hash the password
      user.mdp = newPassword;
      user.otp_code = null;
      user.otp_expires_at = null;
      await user.save();

      res.status(200).json({ message: 'Mot de passe réinitialisé avec succès.' });
    } catch (error) {
      console.error('Erreur resetPassword:', error);
      res.status(500).json({ message: 'Erreur lors de la réinitialisation', error: error.message });
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

      // Vérification de l'email
      if (!user.email_verified) {
        return res.status(403).json({ message: 'EMAIL_NOT_VERIFIED', email: user.email });
      }

      let storeInfo = null;
      if (user.role === 'EPICIER') {
        const store = await Store.findOne({ where: { utilisateur_id: user.id } });
        if (!store) {
          return res.status(403).json({ message: 'Profil épicier introuvable.' });
        }

        if (store.statut_inscription === 'EN_ATTENTE') {
          return res.status(403).json({ message: 'Votre compte Epicier est en attente de validation par un administrateur.' });
        }
        if (store.statut_inscription === 'REFUSE') {
          return res.status(403).json({ message: 'Votre demande d\'inscription a été refusée par un administrateur.' });
        }

        storeInfo = {
          id: store.id,
          nom_boutique: store.nom_boutique,
          statut_inscription: store.statut_inscription,
        };
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
          telephone: user.telephone,
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
      const { userId, action } = req.body;

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
      const { idToken, accessToken, role, doc_verf, nom_boutique, description_boutique, adresse, telephone } = req.body;
      const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
      
      let payload;

      if (idToken) {
        const ticket = await client.verifyIdToken({
          idToken,
          audience: process.env.GOOGLE_CLIENT_ID,
        });
        payload = ticket.getPayload();
      } else if (accessToken) {
        const https = require('https');
        const fetchUserData = (token) => {
          return new Promise((resolve, reject) => {
            https.get(`https://www.googleapis.com/oauth2/v3/userinfo?access_token=${token}`, (res) => {
              let data = '';
              res.on('data', (chunk) => data += chunk);
              res.on('end', () => resolve(JSON.parse(data)));
            }).on('error', reject);
          });
        };
        payload = await fetchUserData(accessToken);
      }

      if (!payload) {
        return res.status(401).json({ message: "Aucun jeton valide fourni." });
      }

      const { email, name, given_name, family_name, sub: googleId } = payload;

      let user = await User.findOne({ 
        where: { 
          [require('sequelize').Op.or]: [
            { email },
            { id_google: googleId }
          ]
        } 
      });

      let isNewUser = false;
      let newStore = null;

      if (!user) {
        if (role === 'EPICIER') {
          // Gestion du document de vérification
          let final_doc_verf = doc_verf; // Value from req.body
          if (req.files && req.files.document_verification && req.files.document_verification[0]) {
            const file = req.files.document_verification[0];
            const filename = `doc-${Date.now()}${path.extname(file.originalname)}`;
            const dir = path.join(__dirname, '../../uploads/documents');
            if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
            fs.writeFileSync(path.join(dir, filename), file.buffer);
            final_doc_verf = `uploads/documents/${filename}`;
            console.log(`Document enregistré pour inscription Google: ${final_doc_verf}`);
          }

          if (!final_doc_verf) {
            return res.status(400).json({ message: "Le document de vérification est obligatoire pour s'inscrire en tant qu'épicier." });
          }

          user = await User.create({
            nom: family_name || name || 'Inconnu',
            prenom: given_name || '',
            email,
            mdp: await bcrypt.hash(Math.random().toString(36), 10),
            id_google: googleId,
            role: 'EPICIER',
            doc_verf: final_doc_verf,
            is_active: true,
            email_verified: true, // Google already verified the email
          });
          
          newStore = await Store.create({
            utilisateur_id: user.id,
            nom_boutique: nom_boutique || `Epicerie de ${given_name || name}`,
            adresse: adresse || 'À configurer',
            telephone: telephone || null,
            description: description_boutique,
            statut_inscription: 'EN_ATTENTE',
            is_active: true
          });

          // Notifier les admins
          notifyAdmins('Nouvelle Inscription (Google)', `Un nouvel épicier (${user.prenom} ${user.nom}) s'est inscrit via Google et attend sa validation.`, { type: 'NEW_REGISTRATION' });
        } else {
          user = await User.create({
            nom: family_name || name || 'Inconnu',
            prenom: given_name || '',
            email,
            mdp: await bcrypt.hash(Math.random().toString(36), 10),
            id_google: googleId,
            adresse: 'Google Auth',
            role: 'CLIENT',
            is_active: true,
            email_verified: true, // Google already verified the email
          });
        }
        isNewUser = true;
      } else if (!user.id_google) {
        user.id_google = googleId;
        user.email_verified = true; // Link Google = email verified
        await user.save();
      }

      if (user && user.role === 'CLIENT' && role === 'EPICIER') {
        return res.status(400).json({ message: "EMAIL_EXISTS: Cet email est déjà associé à un compte Client. Vous ne pouvez pas vous connecter en tant qu'Epicier." });
      }

      if (!user.is_active) {
        return res.status(403).json({ message: 'Ce compte est inactif.' });
      }

      let storeInfo = null;
      if (user.role === 'EPICIER') {
        const store = newStore || await Store.findOne({ where: { utilisateur_id: user.id } });
        if (!store) {
          return res.status(403).json({ message: 'Profil épicier introuvable.' });
        }
        if (store.statut_inscription === 'EN_ATTENTE') {
          return res.status(403).json({ message: 'Votre compte Epicier est en attente de validation par un administrateur.' });
        }
        if (store.statut_inscription === 'REFUSE') {
          return res.status(403).json({ message: 'Votre demande d\'inscription a été refusée par un administrateur.' });
        }
        storeInfo = { id: store.id, nom_boutique: store.nom_boutique, statut_inscription: store.statut_inscription };
      }

      const token = jwt.sign(
        { id: user.id, email: user.email, role: user.role, storeId: storeInfo ? storeInfo.id : null },
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
          telephone: user.telephone,
        },
        store: storeInfo
      });

    } catch (error) {
      console.error('Erreur googleLogin:', error);
      res.status(401).json({ message: 'Échec de l\'authentification Google', error: error.message });
    }
  },
  
  // Connexion via Facebook
  facebookLogin: async (req, res) => {
    try {
      const { accessToken, role, doc_verf, nom_boutique, description_boutique, adresse, telephone } = req.body;
      
      const https = require('https');
      const fetchUserData = (token) => {
        return new Promise((resolve, reject) => {
          https.get(`https://graph.facebook.com/me?fields=id,name,email,first_name,last_name&access_token=${token}`, (fbRes) => {
            let data = '';
            fbRes.on('data', (chunk) => data += chunk);
            fbRes.on('end', () => resolve(JSON.parse(data)));
          }).on('error', reject);
        });
      };
      
      const payload = await fetchUserData(accessToken);
      
      if (!payload || payload.error) {
        return res.status(401).json({ message: "Jeton Facebook invalide.", error: payload?.error });
      }

      const { email, name, first_name, last_name, id: facebookId } = payload;
      
      // The rest of the logic is shared with googleLogin (find or create user)
      // I will extract this logic if possible or replicate it for now to avoid breaking things
      let user = await User.findOne({ 
        where: { 
          [require('sequelize').Op.or]: [
            { email },
            { id_facebook: facebookId }
          ]
        } 
      });

      let isNewUser = false;
      let newStore = null;

      if (!user) {
        if (role === 'EPICIER') {
          // Gestion du document de vérification
          let final_doc_verf = doc_verf; // Value from req.body
          if (req.files && req.files.document_verification && req.files.document_verification[0]) {
            const file = req.files.document_verification[0];
            const filename = `doc-${Date.now()}${path.extname(file.originalname)}`;
            const dir = path.join(__dirname, '../../uploads/documents');
            if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
            fs.writeFileSync(path.join(dir, filename), file.buffer);
            final_doc_verf = `uploads/documents/${filename}`;
            console.log(`Document enregistré pour inscription Facebook: ${final_doc_verf}`);
          }

          if (!final_doc_verf) {
            return res.status(400).json({ message: "Le document de vérification est obligatoire." });
          }

          user = await User.create({
            nom: last_name || name || 'Inconnu',
            prenom: first_name || '',
            email,
            mdp: await bcrypt.hash(Math.random().toString(36), 10),
            id_facebook: facebookId,
            role: 'EPICIER',
            doc_verf: final_doc_verf,
            is_active: true,
            email_verified: true,
          });
          
          newStore = await Store.create({
            utilisateur_id: user.id,
            nom_boutique: nom_boutique || `Epicerie de ${first_name || name}`,
            adresse: adresse || 'À configurer',
            telephone: telephone || null,
            description: description_boutique,
            statut_inscription: 'EN_ATTENTE',
            is_active: true
          });

          // Notifier les admins
          notifyAdmins('Nouvelle Inscription (Facebook)', `Un nouvel épicier (${user.prenom} ${user.nom}) s'est inscrit via Facebook et attend sa validation.`, { type: 'NEW_REGISTRATION' });
        } else {
          user = await User.create({
            nom: last_name || name || 'Inconnu',
            prenom: first_name || '',
            email,
            mdp: await bcrypt.hash(Math.random().toString(36), 10),
            id_facebook: facebookId,
            role: 'CLIENT',
            is_active: true,
            email_verified: true,
          });
        }
        isNewUser = true;
      } else if (!user.id_facebook) {
        user.id_facebook = facebookId;
        user.email_verified = true;
        await user.save();
      }

      // Check role constraints and store status
      if (user && user.role === 'CLIENT' && role === 'EPICIER') {
        return res.status(400).json({ message: "EMAIL_EXISTS: Cet email est déjà associé à un compte Client." });
      }

      let storeInfo = null;
      if (user.role === 'EPICIER') {
        const store = newStore || await Store.findOne({ where: { utilisateur_id: user.id } });
        if (!store) return res.status(403).json({ message: 'Profil épicier introuvable.' });
        if (store.statut_inscription === 'EN_ATTENTE') return res.status(403).json({ message: 'Compte en attente de validation.' });
        if (store.statut_inscription === 'REFUSE') return res.status(403).json({ message: 'Demande refusée.' });
        storeInfo = { id: store.id, nom_boutique: store.nom_boutique, statut_inscription: store.statut_inscription };
      }

      const token = jwt.sign(
        { id: user.id, email: user.email, role: user.role, storeId: storeInfo ? storeInfo.id : null },
        JWT_SECRET,
        { expiresIn: '30d' }
      );

      res.status(200).json({
        message: 'Connexion Facebook réussie',
        token,
        user: { id: user.id, nom: user.nom, prenom: user.prenom, email: user.email, role: user.role, telephone: user.telephone },
        store: storeInfo
      });
    } catch (error) {
      console.error('Erreur facebookLogin:', error);
      res.status(401).json({ message: 'Échec de l\'authentification Facebook', error: error.message });
    }
  },

  // Connexion via Instagram (Unifié avec Meta Graph API)
  instagramLogin: async (req, res) => {
    try {
      const { accessToken, role, doc_verf, nom_boutique, description_boutique, adresse, telephone } = req.body;
      
      if (!accessToken) {
        return res.status(400).json({ message: 'accessToken requis' });
      }

      const https = require('https');
      const fetchUserData = (token) => {
        return new Promise((resolve, reject) => {
          // On utilise graph.facebook.com car Instagram est unifié sous Meta
          // Pour les comptes pros, on peut obtenir l'ID Instagram via /me?fields=instagram_accounts
          https.get(`https://graph.facebook.com/me?fields=id,name,email,picture&access_token=${token}`, (metaRes) => {
            let data = '';
            metaRes.on('data', (chunk) => data += chunk);
            metaRes.on('end', () => resolve(JSON.parse(data)));
          }).on('error', reject);
        });
      };
      
      const payload = await fetchUserData(accessToken);
      
      if (!payload || payload.error) {
        console.error('Erreur Meta Graph:', payload?.error);
        return res.status(401).json({ message: "Jeton Meta/Instagram invalide.", error: payload?.error });
      }

      const { id: metaId, name, email: metaEmail, picture } = payload;
      
      // Fallback email si non fourni par Meta
      const email = metaEmail || `${metaId}@meta.com`;
      const [prenom, ...nomParties] = (name || 'Utilisateur Insta').split(' ');
      const nom = nomParties.join(' ') || prenom;

      // Recherche par id_instagram ou email
      let user = await User.findOne({ 
        where: { 
          [require('sequelize').Op.or]: [
            { email },
            { id_instagram: metaId }
          ]
        } 
      });

      let isNewUser = false;
      let newStore = null;

      if (!user) {
        // Validation spécifique Épicier pour les nouveaux comptes
        if (role === 'EPICIER') {
          // Gestion du document de vérification
          let final_doc_verf = doc_verf; // Value from req.body
          if (req.files && req.files.document_verification && req.files.document_verification[0]) {
            const file = req.files.document_verification[0];
            const filename = `doc-${Date.now()}${path.extname(file.originalname)}`;
            const dir = path.join(__dirname, '../../uploads/documents');
            if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
            fs.writeFileSync(path.join(dir, filename), file.buffer);
            final_doc_verf = `uploads/documents/${filename}`;
            console.log(`Document enregistré pour inscription Instagram: ${final_doc_verf}`);
          }

          if (!final_doc_verf) return res.status(400).json({ message: "DOCUMENT_REQUIRED: Un document est requis." });
          if (!nom_boutique) return res.status(400).json({ message: "STORE_NAME_REQUIRED: Le nom de boutique est requis." });

          user = await User.create({
            nom,
            prenom,
            email,
            mdp: await bcrypt.hash(Math.random().toString(36), 10),
            id_instagram: metaId,
            role: 'EPICIER',
            doc_verf: final_doc_verf,
            is_active: true,
            email_verified: true,
          });

          const { Store } = require('../models'); 
          newStore = await Store.create({
            utilisateur_id: user.id,
            nom_boutique,
            description: description_boutique || '',
            adresse: adresse || '',
            telephone: telephone || '',
            statut_inscription: 'EN_ATTENTE'
          });

          // Notifier les admins
          notifyAdmins('Nouvelle Inscription (Instagram)', `Un nouvel épicier (${user.prenom} ${user.nom}) s'est inscrit via Instagram et attend sa validation.`, { type: 'NEW_REGISTRATION' });
        } else {
          user = await User.create({
            nom,
            prenom,
            email,
            mdp: await bcrypt.hash(Math.random().toString(36), 10),
            id_instagram: metaId,
            role: 'CLIENT',
            is_active: true,
            email_verified: true,
          });
        }
        isNewUser = true;
      } else if (!user.id_instagram) {
        user.id_instagram = metaId;
        user.email_verified = true;
        await user.save();
      }

      // Vérification du rôle existant
      if (user && user.role === 'CLIENT' && role === 'EPICIER') {
        return res.status(400).json({ message: "EMAIL_EXISTS: Cet email est déjà associé à un compte Client." });
      }

      let storeInfo = null;
      if (user.role === 'EPICIER') {
        const { Store } = require('../models');
        const store = newStore || await Store.findOne({ where: { utilisateur_id: user.id } });
        if (!store) return res.status(403).json({ message: 'Profil épicier introuvable.' });
        storeInfo = { id: store.id, nom_boutique: store.nom_boutique, statut_inscription: store.statut_inscription };
      }

      const token = jwt.sign(
        { id: user.id, email: user.email, role: user.role, storeId: storeInfo ? storeInfo.id : null },
        JWT_SECRET,
        { expiresIn: '30d' }
      );

      res.status(200).json({
        message: 'Connexion Instagram réussie',
        token,
        user: { id: user.id, nom: user.nom, prenom: user.prenom, email: user.email, role: user.role, telephone: user.telephone },
        store: storeInfo
      });
    } catch (error) {
      console.error('Erreur instagramLogin:', error);
      res.status(401).json({ message: 'Échec de l\'authentification Instagram', error: error.message });
    }
  },

  // Mettre à jour le token FCM de l'utilisateur
  updateFCMToken: async (req, res) => {
    try {
      const { fcm_token } = req.body;
      const userId = req.user.id;

      if (!fcm_token) {
        return res.status(400).json({ message: 'fcm_token requis' });
      }

      const user = await User.findByPk(userId);
      if (!user) {
        return res.status(404).json({ message: 'Utilisateur non trouvé' });
      }

      user.fcm_token = fcm_token;
      await user.save();

      res.status(200).json({ message: 'FCM token mis à jour' });
    } catch (error) {
      console.error('Erreur updateFCMToken:', error);
      res.status(500).json({ message: 'Erreur lors de la mise à jour du FCM token', error: error.message });
    }
  },

  // Récupérer les infos de l'utilisateur actuel (session restoration)
  getMe: async (req, res) => {
    try {
      const user = await User.findByPk(req.user.id);
      if (!user) {
        return res.status(404).json({ message: 'Utilisateur non trouvé' });
      }

      let storeInfo = null;
      if (user.role === 'EPICIER') {
        const store = await Store.findOne({ where: { utilisateur_id: user.id } });
        if (store) {
          storeInfo = {
            id: store.id,
            nom_boutique: store.nom_boutique,
            statut_inscription: store.statut_inscription,
          };
        }
      }

      res.status(200).json({
        user: {
          id: user.id,
          nom: user.nom,
          prenom: user.prenom,
          email: user.email,
          role: user.role,
          telephone: user.telephone,
          adresse: user.adresse
        },
        store: storeInfo
      });
    } catch (error) {
      console.error('Erreur getMe:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération du profil', error: error.message });
    }
  },

  // Mettre à jour le profil (nom, prenom, telephone, adresse)
  updateProfile: async (req, res) => {
    try {
      const { nom, prenom, telephone, adresse } = req.body;
      const userId = req.user.id;

      const user = await User.findByPk(userId);
      if (!user) {
        return res.status(404).json({ message: 'Utilisateur non trouvé' });
      }

      if (nom) user.nom = nom;
      if (prenom) user.prenom = prenom;
      if (telephone) user.telephone = telephone;
      if (adresse) user.adresse = adresse;

      await user.save();

      res.status(200).json({
        message: 'Profil mis à jour avec succès',
        user: {
          id: user.id,
          nom: user.nom,
          prenom: user.prenom,
          email: user.email,
          role: user.role,
          telephone: user.telephone,
          adresse: user.adresse
        }
      });
    } catch (error) {
      console.error('Erreur updateProfile:', error);
      res.status(500).json({ message: 'Erreur lors de la mise à jour du profil', error: error.message });
    }
  },

  // Mettre à jour le mot de passe
  updatePassword: async (req, res) => {
    try {
      const { currentPassword, newPassword } = req.body;
      const userId = req.user.id;

      if (!currentPassword || !newPassword) {
        return res.status(400).json({ message: 'Ancien et nouveau mot de passe requis' });
      }

      const user = await User.findByPk(userId);
      if (!user) {
        return res.status(404).json({ message: 'Utilisateur non trouvé' });
      }

      // Vérifier l'ancien mot de passe
      const isMatch = await bcrypt.compare(currentPassword, user.mdp);
      if (!isMatch) {
        return res.status(401).json({ message: 'L\'ancien mot de passe est incorrect' });
      }

      // Mettre à jour le mot de passe (le hook beforeUpdate s'occupera du hashage)
      user.mdp = newPassword;
      await user.save();

      res.status(200).json({ message: 'Mot de passe mis à jour avec succès' });
    } catch (error) {
      console.error('Erreur updatePassword:', error);
      res.status(500).json({ message: 'Erreur lors de la mise à jour du mot de passe', error: error.message });
    }
  }
};

module.exports = authController;
