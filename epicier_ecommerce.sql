-- =============================================================================
-- Epicier E-commerce — schéma et données de test (unique fichier canonique)
-- Aligné sur les modèles Sequelize (backend/src/models).
--
-- Schéma cible (pas de colonnes fantômes) :
--   Inscription épicier : statut_inscription uniquement sur epiciers (pas sur utilisateurs).
--   categories     : id, nom, description (pas display_order, is_active, image_url)
--   produits       : id, nom, description, categorie_id, image_principale, date_ajout, date_modif
--                    (pas prix sur produits — le prix est dans epicier_produits.prix ; pas unite / type_unite)
--   epicier_produits : prix par boutique pour chaque produit du catalogue global
--   reclamations   : type COMMANDE | AVIS, commande_id et avis_id selon le cas
-- BDD existante : au démarrage, backend/src/app.js peut supprimer les colonnes legacy restantes (MySQL).
-- Images: chemins relatifs à la racine backend/ (uploads/...).
-- Comptes test: admin@gmail.com / 12345678 | epicier: *@hanut.com / Password123 | client: client@demo.ma / password123
-- Généré par: node backend/scripts/generate-full-schema-sql.js
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET sql_mode = '';

DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `reclamations`;
DROP TABLE IF EXISTS `avis`;
DROP TABLE IF EXISTS `detailsCommande`;
DROP TABLE IF EXISTS `commandes`;
DROP TABLE IF EXISTS `panier_produits`;
DROP TABLE IF EXISTS `paniers`;
DROP TABLE IF EXISTS `epicier_produits`;
DROP TABLE IF EXISTS `disponibilites`;
DROP TABLE IF EXISTS `produits`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `epiciers`;
DROP TABLE IF EXISTS `utilisateurs`;

-- --------------------------------------------------------------------------- utilisateurs
CREATE TABLE `utilisateurs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nom` varchar(100) NOT NULL,
  `prenom` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `mdp` varchar(255) NOT NULL,
  `id_google` varchar(100) DEFAULT NULL,
  `id_facebook` varchar(100) DEFAULT NULL,
  `id_instagram` varchar(100) DEFAULT NULL,
  `role` enum('CLIENT','ADMIN','EPICIER') NOT NULL DEFAULT 'CLIENT',
  `doc_verf` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `fcm_token` varchar(255) DEFAULT NULL,
  `telephone` varchar(20) DEFAULT NULL,
  `email_verified` tinyint(1) DEFAULT '0',
  `otp_code` varchar(6) DEFAULT NULL,
  `otp_expires_at` datetime DEFAULT NULL,
  `date_creation` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `utilisateurs` (`id`, `nom`, `prenom`, `email`, `mdp`, `role`, `doc_verf`, `is_active`, `email_verified`, `telephone`, `date_creation`) VALUES
