-- Run this once to remove panier tables from the database.
-- The app now uses in-memory cart (backend/src/store/cartStore.js); no DB storage for cart.

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS panier_produits;
DROP TABLE IF EXISTS paniers;
SET FOREIGN_KEY_CHECKS = 1;
