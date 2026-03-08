// Middleware d'authentification JWT (à compléter)
const authMiddleware = (req, res, next) => {
  const token = req.headers['authorization'];
  if (!token) {
    return res.status(401).json({ error: 'Token manquant' });
  }
  // TODO: vérifier le token JWT
  next();
};

module.exports = authMiddleware;
