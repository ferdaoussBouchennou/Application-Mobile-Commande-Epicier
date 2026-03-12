-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1
-- Généré le : jeu. 12 mars 2026 à 16:46
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
  `note` tinyint(4) NOT NULL CHECK (`note` between 1 and 5),
  `commentaire` text DEFAULT NULL,
  `client_id` int(11) NOT NULL,
  `epicier_id` int(11) NOT NULL,
  `commande_id` int(11) DEFAULT NULL,
  `date_avis` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `avis`
--

INSERT INTO `avis` (`id`, `note`, `commentaire`, `client_id`, `epicier_id`, `commande_id`, `date_avis`) VALUES
(1, 5, 'Très bon accueil et produits frais.', 2, 1, 2, '2026-03-08 17:00:00'),
(2, 4, 'RAS, livraison correcte.', 2, 1, 3, '2026-03-07 12:00:00'),
(3, 4, 'Epicerie de confiance.', 2, 1, 5, '2026-03-05 15:00:00');

-- --------------------------------------------------------

--
-- Structure de la table `categories`
--

CREATE TABLE `categories` (
  `id` int(11) NOT NULL,
  `nom` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `categories`
--

INSERT INTO `categories` (`id`, `nom`) VALUES
(1, 'Huiles'),
(2, 'Confiserie'),
(3, 'Farines'),
(4, 'Conserves'),
(5, 'Laitiers'),
(6, 'Hygiène'),
(7, 'Boissons'),
(8, 'Épices'),
(9, 'Boulangerie'),
(11, 'Pâtes et riz'),
(13, 'Sanae Cat');

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
  `statut` enum('reçue','prête','livrée') NOT NULL DEFAULT 'reçue',
  `montant_total` decimal(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `commandes`
--

INSERT INTO `commandes` (`id`, `client_id`, `epicier_id`, `date_commande`, `date_recuperation`, `statut`, `montant_total`) VALUES
(1, 2, 1, '2026-03-09 10:00:00', NULL, 'reçue', 45.50),
(2, 2, 1, '2026-03-08 14:30:00', '2026-03-08 16:00:00', 'livrée', 186.50),
(3, 2, 1, '2026-03-07 09:15:00', '2026-03-07 11:00:00', 'livrée', 87.00),
(4, 2, 1, '2026-03-06 18:00:00', NULL, 'prête', 98.50),
(5, 2, 1, '2026-03-05 12:00:00', '2026-03-05 14:00:00', 'livrée', 32.00);

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
  `total_ligne` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `detailscommande`
--

INSERT INTO `detailscommande` (`id`, `commande_id`, `produit_id`, `quantite`, `prix_unitaire`, `total_ligne`) VALUES
(1, 1, 444, 2, 7.00, 14.00),
(2, 1, 445, 3, 2.50, 7.50),
(3, 1, 458, 4, 1.50, 6.00),
(4, 1, 461, 18, 1.00, 18.00),
(5, 2, 441, 1, 19.50, 19.50),
(6, 2, 448, 1, 35.00, 35.00),
(7, 2, 443, 1, 120.00, 120.00),
(8, 2, 454, 2, 6.00, 12.00),
(9, 3, 449, 2, 13.00, 26.00),
(10, 3, 450, 1, 15.00, 15.00),
(11, 3, 452, 2, 11.00, 22.00),
(12, 3, 454, 4, 6.00, 24.00),
(13, 4, 447, 2, 18.00, 36.00),
(14, 4, 446, 4, 2.50, 10.00),
(15, 4, 455, 2, 8.50, 17.00),
(16, 4, 463, 3, 4.50, 13.50),
(17, 4, 464, 1, 22.00, 22.00),
(18, 5, 444, 2, 7.00, 14.00),
(19, 5, 456, 3, 6.00, 18.00);

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `disponibilites`
--

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
(35, 5, 'dimanche', '09:00:00', '14:00:00'),
(36, 6, 'lundi', '08:00:00', '22:00:00'),
(37, 6, 'mardi', '08:00:00', '22:00:00'),
(38, 6, 'mercredi', '08:00:00', '22:00:00'),
(39, 6, 'jeudi', '08:00:00', '22:00:00'),
(40, 6, 'vendredi', '08:00:00', '22:00:00'),
(41, 6, 'samedi', '08:00:00', '22:00:00'),
(42, 6, 'dimanche', '09:00:00', '14:00:00'),
(43, 7, 'lundi', '08:00:00', '22:00:00'),
(44, 7, 'mardi', '08:00:00', '22:00:00'),
(45, 7, 'mercredi', '08:00:00', '22:00:00'),
(46, 7, 'jeudi', '08:00:00', '22:00:00'),
(47, 7, 'vendredi', '08:00:00', '22:00:00'),
(48, 7, 'samedi', '08:00:00', '22:00:00'),
(49, 7, 'dimanche', '09:00:00', '14:00:00'),
(50, 8, 'lundi', '08:00:00', '22:00:00'),
(51, 8, 'mardi', '08:00:00', '22:00:00'),
(52, 8, 'mercredi', '08:00:00', '22:00:00'),
(53, 8, 'jeudi', '08:00:00', '22:00:00'),
(54, 8, 'vendredi', '08:00:00', '22:00:00'),
(55, 8, 'samedi', '08:00:00', '22:00:00'),
(56, 8, 'dimanche', '09:00:00', '14:00:00'),
(57, 9, 'lundi', '08:00:00', '22:00:00'),
(58, 9, 'mardi', '08:00:00', '22:00:00'),
(59, 9, 'mercredi', '08:00:00', '22:00:00'),
(60, 9, 'jeudi', '08:00:00', '22:00:00'),
(61, 9, 'vendredi', '08:00:00', '22:00:00'),
(62, 9, 'samedi', '08:00:00', '22:00:00'),
(63, 9, 'dimanche', '09:00:00', '14:00:00'),
(64, 10, 'lundi', '08:00:00', '22:00:00'),
(65, 10, 'mardi', '08:00:00', '22:00:00'),
(66, 10, 'mercredi', '08:00:00', '22:00:00'),
(67, 10, 'jeudi', '08:00:00', '22:00:00'),
(68, 10, 'vendredi', '08:00:00', '22:00:00'),
(69, 10, 'samedi', '08:00:00', '22:00:00'),
(70, 10, 'dimanche', '09:00:00', '14:00:00'),
(71, 11, 'lundi', '08:00:00', '22:00:00'),
(72, 11, 'mardi', '08:00:00', '22:00:00'),
(73, 11, 'mercredi', '08:00:00', '22:00:00'),
(74, 11, 'jeudi', '08:00:00', '22:00:00'),
(75, 11, 'vendredi', '08:00:00', '22:00:00'),
(76, 11, 'samedi', '08:00:00', '22:00:00'),
(77, 11, 'dimanche', '09:00:00', '14:00:00'),
(104, 13, 'lundi', '09:15:00', '22:00:00'),
(105, 13, 'mercredi', '08:00:00', '20:50:00'),
(106, 13, 'jeudi', '08:00:00', '22:00:00'),
(107, 13, 'vendredi', '08:00:00', '22:00:00'),
(108, 13, 'samedi', '08:00:00', '22:00:00'),
(109, 13, 'dimanche', '09:00:00', '14:00:00');

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
  `is_active` tinyint(1) DEFAULT 1,
  `date_creation` datetime NOT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `rating` decimal(2,1) DEFAULT 0.0,
  `statut_inscription` enum('EN_ATTENTE','ACCEPTE','REFUSE') NOT NULL DEFAULT 'EN_ATTENTE'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `epiciers`
--

INSERT INTO `epiciers` (`id`, `utilisateur_id`, `nom_boutique`, `adresse`, `telephone`, `description`, `is_active`, `date_creation`, `image_url`, `rating`, `statut_inscription`, `latitude`, `longitude`) VALUES
(1, 3, 'Epicerie de sara', 'Adresse à configurer', '677777777', 'Votre Hanut de confiance : lait frais, pain chaud, sucre et produits de base.', 1, '2026-03-08 23:51:27', 'uploads/Moul-hanoute-epiciers.jpg', 4.0, 'COMPLETE', NULL, NULL),
(2, 5, 'Epicerie de ali', 'Adresse à configurer', '0655555555', NULL, 1, '2026-03-09 09:55:52', 'uploads/Moul-hanoute-epiciers.jpg', 5.0, 'COMPLETE', NULL, NULL),
(3, 6, 'Épicerie Fleurie', '12 Rue de la Liberté, Casablanca', '0522345678', 'Produits frais et locaux, arrivages quotidiens.', 1, '2026-03-09 14:23:43', 'uploads/Moul-hanoute-epiciers.jpg', 4.5, 'COMPLETE', NULL, NULL),
(4, 7, 'Le Petit Marché', '45 Avenue FAR, Rabat', '0537112233', 'Spécialités régionales et épices fines.', 1, '2026-03-09 14:23:43', 'uploads/Moul-hanoute-epiciers.jpg', 0.0, 'COMPLETE', NULL, NULL),
(5, 8, 'Hanut Marrakech', '7 bis Rue Ibn Batouta, Marrakech', '0524112233', 'Tout pour la maison, livraison rapide dans le quartier.', 1, '2026-03-09 14:23:43', 'uploads/Moul-hanoute-epiciers.jpg', 0.0, 'COMPLETE', NULL, NULL),
(6, 9, 'Épicerie Ahmed', 'Rue de la Liberté, Tunis', '0555112233', 'Produits frais du terroir et épices fines.', 1, '2026-03-09 14:34:37', 'uploads/Moul-hanoute-epiciers.jpg', 0.0, 'COMPLETE', NULL, NULL),
(7, 10, 'Hanut Sami', 'Avenue Habib Bourguiba, Sfax', '0555445566', 'Votre Hanut de quartier ouvert tard le soir.', 1, '2026-03-09 14:34:38', 'uploads/Moul-hanoute-epiciers.jpg', 0.0, 'COMPLETE', NULL, NULL),
(8, 11, 'Chez Leila', 'Route de la Plage, Hammamet', '0555778899', 'Fruits de mer et alimentation générale.', 1, '2026-03-09 14:34:38', 'uploads/Moul-hanoute-epiciers.jpg', 0.0, 'COMPLETE', NULL, NULL),
(9, 12, 'Karim Market', 'Boulevard de l\'Environnement, Sousse', '0555001122', 'Le meilleur couscous et produits locaux.', 1, '2026-03-09 14:34:38', 'uploads/Moul-hanoute-epiciers.jpg', 3.0, 'COMPLETE', NULL, NULL),
(10, 13, 'Mondher Express', 'Cité des Jeunes, Bizerte', '0555334455', 'Rapide, efficace et toujours avec le sourire.', 1, '2026-03-09 14:34:38', 'uploads/Moul-hanoute-epiciers.jpg', 0.0, 'COMPLETE', NULL, NULL),
(11, 14, 'Epicerie de mohamed', 'Adresse à configurer', '0655555555', NULL, 1, '2026-03-09 19:54:35', 'uploads/Moul-hanoute-epiciers.jpg', 2.5, 'COMPLETE', NULL, NULL),
(13, 16, 'Epicerie de Sanae', 'hay diza martil', '0767651199', 'Tafraouti Sanae', 1, '2026-03-12 15:36:40', 'uploads/stores/store_13_1773330098979.jpg', 0.0, 'COMPLETE', 35.6120253, -5.2732300);

-- --------------------------------------------------------

--
-- Structure de la table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `message` varchar(500) NOT NULL,
  `date_envoi` date NOT NULL,
  `client_id` int(11) NOT NULL,
  `lue` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `notifications`
--

INSERT INTO `notifications` (`id`, `message`, `date_envoi`, `client_id`, `lue`) VALUES
(1, 'Votre commande #2 a été livrée. Merci de votre confiance !', '2026-03-08', 2, 1),
(2, 'Votre commande #1 est en préparation.', '2026-03-09', 2, 0),
(3, 'Votre commande #4 est prête à être récupérée.', '2026-03-06', 2, 0);

-- --------------------------------------------------------

--
-- Structure de la table `produits`
--

CREATE TABLE `produits` (
  `id` int(11) NOT NULL,
  `nom` varchar(200) NOT NULL,
  `prix` decimal(10,2) NOT NULL,
  `description` text DEFAULT NULL,
  `epicier_id` int(11) NOT NULL,
  `categorie_id` int(11) NOT NULL,
  `image_principale` varchar(500) DEFAULT NULL,
  `date_ajout` timestamp NOT NULL DEFAULT current_timestamp(),
  `date_modif` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `rupture_stock` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `produits`
--

INSERT INTO `produits` (`id`, `nom`, `prix`, `description`, `epicier_id`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`, `is_active`, `rupture_stock`) VALUES
(441, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 1, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(442, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 1, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(443, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 1, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:44', '2026-03-12 15:25:18', 1, 0),
(444, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 1, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:44', '2026-03-12 05:15:28', 1, 0),
(445, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 1, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:44', '2026-03-12 05:15:28', 1, 0),
(446, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 1, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:44', '2026-03-12 05:15:28', 1, 0),
(447, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 1, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:44', '2026-03-12 05:15:28', 1, 0),
(448, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 1, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(449, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 1, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(450, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 1, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(451, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 1, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(452, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 1, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(453, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 1, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(454, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 1, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:44', '2026-03-12 03:42:56', 1, 0),
(455, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 1, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(456, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 1, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(457, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 1, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(458, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 1, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(461, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 1, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:44', '2026-03-12 03:31:06', 1, 0),
(462, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 1, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:44', '2026-03-12 02:13:25', 1, 0),
(463, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 1, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:44', '2026-03-12 01:49:45', 0, 0),
(464, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 1, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:44', '2026-03-12 05:13:01', 1, 0),
(465, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 1, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:44', '2026-03-12 05:15:58', 0, 0),
(466, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 1, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:44', '2026-03-12 14:53:38', 1, 0),
(467, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 2, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(468, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 2, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(469, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 2, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(470, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 2, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44', 1, 0),
(471, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 2, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(472, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 2, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(473, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 2, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(474, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 2, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(475, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 2, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(476, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 2, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(477, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 2, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(478, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 2, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(479, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 2, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(480, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 2, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(481, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 2, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(482, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 2, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(483, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 2, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(484, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 2, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(485, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 2, 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-10 21:47:45', '2026-03-12 01:20:23', 1, 0),
(486, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 2, 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-10 21:47:45', '2026-03-12 03:28:08', 1, 0),
(487, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 2, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:45', '2026-03-12 03:31:06', 1, 0),
(488, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 2, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(489, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 2, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(490, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 2, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:45', '2026-03-12 05:13:01', 1, 0),
(491, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 2, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(492, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 2, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:45', '2026-03-12 14:53:38', 1, 0),
(493, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 3, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(494, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 3, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(495, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 3, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(496, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 3, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(497, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 3, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(498, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 3, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(499, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 3, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(500, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 3, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(501, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 3, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(502, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 3, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(503, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 3, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(504, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 3, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(505, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 3, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(506, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 3, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(507, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 3, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(508, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 3, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(509, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 3, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(510, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 3, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(511, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 3, 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-10 21:47:45', '2026-03-12 01:20:23', 1, 0),
(512, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 3, 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-10 21:47:45', '2026-03-12 03:28:08', 1, 0),
(513, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 3, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:45', '2026-03-12 03:31:19', 1, 0),
(514, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 3, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(515, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 3, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(516, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 3, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:45', '2026-03-12 05:13:00', 1, 0),
(517, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 3, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(518, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 3, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:45', '2026-03-12 14:53:38', 1, 0),
(519, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 4, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(520, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 4, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(521, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 4, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(522, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 4, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(523, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 4, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(524, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 4, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(525, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 4, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(526, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 4, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(527, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 4, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(528, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 4, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(529, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 4, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(530, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 4, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(531, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 4, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(532, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 4, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(533, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 4, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(534, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 4, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(535, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 4, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(536, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 4, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(537, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 4, 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-10 21:47:45', '2026-03-12 01:20:23', 1, 0),
(538, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 4, 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-10 21:47:45', '2026-03-12 03:28:08', 1, 0),
(539, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 4, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:45', '2026-03-12 03:31:06', 1, 0),
(540, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 4, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(541, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 4, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(542, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 4, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:45', '2026-03-12 05:13:01', 1, 0),
(543, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 4, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(544, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 4, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:45', '2026-03-12 14:53:38', 1, 0),
(545, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 5, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(546, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 5, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(547, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 5, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(548, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 5, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(549, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 5, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(550, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 5, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(551, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 5, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(552, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 5, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(553, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 5, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(554, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 5, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(555, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 5, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(556, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 5, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45', 1, 0),
(557, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 5, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(558, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 5, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(559, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 5, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(560, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 5, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(561, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 5, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(562, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 5, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(563, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 5, 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-10 21:47:46', '2026-03-12 01:20:23', 1, 0),
(564, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 5, 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-10 21:47:46', '2026-03-12 03:28:08', 1, 0),
(565, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 5, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:46', '2026-03-12 03:31:06', 1, 0),
(566, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 5, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(567, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 5, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(568, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 5, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:46', '2026-03-12 05:13:01', 1, 0),
(569, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 5, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(570, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 5, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:46', '2026-03-12 14:53:38', 1, 0),
(571, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 6, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(572, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 6, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(573, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 6, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(574, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 6, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(575, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 6, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(576, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 6, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(577, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 6, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(578, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 6, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(579, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 6, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(580, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 6, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(581, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 6, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(582, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 6, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(583, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 6, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(584, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 6, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(585, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 6, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:46', '2026-03-12 04:49:24', 0, 0),
(586, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 6, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(587, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 6, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(588, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 6, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(589, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 6, 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-10 21:47:46', '2026-03-12 01:20:23', 1, 0),
(590, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 6, 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-10 21:47:46', '2026-03-12 03:28:08', 1, 0),
(591, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 6, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:46', '2026-03-12 03:31:06', 1, 0),
(592, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 6, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(593, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 6, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(594, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 6, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:46', '2026-03-12 05:13:01', 1, 0),
(595, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 6, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(596, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 6, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:46', '2026-03-12 14:53:38', 1, 0),
(597, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 7, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(598, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 7, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(599, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 7, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(600, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 7, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(601, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 7, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(602, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 7, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(603, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 7, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(604, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 7, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(605, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 7, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(606, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 7, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(607, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 7, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(608, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 7, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(609, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 7, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(610, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 7, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(611, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 7, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:46', '2026-03-12 03:46:55', 0, 0),
(612, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 7, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:46', '2026-03-12 04:49:36', 0, 0),
(613, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 7, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(614, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 7, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(615, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 7, 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-10 21:47:46', '2026-03-12 01:20:23', 1, 0),
(616, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 7, 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-10 21:47:46', '2026-03-12 03:28:08', 1, 0),
(617, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 7, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:46', '2026-03-12 03:31:06', 1, 0),
(618, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 7, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(619, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 7, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(620, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 7, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:46', '2026-03-12 05:13:01', 1, 0),
(621, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 7, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(622, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 7, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:46', '2026-03-12 14:53:38', 1, 0),
(623, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 8, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(624, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 8, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(625, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 8, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(626, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 8, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(627, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 8, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(628, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 8, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(629, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 8, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(630, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 8, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(631, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 8, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(632, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 8, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(633, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 8, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(634, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 8, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(635, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 8, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(636, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 8, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(637, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 8, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(638, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 8, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(639, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 8, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(640, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 8, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(641, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 8, 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-10 21:47:46', '2026-03-12 01:20:23', 1, 0),
(642, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 8, 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-10 21:47:46', '2026-03-12 03:28:08', 1, 0),
(643, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 8, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:46', '2026-03-12 03:31:06', 1, 0),
(644, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 8, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(645, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 8, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(646, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 8, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:46', '2026-03-12 05:13:01', 1, 0),
(647, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 8, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(648, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 8, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:46', '2026-03-12 14:53:38', 1, 0),
(649, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 9, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(650, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 9, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(651, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 9, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(652, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 9, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(653, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 9, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(654, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 9, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(655, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 9, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(656, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 9, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(657, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 9, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46', 1, 0),
(658, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 9, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(659, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 9, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(660, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 9, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(661, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 9, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(662, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 9, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(663, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 9, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(664, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 9, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(665, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 9, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(666, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 9, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(667, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 9, 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-10 21:47:47', '2026-03-12 01:20:23', 1, 0),
(668, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 9, 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-10 21:47:47', '2026-03-12 03:28:08', 1, 0),
(669, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 9, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:47', '2026-03-12 03:31:06', 1, 0),
(670, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 9, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(671, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 9, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(672, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 9, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:47', '2026-03-12 05:13:01', 1, 0),
(673, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 9, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(674, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 9, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:47', '2026-03-12 14:53:38', 1, 0),
(675, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 10, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(676, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 10, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(677, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 10, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(678, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 10, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(679, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 10, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(680, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 10, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(681, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 10, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(682, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 10, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(683, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 10, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(684, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 10, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(685, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 10, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(686, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 10, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(687, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 10, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(688, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 10, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(689, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 10, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(690, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 10, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(691, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 10, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(692, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 10, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(693, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 10, 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-10 21:47:47', '2026-03-12 01:20:23', 1, 0),
(694, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 10, 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-10 21:47:47', '2026-03-12 03:28:08', 1, 0),
(695, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 10, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:47', '2026-03-12 03:31:06', 1, 0),
(696, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 10, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(697, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 10, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(698, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 10, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:47', '2026-03-12 05:13:01', 1, 0),
(699, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 10, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(700, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 10, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:47', '2026-03-12 14:53:38', 1, 0),
(701, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 11, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(702, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 11, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(703, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 11, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(704, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 11, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(705, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 11, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(706, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 11, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(707, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 11, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(708, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 11, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(709, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 11, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(710, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 11, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(711, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 11, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(712, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 11, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(713, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 11, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(714, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 11, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(715, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 11, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47', 1, 0),
(716, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 11, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48', 1, 0),
(717, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 11, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48', 1, 0),
(718, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 11, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48', 1, 0),
(719, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 11, 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-10 21:47:48', '2026-03-12 01:20:23', 1, 0),
(720, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 11, 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-10 21:47:48', '2026-03-12 03:28:08', 1, 0),
(721, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 11, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:48', '2026-03-12 03:31:06', 1, 0),
(722, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 11, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48', 1, 0),
(723, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 11, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48', 1, 0),
(724, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 11, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:48', '2026-03-12 05:13:01', 1, 0),
(725, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 11, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48', 1, 0),
(726, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 11, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:48', '2026-03-12 14:53:38', 1, 0),
(727, 'Ain Saiss 15L - Eau minérale', 12.00, 'Eau minérale naturelle Ain Saiss 15L.', 1, 7, 'uploads/Boissons/Ain_Saiss_15L_-_Eau_minerale-1.webp', '2026-03-12 01:14:39', '2026-03-12 15:27:01', 1, 0),
(728, 'Penne 500g AL-ITKANE', 15.00, 'Pâtes penne 500g.', 1, 11, 'uploads/Pates_et_riz/Penne_500g_AL-ITKANE.webp', '2026-03-12 01:14:39', '2026-03-12 01:49:25', 1, 0),
(729, 'Arroz cigala long', 22.00, 'Riz long grain.', 1, 11, 'uploads/Pates_et_riz/Arroz_cigala_long.png', '2026-03-12 01:14:39', '2026-03-12 15:20:51', 1, 1),
(730, 'Pâtes courtes 500g Dalia', 8.00, 'Pâtes courtes 500g.', 1, 11, 'uploads/Pates_et_riz/Pates_courtes_500g-Dalia.png', '2026-03-12 01:14:39', '2026-03-12 01:49:25', 1, 0),
(731, 'Farfalle 500g Kenz', 9.00, 'Pâtes farfalle 500g.', 1, 11, 'uploads/Pates_et_riz/farfalle_500g_kenz.png', '2026-03-12 01:14:39', '2026-03-12 01:49:25', 1, 0),
(732, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 1, 9, 'uploads/boulangerie/Baghrir_Unite.jpg', '2026-03-12 01:18:03', '2026-03-12 03:28:08', 1, 0),
(733, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 1, 9, 'uploads/boulangerie/Msemen_nature.jpg', '2026-03-12 01:18:03', '2026-03-12 01:20:23', 1, 0),
(734, 'Eau Minérale Ain Soltane 5L', 14.00, NULL, 1, 7, 'uploads/Boissons/Eau_Minerale_Ain_Soltane_5L.jpg', '2026-03-12 01:53:39', '2026-03-12 01:53:39', 1, 0),
(735, 'Produit2', 22.01, NULL, 2, 13, 'uploads/Sanae_Cat/Produit.jpg', '2026-03-12 02:49:04', '2026-03-12 05:18:33', 1, 0),
(736, 'Produit1', 22.00, NULL, 2, 13, 'uploads/Sanae_Cat/Produit.png', '2026-03-12 02:49:09', '2026-03-12 05:18:21', 0, 0),
(737, 'L\'eau', 2.00, NULL, 6, 11, 'uploads/Pates_et_riz/temp_1773286916421_mhqze1x9.png', '2026-03-12 03:42:16', '2026-03-12 03:42:36', 0, 0),
(738, 'Produit2', 22.01, NULL, 6, 13, 'uploads/Sanae_Cat/Produit.jpg', '2026-03-12 03:54:03', '2026-03-12 05:18:33', 1, 0),
(739, 'Produit2', 22.01, NULL, 8, 13, 'uploads/Sanae_Cat/Produit.jpg', '2026-03-12 03:54:03', '2026-03-12 05:18:34', 1, 0),
(740, 'Produit2', 22.01, NULL, 11, 13, 'uploads/Sanae_Cat/Produit.jpg', '2026-03-12 03:54:03', '2026-03-12 05:18:34', 1, 0),
(741, 'Produit1', 22.00, NULL, 11, 13, 'uploads/Sanae_Cat/Produit.png', '2026-03-12 05:18:21', '2026-03-12 05:18:28', 0, 0);

-- --------------------------------------------------------

--
-- Structure de la table `reclamations`
--

CREATE TABLE `reclamations` (
  `id` int(11) NOT NULL,
  `description` text NOT NULL,
  `statut` enum('nonResolue','resolue') NOT NULL DEFAULT 'nonResolue',
  `client_id` int(11) NOT NULL,
  `commande_id` int(11) DEFAULT NULL,
  `date_creation` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `reclamations`
--

INSERT INTO `reclamations` (`id`, `description`, `statut`, `client_id`, `commande_id`, `date_creation`) VALUES
(1, 'Un produit de la commande #3 était légèrement abîmé. Demande d\'échange.', 'resolue', 2, 3, '2026-03-07'),
(2, 'Retard de livraison sur la commande #2.', 'nonResolue', 2, 2, '2026-03-08');

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
  `date_creation` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `utilisateurs`
--

INSERT INTO `utilisateurs` (`id`, `nom`, `prenom`, `email`, `mdp`, `id_google`, `id_facebook`, `id_instagram`, `role`, `doc_verf`, `is_active`, `date_creation`) VALUES
(1, 'Admin', 'Application', 'admin@hanut.com', '$2b$10$wll4z6Kmk3d7MASYdI6uX.All3XmUjEea0EWgNZK.IAwiNxeZq/m.', NULL, NULL, NULL, 'ADMIN', NULL, 1, '2026-03-12 01:34:10'),
(2, 'bou', 'fer', 'fer@gmail.com', '$2b$10$6NeGDyqCVTVpRvJIIwtKHeQdUF3BhTJ5sKi7qAiyZY1vfxWxooB0S', NULL, NULL, NULL, 'CLIENT', NULL, 1, '2026-03-08 23:38:57'),
(3, 'ran', 'sara', 'sa@gmail.com', '$2b$10$6NeGDyqCVTVpRvJIIwtKHeQdUF3BhTJ5sKi7qAiyZY1vfxWxooB0S', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-08 23:51:26'),
(5, 'bo', 'ali', 'ali@gmail.com', '$2b$10$6NeGDyqCVTVpRvJIIwtKHeQdUF3BhTJ5sKi7qAiyZY1vfxWxooB0S', NULL, NULL, NULL, 'EPICIER', 'Screenshot_20260309-', 1, '2026-03-09 09:55:51'),
(6, 'Benani', 'Ahmed', 'ahmed.boutique@example.com', '$2b$10$6NeGDyqCVTVpRvJIIwtKHeQdUF3BhTJ5sKi7qAiyZY1vfxWxooB0S', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:23:42'),
(7, 'Tazi', 'Driss', 'driss.market@example.com', '$2b$10$6NeGDyqCVTVpRvJIIwtKHeQdUF3BhTJ5sKi7qAiyZY1vfxWxooB0S', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:23:43'),
(8, 'Mansouri', 'Sanaa', 'sanaa.epicerie@example.com', '$2b$10$6NeGDyqCVTVpRvJIIwtKHeQdUF3BhTJ5sKi7qAiyZY1vfxWxooB0S', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:23:43'),
(9, 'Ben Salah', 'Ahmed', 'ahmed@hanut.com', '$2b$10$6NeGDyqCVTVpRvJIIwtKHeQdUF3BhTJ5sKi7qAiyZY1vfxWxooB0S', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:34:37'),
(10, 'Mansour', 'Sami', 'sami@hanut.com', '$2b$10$6NeGDyqCVTVpRvJIIwtKHeQdUF3BhTJ5sKi7qAiyZY1vfxWxooB0S', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:34:37'),
(11, 'Trabelsi', 'Leila', 'leila@hanut.com', '$2b$10$6NeGDyqCVTVpRvJIIwtKHeQdUF3BhTJ5sKi7qAiyZY1vfxWxooB0S', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:34:38'),
(12, 'Gharbi', 'Karim', 'karim@hanut.com', '$2b$10$6NeGDyqCVTVpRvJIIwtKHeQdUF3BhTJ5sKi7qAiyZY1vfxWxooB0S', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:34:38'),
(13, 'Zied', 'Mondher', 'mondher@hanut.com', '$2b$10$6NeGDyqCVTVpRvJIIwtKHeQdUF3BhTJ5sKi7qAiyZY1vfxWxooB0S', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:34:38'),
(14, 'alaoui', 'mohamed', 'mohamed@gmail.com', '$2b$10$6NeGDyqCVTVpRvJIIwtKHeQdUF3BhTJ5sKi7qAiyZY1vfxWxooB0S', NULL, NULL, NULL, 'EPICIER', 'IMG-20260308-WA0037.', 1, '2026-03-09 19:54:34'),
(16, 'Tafraouti', 'Sanae', 'tafraouti.sanae@etu.uae.ac.ma', '$2b$10$FJHuYOUlh21k8bR7tD/H1OqOHymLti6uROs47PVt/6VapL6l/6Gve', NULL, NULL, NULL, 'EPICIER', 'MenJdid_____Pitches_', 1, '2026-03-12 15:36:40');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `avis`
--
ALTER TABLE `avis`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `epicier_id` (`epicier_id`),
  ADD KEY `commande_id` (`commande_id`);

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
-- Index pour la table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`);

--
-- Index pour la table `produits`
--
ALTER TABLE `produits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `epicier_id` (`epicier_id`),
  ADD KEY `categorie_id` (`categorie_id`);

--
-- Index pour la table `reclamations`
--
ALTER TABLE `reclamations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `client_id` (`client_id`),
  ADD KEY `commande_id` (`commande_id`);

--
-- Index pour la table `utilisateurs`
--
ALTER TABLE `utilisateurs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `email_2` (`email`),
  ADD UNIQUE KEY `email_3` (`email`),
  ADD UNIQUE KEY `email_4` (`email`),
  ADD UNIQUE KEY `email_5` (`email`),
  ADD UNIQUE KEY `email_6` (`email`),
  ADD UNIQUE KEY `email_7` (`email`),
  ADD UNIQUE KEY `email_8` (`email`),
  ADD UNIQUE KEY `email_9` (`email`),
  ADD UNIQUE KEY `email_10` (`email`),
  ADD UNIQUE KEY `email_11` (`email`),
  ADD UNIQUE KEY `email_12` (`email`),
  ADD UNIQUE KEY `email_13` (`email`),
  ADD UNIQUE KEY `email_14` (`email`),
  ADD UNIQUE KEY `email_15` (`email`),
  ADD UNIQUE KEY `email_16` (`email`),
  ADD UNIQUE KEY `email_17` (`email`),
  ADD UNIQUE KEY `email_18` (`email`),
  ADD UNIQUE KEY `email_19` (`email`),
  ADD UNIQUE KEY `email_20` (`email`),
  ADD UNIQUE KEY `email_21` (`email`),
  ADD UNIQUE KEY `email_22` (`email`),
  ADD UNIQUE KEY `email_23` (`email`),
  ADD UNIQUE KEY `email_24` (`email`),
  ADD UNIQUE KEY `email_25` (`email`),
  ADD UNIQUE KEY `email_26` (`email`),
  ADD UNIQUE KEY `email_27` (`email`),
  ADD UNIQUE KEY `email_28` (`email`),
  ADD UNIQUE KEY `email_29` (`email`),
  ADD UNIQUE KEY `email_30` (`email`),
  ADD UNIQUE KEY `email_31` (`email`),
  ADD UNIQUE KEY `email_32` (`email`),
  ADD UNIQUE KEY `email_33` (`email`),
  ADD UNIQUE KEY `email_34` (`email`),
  ADD UNIQUE KEY `email_35` (`email`),
  ADD UNIQUE KEY `email_36` (`email`),
  ADD UNIQUE KEY `email_37` (`email`),
  ADD UNIQUE KEY `email_38` (`email`),
  ADD UNIQUE KEY `email_39` (`email`),
  ADD UNIQUE KEY `email_40` (`email`),
  ADD UNIQUE KEY `email_41` (`email`),
  ADD UNIQUE KEY `email_42` (`email`),
  ADD UNIQUE KEY `email_43` (`email`),
  ADD UNIQUE KEY `email_44` (`email`),
  ADD UNIQUE KEY `email_45` (`email`),
  ADD UNIQUE KEY `email_46` (`email`),
  ADD UNIQUE KEY `email_47` (`email`),
  ADD UNIQUE KEY `email_48` (`email`),
  ADD UNIQUE KEY `email_49` (`email`),
  ADD UNIQUE KEY `email_50` (`email`),
  ADD UNIQUE KEY `email_51` (`email`),
  ADD UNIQUE KEY `email_52` (`email`),
  ADD UNIQUE KEY `email_53` (`email`),
  ADD UNIQUE KEY `email_54` (`email`),
  ADD UNIQUE KEY `email_55` (`email`),
  ADD UNIQUE KEY `email_56` (`email`),
  ADD UNIQUE KEY `email_57` (`email`),
  ADD UNIQUE KEY `email_58` (`email`),
  ADD UNIQUE KEY `email_59` (`email`),
  ADD UNIQUE KEY `email_60` (`email`),
  ADD UNIQUE KEY `email_61` (`email`),
  ADD UNIQUE KEY `email_62` (`email`),
  ADD UNIQUE KEY `email_63` (`email`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `avis`
--
ALTER TABLE `avis`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pour la table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT pour la table `commandes`
--
ALTER TABLE `commandes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT pour la table `detailscommande`
--
ALTER TABLE `detailscommande`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT pour la table `disponibilites`
--
ALTER TABLE `disponibilites`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=110;

--
-- AUTO_INCREMENT pour la table `epiciers`
--
ALTER TABLE `epiciers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT pour la table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pour la table `produits`
--
ALTER TABLE `produits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=753;

--
-- AUTO_INCREMENT pour la table `reclamations`
--
ALTER TABLE `reclamations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT pour la table `utilisateurs`
--
ALTER TABLE `utilisateurs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `avis`
--
ALTER TABLE `avis`
  ADD CONSTRAINT `avis_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `utilisateurs` (`id`),
  ADD CONSTRAINT `avis_ibfk_2` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`),
  ADD CONSTRAINT `avis_ibfk_3` FOREIGN KEY (`commande_id`) REFERENCES `commandes` (`id`) ON DELETE SET NULL;

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
  ADD CONSTRAINT `detailscommande_ibfk_1` FOREIGN KEY (`commande_id`) REFERENCES `commandes` (`id`),
  ADD CONSTRAINT `detailscommande_ibfk_2` FOREIGN KEY (`produit_id`) REFERENCES `produits` (`id`);

--
-- Contraintes pour la table `disponibilites`
--
ALTER TABLE `disponibilites`
  ADD CONSTRAINT `disponibilites_ibfk_1` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `epiciers`
--
ALTER TABLE `epiciers`
  ADD CONSTRAINT `epiciers_ibfk_1` FOREIGN KEY (`utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `utilisateurs` (`id`);

--
-- Contraintes pour la table `produits`
--
ALTER TABLE `produits`
  ADD CONSTRAINT `produits_ibfk_1` FOREIGN KEY (`epicier_id`) REFERENCES `epiciers` (`id`),
  ADD CONSTRAINT `produits_ibfk_2` FOREIGN KEY (`categorie_id`) REFERENCES `categories` (`id`);

--
-- Contraintes pour la table `reclamations`
--
ALTER TABLE `reclamations`
  ADD CONSTRAINT `reclamations_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `utilisateurs` (`id`),
  ADD CONSTRAINT `reclamations_ibfk_2` FOREIGN KEY (`commande_id`) REFERENCES `commandes` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
