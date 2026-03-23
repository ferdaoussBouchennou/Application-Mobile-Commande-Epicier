-- Normalize legacy statuses to the new allowed set.
UPDATE reclamations SET statut = 'En attente' WHERE statut IN ('Ouverte');
UPDATE reclamations SET statut = 'En médiation' WHERE statut IN ('En cours');
UPDATE reclamations SET statut = 'Résolu' WHERE statut IN ('Résolue');

-- Modify enum to the new allowed set.
ALTER TABLE reclamations
  MODIFY statut ENUM('En attente','Résolu','En médiation','Remboursé','Litige ouvert')
  NOT NULL;
