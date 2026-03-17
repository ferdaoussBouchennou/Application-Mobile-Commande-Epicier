const express = require('express');
const router = express.Router();
const commandeController = require('../controllers/commandeController');
const { authMiddleware } = require('../middlewares/auth');

router.get('/', authMiddleware, commandeController.getMyCommandes);
router.get('/:id', authMiddleware, commandeController.getCommandeById);
router.post('/', authMiddleware, commandeController.createFromPanier);

module.exports = router;
