-- Migration: en attente acceptation client (produit remis en stock) + notifications épicier
-- À exécuter sur epicier_ecommerce après epicier_notes_rupture_migration.sql

ALTER TABLE detailscommande ADD COLUMN en_attente_acceptation_client TINYINT(1) DEFAULT 0;

CREATE TABLE IF NOT EXISTS notifications_epicier (
  id INT AUTO_INCREMENT PRIMARY KEY,
  epicier_id INT NOT NULL,
  message VARCHAR(500) NOT NULL,
  lue TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
