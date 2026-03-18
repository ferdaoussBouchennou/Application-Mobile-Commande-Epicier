const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  console.error("FATAL ERROR: JWT_SECRET is not defined in .env");
  process.exit(1);
}

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    return res.status(401).json({ error: 'Token manquant' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = { id: decoded.id, email: decoded.email, role: decoded.role, storeId: decoded.storeId || null };
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Token invalide ou expiré' });
  }
};

const requireEpicier = (req, res, next) => {
  if (req.user.role !== 'EPICIER' || !req.user.storeId) {
    return res.status(403).json({ error: 'Accès réservé aux épiciers' });
  }
  next();
};

const requireEpicierOrAdmin = (req, res, next) => {
  if (req.user.role !== 'EPICIER' && req.user.role !== 'ADMIN') {
    return res.status(403).json({ error: 'Accès réservé aux épiciers ou administrateurs' });
  }
  next();
};

const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'ADMIN') {
    return res.status(403).json({ error: 'Accès réservé aux administrateurs' });
  }
  next();
};

module.exports = { authMiddleware, requireEpicier, requireEpicierOrAdmin, requireAdmin };
