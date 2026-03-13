-- Run only if you want to remove panier tables. The app normally uses DB-backed panier (persists after logout/login).

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS panier_produits;
DROP TABLE IF EXISTS paniers;
SET FOREIGN_KEY_CHECKS = 1;
