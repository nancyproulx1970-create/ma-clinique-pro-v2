-- ============================================================
-- Migration: add_fk_constraints
-- ============================================================
-- Ajoute les contraintes FK manquantes pour l'intégrité référentielle.
--
-- Avant cette migration :
--   - Agenda.patient_id (bigint) → aucune FK vers Patients.id
--   - Dossier_Clinique.patient_id (bigint) → aucune FK vers Patients.id
--
-- ON DELETE SET NULL : si un patient est supprimé, les RDV/dossiers
-- conservent leur historique mais perdent le lien vers le patient.
-- ============================================================

-- FK : Agenda.patient_id → Patients.id
ALTER TABLE "Agenda"
  ADD CONSTRAINT "Agenda_patient_id_fkey"
  FOREIGN KEY (patient_id)
  REFERENCES "Patients"(id)
  ON DELETE SET NULL;

-- FK : Dossier_Clinique.patient_id → Patients.id
ALTER TABLE "Dossier_Clinique"
  ADD CONSTRAINT "Dossier_Clinique_patient_id_fkey"
  FOREIGN KEY (patient_id)
  REFERENCES "Patients"(id)
  ON DELETE SET NULL;
