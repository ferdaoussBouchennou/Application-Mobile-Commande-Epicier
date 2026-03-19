const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authMiddleware } = require('../middlewares/auth');


// Routes d'authentification (publiques)
router.post('/register/client', authController.registerClient);
router.post('/register/epicier', authController.registerEpicier);
router.post('/login', authController.login);
router.post('/google', authController.googleLogin);
router.post('/facebook', authController.facebookLogin);
router.post('/instagram', authController.instagramLogin);

// Vérification d'email et OTP
router.post('/verify-email', authController.verifyEmail);
router.post('/resend-otp', authController.resendOTP);

// Mot de passe oublié / réinitialisation
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);

// Validation d'un épicier (Idéalement protégée par un middleware Admin)
router.post('/validate-epicier', authController.validateEpicier);

// Mise à jour du token FCM (requiert authentification)
router.post('/fcm-token', authMiddleware, authController.updateFCMToken);

// Récupérer le profil actuel (restauration de session)
router.get('/me', authMiddleware, authController.getMe);

// Mise à jour du profil et mot de passe
router.put('/update-profile', authMiddleware, authController.updateProfile);
router.put('/update-password', authMiddleware, authController.updatePassword);


module.exports = router;
