-- ============================================================
-- Migration: auto_create_parametres_agenda
-- ============================================================
-- Problème : quand un nouvel utilisateur se connecte, aucune ligne
-- n'existe dans Parametres_Agenda. La query FlutterFlow retourne 0
-- résultat et les champs restent vides.
--
-- Solution : étendre le trigger handle_new_user_profile pour créer
-- aussi une ligne dans Parametres_Agenda avec les valeurs par défaut.
--
-- En plus, insérer maintenant la ligne manquante pour l'utilisateur
-- existant qui n'en a pas.
-- ============================================================

-- 1. Insérer la ligne manquante pour l'utilisateur existant
INSERT INTO "Parametres_Agenda" (owner_id, adresse_depart, adresse_sterilisation)
SELECT u.id, '', ''
FROM auth.users u
LEFT JOIN "Parametres_Agenda" pa ON pa.owner_id = u.id
WHERE pa.id IS NULL
ON CONFLICT DO NOTHING;

-- 2. Mettre à jour le trigger pour créer automatiquement la ligne au signup
CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Créer le profil professionnel
  INSERT INTO public.profils_professionnels (user_id, profile_completed)
  VALUES (NEW.id, false)
  ON CONFLICT (user_id) DO NOTHING;

  -- Créer les paramètres agenda avec valeurs par défaut
  INSERT INTO public."Parametres_Agenda" (owner_id)
  VALUES (NEW.id)
  ON CONFLICT (owner_id) DO NOTHING;

  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'handle_new_user_profile: erreur pour user_id=%, erreur: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;
