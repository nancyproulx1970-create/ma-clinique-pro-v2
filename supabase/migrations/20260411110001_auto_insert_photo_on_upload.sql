-- ============================================================
-- Migration: auto_insert_photo_on_upload
-- ============================================================
-- Quand un fichier est uploadé dans le bucket soins_photos,
-- ce trigger crée automatiquement une ligne dans photos_soins
-- avec le storage_path correct.
--
-- Le path attendu est : {uid}/{visite_id}/{timestamp}.jpg
-- Le trigger extrait le visite_id du path.
--
-- Les métadonnées (moment, cote, vue) restent NULL — elles
-- seront remplies ensuite par l'utilisateur via FlutterFlow
-- (Update Row après tagging).
-- ============================================================

CREATE OR REPLACE FUNCTION public.auto_insert_photo_on_upload()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_parts TEXT[];
  v_uid TEXT;
  v_visite_id TEXT;
BEGIN
  -- Only process soins_photos bucket
  IF NEW.bucket_id != 'soins_photos' THEN
    RETURN NEW;
  END IF;

  IF NEW.owner IS NULL THEN
    RETURN NEW;
  END IF;

  -- Parse path: {uid}/{visite_id}/{filename}
  v_parts := string_to_array(NEW.name, '/');

  -- Need at least 3 segments: uid/visite_id/filename
  IF array_length(v_parts, 1) < 3 THEN
    -- Fallback: 2 segments = uid/filename (no visite_id)
    INSERT INTO public.photos_soins (owner_id, storage_path, taken_at)
    VALUES (NEW.owner, NEW.name, now())
    ON CONFLICT DO NOTHING;
    RETURN NEW;
  END IF;

  v_uid := v_parts[1];
  v_visite_id := v_parts[2];

  INSERT INTO public.photos_soins (owner_id, visite_id, storage_path, taken_at)
  VALUES (
    NEW.owner,
    v_visite_id::uuid,
    NEW.name,
    now()
  )
  ON CONFLICT DO NOTHING;

  RETURN NEW;

EXCEPTION
  WHEN invalid_text_representation THEN
    -- visite_id is not a valid UUID — insert without it
    INSERT INTO public.photos_soins (owner_id, storage_path, taken_at)
    VALUES (NEW.owner, NEW.name, now())
    ON CONFLICT DO NOTHING;
    RETURN NEW;
  WHEN others THEN
    RAISE WARNING 'auto_insert_photo_on_upload: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Attach to storage.objects (same pattern as sync_upload_url_to_profile)
DROP TRIGGER IF EXISTS trg_auto_insert_photo ON storage.objects;
CREATE TRIGGER trg_auto_insert_photo
  AFTER INSERT ON storage.objects
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_insert_photo_on_upload();
