-- ============================================================
-- Migration: drop_global_storage_policies
-- ============================================================
-- These 2 policies use qual=true / with_check=true, which means
-- ANY authenticated user can read/upload ANY file in ANY bucket.
-- They override all per-user isolation policies.
--
-- WARNING: this will break uploads in buckets where FlutterFlow
-- does not use {uid}/... paths (clinic-assets, patient-photos,
-- soins_photos). The audio-notes bucket is safe because it
-- already uses {uid}/... paths. The other buckets must be fixed
-- in FlutterFlow before this migration is applied.
-- ============================================================

DROP POLICY "allow authenticated read 1x29xl5_0" ON storage.objects;
DROP POLICY "allow authenticated uploads 1x29xl5_0" ON storage.objects;
