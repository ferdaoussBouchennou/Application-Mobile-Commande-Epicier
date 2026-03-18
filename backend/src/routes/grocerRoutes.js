const express = require('express');
const router = express.Router();
const grocerController = require('../controllers/grocerController');
const { authMiddleware, requireEpicier } = require('../middlewares/auth');
const uploadProductImage = require('../middlewares/uploadProductImage');

router.get('/profile', authMiddleware, requireEpicier, grocerController.getStoreProfile);
router.put('/complete-registration', authMiddleware, requireEpicier, grocerController.completeRegistration);
router.post('/upload-store-image', authMiddleware, (req, res, next) => {
  uploadProductImage.single('image')(req, res, (err) => {
    if (err) {
      return res.status(400).json({ message: err.message || 'Erreur upload' });
    }
    next();
  });
}, grocerController.uploadStoreImage);

router.get('/dashboard', authMiddleware, requireEpicier, grocerController.getDashboard);
router.get('/commandes', authMiddleware, requireEpicier, grocerController.getCommandes);
router.get('/commandes/count-new', authMiddleware, requireEpicier, grocerController.getCommandesCountNew);
router.get('/commandes/:id', authMiddleware, requireEpicier, grocerController.getCommandeById);
router.patch('/commandes/:id/notes', authMiddleware, requireEpicier, grocerController.updateCommandeNotes);
router.patch('/commandes/:id/items/:detailId/rupture', authMiddleware, requireEpicier, grocerController.markRuptureDetail);
router.post('/commandes/:id/accepter', authMiddleware, requireEpicier, grocerController.acceptCommande);
router.post('/commandes/:id/refuser', authMiddleware, requireEpicier, grocerController.refuseCommande);
router.patch('/commandes/:id/statut', authMiddleware, requireEpicier, grocerController.updateCommandeStatut);
router.get('/products', authMiddleware, requireEpicier, grocerController.getMyProducts);
router.get('/products/available-for-category/:categoryId', authMiddleware, requireEpicier, grocerController.getAvailableProductsForCategory);
router.post('/products/upload-image', (req, res, next) => {
  uploadProductImage.single('image')(req, res, (err) => {
    if (err) {
      const status = err.code === 'LIMIT_FILE_SIZE' ? 400 : 400;
      return res.status(status).json({ message: err.message || 'Erreur upload' });
    }
    next();
  });
}, grocerController.uploadProductImage);
router.post('/products', authMiddleware, requireEpicier, grocerController.createProduct);
router.post('/products/copy/:productId', authMiddleware, requireEpicier, grocerController.copyProductToCatalogue);
router.put('/products/:id', authMiddleware, requireEpicier, grocerController.updateProduct);
router.patch('/products/:id/rupture-stock', authMiddleware, requireEpicier, grocerController.toggleRuptureStock);
router.put('/products/:id/restore', authMiddleware, requireEpicier, grocerController.restoreProductToCatalogue);
router.delete('/products/:id', authMiddleware, requireEpicier, grocerController.deleteProduct);
router.get('/categories/:categoryId/inactive-products', authMiddleware, requireEpicier, grocerController.getInactiveProductsForCategory);
router.post('/categories/:categoryId/restore', authMiddleware, requireEpicier, grocerController.restoreCategoryWithProducts);
router.delete('/categories/:categoryId', authMiddleware, requireEpicier, grocerController.removeCategoryFromCatalogue);

module.exports = router;
