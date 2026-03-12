const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authMiddleware, requireAdmin } = require('../middlewares/auth');

router.get('/stats', adminController.getStats);
router.get('/users', adminController.getUsers);
router.patch('/users/:id/status', adminController.updateUserStatus);
router.post('/register-epicier', adminController.registerEpicier);

// Gestion des catégories de la plateforme (CRUD admin)
router.get('/categories', authMiddleware, requireAdmin, adminController.getCategories);
router.post('/categories', authMiddleware, requireAdmin, adminController.createCategory);
router.put('/categories/:id', authMiddleware, requireAdmin, adminController.updateCategory);
router.delete('/categories/:id', authMiddleware, requireAdmin, adminController.deleteCategory);

module.exports = router;
