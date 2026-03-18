-- Migration pour la gestion des commandes épicier (acceptation/refus, statuts étendus)
-- À exécuter sur la base epicier_ecommerce

-- 1. Ajouter la colonne message_refus pour les refus (ignorer si déjà présente)
ALTER TABLE commandes ADD COLUMN message_refus TEXT DEFAULT NULL;

-- 2. Modifier l'enum statut (reçue, prête, refusee, livrée)
ALTER TABLE commandes MODIFY COLUMN statut ENUM('reçue','prête','refusee','livrée') NOT NULL DEFAULT 'reçue';

-- 3. Ajouter lu_epicier pour le badge "nouvelles commandes" (0=non lu, 1=lu)
ALTER TABLE commandes ADD COLUMN lu_epicier TINYINT(1) DEFAULT 0;

-- Mettre à jour les commandes existantes: reçue reste reçue, prête reste prête, livrée reste livrée
-- Les données existantes sont compatibles
