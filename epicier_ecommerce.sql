-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1
-- Généré le : mer. 11 mars 2026 à 16:50
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
(9, 'Boulangerie');

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
(77, 11, 'dimanche', '09:00:00', '14:00:00');

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

INSERT INTO `epiciers` (`id`, `utilisateur_id`, `nom_boutique`, `adresse`, `telephone`, `description`, `is_active`, `date_creation`, `image_url`, `rating`, `statut_inscription`) VALUES
(1, 3, 'Epicerie de sara', 'Adresse à configurer', '677777777', 'Votre Hanut de confiance : lait frais, pain chaud, sucre et produits de base.', 1, '2026-03-08 23:51:27', 'uploads/Moul-hanoute-epiciers.jpg', 4.0, 'ACCEPTE'),
(2, 5, 'Epicerie de ali', 'Adresse à configurer', '0655555555', NULL, 1, '2026-03-09 09:55:52', 'uploads/Moul-hanoute-epiciers.jpg', 5.0, 'ACCEPTE'),
(3, 6, 'Épicerie Fleurie', '12 Rue de la Liberté, Casablanca', '0522345678', 'Produits frais et locaux, arrivages quotidiens.', 1, '2026-03-09 14:23:43', 'uploads/Moul-hanoute-epiciers.jpg', 4.5, 'ACCEPTE'),
(4, 7, 'Le Petit Marché', '45 Avenue FAR, Rabat', '0537112233', 'Spécialités régionales et épices fines.', 1, '2026-03-09 14:23:43', 'uploads/Moul-hanoute-epiciers.jpg', 0.0, 'ACCEPTE'),
(5, 8, 'Hanut Marrakech', '7 bis Rue Ibn Batouta, Marrakech', '0524112233', 'Tout pour la maison, livraison rapide dans le quartier.', 1, '2026-03-09 14:23:43', 'uploads/Moul-hanoute-epiciers.jpg', 0.0, 'ACCEPTE'),
(6, 9, 'Épicerie Ahmed', 'Rue de la Liberté, Tunis', '0555112233', 'Produits frais du terroir et épices fines.', 1, '2026-03-09 14:34:37', 'uploads/Moul-hanoute-epiciers.jpg', 0.0, 'ACCEPTE'),
(7, 10, 'Hanut Sami', 'Avenue Habib Bourguiba, Sfax', '0555445566', 'Votre Hanut de quartier ouvert tard le soir.', 1, '2026-03-09 14:34:38', 'uploads/Moul-hanoute-epiciers.jpg', 0.0, 'ACCEPTE'),
(8, 11, 'Chez Leila', 'Route de la Plage, Hammamet', '0555778899', 'Fruits de mer et alimentation générale.', 1, '2026-03-09 14:34:38', 'uploads/Moul-hanoute-epiciers.jpg', 0.0, 'ACCEPTE'),
(9, 12, 'Karim Market', 'Boulevard de l\'Environnement, Sousse', '0555001122', 'Le meilleur couscous et produits locaux.', 1, '2026-03-09 14:34:38', 'uploads/Moul-hanoute-epiciers.jpg', 3.0, 'ACCEPTE'),
(10, 13, 'Mondher Express', 'Cité des Jeunes, Bizerte', '0555334455', 'Rapide, efficace et toujours avec le sourire.', 1, '2026-03-09 14:34:38', 'uploads/Moul-hanoute-epiciers.jpg', 0.0, 'ACCEPTE'),
(11, 14, 'Epicerie de mohamed', 'Adresse à configurer', '0655555555', NULL, 1, '2026-03-09 19:54:35', 'uploads/Moul-hanoute-epiciers.jpg', 2.5, 'ACCEPTE');

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
  `date_modif` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `produits`
--

