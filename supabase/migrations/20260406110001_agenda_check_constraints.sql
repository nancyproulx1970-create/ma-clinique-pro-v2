-- ============================================================
-- Migration: agenda_check_constraints
-- ============================================================
-- 1. Corrige 1 ligne Agenda avec statut = '' → 'planifie'
-- 2. Ajoute CHECK sur Agenda.statut  (valeurs observées + 'annule')
-- 3. Ajoute CHECK sur Agenda.statut_paiement (valeurs observées)
-- ============================================================

-- Étape 1 : corriger la ligne avec statut vide
UPDATE "Agenda" SET statut = 'planifie' WHERE statut = '';

-- Étape 2 : CHECK sur statut
ALTER TABLE "Agenda"
  ADD CONSTRAINT "Agenda_statut_check"
  CHECK (statut IN ('planifie', 'complete', 'annule'));

-- Étape 3 : CHECK sur statut_paiement
ALTER TABLE "Agenda"
  ADD CONSTRAINT "Agenda_statut_paiement_check"
  CHECK (statut_paiement IN ('non_facturé', 'facturé', 'remboursé'));
