const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Routes d'authentification
router.post('/register/client', authController.registerClient);
router.post('/register/epicier', authController.registerEpicier);
router.post('/login', authController.login);

module.exports = router;
