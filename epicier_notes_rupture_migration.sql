-- Migration: notes commande + rupture par ligne
-- À exécuter sur epicier_ecommerce

ALTER TABLE commandes ADD COLUMN notes TEXT DEFAULT NULL;
ALTER TABLE detailscommande ADD COLUMN rupture TINYINT(1) DEFAULT 0;
