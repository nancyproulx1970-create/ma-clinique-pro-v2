-- ============================================================
-- Migration: drop_redundant_storage_policies
-- ============================================================
-- Supprime les 4 policies "Give users authenticated access to folder"
-- sur soins_photos. Elles ne filtrent PAS par uid — elles vérifient
-- seulement que le chemin commence par /private/, ce qui ne protège
-- rien. Les policies per-uid (soins_photos_select/insert/update/delete)
-- sont déjà en place et correctes.
--
-- NOTE : les 2 policies globales (allow authenticated read/uploads
-- 1x29xl5_0) NE SONT PAS supprimées dans cette migration car les
-- uploads FlutterFlow dans clinic-assets et patient-photos n'utilisent
-- pas encore de chemin {uid}/... — les supprimer casserait ces uploads.
-- Elles seront supprimées dans une migration future après correction
-- des chemins dans FlutterFlow.
-- ============================================================

DROP POLICY IF EXISTS "Give users authenticated access to folder 1xygtvy_0" ON storage.objects;
DROP POLICY IF EXISTS "Give users authenticated access to folder 1xygtvy_1" ON storage.objects;
DROP POLICY IF EXISTS "Give users authenticated access to folder 1xygtvy_2" ON storage.objects;
DROP POLICY IF EXISTS "Give users authenticated access to folder 1xygtvy_3" ON storage.objects;
