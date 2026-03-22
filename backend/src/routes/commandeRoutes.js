const express = require('express');
const router = express.Router();
const commandeController = require('../controllers/commandeController');
const reclamationController = require('../controllers/reclamationController');
const { authMiddleware } = require('../middlewares/auth');

router.get('/', authMiddleware, commandeController.getMyCommandes);
router.get('/:id', authMiddleware, commandeController.getCommandeById);
router.post('/', authMiddleware, commandeController.createFromPanier);
router.post('/:id/reclamations', authMiddleware, reclamationController.create);
router.post('/:id/items/:detailId/accepter-produit', authMiddleware, commandeController.accepterProduitRemisEnStock);
router.post('/:id/items/:detailId/refuser-produit', authMiddleware, commandeController.refuserProduitRemisEnStock);

module.exports = router;
