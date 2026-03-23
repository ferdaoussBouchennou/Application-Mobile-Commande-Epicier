ALTER TABLE reclamations
  MODIFY date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Optional: if you want non-midnight times for existing rows.
UPDATE reclamations
SET date_creation = TIMESTAMP(DATE(date_creation), CURRENT_TIME)
WHERE TIME(date_creation) = '00:00:00';
