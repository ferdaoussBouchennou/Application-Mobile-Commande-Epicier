-- Migration: notes commande + rupture par ligne + acceptation client
-- À exécuter sur epicier_ecommerce

ALTER TABLE commandes ADD COLUMN notes TEXT DEFAULT NULL;
ALTER TABLE detailscommande ADD COLUMN rupture TINYINT(1) DEFAULT 0;
ALTER TABLE commandes ADD COLUMN client_accepte_modification TINYINT(1) DEFAULT 0;
