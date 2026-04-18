-- ============================================================
-- Migration: bucket_fix_and_index_cleanup
-- ============================================================
-- 1. Corrige le bucket soins_photos : pas de limite ni de type MIME
--    → vecteur d'upload de fichiers arbitraires par tout utilisateur auth
-- 2. Supprime 3 paires d'index dupliqués (même table, même colonne)
--    → réduit overhead sur INSERT/UPDATE
-- ============================================================

-- Étape 1 : sécuriser le bucket soins_photos
UPDATE storage.buckets
SET
  file_size_limit  = 10485760,   -- 10 MB (cohérent avec patient-photos = 20MB)
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
WHERE id = 'soins_photos';

-- Étape 2 : supprimer les index dupliqués
-- Agenda : idx_agenda_owner et idx_agenda_owner_id sont identiques
DROP INDEX IF EXISTS public.idx_agenda_owner;

-- Soins : idx_soins_owner et idx_soins_owner_id sont identiques
DROP INDEX IF EXISTS public.idx_soins_owner;

-- Patients : idx_patients_owner et idx_patients_owner_id sont identiques
DROP INDEX IF EXISTS public.idx_patients_owner;
