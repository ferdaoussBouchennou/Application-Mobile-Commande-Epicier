-- Migration : table unique notifications avec utilisateur_id
-- Remplace client_id par utilisateur_id, fusionne notifications_epicier dans notifications
-- À exécuter sur epicier_ecommerce
--
-- Si notifications_epicier n'existe pas, ignorer l'erreur à l'étape 3 et commenter les lignes 3-4.

-- 1. Ajouter utilisateur_id à notifications
ALTER TABLE notifications ADD COLUMN utilisateur_id INT NULL AFTER id;

-- 2. Migrer les données existantes (client_id -> utilisateur_id)
UPDATE notifications SET utilisateur_id = client_id WHERE client_id IS NOT NULL;

-- 3. Migrer notifications_epicier vers notifications (si la table existe)
-- En cas d'erreur "Table doesn't exist", commenter les 4 lignes ci-dessous et l'étape 4
INSERT INTO notifications (utilisateur_id, message, date_envoi, lue)
SELECT e.utilisateur_id, ne.message, COALESCE(DATE(ne.created_at), CURDATE()), COALESCE(ne.lue, 0)
FROM notifications_epicier ne
JOIN epiciers e ON ne.epicier_id = e.id;

-- 4. Supprimer la table notifications_epicier (redondante)
DROP TABLE IF EXISTS notifications_epicier;

-- 5. Supprimer l'ancienne contrainte FK et la colonne client_id
-- Si erreur sur le nom de contrainte : SHOW CREATE TABLE notifications; et utiliser le nom exact
ALTER TABLE notifications DROP FOREIGN KEY notifications_ibfk_1;
ALTER TABLE notifications DROP COLUMN client_id;

-- 6. Rendre utilisateur_id obligatoire et ajouter la FK
ALTER TABLE notifications MODIFY utilisateur_id INT NOT NULL;
ALTER TABLE notifications ADD CONSTRAINT notifications_utilisateur_fk 
  FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id);

-- 7. Index pour les requêtes par utilisateur
CREATE INDEX idx_notifications_utilisateur_lue ON notifications(utilisateur_id, lue);


-- Migration : date_envoi en DATETIME pour afficher l'heure exacte des notifications
-- Résout le problème des notifications affichant toutes le même temps (ex: "il y a 15h")
-- À exécuter sur la base epicier_ecommerce

-- Modifier la colonne date_envoi pour inclure l'heure
ALTER TABLE notifications MODIFY date_envoi DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;
