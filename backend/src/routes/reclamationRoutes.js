const express = require('express');
const router = express.Router();
const controller = require('../controllers/reclamationController');
const { authMiddleware, requireEpicier } = require('../middlewares/auth');
const upload = require('../middlewares/uploadProductImage');

// Client
router.post('/', authMiddleware, upload.single('photo'), controller.createReclamation);
router.get('/mine', authMiddleware, controller.getClientReclamations);

// Epicier
router.get('/store', authMiddleware, requireEpicier, controller.getStoreReclamations);
router.patch('/:id', authMiddleware, requireEpicier, controller.updateReclamation);

module.exports = router;
