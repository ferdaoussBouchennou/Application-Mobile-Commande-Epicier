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

-- ══════════════════════════════════════════════════════════════
-- TABLE : detailsCommande
-- ══════════════════════════════════════════════════════════════
CREATE TABLE detailsCommande (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    commande_id   INT NOT NULL,
    produit_id    INT NOT NULL,
    quantite      INT NOT NULL DEFAULT 1,
    prix_unitaire DECIMAL(10,2) NOT NULL,
    total_ligne   DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (commande_id) REFERENCES commandes(id),
    FOREIGN KEY (produit_id)  REFERENCES produits(id) ON DELETE RESTRICT
);

-- ══════════════════════════════════════════════════════════════
-- TABLE : avis
-- ══════════════════════════════════════════════════════════════
CREATE TABLE avis (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    note        TINYINT NOT NULL CHECK (note BETWEEN 1 AND 5),
    commentaire TEXT,
    client_id   INT NOT NULL,
    epicier_id  INT NOT NULL,
    commande_id INT,
    date_avis   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id)   REFERENCES utilisateurs(id),
    FOREIGN KEY (epicier_id)  REFERENCES epiciers(id),
    FOREIGN KEY (commande_id) REFERENCES commandes(id) ON DELETE SET NULL
);

-- ══════════════════════════════════════════════════════════════
-- TABLE : reclamations
-- ══════════════════════════════════════════════════════════════
CREATE TABLE reclamations (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    description   TEXT NOT NULL,
    statut        ENUM('nonResolue','resolue') NOT NULL DEFAULT 'nonResolue',
    client_id     INT NOT NULL,
    commande_id   INT,
    date_creation DATE NOT NULL,
    FOREIGN KEY (client_id)   REFERENCES utilisateurs(id),
    FOREIGN KEY (commande_id) REFERENCES commandes(id) ON DELETE SET NULL
);

-- ══════════════════════════════════════════════════════════════
-- TABLE : notifications
-- ══════════════════════════════════════════════════════════════
CREATE TABLE notifications (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    message    VARCHAR(500) NOT NULL,
    date_envoi DATE NOT NULL,
    client_id  INT NOT NULL,
    lue        BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (client_id) REFERENCES utilisateurs(id)
);