(1, 'Admin', 'System', 'admin@gmail.com', '$2b$10$cjD.ksrAef4TnhtYbWvPKOIayrEt4rrP2WR9VneqKabOFDHCkHEma', 'ADMIN', NULL, 1, 1, NULL, '2026-01-01 10:00:00'),
(2, 'Ben Salah', 'Ahmed', 'ahmed@hanut.com', '$2b$10$oxzsRPBl4D3Nc76dDniLHuqjQqC/eVF209Tqya9hk7v8NSHLejmf2', 'EPICIER', 'uploads/documents/doc-1774122338623.png', 1, 1, '0555112233', '2026-01-02 10:00:00'),
(3, 'Mansour', 'Sami', 'sami@hanut.com', '$2b$10$oxzsRPBl4D3Nc76dDniLHuqjQqC/eVF209Tqya9hk7v8NSHLejmf2', 'EPICIER', 'uploads/documents/doc-1774122338623.png', 1, 1, '0555445566', '2026-01-02 10:05:00'),
(4, 'Trabelsi', 'Leila', 'leila@hanut.com', '$2b$10$oxzsRPBl4D3Nc76dDniLHuqjQqC/eVF209Tqya9hk7v8NSHLejmf2', 'EPICIER', 'uploads/documents/doc-1774122338623.png', 1, 1, '0555778899', '2026-01-02 10:10:00'),
(5, 'Gharbi', 'Karim', 'karim@hanut.com', '$2b$10$oxzsRPBl4D3Nc76dDniLHuqjQqC/eVF209Tqya9hk7v8NSHLejmf2', 'EPICIER', 'uploads/documents/doc-1774122338623.png', 1, 1, '0555001122', '2026-01-02 10:15:00'),
(6, 'Zied', 'Mondher', 'mondher@hanut.com', '$2b$10$oxzsRPBl4D3Nc76dDniLHuqjQqC/eVF209Tqya9hk7v8NSHLejmf2', 'EPICIER', 'uploads/documents/doc-1774122338623.png', 1, 1, '0555334455', '2026-01-02 10:20:00'),
(7, 'Alami', 'Youssef', 'client@demo.ma', '$2b$10$0AAvlCtHz3aLpFCuPtlNCeI.wRDNOPuFPOOW7OsHoh8XpLNzxryzW', 'CLIENT', NULL, 1, 1, '0661122334', '2026-01-10 12:00:00'),
(8, 'Idrissi', 'Fatima', 'fatima@demo.ma', '$2b$10$0AAvlCtHz3aLpFCuPtlNCeI.wRDNOPuFPOOW7OsHoh8XpLNzxryzW', 'CLIENT', NULL, 1, 1, '0665566778', '2026-01-11 12:00:00');

-- --------------------------------------------------------------------------- epiciers
CREATE TABLE `epiciers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `utilisateur_id` int NOT NULL,
  `nom_boutique` varchar(200) NOT NULL,
  `adresse` varchar(255) NOT NULL,
  `telephone` varchar(20) DEFAULT NULL,
  `description` text,
  `image_url` varchar(500) DEFAULT NULL,
  `rating` decimal(2,1) DEFAULT '0.0',
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `statut_inscription` enum('EN_ATTENTE','ACCEPTE','REFUSE','COMPLETE') NOT NULL DEFAULT 'EN_ATTENTE',
  `is_active` tinyint(1) DEFAULT '1',
  `date_creation` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `utilisateur_id` (`utilisateur_id`),
  CONSTRAINT `epiciers_ibfk_user` FOREIGN KEY (`utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `epiciers` (`id`, `utilisateur_id`, `nom_boutique`, `adresse`, `telephone`, `description`, `image_url`, `rating`, `latitude`, `longitude`, `statut_inscription`, `is_active`, `date_creation`) VALUES
(1, 2, 'Épicerie Ahmed', 'Rue de la Liberté, Fès', '0555112233', 'Produits frais, lait, pain et alimentation générale.', 'uploads/epiciers/hanut1.jpg', 4.5, 34.0208820, -5.0000000, 'COMPLETE', 1, '2026-01-03 08:00:00'),
(2, 3, 'Hanut Sami', 'Avenue principale, Rabat', '0555445566', 'Votre Hanut de quartier : pain chaud et lait tous les matins.', 'uploads/epiciers/hanut2.jpg', 4.2, 33.9715900, -6.8498130, 'COMPLETE', 1, '2026-01-03 08:00:00'),
(3, 4, 'Chez Leila', 'Route de la Plage, Tanger', '0555778899', 'Alimentation générale et produits de première nécessité.', 'uploads/epiciers/hanut3.jpg', 4.8, 35.7594650, -5.8339540, 'COMPLETE', 1, '2026-01-03 08:00:00'),
(4, 5, 'Karim Market', 'Boulevard de l''Environnement, Casablanca', '0555001122', 'Épicerie fine, semoule, huile et pain traditionnel.', 'uploads/epiciers/hanut4.jpg', 3.9, 33.5731100, -7.5898430, 'COMPLETE', 1, '2026-01-03 08:00:00'),
(5, 6, 'Mondher Express', 'Cité des Jeunes, Meknès', '0555334455', 'Service rapide : lait, sucre, pain et plus.', 'uploads/epiciers/hanut5.jpg', 4.0, 33.8950000, -5.5547300, 'COMPLETE', 1, '2026-01-03 08:00:00');

