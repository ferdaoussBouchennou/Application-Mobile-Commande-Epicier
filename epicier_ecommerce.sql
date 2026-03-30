-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1
-- Généré le : lun. 30 mars 2026 à 12:18
-- Version du serveur : 10.4.32-MariaDB
-- Version de PHP : 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `epicier_ecommerce`
--

-- --------------------------------------------------------

--
-- Structure de la table `avis`
--

CREATE TABLE `avis` (
  `id` int(11) NOT NULL,
  `client_id` int(11) NOT NULL,
  `epicier_id` int(11) NOT NULL,
  `note` tinyint(4) NOT NULL,
  `commentaire` text DEFAULT NULL,
  `date_avis` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `avis`
--

INSERT INTO `avis` (`id`, `client_id`, `epicier_id`, `note`, `commentaire`, `date_avis`) VALUES
(1, 7, 1, 5, 'Très bon accueil et produits frais.', '2026-03-08 17:00:00'),
(2, 8, 2, 4, 'Livraison rapide.', '2026-03-09 10:00:00'),
(3, 7, 3, 5, 'Excellent choix.', '2026-03-09 18:30:00'),
(4, 24, 1, 1, 'Mal service', '2026-03-30 08:57:02');

-- --------------------------------------------------------

--
-- Structure de la table `categories`
--

CREATE TABLE `categories` (
  `id` int(11) NOT NULL,
  `nom` varchar(100) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `categories`
--

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

-- --------------------------------------------------------

--
-- Structure de la table `commandes`
--

CREATE TABLE `commandes` (
  `id` int(11) NOT NULL,
  `client_id` int(11) NOT NULL,
  `epicier_id` int(11) NOT NULL,
  `date_commande` datetime NOT NULL DEFAULT current_timestamp(),
  `date_recuperation` datetime DEFAULT NULL,
  `statut` enum('reçue','prête','refusee','livrée') NOT NULL DEFAULT 'reçue',
  `message_refus` text DEFAULT NULL,
  `lu_epicier` tinyint(4) DEFAULT 0,
  `notes` text DEFAULT NULL,
  `client_accepte_modification` tinyint(4) DEFAULT 0,
  `montant_total` decimal(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `commandes`
--

INSERT INTO `commandes` (`id`, `client_id`, `epicier_id`, `date_commande`, `date_recuperation`, `statut`, `message_refus`, `lu_epicier`, `notes`, `client_accepte_modification`, `montant_total`) VALUES
(1, 7, 1, '2026-03-15 09:30:00', '2026-03-15 11:00:00', 'livrée', NULL, 1, NULL, 0, 46.00),
(2, 7, 2, '2026-03-16 10:00:00', NULL, 'prête', NULL, 1, NULL, 0, 30.00),
(3, 8, 3, '2026-03-17 14:20:00', NULL, 'reçue', NULL, 0, NULL, 0, 30.00),
(4, 7, 4, '2026-03-10 08:00:00', '2026-03-10 10:00:00', 'livrée', NULL, 1, NULL, 0, 120.00),
(5, 8, 1, '2026-03-12 16:00:00', NULL, 'refusee', 'Stock insuffisant', 1, NULL, 0, 0.00),
(6, 7, 5, '2026-03-18 11:00:00', NULL, 'reçue', NULL, 0, NULL, 0, 55.50),
(9, 24, 1, '2026-03-30 08:47:30', '2026-03-31 11:00:00', 'livrée', NULL, 1, NULL, 0, 19.00),
(10, 24, 1, '2026-03-30 08:58:32', '2026-03-30 17:00:00', 'reçue', NULL, 0, NULL, 1, 140.50),
(11, 24, 1, '2026-03-30 09:02:25', '2026-03-31 13:00:00', 'reçue', NULL, 0, NULL, 1, 74.00),
(12, 24, 1, '2026-03-30 09:04:14', '2026-04-01 12:00:00', 'reçue', NULL, 0, NULL, 0, 56.00),
(13, 24, 1, '2026-03-30 09:04:40', '2026-04-04 11:00:00', 'refusee', 'Hello', 1, NULL, 0, 19.00),
(14, 24, 1, '2026-03-30 09:28:42', '2026-03-30 10:00:00', 'refusee', 'sorry', 0, NULL, 0, 27.50);

-- --------------------------------------------------------

--
-- Structure de la table `detailscommande`
--

CREATE TABLE `detailscommande` (
  `id` int(11) NOT NULL,
  `commande_id` int(11) NOT NULL,
  `produit_id` int(11) NOT NULL,
  `quantite` int(11) NOT NULL DEFAULT 1,
  `prix_unitaire` decimal(10,2) NOT NULL,
  `total_ligne` decimal(10,2) NOT NULL,
  `rupture` tinyint(4) DEFAULT 0,
  `en_attente_acceptation_client` tinyint(4) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `detailscommande`
--

INSERT INTO `detailscommande` (`id`, `commande_id`, `produit_id`, `quantite`, `prix_unitaire`, `total_ligne`, `rupture`, `en_attente_acceptation_client`) VALUES
(1, 1, 1, 2, 19.50, 39.00, 0, 0),
(2, 1, 4, 1, 7.00, 7.00, 0, 0),
(3, 2, 14, 4, 6.00, 24.00, 0, 0),
(4, 2, 18, 4, 1.50, 6.00, 0, 0),
(5, 3, 11, 2, 15.00, 30.00, 0, 0),
(6, 4, 3, 1, 120.00, 120.00, 0, 0),
(7, 6, 8, 1, 35.00, 35.00, 0, 0),
(8, 6, 9, 1, 13.00, 13.00, 0, 0),
(9, 6, 18, 5, 1.50, 7.50, 0, 0),
(13, 9, 22, 2, 2.00, 4.00, 0, 0),
(14, 9, 25, 1, 15.00, 15.00, 0, 0),
(15, 10, 3, 1, 120.00, 120.00, 1, 0),
(16, 10, 23, 1, 4.50, 4.50, 1, 0),
(17, 10, 24, 1, 22.00, 22.00, 0, 0),
(18, 10, 14, 1, 6.00, 6.00, 0, 0),
(19, 10, 15, 1, 8.50, 8.50, 0, 0),
(20, 10, 12, 1, 11.00, 11.00, 0, 0),
(21, 10, 5, 1, 2.50, 2.50, 0, 0),
(22, 10, 4, 1, 7.00, 7.00, 0, 0),
(23, 10, 7, 1, 18.00, 18.00, 0, 0),
(24, 10, 6, 1, 2.50, 2.50, 0, 0),
(25, 10, 10, 1, 15.00, 15.00, 0, 0),
(26, 10, 9, 1, 13.00, 13.00, 0, 0),
(27, 10, 8, 1, 35.00, 35.00, 0, 0),
(28, 11, 13, 1, 16.00, 16.00, 0, 1),
(29, 11, 12, 1, 11.00, 11.00, 0, 1),
(30, 11, 11, 1, 15.00, 15.00, 1, 0),
(31, 11, 26, 1, 10.00, 10.00, 0, 0),
(32, 11, 25, 1, 15.00, 15.00, 0, 0),
(33, 11, 24, 1, 22.00, 22.00, 0, 0),
(34, 12, 6, 1, 2.50, 2.50, 1, 0),
(35, 12, 7, 1, 18.00, 18.00, 0, 0),
(36, 12, 4, 1, 7.00, 7.00, 0, 0),
(37, 12, 5, 1, 2.50, 2.50, 0, 0),
(38, 12, 15, 1, 8.50, 8.50, 0, 0),
(39, 12, 16, 1, 6.00, 6.00, 0, 0),
(40, 12, 17, 1, 14.00, 14.00, 0, 0),
(41, 13, 22, 2, 2.00, 4.00, 0, 0),
(42, 13, 25, 1, 15.00, 15.00, 0, 0),
(43, 14, 7, 1, 18.00, 18.00, 0, 0),
(44, 14, 4, 1, 7.00, 7.00, 0, 0),
(45, 14, 5, 1, 2.50, 2.50, 0, 0);

-- --------------------------------------------------------

--
-- Structure de la table `disponibilites`
--

CREATE TABLE `disponibilites` (
  `id` int(11) NOT NULL,
  `epicier_id` int(11) NOT NULL,
  `jour` enum('lundi','mardi','mercredi','jeudi','vendredi','samedi','dimanche') NOT NULL,
  `heure_debut` time NOT NULL,
  `heure_fin` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `disponibilites`
--

INSERT INTO `disponibilites` (`id`, `epicier_id`, `jour`, `heure_debut`, `heure_fin`) VALUES
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
(35, 5, 'dimanche', '09:00:00', '14:00:00'),
(36, 1, 'lundi', '08:00:00', '22:00:00'),
(37, 1, 'mardi', '08:00:00', '22:00:00'),
(38, 1, 'mercredi', '08:00:00', '22:00:00'),
(39, 1, 'jeudi', '08:00:00', '22:00:00'),
(40, 1, 'vendredi', '08:00:00', '22:00:00'),
(41, 1, 'samedi', '08:00:00', '22:00:00'),
(42, 1, 'dimanche', '09:00:00', '14:00:00');

-- --------------------------------------------------------

--
-- Structure de la table `epiciers`
--

CREATE TABLE `epiciers` (
  `id` int(11) NOT NULL,
  `utilisateur_id` int(11) NOT NULL,
  `nom_boutique` varchar(200) NOT NULL,
  `adresse` varchar(255) NOT NULL,
  `telephone` varchar(20) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `rating` decimal(2,1) DEFAULT 0.0,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `statut_inscription` enum('EN_ATTENTE','ACCEPTE','REFUSE','COMPLETE') NOT NULL DEFAULT 'EN_ATTENTE',
  `is_active` tinyint(1) DEFAULT 1,
  `date_creation` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `epiciers`
--

INSERT INTO `epiciers` (`id`, `utilisateur_id`, `nom_boutique`, `adresse`, `telephone`, `description`, `image_url`, `rating`, `latitude`, `longitude`, `statut_inscription`, `is_active`, `date_creation`) VALUES
(1, 2, 'Épicerie Ahmed', 'Centre-ville, Tétouan', '0555112234', 'Produits frais, lait, pain et alimentation générale.', 'uploads/epiciers/hanut1.jpg', 3.0, 35.57845000, -5.36837000, 'COMPLETE', 1, '2026-01-03 08:00:00'),
(2, 3, 'Hanut Sami', 'Avenue Hassan II, Tétouan', '0555445566', 'Votre Hanut de quartier : pain chaud et lait tous les matins.', 'uploads/epiciers/hanut2.jpg', 4.2, 35.58012000, -5.36154000, 'COMPLETE', 1, '2026-01-03 08:00:00'),
(3, 4, 'Chez Leila', 'Route de Martil, Tétouan', '0555778899', 'Alimentation générale et produits de première nécessité.', 'uploads/epiciers/hanut3.jpg', 4.8, 35.57500000, -5.35000000, 'COMPLETE', 1, '2026-01-03 08:00:00'),
(4, 5, 'Karim Market', 'Bab Toute, Tétouan', '0555001122', 'Épicerie fine, semoule, huile et pain traditionnel.', 'uploads/epiciers/hanut4.jpg', 3.9, 35.57211000, -5.37284000, 'COMPLETE', 1, '2026-01-03 08:00:00'),
(5, 6, 'Mondher Express', 'Quartier Administratif, Tétouan', '0555334455', 'Service rapide : lait, sucre, pain et plus.', 'uploads/epiciers/hanut5.jpg', 4.0, 35.56890000, -5.36573000, 'COMPLETE', 1, '2026-01-03 08:00:00');

-- --------------------------------------------------------

--
-- Structure de la table `epicier_produits`
--

CREATE TABLE `epicier_produits` (
  `epicier_id` int(11) NOT NULL,
  `produit_id` int(11) NOT NULL,
  `prix` decimal(10,2) NOT NULL,
  `rupture_stock` tinyint(1) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `date_ajout` datetime NOT NULL DEFAULT current_timestamp(),
  `date_modif` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `epicier_produits`
--

INSERT INTO `epicier_produits` (`epicier_id`, `produit_id`, `prix`, `rupture_stock`, `is_active`, `date_ajout`, `date_modif`) VALUES
(1, 1, 19.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 2, 85.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 3, 120.00, 1, 1, '2026-03-10 10:00:00', '2026-03-30 08:59:35'),
(1, 4, 7.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 5, 2.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 6, 2.50, 1, 1, '2026-03-10 10:00:00', '2026-03-30 09:11:21'),
(1, 7, 18.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 8, 35.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 9, 13.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 10, 15.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 11, 15.00, 1, 1, '2026-03-10 10:00:00', '2026-03-30 09:11:46'),
(1, 12, 11.00, 0, 1, '2026-03-10 10:00:00', '2026-03-30 09:24:58'),
(1, 13, 16.00, 0, 1, '2026-03-10 10:00:00', '2026-03-30 09:24:47'),
(1, 14, 6.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 15, 8.50, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 16, 6.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 17, 14.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 18, 1.50, 0, 0, '2026-03-10 10:00:00', '2026-03-23 21:50:39'),
(1, 19, 2.00, 0, 0, '2026-03-10 10:00:00', '2026-03-23 21:50:39'),
(1, 20, 1.50, 0, 0, '2026-03-10 10:00:00', '2026-03-23 21:50:39'),
(1, 21, 1.00, 0, 1, '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(1, 22, 2.00, 0, 1, '2026-03-10 10:00:00', '2026-03-23 21:07:09'),
(1, 23, 4.50, 1, 1, '2026-03-10 10:00:00', '2026-03-30 08:59:39'),
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

-- --------------------------------------------------------

--
-- Structure de la table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `utilisateur_id` int(11) NOT NULL,
  `message` text NOT NULL,
  `lue` tinyint(1) DEFAULT 0,
  `date_envoi` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `notifications`
--

INSERT INTO `notifications` (`id`, `utilisateur_id`, `message`, `lue`, `date_envoi`) VALUES
(1, 2, 'Nouvelle commande #9 reçue (19.00 MAD).', 1, '2026-03-30 08:47:30'),
(2, 24, 'Votre commande a été acceptée et est prête à être récupérée.', 1, '2026-03-30 08:55:11'),
(3, 2, 'Nouvel avis reçu : 1/5 — \"Mal service\" (commande #9)', 0, '2026-03-30 08:57:02'),
(4, 2, 'Nouvelle commande #10 reçue (265.00 MAD).', 0, '2026-03-30 08:58:32'),
(5, 24, 'Le produit \"Huile Argan Alimentaire 250ml\" est en rupture de stock dans votre commande #10. La commande a été modifiée (nouveau total: 145.00 MAD). Souhaitez-vous continuer? Contactez l\'épicier pour plus d\'infos.', 1, '2026-03-30 08:59:35'),
(6, 24, 'Le produit \"Savon El Kef\" est en rupture de stock dans votre commande #10. La commande a été modifiée (nouveau total: 140.50 MAD). Souhaitez-vous continuer? Contactez l\'épicier pour plus d\'infos.', 1, '2026-03-30 08:59:39'),
(7, 2, 'Le client a accepté les modifications (ruptures) de la commande #10. Vous pouvez accepter la commande.', 0, '2026-03-30 09:01:40'),
(8, 2, 'Nouvelle commande #11 reçue (89.00 MAD).', 0, '2026-03-30 09:02:25'),
(9, 2, 'Nouvelle commande #12 reçue (58.50 MAD).', 0, '2026-03-30 09:04:14'),
(10, 2, 'Nouvelle commande #13 reçue (19.00 MAD).', 0, '2026-03-30 09:04:40'),
(11, 24, 'Changement de plan', 1, '2026-03-30 09:09:22'),
(12, 24, 'Le produit \"Raibi Jamila\" est en rupture de stock dans votre commande #12. La commande a été modifiée (nouveau total: 56.00 MAD). Souhaitez-vous continuer? Contactez l\'épicier pour plus d\'infos.', 1, '2026-03-30 09:11:21'),
(13, 24, 'Le produit \"Confiture Aïcha Fraise\" est en rupture de stock dans votre commande #11. La commande a été modifiée (nouveau total: 73.00 MAD). Souhaitez-vous continuer? Contactez l\'épicier pour plus d\'infos.', 1, '2026-03-30 09:11:37'),
(14, 24, 'Le produit \"Tomate Aïcha 400g\" est en rupture de stock dans votre commande #11. La commande a été modifiée (nouveau total: 62.00 MAD). Souhaitez-vous continuer? Contactez l\'épicier pour plus d\'infos.', 1, '2026-03-30 09:11:42'),
(15, 24, 'Le produit \"Thon Mario à l\'huile\" est en rupture de stock dans votre commande #11. La commande a été modifiée (nouveau total: 47.00 MAD). Souhaitez-vous continuer? Contactez l\'épicier pour plus d\'infos.', 1, '2026-03-30 09:11:46'),
(16, 2, 'Le client a accepté les modifications (ruptures) de la commande #11. Vous pouvez accepter la commande.', 0, '2026-03-30 09:14:39'),
(17, 2, 'Nouvelle réclamation #4 · Commande #9 · Client: Ismail Hamani · Motif: Retard important', 1, '2026-03-30 09:22:24'),
(18, 1, 'Nouvelle litige reçue: Un client (Ismail Hamani) a ouvert une réclamation : Retard important', 1, '2026-03-30 09:22:24'),
(19, 24, 'Le produit \"Confiture Aïcha Fraise\" est à nouveau disponible. Souhaitez-vous l\'ajouter à votre commande #11? (nouveau total: 63.00 MAD)', 0, '2026-03-30 09:24:47'),
(20, 24, 'Le produit \"Tomate Aïcha 400g\" est à nouveau disponible. Souhaitez-vous l\'ajouter à votre commande #11? (nouveau total: 74.00 MAD)', 0, '2026-03-30 09:24:58'),
(21, 2, 'Nouvelle commande #14 reçue (27.50 MAD).', 0, '2026-03-30 09:28:42'),
(22, 2, 'Le client a annulé la commande #14. Motif : \"sorry\"', 1, '2026-03-30 09:28:58'),
(23, 1, 'Nouvelle inscription epicier (Facebook): Un nouvel épicier (Fatima Fatima) s\'est inscrit via Facebook et attend sa validation.', 1, '2026-03-30 09:31:41'),
(24, 1, 'Nouvelle inscription epicier: Un nouvel épicier (Zakariyae El Allouche) est en attente de validation.', 1, '2026-03-30 09:39:11'),
(25, 2, 'Statut réclamation (avis) #5 : Résolu', 0, '2026-03-30 09:58:52');

-- --------------------------------------------------------

--
-- Structure de la table `produits`
--

CREATE TABLE `produits` (
  `id` int(11) NOT NULL,
  `nom` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `categorie_id` int(11) NOT NULL,
  `image_principale` varchar(500) DEFAULT NULL,
  `date_ajout` datetime NOT NULL DEFAULT current_timestamp(),
  `date_modif` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `produits`
--

INSERT INTO `produits` (`id`, `nom`, `description`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES
(1, 'Huile Lesieur 1L', 'Huile de table raffinée Lesieur.', 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(2, 'Huile d\'Olive Oued Souss 1L', 'Huile d\'olive extra vierge du Maroc.', 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(3, 'Huile Argan Alimentaire 250ml', 'Huile d\'argan pure et certifiée.', 1, 'uploads/huiles/argan.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(4, 'Lait Centrale 1L', 'Lait frais pasteurisé Centrale Danone.', 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(5, 'Yaourt Jaouda Fraise', 'Yaourt crémeux aux morceaux de fruits.', 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(6, 'Raibi Jamila', 'Boisson lactée fermentée iconique.', 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(7, 'Fromage La Vache Qui Rit (16p)', 'Portions de fromage fondu.', 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(8, 'Farine Mouna 5kg', 'Farine de blé tendre de luxe.', 3, 'uploads/farines/mouna.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(9, 'Semoule Fine Al Ittihad 1kg', 'Semoule de blé dur pour couscous.', 3, 'uploads/farines/semoule.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(10, 'Couscous Dari 1kg', 'Couscous marocain précuit.', 3, 'uploads/farines/dari.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(11, 'Thon Mario à l\'huile', 'Morceaux de thon de qualité.', 4, 'uploads/conserves/mario.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(12, 'Tomate Aïcha 400g', 'Double concentré de tomate Aïcha.', 4, 'uploads/conserves/aicha.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(13, 'Confiture Aïcha Fraise', 'Confiture de fraises extra.', 4, 'uploads/conserves/confiture.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(14, 'Eau Sidi Ali 1.5L', 'Eau minérale naturelle Sidi Ali.', 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(15, 'Eau Gazeuse Oulmès 1L', 'Eau minérale gazeuse naturelle.', 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(16, 'Poms', 'Boisson rafraîchissante à la pomme.', 7, 'uploads/boissons/poms.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(17, 'Thé Sultan (Grain Vert)', 'Thé vert de qualité supérieure.', 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(18, 'Pain Batbout', 'Petit pain traditionnel marocain.', 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(19, 'Msemen nature', 'Crêpe feuilletée marocaine.', 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(20, 'Baghrir', 'Crêpe mille trous.', 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(21, 'Biscuits Henry\'s', 'Biscuits secs traditionnels.', 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(22, 'Merendina Classic', 'Génoise enrobée de chocolat.', 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(23, 'Savon El Kef', 'Savon de marseille traditionnel.', 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(24, 'Détergent Magix 1kg', 'Lessive poudre pour machine.', 6, 'uploads/hygiene/magix.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(25, 'Ras el Hanout 50g', 'Mélange d\'épices marocain.', 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(26, 'Kamoun (Cumin) 50g', 'Cumin moulu pur.', 8, 'uploads/epices/cumin.jpg', '2026-03-10 10:00:00', '2026-03-10 10:00:00'),
(27, 'samak el awam', 'test test', 7, 'uploads/Boissons/energy_drink.jpg', '2026-03-30 09:53:25', '2026-03-30 09:55:25');

-- --------------------------------------------------------

--
-- Structure de la table `reclamations`
--

CREATE TABLE `reclamations` (
  `id` int(11) NOT NULL,
  `motif` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `photo` varchar(255) DEFAULT NULL,
  `statut` enum('En attente','Résolu','En médiation','Remboursé','Litige ouvert') NOT NULL DEFAULT 'En attente',
  `reponse_epicier` text DEFAULT NULL,
  `client_id` int(11) NOT NULL,
  `commande_id` int(11) DEFAULT NULL,
  `epicier_id` int(11) DEFAULT NULL,
  `avis_id` int(11) DEFAULT NULL,
  `type` enum('COMMANDE','AVIS') NOT NULL DEFAULT 'COMMANDE',
  `date_creation` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `reclamations`
--

INSERT INTO `reclamations` (`id`, `motif`, `description`, `photo`, `statut`, `reponse_epicier`, `client_id`, `commande_id`, `epicier_id`, `avis_id`, `type`, `date_creation`) VALUES
(1, 'Produit manquant', 'Il manquait une bouteille d\'huile dans le colis.', NULL, 'En attente', NULL, 7, 1, 1, NULL, 'COMMANDE', '2026-03-16 09:00:00'),
(2, 'Question avis', 'Je souhaite modifier mon commentaire.', NULL, 'Résolu', NULL, 8, NULL, 2, 2, 'AVIS', '2026-03-10 12:00:00'),
(4, 'Retard important', 'Je souhaite modifier mon commentaire.', NULL, 'En attente', 'Désole ismail', 24, 9, 1, NULL, 'COMMANDE', '2026-03-30 09:22:24'),
(5, 'Avis hors sujet', 'Il manquait une bouteille d\'huile dans le colis.', NULL, 'Résolu', NULL, 24, NULL, 1, 4, 'AVIS', '2026-03-30 09:26:10');

-- --------------------------------------------------------

--
-- Structure de la table `utilisateurs`
--

CREATE TABLE `utilisateurs` (
  `id` int(11) NOT NULL,
  `nom` varchar(100) NOT NULL,
  `prenom` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `mdp` varchar(255) NOT NULL,
  `id_google` varchar(100) DEFAULT NULL,
  `id_facebook` varchar(100) DEFAULT NULL,
  `id_instagram` varchar(100) DEFAULT NULL,
  `role` enum('CLIENT','ADMIN','EPICIER') NOT NULL DEFAULT 'CLIENT',
  `doc_verf` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `fcm_token` varchar(255) DEFAULT NULL,
  `telephone` varchar(20) DEFAULT NULL,
  `email_verified` tinyint(1) DEFAULT 0,
  `otp_code` varchar(6) DEFAULT NULL,
  `otp_expires_at` datetime DEFAULT NULL,
  `date_creation` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `utilisateurs`
--

INSERT INTO `utilisateurs` (`id`, `nom`, `prenom`, `email`, `mdp`, `id_google`, `id_facebook`, `id_instagram`, `role`, `doc_verf`, `is_active`, `fcm_token`, `telephone`, `email_verified`, `otp_code`, `otp_expires_at`, `date_creation`) VALUES
(1, 'Admin', 'System', 'admin@gmail.com', '$2b$10$cjD.ksrAef4TnhtYbWvPKOIayrEt4rrP2WR9VneqKabOFDHCkHEma', NULL, NULL, NULL, 'ADMIN', NULL, 1, NULL, NULL, 1, NULL, NULL, '2026-01-01 10:00:00'),
(2, 'Ben Salah', 'Ahmed', 'ahmed@hanut.com', '$2b$10$oxzsRPBl4D3Nc76dDniLHuqjQqC/eVF209Tqya9hk7v8NSHLejmf2', NULL, NULL, NULL, 'EPICIER', 'uploads/documents/doc-1774122338623.png', 1, NULL, '0555112233', 1, NULL, NULL, '2026-01-02 10:00:00'),
(3, 'Mansour', 'Sami', 'sami@hanut.com', '$2b$10$oxzsRPBl4D3Nc76dDniLHuqjQqC/eVF209Tqya9hk7v8NSHLejmf2', NULL, NULL, NULL, 'EPICIER', 'uploads/documents/doc-1774122338623.png', 1, NULL, '0555445566', 1, NULL, NULL, '2026-01-02 10:05:00'),
(4, 'Trabelsi', 'Leila', 'leila@hanut.com', '$2b$10$oxzsRPBl4D3Nc76dDniLHuqjQqC/eVF209Tqya9hk7v8NSHLejmf2', NULL, NULL, NULL, 'EPICIER', 'uploads/documents/doc-1774122338623.png', 1, NULL, '0555778899', 1, NULL, NULL, '2026-01-02 10:10:00'),
(5, 'Gharbi', 'Karim', 'karim@hanut.com', '$2b$10$oxzsRPBl4D3Nc76dDniLHuqjQqC/eVF209Tqya9hk7v8NSHLejmf2', NULL, NULL, NULL, 'EPICIER', 'uploads/documents/doc-1774122338623.png', 1, NULL, '0555001122', 1, NULL, NULL, '2026-01-02 10:15:00'),
(6, 'Zied', 'Mondher', 'mondher@hanut.com', '$2b$10$oxzsRPBl4D3Nc76dDniLHuqjQqC/eVF209Tqya9hk7v8NSHLejmf2', NULL, NULL, NULL, 'EPICIER', 'uploads/documents/doc-1774122338623.png', 1, NULL, '0555334455', 1, NULL, NULL, '2026-01-02 10:20:00'),
(7, 'Alami', 'Youssef', 'client@demo.ma', '$2b$10$0AAvlCtHz3aLpFCuPtlNCeI.wRDNOPuFPOOW7OsHoh8XpLNzxryzW', NULL, NULL, NULL, 'CLIENT', NULL, 1, NULL, '0661122334', 1, NULL, NULL, '2026-01-10 12:00:00'),
(8, 'Idrissi', 'Fatima', 'fatima@demo.ma', '$2b$10$0AAvlCtHz3aLpFCuPtlNCeI.wRDNOPuFPOOW7OsHoh8XpLNzxryzW', NULL, NULL, NULL, 'CLIENT', NULL, 1, NULL, '0665566778', 1, NULL, NULL, '2026-01-11 12:00:00'),
(24, 'Hamani', 'Ismail', 'ismail@gmail.com', '$2b$10$ra8ItSUxeN1JRKslaELn1e8Y4Mzrtfb9aJYyVaSrUchipZp3..jo.', NULL, NULL, NULL, 'CLIENT', NULL, 1, NULL, '0612345678', 1, NULL, NULL, '2026-03-30 08:41:32');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `avis`
--
ALTER TABLE `avis`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `epicier_id` (`epicier_id`);

--
-- Index pour la table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `commandes`
--
ALTER TABLE `commandes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `epicier_id` (`epicier_id`);

--
-- Index pour la table `detailscommande`
--
ALTER TABLE `detailscommande`
  ADD PRIMARY KEY (`id`),
  ADD KEY `commande_id` (`commande_id`),
  ADD KEY `produit_id` (`produit_id`);

--
-- Index pour la table `disponibilites`
--
ALTER TABLE `disponibilites`
  ADD PRIMARY KEY (`id`),
  ADD KEY `epicier_id` (`epicier_id`);

--
-- Index pour la table `epiciers`
--
ALTER TABLE `epiciers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `utilisateur_id` (`utilisateur_id`);

--
-- Index pour la table `epicier_produits`
--
ALTER TABLE `epicier_produits`
  ADD PRIMARY KEY (`epicier_id`,`produit_id`),
  ADD KEY `produit_id` (`produit_id`);

--
-- Index pour la table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `utilisateur_id` (`utilisateur_id`);

--
-- Index pour la table `produits`
--
ALTER TABLE `produits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `categorie_id` (`categorie_id`);

--
-- Index pour la table `reclamations`
--
ALTER TABLE `reclamations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `commande_id` (`commande_id`),
  ADD KEY `epicier_id` (`epicier_id`),
  ADD KEY `avis_id` (`avis_id`);

--
-- Index pour la table `utilisateurs`
--
ALTER TABLE `utilisateurs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `avis`
--
ALTER TABLE `avis`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT pour la table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT pour la table `commandes`
--
ALTER TABLE `commandes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT pour la table `detailscommande`
--
ALTER TABLE `detailscommande`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT pour la table `disponibilites`
--
ALTER TABLE `disponibilites`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=57;

--
-- AUTO_INCREMENT pour la table `epiciers`
--
ALTER TABLE `epiciers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT pour la table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT pour la table `produits`
--
ALTER TABLE `produits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT pour la table `reclamations`
--
ALTER TABLE `reclamations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT pour la table `utilisateurs`
--
ALTER TABLE `utilisateurs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `avis`
--
ALTER TABLE `avis`
  ADD CONSTRAINT `avis_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `utilisateurs` (`id`),
  ADD CONSTRAINT `avis_ibfk_2` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`);

--
-- Contraintes pour la table `commandes`
--
ALTER TABLE `commandes`
  ADD CONSTRAINT `commandes_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `utilisateurs` (`id`),
  ADD CONSTRAINT `commandes_ibfk_2` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`);

--
-- Contraintes pour la table `detailscommande`
--
ALTER TABLE `detailscommande`
  ADD CONSTRAINT `detailscommande_ibfk_1` FOREIGN KEY (`commande_id`) REFERENCES `commandes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `detailscommande_ibfk_2` FOREIGN KEY (`produit_id`) REFERENCES `produits` (`id`);

--
-- Contraintes pour la table `disponibilites`
--
ALTER TABLE `disponibilites`
  ADD CONSTRAINT `disponibilites_ibfk_1` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `epiciers`
--
ALTER TABLE `epiciers`
  ADD CONSTRAINT `epiciers_ibfk_user` FOREIGN KEY (`utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `epicier_produits`
--
ALTER TABLE `epicier_produits`
  ADD CONSTRAINT `epicier_produits_ibfk_1` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `epicier_produits_ibfk_2` FOREIGN KEY (`produit_id`) REFERENCES `produits` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`utilisateur_id`) REFERENCES `utilisateurs` (`id`);

--
-- Contraintes pour la table `produits`
--
ALTER TABLE `produits`
  ADD CONSTRAINT `produits_ibfk_1` FOREIGN KEY (`categorie_id`) REFERENCES `categories` (`id`);

--
-- Contraintes pour la table `reclamations`
--
ALTER TABLE `reclamations`
  ADD CONSTRAINT `reclamations_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `utilisateurs` (`id`),
  ADD CONSTRAINT `reclamations_ibfk_2` FOREIGN KEY (`commande_id`) REFERENCES `commandes` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `reclamations_ibfk_3` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `reclamations_ibfk_4` FOREIGN KEY (`avis_id`) REFERENCES `avis` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
