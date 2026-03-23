-- Migration complète : commandes épicier, rupture stock, acceptation client
-- À exécuter sur la base epicier_ecommerce
-- (Consolidation de epicier_orders, epicier_notes_rupture, epicier_pending_acceptance)
--
-- Si des colonnes/tables existent déjà, ignorer les erreurs ou exécuter les lignes une par une.

-- 1. Commandes : message_refus, statut étendu, lu_epicier
ALTER TABLE commandes ADD COLUMN message_refus TEXT DEFAULT NULL;
ALTER TABLE commandes MODIFY COLUMN statut ENUM('reçue','prête','refusee','livrée') NOT NULL DEFAULT 'reçue';
ALTER TABLE commandes ADD COLUMN lu_epicier TINYINT(1) DEFAULT 0;

-- 2. Notes commande + rupture par ligne + acceptation client
ALTER TABLE commandes ADD COLUMN notes TEXT DEFAULT NULL;
ALTER TABLE commandes ADD COLUMN client_accepte_modification TINYINT(1) DEFAULT 0;
ALTER TABLE detailscommande ADD COLUMN rupture TINYINT(1) DEFAULT 0;

-- 3. Produit remis en stock : en attente acceptation client
ALTER TABLE detailscommande ADD COLUMN en_attente_acceptation_client TINYINT(1) DEFAULT 0;

-- 4. Notifications épicier (nouvelles commandes, avis, réclamations, accept/refus produit)
CREATE TABLE IF NOT EXISTS notifications_epicier (
  id INT AUTO_INCREMENT PRIMARY KEY,
  epicier_id INT NOT NULL,
  message VARCHAR(500) NOT NULL,
  lue TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_epicier_lue (epicier_id, lue)
);
