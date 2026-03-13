-- Run this to remove panier tables from the database.
-- The app uses in-memory cart (session); see backend/src/store/cartStore.js. No DB storage for panier.

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS panier_produits;
DROP TABLE IF EXISTS paniers;
SET FOREIGN_KEY_CHECKS = 1;
