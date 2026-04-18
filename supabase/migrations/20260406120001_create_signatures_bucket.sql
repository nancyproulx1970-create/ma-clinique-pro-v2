-- ============================================================
-- Migration: create_signatures_bucket
-- ============================================================
-- Crée un bucket privé pour les signatures professionnelles et
-- les signatures de consentement patient.
--
-- Problème résolu : les signatures étaient stockées dans clinic-assets
-- (bucket PUBLIC) — elles étaient accessibles sans authentification.
--
-- Politique : chaque praticienne ne peut lire/écrire QUE ses propres
-- fichiers. Le chemin attendu est : {uid}/{filename}
-- Ex: 5523ea42-.../signature.png
--
-- IMPORTANT : ne pas migrer les fichiers existants avant que FlutterFlow
-- soit mis à jour pour utiliser ce bucket et les bons chemins.
-- ============================================================

-- Créer le bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'signatures',
  'signatures',
  false,                          -- privé : aucun accès sans auth
  2097152,                        -- 2 MB (largement suffisant pour une signature)
  ARRAY['image/png', 'image/jpeg', 'image/webp']
);

-- SELECT : chaque praticienne lit uniquement son propre dossier
CREATE POLICY "signatures_select_own"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'signatures'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- INSERT : chaque praticienne écrit uniquement dans son propre dossier
CREATE POLICY "signatures_insert_own"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'signatures'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- UPDATE : chaque praticienne met à jour uniquement ses propres fichiers
CREATE POLICY "signatures_update_own"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'signatures'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- DELETE : chaque praticienne supprime uniquement ses propres fichiers
CREATE POLICY "signatures_delete_own"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'signatures'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
