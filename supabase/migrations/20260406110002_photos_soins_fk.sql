-- ============================================================
-- Migration: photos_soins_fk
-- ============================================================
-- Photos_Soins n'a aucun lien FK vers les autres tables.
-- patient_nom est du texte libre — aucune référence au patient réel.
--
-- On ajoute :
--   - patient_id  → Patients.id  (nullable, ON DELETE SET NULL)
--   - agenda_id   → Agenda.id    (nullable, ON DELETE SET NULL)
--   - dossier_id  → Dossier_Clinique.id (nullable, ON DELETE SET NULL)
--
-- Les colonnes sont nullable pour ne pas bloquer les insertions
-- FlutterFlow qui n'envoient pas encore ces champs.
-- La table a 0 lignes — aucun risque de régression.
-- ============================================================

ALTER TABLE "Photos_Soins"
  ADD COLUMN IF NOT EXISTS patient_id BIGINT
    REFERENCES "Patients"(id) ON DELETE SET NULL;

ALTER TABLE "Photos_Soins"
  ADD COLUMN IF NOT EXISTS agenda_id UUID
    REFERENCES "Agenda"(id) ON DELETE SET NULL;

ALTER TABLE "Photos_Soins"
  ADD COLUMN IF NOT EXISTS dossier_id UUID
    REFERENCES "Dossier_Clinique"(id) ON DELETE SET NULL;

-- Index pour les requêtes par patient et par RDV
CREATE INDEX IF NOT EXISTS idx_photos_soins_patient_id
  ON "Photos_Soins" (patient_id);

CREATE INDEX IF NOT EXISTS idx_photos_soins_agenda_id
  ON "Photos_Soins" (agenda_id);
