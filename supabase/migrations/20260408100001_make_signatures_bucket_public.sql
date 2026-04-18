-- ============================================================
-- Migration: make_signatures_bucket_public
-- ============================================================
-- Décision produit : la signature professionnelle et le logo
-- sont des éléments affichés sur les reçus et documents partagés
-- avec les patients. Un bucket public est approprié.
--
-- Les fichiers cliniques sensibles (photos de soins, prescriptions)
-- restent dans des buckets privés séparés.
-- ============================================================

UPDATE storage.buckets
SET public = true
WHERE id = 'signatures';
