-- ============================================================
-- Migration: auto_sync_upload_urls
-- ============================================================
-- Problème : FlutterFlow upload les fichiers dans Storage mais
-- n'écrit pas l'URL dans profils_professionnels.
--
-- Solution : un trigger sur storage.objects qui détecte les
-- nouveaux fichiers dans les buckets `signatures` et `clinic-assets`
-- et met à jour automatiquement la bonne colonne du profil.
--
-- Fonctionne sans aucune action FlutterFlow supplémentaire.
-- ============================================================

CREATE OR REPLACE FUNCTION public.sync_upload_url_to_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_public_url TEXT;
  v_supabase_url TEXT := 'https://anzgkxmxkcetzbtjttuh.supabase.co';
BEGIN
  -- Signature : bucket "signatures", path = {uid}/filename
  IF NEW.bucket_id = 'signatures' AND NEW.owner IS NOT NULL THEN
    v_public_url := v_supabase_url || '/storage/v1/object/public/signatures/' || NEW.name;

    UPDATE public.profils_professionnels
    SET signature_pro_url = v_public_url
    WHERE user_id = NEW.owner;
  END IF;

  -- Logo : bucket "clinic-assets", path commence par "logo/"
  IF NEW.bucket_id = 'clinic-assets' AND NEW.owner IS NOT NULL
     AND NEW.name LIKE 'logo/%' THEN
    v_public_url := v_supabase_url || '/storage/v1/object/public/clinic-assets/' || NEW.name;

    UPDATE public.profils_professionnels
    SET logo_clinique_url = v_public_url
    WHERE user_id = NEW.owner;
  END IF;

  RETURN NEW;
END;
$$;

-- Attacher le trigger à storage.objects sur INSERT
CREATE TRIGGER trg_sync_upload_url
  AFTER INSERT ON storage.objects
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_upload_url_to_profile();
