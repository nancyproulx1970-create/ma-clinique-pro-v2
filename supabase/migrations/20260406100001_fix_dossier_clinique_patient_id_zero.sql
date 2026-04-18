-- ============================================================
-- Migration: fix_dossier_clinique_patient_id_zero
-- ============================================================
-- Dossier_Clinique a 2 lignes avec patient_id = 0 (valeur sentinelle
-- utilisée par FlutterFlow quand aucun patient n'est sélectionné).
-- patient_id = 0 n'existe pas dans Patients (bigint identity > 0).
-- On corrige en mettant NULL pour permettre l'ajout de la FK ensuite.
-- ============================================================

UPDATE "Dossier_Clinique"
SET patient_id = NULL
WHERE patient_id = 0;
