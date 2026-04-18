-- ============================================================
-- Migration: fix_security_definer_view
-- ============================================================
-- v_parametres_agenda était définie avec SECURITY DEFINER,
-- ce qui fait tourner la vue avec les permissions du créateur
-- et peut contourner le RLS de Parametres_Agenda.
-- On la recrée avec SECURITY INVOKER (comportement par défaut et correct).
-- ============================================================

DROP VIEW IF EXISTS public.v_parametres_agenda;

CREATE VIEW public.v_parametres_agenda
WITH (security_invoker = true)
AS
SELECT
  id,
  owner_id,
  heure_debut_journee,
  heure_fin_journee,
  buffer_entre_rdv_minutes,
  max_patients_jour,
  ville_depart,
  adresse_depart,
  lieu_sterilisation,
  jours_travail,
  created_at,
  updated_at,
  mode_pratique,
  ville_fin_journee,
  adresse_sterilisation,
  ville_sterilisation,
  travaille_fin_semaine,
  CASE
    WHEN lower(COALESCE(ville_sterilisation, '')) = lower(COALESCE(ville_depart, ''))
    THEN 'circulaire'
    ELSE 'lineaire'
  END AS type_tournee
FROM "Parametres_Agenda";
