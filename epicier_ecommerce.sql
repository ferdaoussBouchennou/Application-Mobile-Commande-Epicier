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

-- ══════════════════════════════════════════════════════════════
-- TABLE : utilisateurs  (clients + admins via role)
-- ══════════════════════════════════════════════════════════════
CREATE TABLE utilisateurs (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    nom           VARCHAR(100) NOT NULL,
    prenom        VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    mdp           VARCHAR(255) NOT NULL,
    id_google     VARCHAR(100),
    telephone     VARCHAR(20),
    adresse       VARCHAR(255) NOT NULL,
    role          ENUM('CLIENT', 'ADMIN', 'EPICIER') NOT NULL DEFAULT 'CLIENT',
    doc_verf      VARCHAR(20),
    is_active     BOOLEAN DEFAULT TRUE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ══════════════════════════════════════════════════════════════
-- TABLE : categories
-- ══════════════════════════════════════════════════════════════
CREATE TABLE categories (
    id  INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL
);

-- ══════════════════════════════════════════════════════════════
-- TABLE : epiciers  ← AJOUTÉE (manquait dans le fichier original)
-- ══════════════════════════════════════════════════════════════
CREATE TABLE epiciers (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT NOT NULL UNIQUE,
    nom_boutique   VARCHAR(200) NOT NULL,
    adresse        VARCHAR(255) NOT NULL,
    telephone      VARCHAR(20),
    description    TEXT,
    is_active      BOOLEAN DEFAULT TRUE,
    date_creation  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

-- ══════════════════════════════════════════════════════════════
-- TABLE : produits
-- ══════════════════════════════════════════════════════════════
CREATE TABLE produits (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    nom              VARCHAR(200) NOT NULL,
    prix             DECIMAL(10,2) NOT NULL,
    description      TEXT,
    epicier_id       INT NOT NULL,
    categorie_id     INT NOT NULL,
    image_principale VARCHAR(500),
    date_ajout       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modif       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (epicier_id)   REFERENCES epiciers(id),
    FOREIGN KEY (categorie_id) REFERENCES categories(id)
);

-- ══════════════════════════════════════════════════════════════
-- TABLE : disponibilites
-- ══════════════════════════════════════════════════════════════
CREATE TABLE disponibilites (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    epicier_id  INT NOT NULL,
    jour        ENUM('lundi','mardi','mercredi','jeudi','vendredi','samedi','dimanche') NOT NULL,
    heure_debut TIME NOT NULL,
    heure_fin   TIME NOT NULL,
    FOREIGN KEY (epicier_id) REFERENCES epiciers(id)
);

-- ══════════════════════════════════════════════════════════════
-- TABLE : paniers
-- ══════════════════════════════════════════════════════════════
CREATE TABLE paniers (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    client_id     INT NOT NULL UNIQUE,
    date_creation DATE NOT NULL,
    FOREIGN KEY (client_id) REFERENCES utilisateurs(id)
);

-- ══════════════════════════════════════════════════════════════
-- TABLE : panier_produits
-- CORRECTION : REFERENCES articles(id) → REFERENCES produits(id)
-- ══════════════════════════════════════════════════════════════
CREATE TABLE panier_produits (
    panier_id  INT NOT NULL,
    produit_id INT NOT NULL,
    quantite   INT NOT NULL DEFAULT 1,
    PRIMARY KEY (panier_id, produit_id),
    FOREIGN KEY (panier_id)  REFERENCES paniers(id),
    FOREIGN KEY (produit_id) REFERENCES produits(id)
);

-- ══════════════════════════════════════════════════════════════
-- TABLE : commandes
-- ══════════════════════════════════════════════════════════════
CREATE TABLE commandes (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    client_id         INT NOT NULL,
    epicier_id        INT NOT NULL,
    date_commande     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_recuperation DATETIME,
    statut            ENUM('reçue','prête','livrée') NOT NULL DEFAULT 'reçue',
    montant_total     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (client_id)  REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    FOREIGN KEY (epicier_id) REFERENCES epiciers(id)     ON DELETE RESTRICT
);

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
