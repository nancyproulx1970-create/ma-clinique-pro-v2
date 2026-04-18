-- ============================================================
-- Migration: add_updated_at
-- ============================================================
-- Ajoute la colonne updated_at et le trigger correspondant aux tables
-- qui n'en ont pas : Agenda, Dossier_Clinique, profils_professionnels.
--
-- La fonction update_updated_at_column() existe déjà dans le projet.
-- ============================================================

-- Agenda
ALTER TABLE "Agenda"
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE TRIGGER update_agenda_updated_at
  BEFORE UPDATE ON "Agenda"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Dossier_Clinique
ALTER TABLE "Dossier_Clinique"
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE TRIGGER update_dossier_clinique_updated_at
  BEFORE UPDATE ON "Dossier_Clinique"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- profils_professionnels
ALTER TABLE profils_professionnels
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE TRIGGER update_profils_professionnels_updated_at
  BEFORE UPDATE ON profils_professionnels
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
