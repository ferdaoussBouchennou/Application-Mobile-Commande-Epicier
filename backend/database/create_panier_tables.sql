-- Create panier tables so the cart persists per user (survives logout/login and server restart).
-- Run this if you previously ran drop_panier_tables.sql or if paniers/panier_produits are missing.

CREATE TABLE IF NOT EXISTS `paniers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `client_id` int(11) NOT NULL,
  `date_creation` date NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `client_id` (`client_id`),
  CONSTRAINT `paniers_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `panier_produits` (
  `panier_id` int(11) NOT NULL,
  `produit_id` int(11) NOT NULL,
  `epicier_id` int(11) DEFAULT NULL,
  `quantite` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`panier_id`,`produit_id`),
  KEY `produit_id` (`produit_id`),
  KEY `epicier_id` (`epicier_id`),
  CONSTRAINT `panier_produits_ibfk_1` FOREIGN KEY (`panier_id`) REFERENCES `paniers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `panier_produits_ibfk_2` FOREIGN KEY (`produit_id`) REFERENCES `produits` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `panier_produits_ibfk_3` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
