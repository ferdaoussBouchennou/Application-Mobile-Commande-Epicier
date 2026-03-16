const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authMiddleware } = require('../middlewares/auth');


// Routes d'authentification (publiques)
router.post('/register/client', authController.registerClient);
router.post('/register/epicier', authController.registerEpicier);
router.post('/login', authController.login);
router.post('/google', authController.googleLogin);

// Validation d'un épicier (Idéalement protégée par un middleware Admin)
router.post('/validate-epicier', authController.validateEpicier);

// Mise à jour du token FCM (requiert authentification)
router.post('/fcm-token', authMiddleware, authController.updateFCMToken);


module.exports = router;
