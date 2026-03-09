const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Routes d'authentification (publiques)
router.post('/register/client', authController.registerClient);
router.post('/register/epicier', authController.registerEpicier);
router.post('/login', authController.login);

// Validation d'un épicier (Idéalement protégée par un middleware Admin)
router.post('/validate-epicier', authController.validateEpicier);

module.exports = router;