-- --------------------------------------------------------------------------- categories
CREATE TABLE `categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nom` varchar(100) NOT NULL,
  `description` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `categories` (`id`, `nom`, `description`) VALUES
(1, 'Huiles', 'Huiles alimentaires'),
(2, 'Confiserie', 'Biscuits et gâteaux'),
(3, 'Farines', 'Farines et couscous'),
(4, 'Conserves', 'Conserves et confitures'),
(5, 'Laitiers', 'Produits laitiers'),
(6, 'Hygiène', 'Hygiène et entretien'),
(7, 'Boissons', 'Eaux et boissons'),
(8, 'Épices', 'Épices et aromates'),
(9, 'Boulangerie', 'Pain et pâtisserie');

-- --------------------------------------------------------------------------- produits (pas de prix ni unite — prix dans epicier_produits)
CREATE TABLE `produits` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nom` varchar(200) NOT NULL,
  `description` text,
  `categorie_id` int NOT NULL,
  `image_principale` varchar(500) DEFAULT NULL,
  `date_ajout` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_modif` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `categorie_id` (`categorie_id`),
  CONSTRAINT `produits_ibfk_1` FOREIGN KEY (`categorie_id`) REFERENCES `categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (1, 'Huile Lesieur 1L', 'Huile de table raffinée Lesieur.', 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (2, 'Huile d''Olive Oued Souss 1L', 'Huile d''olive extra vierge du Maroc.', 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (3, 'Huile Argan Alimentaire 250ml', 'Huile d''argan pure et certifiée.', 1, 'uploads/huiles/argan.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (4, 'Lait Centrale 1L', 'Lait frais pasteurisé Centrale Danone.', 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (5, 'Yaourt Jaouda Fraise', 'Yaourt crémeux aux morceaux de fruits.', 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (6, 'Raibi Jamila', 'Boisson lactée fermentée iconique.', 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (7, 'Fromage La Vache Qui Rit (16p)', 'Portions de fromage fondu.', 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (8, 'Farine Mouna 5kg', 'Farine de blé tendre de luxe.', 3, 'uploads/farines/mouna.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (9, 'Semoule Fine Al Ittihad 1kg', 'Semoule de blé dur pour couscous.', 3, 'uploads/farines/semoule.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (10, 'Couscous Dari 1kg', 'Couscous marocain précuit.', 3, 'uploads/farines/dari.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (11, 'Thon Mario à l''huile', 'Morceaux de thon de qualité.', 4, 'uploads/conserves/mario.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (12, 'Tomate Aïcha 400g', 'Double concentré de tomate Aïcha.', 4, 'uploads/conserves/aicha.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (13, 'Confiture Aïcha Fraise', 'Confiture de fraises extra.', 4, 'uploads/conserves/confiture.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (14, 'Eau Sidi Ali 1.5L', 'Eau minérale naturelle Sidi Ali.', 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (15, 'Eau Gazeuse Oulmès 1L', 'Eau minérale gazeuse naturelle.', 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (16, 'Poms', 'Boisson rafraîchissante à la pomme.', 7, 'uploads/boissons/poms.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (17, 'Thé Sultan (Grain Vert)', 'Thé vert de qualité supérieure.', 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (18, 'Pain Batbout', 'Petit pain traditionnel marocain.', 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (19, 'Msemen nature', 'Crêpe feuilletée marocaine.', 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (20, 'Baghrir', 'Crêpe mille trous.', 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (21, 'Biscuits Henry''s', 'Biscuits secs traditionnels.', 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (22, 'Merendina Classic', 'Génoise enrobée de chocolat.', 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (23, 'Savon El Kef', 'Savon de marseille traditionnel.', 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (24, 'Détergent Magix 1kg', 'Lessive poudre pour machine.', 6, 'uploads/hygiene/magix.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (25, 'Ras el Hanout 50g', 'Mélange d''épices marocain.', 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');
INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES (26, 'Kamoun (Cumin) 50g', 'Cumin moulu pur.', 8, 'uploads/epices/cumin.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00');

-- --------------------------------------------------------------------------- epicier_produits
CREATE TABLE `epicier_produits` (
  `epicier_id` int NOT NULL,
  `produit_id` int NOT NULL,
  `prix` decimal(10,2) NOT NULL,
  `rupture_stock` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `date_ajout` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_modif` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`epicier_id`,`produit_id`),
  KEY `produit_id` (`produit_id`),
  CONSTRAINT `epicier_produits_ibfk_1` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `epicier_produits_ibfk_2` FOREIGN KEY (`produit_id`) REFERENCES `produits` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `epicier_produits` (`epicier_id`, `produit_id`, `prix`, `rupture_stock`, `is_active`, `date_ajout`, `date_modif`) VALUES