INSERT INTO `produits` (`id`, `nom`, `prix`, `description`, `epicier_id`, `categorie_id`, `image_principale`, `date_ajout`, `date_modif`) VALUES
(441, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 1, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(442, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 1, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(443, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 1, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(444, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 1, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(445, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 1, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(446, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 1, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(447, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 1, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(448, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 1, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(449, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 1, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(450, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 1, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(451, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 1, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(452, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 1, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(453, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 1, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(454, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 1, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(455, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 1, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(456, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 1, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(457, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 1, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(458, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 1, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(461, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 1, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(462, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 1, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(463, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 1, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(464, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 1, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(465, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 1, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(466, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 1, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(467, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 2, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(468, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 2, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(469, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 2, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(470, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 2, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:44', '2026-03-10 21:47:44'),
(471, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 2, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(472, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 2, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(473, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 2, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(474, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 2, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(475, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 2, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(476, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 2, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(477, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 2, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(478, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 2, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(479, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 2, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(480, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 2, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(481, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 2, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(482, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 2, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(483, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 2, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(484, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 2, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(485, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 2, 9, 'uploads/boulangerie/msemen.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(486, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 2, 9, 'uploads/boulangerie/baghrir.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(487, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 2, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(488, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 2, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(489, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 2, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(490, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 2, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(491, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 2, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(492, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 2, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(493, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 3, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(494, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 3, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(495, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 3, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(496, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 3, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(497, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 3, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(498, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 3, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(499, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 3, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(500, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 3, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(501, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 3, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(502, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 3, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(503, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 3, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(504, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 3, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(505, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 3, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(506, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 3, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(507, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 3, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(508, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 3, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(509, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 3, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(510, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 3, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(511, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 3, 9, 'uploads/boulangerie/msemen.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(512, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 3, 9, 'uploads/boulangerie/baghrir.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(513, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 3, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(514, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 3, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(515, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 3, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(516, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 3, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(517, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 3, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(518, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 3, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(519, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 4, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(520, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 4, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(521, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 4, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(522, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 4, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(523, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 4, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(524, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 4, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(525, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 4, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(526, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 4, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(527, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 4, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(528, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 4, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(529, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 4, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(530, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 4, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(531, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 4, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(532, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 4, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(533, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 4, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(534, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 4, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(535, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 4, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(536, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 4, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(537, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 4, 9, 'uploads/boulangerie/msemen.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(538, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 4, 9, 'uploads/boulangerie/baghrir.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(539, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 4, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(540, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 4, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(541, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 4, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(542, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 4, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(543, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 4, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(544, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 4, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(545, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 5, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(546, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 5, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(547, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 5, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(548, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 5, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(549, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 5, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(550, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 5, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(551, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 5, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(552, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 5, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(553, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 5, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(554, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 5, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(555, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 5, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(556, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 5, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:45', '2026-03-10 21:47:45'),
(557, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 5, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(558, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 5, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(559, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 5, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(560, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 5, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(561, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 5, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(562, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 5, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(563, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 5, 9, 'uploads/boulangerie/msemen.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(564, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 5, 9, 'uploads/boulangerie/baghrir.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(565, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 5, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(566, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 5, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(567, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 5, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(568, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 5, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(569, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 5, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(570, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 5, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(571, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 6, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(572, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 6, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(573, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 6, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(574, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 6, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(575, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 6, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(576, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 6, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(577, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 6, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(578, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 6, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(579, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 6, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(580, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 6, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(581, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 6, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(582, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 6, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(583, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 6, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(584, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 6, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(585, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 6, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(586, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 6, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(587, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 6, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(588, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 6, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(589, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 6, 9, 'uploads/boulangerie/msemen.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(590, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 6, 9, 'uploads/boulangerie/baghrir.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(591, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 6, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(592, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 6, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(593, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 6, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(594, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 6, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(595, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 6, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(596, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 6, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(597, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 7, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(598, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 7, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(599, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 7, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(600, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 7, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(601, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 7, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(602, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 7, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(603, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 7, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(604, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 7, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(605, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 7, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(606, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 7, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(607, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 7, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(608, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 7, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(609, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 7, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(610, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 7, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(611, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 7, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(612, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 7, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(613, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 7, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(614, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 7, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(615, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 7, 9, 'uploads/boulangerie/msemen.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(616, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 7, 9, 'uploads/boulangerie/baghrir.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(617, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 7, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(618, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 7, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(619, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 7, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(620, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 7, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(621, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 7, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(622, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 7, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(623, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 8, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(624, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 8, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(625, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 8, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(626, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 8, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(627, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 8, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(628, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 8, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(629, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 8, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(630, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 8, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(631, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 8, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(632, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 8, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(633, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 8, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(634, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 8, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(635, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 8, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(636, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 8, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(637, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 8, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(638, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 8, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(639, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 8, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(640, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 8, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(641, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 8, 9, 'uploads/boulangerie/msemen.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(642, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 8, 9, 'uploads/boulangerie/baghrir.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(643, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 8, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(644, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 8, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(645, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 8, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(646, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 8, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(647, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 8, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(648, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 8, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(649, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 9, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(650, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 9, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(651, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 9, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(652, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 9, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(653, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 9, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(654, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 9, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(655, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 9, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(656, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 9, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(657, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 9, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:46', '2026-03-10 21:47:46'),
(658, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 9, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(659, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 9, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(660, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 9, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(661, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 9, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(662, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 9, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(663, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 9, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(664, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 9, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(665, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 9, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(666, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 9, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(667, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 9, 9, 'uploads/boulangerie/msemen.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(668, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 9, 9, 'uploads/boulangerie/baghrir.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(669, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 9, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(670, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 9, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(671, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 9, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(672, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 9, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(673, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 9, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(674, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 9, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(675, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 10, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(676, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 10, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(677, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 10, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(678, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 10, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(679, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 10, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(680, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 10, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(681, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 10, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(682, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 10, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(683, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 10, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(684, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 10, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(685, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 10, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(686, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 10, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(687, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 10, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(688, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 10, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(689, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 10, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(690, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 10, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(691, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 10, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(692, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 10, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(693, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 10, 9, 'uploads/boulangerie/msemen.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(694, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 10, 9, 'uploads/boulangerie/baghrir.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(695, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 10, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(696, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 10, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(697, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 10, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(698, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 10, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(699, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 10, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(700, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 10, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(701, 'Huile Lesieur 1L', 19.50, 'Huile de table raffinée Lesieur.', 11, 1, 'uploads/huiles/lesieur.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(702, 'Huile d\'Olive Oued Souss 1L', 85.00, 'Huile d\'olive extra vierge du Maroc.', 11, 1, 'uploads/huiles/oued_souss.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(703, 'Huile Argan Alimentaire 250ml', 120.00, 'Huile d\'argan pure et certifiée.', 11, 1, 'uploads/huiles/argan.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(704, 'Lait Centrale 1L', 7.00, 'Lait frais pasteurisé Centrale Danone.', 11, 5, 'uploads/laitiers/centrale.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(705, 'Yaourt Jaouda Fraise', 2.50, 'Yaourt crémeux aux morceaux de fruits.', 11, 5, 'uploads/laitiers/jaouda_fraise.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(706, 'Raibi Jamila', 2.50, 'Boisson lactée fermentée iconique.', 11, 5, 'uploads/laitiers/raibi.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(707, 'Fromage La Vache Qui Rit (16p)', 18.00, 'Portions de fromage fondu.', 11, 5, 'uploads/laitiers/vache_qui_rit.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(708, 'Farine Mouna 5kg', 35.00, 'Farine de blé tendre de luxe.', 11, 3, 'uploads/farines/mouna.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(709, 'Semoule Fine Al Ittihad 1kg', 13.00, 'Semoule de blé dur pour couscous.', 11, 3, 'uploads/farines/semoule.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(710, 'Couscous Dari 1kg', 15.00, 'Couscous marocain précuit.', 11, 3, 'uploads/farines/dari.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(711, 'Thon Mario à l\'huile', 15.00, 'Morceaux de thon de qualité.', 11, 4, 'uploads/conserves/mario.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(712, 'Tomate Aïcha 400g', 11.00, 'Double concentré de tomate Aïcha.', 11, 4, 'uploads/conserves/aicha.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(713, 'Confiture Aïcha Fraise', 16.00, 'Confiture de fraises extra.', 11, 4, 'uploads/conserves/confiture.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(714, 'Eau Sidi Ali 1.5L', 6.00, 'Eau minérale naturelle Sidi Ali.', 11, 7, 'uploads/boissons/sidi_ali.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(715, 'Eau Gazeuse Oulmès 1L', 8.50, 'Eau minérale gazeuse naturelle.', 11, 7, 'uploads/boissons/oulmes.jpg', '2026-03-10 21:47:47', '2026-03-10 21:47:47'),
(716, 'Poms', 6.00, 'Boisson rafraîchissante à la pomme.', 11, 7, 'uploads/boissons/poms.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48'),
(717, 'Thé Sultan (Grain Vert)', 14.00, 'Thé vert de qualité supérieure.', 11, 7, 'uploads/boissons/the_sultan.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48'),
(718, 'Pain Batbout (Unité)', 1.50, 'Petit pain traditionnel marocain.', 11, 9, 'uploads/boulangerie/batbout.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48'),
(719, 'Msemen nature', 2.00, 'Crêpe feuilletée marocaine.', 11, 9, 'uploads/boulangerie/msemen.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48'),
(720, 'Baghrir (Unité)', 1.50, 'Crêpe mille trous.', 11, 9, 'uploads/boulangerie/baghrir.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48'),
(721, 'Biscuits Henry\'s', 1.00, 'Biscuits secs traditionnels.', 11, 2, 'uploads/confiserie/henrys.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48'),
(722, 'Merendina Classic', 2.00, 'Génoise enrobée de chocolat.', 11, 2, 'uploads/confiserie/merendina.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48'),
(723, 'Savon El Kef', 4.50, 'Savon de marseille traditionnel.', 11, 6, 'uploads/hygiene/elkef.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48'),
(724, 'Détergent Magix 1kg', 22.00, 'Lessive poudre pour machine.', 11, 6, 'uploads/hygiene/magix.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48'),
(725, 'Ras el Hanout 50g', 15.00, 'Mélange d\'épices marocain.', 11, 8, 'uploads/epices/ras_hanout.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48'),
(726, 'Kamoun (Cumin) 50g', 10.00, 'Cumin moulu pur.', 11, 8, 'uploads/epices/cumin.jpg', '2026-03-10 21:47:48', '2026-03-10 21:47:48');

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
(2, 'bou', 'fer', 'fer@gmail.com', '$2b$10$SX7HzPJSA6gTvDolFM3W4ezT8lfv.G4RqG9qfBWATqozqw542axly', NULL, NULL, NULL, 'CLIENT', NULL, 1, '2026-03-08 23:38:57'),
(3, 'ran', 'sara', 'sa@gmail.com', '$2b$10$lcOHuH/Iod72sCrkYNsvCuN.CH8s8TtWfQbh8hsV9FQvGIl4.cWFm', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-08 23:51:26'),
(5, 'bo', 'ali', 'ali@gmail.com', '$2b$10$IxNmQ/xwZL6jEz6WPENrHOtuURWO8GpySH5SjIknEdWWVfeCQHWSu', NULL, NULL, NULL, 'EPICIER', 'Screenshot_20260309-', 1, '2026-03-09 09:55:51'),
(6, 'Benani', 'Ahmed', 'ahmed.boutique@example.com', '$2b$10$4I3EhhJzviZuTmgM9ULkIuEu/mAx0QwqgA5IvwXGexWvmjDAcyJNe', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:23:42'),
(7, 'Tazi', 'Driss', 'driss.market@example.com', '$2b$10$/fy/dLCHTU6mac8EPqisIOeX9.ndCJWLvLZPnzAkSPDvSSS0EYNnq', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:23:43'),
(8, 'Mansouri', 'Sanaa', 'sanaa.epicerie@example.com', '$2b$10$fdnAaoWwrStvfhOASa1Nku/xzNOXhrdoEntECaPzyNApAM8IdFa9m', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:23:43'),
(9, 'Ben Salah', 'Ahmed', 'ahmed@hanut.com', '$2b$10$sRi.VJF.h/aRHiUTh0jS7.Oj6GUESJVYOT6lxpmVGGm833/garYrO', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:34:37'),
(10, 'Mansour', 'Sami', 'sami@hanut.com', '$2b$10$loWEptD0Xd0bzfQTEGcMeeP2W.Imm1/tOrpsn2o7jz/uqFhbq/Awm', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:34:37'),
(11, 'Trabelsi', 'Leila', 'leila@hanut.com', '$2b$10$88dNhQUYG6Q.TJks7r5eR.W2iiZ7s/pVQxG8Oj6euRRyJFvlPDCwa', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:34:38'),
(12, 'Gharbi', 'Karim', 'karim@hanut.com', '$2b$10$uYx.vgvEfKO9IdUSmUFaxunjD7882TCNlQCTxqyXUAgwU61sTXjuO', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:34:38'),
(13, 'Zied', 'Mondher', 'mondher@hanut.com', '$2b$10$5xJDNZk3i33nyOol0qfa2Oll2B/O95vyvxQeeRkwBzf4RWaBw3dEq', NULL, NULL, NULL, 'EPICIER', NULL, 1, '2026-03-09 14:34:38'),
(14, 'alaoui', 'mohamed', 'mohamed@gmail.com', '$2b$10$ArEJo8NTVH3VdKbQi.wqF.aymvErOHy3vpq7wgu2qQGGNJkYkYfU6', NULL, NULL, NULL, 'EPICIER', 'IMG-20260308-WA0037.', 1, '2026-03-09 19:54:34');

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
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `avis`
--
ALTER TABLE `avis`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT pour la table `commandes`
--
ALTER TABLE `commandes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `detailscommande`
--
ALTER TABLE `detailscommande`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `disponibilites`
--
ALTER TABLE `disponibilites`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=78;

--
-- AUTO_INCREMENT pour la table `epiciers`
--
ALTER TABLE `epiciers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT pour la table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `produits`
--
ALTER TABLE `produits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=727;

--
-- AUTO_INCREMENT pour la table `reclamations`
--
ALTER TABLE `reclamations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `utilisateurs`
--
ALTER TABLE `utilisateurs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

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
