const express = require('express');
const router = express.Router();
const commandeController = require('../controllers/commandeController');
const { authMiddleware } = require('../middlewares/auth');

router.post('/', authMiddleware, commandeController.createFromPanier);

module.exports = router;