(1, 1, 19.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 2, 85.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 3, 120.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 4, 7.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 5, 2.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 6, 2.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 7, 18.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 8, 35.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 9, 13.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 10, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 11, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 12, 11.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 13, 16.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 14, 6.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 15, 8.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 16, 6.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 17, 14.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 18, 1.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 19, 2.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 20, 1.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 21, 1.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 22, 2.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 23, 4.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 24, 22.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 25, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 26, 10.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 1, 19.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 2, 85.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 3, 120.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 4, 7.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 5, 2.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 6, 2.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 7, 18.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 8, 35.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 9, 13.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 10, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 11, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 12, 11.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 13, 16.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 14, 6.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 15, 8.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 16, 6.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 17, 14.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 18, 1.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 19, 2.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 20, 1.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 21, 1.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 22, 2.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 23, 4.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 24, 22.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 25, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 26, 10.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 1, 19.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 2, 85.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 3, 120.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 4, 7.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 5, 2.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 6, 2.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 7, 18.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 8, 35.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 9, 13.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 10, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 11, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 12, 11.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 13, 16.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 14, 6.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 15, 8.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 16, 6.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 17, 14.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 18, 1.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 19, 2.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 20, 1.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 21, 1.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 22, 2.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 23, 4.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 24, 22.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 25, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 26, 10.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 1, 19.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 2, 85.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 3, 120.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 4, 7.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 5, 2.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 6, 2.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 7, 18.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 8, 35.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 9, 13.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 10, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 11, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 12, 11.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 13, 16.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 14, 6.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 15, 8.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 16, 6.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 17, 14.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 18, 1.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 19, 2.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 20, 1.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 21, 1.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 22, 2.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 23, 4.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 24, 22.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 25, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 26, 10.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 1, 19.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 2, 85.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 3, 120.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 4, 7.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 5, 2.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 6, 2.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 7, 18.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 8, 35.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 9, 13.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 10, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 11, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 12, 11.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 13, 16.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 14, 6.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 15, 8.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 16, 6.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 17, 14.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 18, 1.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 19, 2.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 20, 1.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 21, 1.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 22, 2.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 23, 4.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 24, 22.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 25, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 26, 10.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00');

-- --------------------------------------------------------------------------- disponibilites
CREATE TABLE `disponibilites` (
  `id` int NOT NULL AUTO_INCREMENT,
  `epicier_id` int NOT NULL,
  `jour` enum('lundi','mardi','mercredi','jeudi','vendredi','samedi','dimanche') NOT NULL,
  `heure_debut` time NOT NULL,
  `heure_fin` time NOT NULL,
  PRIMARY KEY (`id`),
  KEY `epicier_id` (`epicier_id`),
  CONSTRAINT `disponibilites_ibfk_1` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `disponibilites` (`id`, `epicier_id`, `jour`, `heure_debut`, `heure_fin`) VALUES
(1, 1, 'lundi', '08:00:00', '22:00:00'),
(2, 1, 'mardi', '08:00:00', '22:00:00'),
(3, 1, 'mercredi', '08:00:00', '22:00:00'),
(4, 1, 'jeudi', '08:00:00', '22:00:00'),
(5, 1, 'vendredi', '08:00:00', '22:00:00'),
(6, 1, 'samedi', '08:00:00', '22:00:00'),
(7, 1, 'dimanche', '09:00:00', '14:00:00'),
(8, 2, 'lundi', '08:00:00', '22:00:00'),
(9, 2, 'mardi', '08:00:00', '22:00:00'),
(10, 2, 'mercredi', '08:00:00', '22:00:00'),
(11, 2, 'jeudi', '08:00:00', '22:00:00'),
(12, 2, 'vendredi', '08:00:00', '22:00:00'),
(13, 2, 'samedi', '08:00:00', '22:00:00'),
(14, 2, 'dimanche', '09:00:00', '14:00:00'),
(15, 3, 'lundi', '08:00:00', '22:00:00'),
(16, 3, 'mardi', '08:00:00', '22:00:00'),
(17, 3, 'mercredi', '08:00:00', '22:00:00'),
(18, 3, 'jeudi', '08:00:00', '22:00:00'),
(19, 3, 'vendredi', '08:00:00', '22:00:00'),
(20, 3, 'samedi', '08:00:00', '22:00:00'),
(21, 3, 'dimanche', '09:00:00', '14:00:00'),
(22, 4, 'lundi', '08:00:00', '22:00:00'),
(23, 4, 'mardi', '08:00:00', '22:00:00'),
(24, 4, 'mercredi', '08:00:00', '22:00:00'),
(25, 4, 'jeudi', '08:00:00', '22:00:00'),
(26, 4, 'vendredi', '08:00:00', '22:00:00'),
(27, 4, 'samedi', '08:00:00', '22:00:00'),
(28, 4, 'dimanche', '09:00:00', '14:00:00'),
(29, 5, 'lundi', '08:00:00', '22:00:00'),
(30, 5, 'mardi', '08:00:00', '22:00:00'),
(31, 5, 'mercredi', '08:00:00', '22:00:00'),
(32, 5, 'jeudi', '08:00:00', '22:00:00'),
(33, 5, 'vendredi', '08:00:00', '22:00:00'),
(34, 5, 'samedi', '08:00:00', '22:00:00'),
(35, 5, 'dimanche', '09:00:00', '14:00:00');

-- --------------------------------------------------------------------------- commandes
CREATE TABLE `commandes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `client_id` int NOT NULL,
  `epicier_id` int NOT NULL,
  `date_commande` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_recuperation` datetime DEFAULT NULL,
  `statut` enum('reçue','prête','refusee','livrée') NOT NULL DEFAULT 'reçue',
  `message_refus` text,
  `lu_epicier` tinyint DEFAULT '0',
  `notes` text,
  `client_accepte_modification` tinyint DEFAULT '0',
  `montant_total` decimal(10,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`),
  KEY `client_id` (`client_id`),
  KEY `epicier_id` (`epicier_id`),
  CONSTRAINT `commandes_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `utilisateurs` (`id`),
  CONSTRAINT `commandes_ibfk_2` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `commandes` (`id`, `client_id`, `epicier_id`, `date_commande`, `date_recuperation`, `statut`, `message_refus`, `lu_epicier`, `montant_total`) VALUES
(1, 7, 1, '2026-03-15 09:30:00', '2026-03-15 11:00:00', 'livrée', NULL, 1, 46.00),
(2, 7, 2, '2026-03-16 10:00:00', NULL, 'prête', NULL, 1, 30.00),
(3, 8, 3, '2026-03-17 14:20:00', NULL, 'reçue', NULL, 0, 30.00),
(4, 7, 4, '2026-03-10 08:00:00', '2026-03-10 10:00:00', 'livrée', NULL, 1, 120.00),
(5, 8, 1, '2026-03-12 16:00:00', NULL, 'refusee', 'Stock insuffisant', 1, 0.00),
(6, 7, 5, '2026-03-18 11:00:00', NULL, 'reçue', NULL, 0, 55.50);

-- --------------------------------------------------------------------------- detailsCommande
CREATE TABLE `detailsCommande` (
  `id` int NOT NULL AUTO_INCREMENT,
  `commande_id` int NOT NULL,
  `produit_id` int NOT NULL,
  `quantite` int NOT NULL DEFAULT '1',
  `prix_unitaire` decimal(10,2) NOT NULL,
  `total_ligne` decimal(10,2) NOT NULL,
  `rupture` tinyint DEFAULT '0',
  `en_attente_acceptation_client` tinyint DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `commande_id` (`commande_id`),
  KEY `produit_id` (`produit_id`),
  CONSTRAINT `detailscommande_ibfk_1` FOREIGN KEY (`commande_id`) REFERENCES `commandes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `detailscommande_ibfk_2` FOREIGN KEY (`produit_id`) REFERENCES `produits` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `detailsCommande` (`id`, `commande_id`, `produit_id`, `quantite`, `prix_unitaire`, `total_ligne`, `rupture`, `en_attente_acceptation_client`) VALUES
(1, 1, 1, 2, 19.50, 39.00, 0, 0),
(2, 1, 4, 1, 7.00, 7.00, 0, 0),
(3, 2, 14, 4, 6.00, 24.00, 0, 0),
(4, 2, 18, 4, 1.50, 6.00, 0, 0),
(5, 3, 11, 2, 15.00, 30.00, 0, 0),
(6, 4, 3, 1, 120.00, 120.00, 0, 0),
(7, 6, 8, 1, 35.00, 35.00, 0, 0),
(8, 6, 9, 1, 13.00, 13.00, 0, 0),
(9, 6, 18, 5, 1.50, 7.50, 0, 0);

-- --------------------------------------------------------------------------- paniers
CREATE TABLE `paniers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `client_id` int NOT NULL,
  `date_creation` date NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `client_id` (`client_id`),
  CONSTRAINT `paniers_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `paniers` (`id`, `client_id`, `date_creation`) VALUES (1, 7, '2026-03-20');

-- --------------------------------------------------------------------------- panier_produits
CREATE TABLE `panier_produits` (
  `panier_id` int NOT NULL,
  `produit_id` int NOT NULL,
  `epicier_id` int DEFAULT NULL,
  `quantite` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`panier_id`,`produit_id`),
  KEY `produit_id` (`produit_id`),
  KEY `epicier_id` (`epicier_id`),
  CONSTRAINT `panier_produits_ibfk_1` FOREIGN KEY (`panier_id`) REFERENCES `paniers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `panier_produits_ibfk_2` FOREIGN KEY (`produit_id`) REFERENCES `produits` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `panier_produits_ibfk_3` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `panier_produits` (`panier_id`, `produit_id`, `epicier_id`, `quantite`) VALUES (1, 14, 1, 2), (1, 18, 1, 3);

-- --------------------------------------------------------------------------- avis
CREATE TABLE `avis` (
  `id` int NOT NULL AUTO_INCREMENT,
  `client_id` int NOT NULL,
  `epicier_id` int NOT NULL,
  `note` tinyint NOT NULL,
  `commentaire` text,
  `date_avis` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `client_id` (`client_id`),
  KEY `epicier_id` (`epicier_id`),
  CONSTRAINT `avis_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `utilisateurs` (`id`),
  CONSTRAINT `avis_ibfk_2` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `avis` (`id`, `client_id`, `epicier_id`, `note`, `commentaire`, `date_avis`) VALUES
(1, 7, 1, 5, 'Très bon accueil et produits frais.', '2026-03-08 17:00:00'),
(2, 8, 2, 4, 'Livraison rapide.', '2026-03-09 10:00:00'),
(3, 7, 3, 5, 'Excellent choix.', '2026-03-09 18:30:00');

-- --------------------------------------------------------------------------- reclamations
CREATE TABLE `reclamations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `motif` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `photo` varchar(255) DEFAULT NULL,
  `statut` enum('En attente','Résolu','En médiation','Remboursé','Litige ouvert') NOT NULL DEFAULT 'En attente',
  `reponse_epicier` text,
  `client_id` int NOT NULL,
  `commande_id` int DEFAULT NULL,
  `epicier_id` int DEFAULT NULL,
  `avis_id` int DEFAULT NULL,
  `type` enum('COMMANDE','AVIS') NOT NULL DEFAULT 'COMMANDE',
  `date_creation` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `client_id` (`client_id`),
  KEY `commande_id` (`commande_id`),
  KEY `epicier_id` (`epicier_id`),
  KEY `avis_id` (`avis_id`),
  CONSTRAINT `reclamations_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `utilisateurs` (`id`),
  CONSTRAINT `reclamations_ibfk_2` FOREIGN KEY (`commande_id`) REFERENCES `commandes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `reclamations_ibfk_3` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `reclamations_ibfk_4` FOREIGN KEY (`avis_id`) REFERENCES `avis` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `reclamations` (`id`, `motif`, `description`, `photo`, `statut`, `client_id`, `commande_id`, `epicier_id`, `avis_id`, `type`, `date_creation`) VALUES
(1, 'Produit manquant', 'Il manquait une bouteille d''huile dans le colis.', NULL, 'En attente', 7, 1, 1, NULL, 'COMMANDE', '2026-03-16 09:00:00'),
(2, 'Question avis', 'Je souhaite modifier mon commentaire.', NULL, 'Résolu', 8, NULL, 2, 2, 'AVIS', '2026-03-10 12:00:00');

-- --------------------------------------------------------------------------- notifications
CREATE TABLE `notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `utilisateur_id` int NOT NULL,
  `message` text NOT NULL,
  `lue` tinyint(1) DEFAULT '0',
  `date_envoi` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `utilisateur_id` (`utilisateur_id`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `notifications` (`id`, `utilisateur_id`, `message`, `lue`, `date_envoi`) VALUES
(1, 7, 'Votre commande #1 est prête à être récupérée.', 0, '2026-03-15 10:30:00'),
(2, 7, 'Bienvenue sur Epicier !', 1, '2026-01-10 12:05:00'),
(3, 2, 'Nouvelle commande reçue pour votre boutique.', 0, '2026-03-17 14:25:00'),
(4, 7, 'Votre commande #2 est prête.', 1, '2026-03-16 11:00:00'),
(5, 8, 'Promotion : -10% ce week-end.', 0, '2026-03-18 08:00:00');

SET FOREIGN_KEY_CHECKS = 1;

-- AUTO_INCREMENT
ALTER TABLE `utilisateurs` AUTO_INCREMENT = 9;
ALTER TABLE `epiciers` AUTO_INCREMENT = 6;
ALTER TABLE `categories` AUTO_INCREMENT = 10;
ALTER TABLE `produits` AUTO_INCREMENT = 27;
ALTER TABLE `commandes` AUTO_INCREMENT = 7;
ALTER TABLE `detailsCommande` AUTO_INCREMENT = 10;
ALTER TABLE `paniers` AUTO_INCREMENT = 2;
ALTER TABLE `avis` AUTO_INCREMENT = 4;
ALTER TABLE `reclamations` AUTO_INCREMENT = 3;
ALTER TABLE `notifications` AUTO_INCREMENT = 6;
ALTER TABLE `disponibilites` AUTO_INCREMENT = 36;
