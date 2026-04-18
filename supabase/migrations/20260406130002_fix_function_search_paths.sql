-- ============================================================
-- Migration: fix_function_search_paths
-- ============================================================
-- Toutes les fonctions sans search_path fixe sont vulnérables à
-- une attaque par injection de schéma : un attaquant avec accès
-- à la DB pourrait créer un schéma qui shadow des fonctions système.
-- On fixe search_path = '' (chaîne vide = utilisation des schémas
-- qualifiés uniquement, recommandé par Supabase).
-- ============================================================

ALTER FUNCTION public.check_agenda_overlap()
  SET search_path = '';

ALTER FUNCTION public.create_agenda_entry(uuid, bigint, text, date, time without time zone, text, text, numeric, text)
  SET search_path = '';

ALTER FUNCTION public.create_agenda_entry(uuid, uuid, text, date, time without time zone, integer, text)
  SET search_path = '';

ALTER FUNCTION public.create_agenda_entry(bigint, text, date, time without time zone, text, text, numeric, text)
  SET search_path = '';

ALTER FUNCTION public.ensure_workspace(text)
  SET search_path = '';

ALTER FUNCTION public.get_slot_status(uuid, date, text)
  SET search_path = '';

ALTER FUNCTION public.is_profile_complete(profils_professionnels)
  SET search_path = '';

ALTER FUNCTION public.profil_est_complet()
  SET search_path = '';

ALTER FUNCTION public.set_agenda_end_time()
  SET search_path = '';

ALTER FUNCTION public.set_agenda_times()
  SET search_path = '';

ALTER FUNCTION public.set_heure_fin()
  SET search_path = '';

ALTER FUNCTION public.slot_est_occupe(uuid, date, text)
  SET search_path = '';

ALTER FUNCTION public.suggerer_jours_disponibles(uuid, date, integer, integer)
  SET search_path = '';

ALTER FUNCTION public.trouver_creneaux_libres(uuid, date, integer)
  SET search_path = '';

ALTER FUNCTION public.trouver_prochain_creneau(uuid, date, integer, time without time zone, time without time zone, integer)
  SET search_path = '';

ALTER FUNCTION public.update_updated_at_column()
  SET search_path = '';

ALTER FUNCTION public.upsert_profil(uuid, jsonb)
  SET search_path = '';

ALTER FUNCTION public.verifier_chevauchement_agenda()
  SET search_path = '';
