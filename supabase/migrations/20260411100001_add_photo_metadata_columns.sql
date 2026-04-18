-- ============================================================
-- Migration: add_photo_metadata_columns
-- ============================================================
-- Ajoute type_photo pour distinguer photos de soins vs bilan.
-- Ajoute des index composites pour les 2 patterns de query :
--   - soins : (visite_id, type_photo)
--   - bilan : (patient_id, type_photo)
-- Default = 'soin' pour que les 13 photos existantes soient
-- automatiquement catégorisées correctement.
-- ============================================================

ALTER TABLE photos_soins
  ADD COLUMN IF NOT EXISTS type_photo TEXT NOT NULL DEFAULT 'soin'
    CHECK (type_photo IN ('soin', 'bilan'));

-- Index composites pour les queries FlutterFlow
CREATE INDEX IF NOT EXISTS idx_photos_soins_visite_type
  ON photos_soins (visite_id, type_photo);

CREATE INDEX IF NOT EXISTS idx_photos_soins_patient_type
  ON photos_soins (patient_id, type_photo);
