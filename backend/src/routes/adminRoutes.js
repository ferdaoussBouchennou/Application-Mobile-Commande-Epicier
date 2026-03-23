const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authMiddleware, requireAdmin } = require('../middlewares/auth');
const uploadProductImage = require('../middlewares/uploadProductImage');

router.get('/stats', adminController.getStats);
router.get('/dashboard/stats', authMiddleware, requireAdmin, adminController.getDashboardStats);
router.get('/users', adminController.getUsers);
router.patch('/users/:id/status', adminController.updateUserStatus);
router.put('/users/:id/details', authMiddleware, requireAdmin, uploadProductImage.fields([
  { name: 'document_verification', maxCount: 1 }
]), adminController.updateUserDetails);
router.put('/stores/:id/details', authMiddleware, requireAdmin, adminController.updateStoreDetails);
router.post('/register-epicier', uploadProductImage.fields([
  { name: 'image_boutique', maxCount: 1 },
  { name: 'document_verification', maxCount: 1 }
]), adminController.registerEpicier);

// Gestion des catégories de la plateforme (CRUD admin)
router.get('/categories', authMiddleware, requireAdmin, adminController.getCategories);
router.post('/categories', authMiddleware, requireAdmin, adminController.createCategory);
router.put('/categories/:id', authMiddleware, requireAdmin, adminController.updateCategory);
router.delete('/categories/:id', authMiddleware, requireAdmin, adminController.deleteCategory);

// Gestion des produits par catégorie (admin)
router.get('/stores', authMiddleware, requireAdmin, adminController.getStores);
router.get('/stores/:storeId/products', authMiddleware, requireAdmin, adminController.getStoreProducts);
router.delete('/stores/:storeId/categories/:categoryId', authMiddleware, requireAdmin, adminController.deactivateStoreCategory);
router.get('/categories/:categoryId/products', authMiddleware, requireAdmin, adminController.getCategoryProducts);
router.post('/products', authMiddleware, requireAdmin, adminController.createProduct);
router.put('/products/:id', authMiddleware, requireAdmin, adminController.updateProduct);
router.patch('/products/:id/deactivate', authMiddleware, requireAdmin, adminController.deactivateProduct);
router.patch('/products/:id/activate', authMiddleware, requireAdmin, adminController.activateProduct);
router.patch('/products/:id/rupture-stock', authMiddleware, requireAdmin, adminController.toggleRuptureStock);
router.post('/products/upload-image', (req, res, next) => {
  uploadProductImage.single('image')(req, res, (err) => {
    if (err) {
      const status = err.code === 'LIMIT_FILE_SIZE' ? 400 : 400;
      return res.status(status).json({ message: err.message || 'Erreur upload' });
    }
    next();
  });
}, authMiddleware, requireAdmin, adminController.uploadProductImage);

// Gestion des commandes et litiges
router.get('/orders/stats', authMiddleware, requireAdmin, adminController.getOrderStats);
router.get('/orders/recent', authMiddleware, requireAdmin, adminController.getRecentOrders);
router.get('/disputes', authMiddleware, requireAdmin, adminController.getDisputes);
router.patch('/disputes/:id/status', authMiddleware, requireAdmin, adminController.resolveDispute);

module.exports = router;
