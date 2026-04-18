-- ============================================================
-- Migration: add_missing_fk_indexes
-- ============================================================
-- Colonnes FK sans index détectées par le conseiller de performance.
-- Un JOIN ou DELETE en cascade sur ces colonnes forçait un seq scan.
-- ============================================================

-- Agenda.patient_id → Patients.id
CREATE INDEX IF NOT EXISTS idx_agenda_patient_id
  ON "Agenda" (patient_id);

-- Dossier_Clinique.agenda_id → Agenda.id
CREATE INDEX IF NOT EXISTS idx_dossier_clinique_agenda_id
  ON "Dossier_Clinique" (agenda_id);

-- Lexique_Clinique.owner_id → auth.users.id
CREATE INDEX IF NOT EXISTS idx_lexique_clinique_owner_id
  ON "Lexique_Clinique" (owner_id);

-- Photos_Soins.dossier_id → Dossier_Clinique.id
CREATE INDEX IF NOT EXISTS idx_photos_soins_dossier_id
  ON "Photos_Soins" (dossier_id);
