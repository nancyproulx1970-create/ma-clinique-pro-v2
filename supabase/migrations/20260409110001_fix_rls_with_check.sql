-- ============================================================
-- Migration: fix_rls_with_check
-- ============================================================
-- Corrige les policies ALL sans WITH CHECK sur 3 tables.
-- Sans WITH CHECK, un utilisateur pourrait INSERT une ligne
-- avec le owner_id d'un autre utilisateur.
-- Corrige aussi Lexique_Clinique SELECT (qual = true → owner_id).
-- ============================================================

-- DEPENSES : remplacer la policy ALL par des policies séparées
DROP POLICY IF EXISTS "Acces_Prive_Depenses" ON "Depenses";

CREATE POLICY "depenses_select" ON "Depenses"
  FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "depenses_insert" ON "Depenses"
  FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "depenses_update" ON "Depenses"
  FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
CREATE POLICY "depenses_delete" ON "Depenses"
  FOR DELETE USING (owner_id = auth.uid());

-- INVENTAIRE : idem
DROP POLICY IF EXISTS "Acces_Prive_Inventaire" ON "Inventaire";

CREATE POLICY "inventaire_select" ON "Inventaire"
  FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "inventaire_insert" ON "Inventaire"
  FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "inventaire_update" ON "Inventaire"
  FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
CREATE POLICY "inventaire_delete" ON "Inventaire"
  FOR DELETE USING (owner_id = auth.uid());

-- PHOTOS_SOINS : idem
DROP POLICY IF EXISTS "Acces_Prive_Photos_V2" ON "Photos_Soins";

CREATE POLICY "photos_soins_select" ON "Photos_Soins"
  FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "photos_soins_insert" ON "Photos_Soins"
  FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "photos_soins_update" ON "Photos_Soins"
  FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
CREATE POLICY "photos_soins_delete" ON "Photos_Soins"
  FOR DELETE USING (owner_id = auth.uid());

-- LEXIQUE_CLINIQUE : SELECT était qual = true (visible par tous)
DROP POLICY IF EXISTS "lexique_select" ON "Lexique_Clinique";

CREATE POLICY "lexique_select" ON "Lexique_Clinique"
  FOR SELECT USING (owner_id = auth.uid());

-- IA_LOGS : ajouter INSERT policy pour le client (même si l'Edge Function
-- utilise SECURITY DEFINER, mieux vaut protéger contre l'accès direct)
CREATE POLICY "ia_logs_insert" ON ia_logs
  FOR INSERT WITH CHECK (user_id = auth.uid());
