-- ============================================================
-- Migration: create_tax_schema
-- Architecture fiscale — SaaS soins à domicile Canada
-- Version finale
-- ============================================================

-- ─── Tables de référence ────────────────────────────────────────────────────

CREATE TABLE tax_codes (
  code        TEXT PRIMARY KEY,
  label       TEXT NOT NULL,
  item_type   TEXT NOT NULL CHECK (item_type IN ('service', 'product')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE tax_code_jurisdictions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tax_code    TEXT NOT NULL REFERENCES tax_codes(code),
  province    TEXT NOT NULL
    CHECK (province IN ('AB','BC','MB','NB','NL','NS','ON','PE','QC','SK','YT','NT','NU')),
  tax_type    TEXT NOT NULL CHECK (tax_type IN ('GST', 'HST', 'QST', 'PST')),
  status      TEXT NOT NULL CHECK (status IN ('taxable', 'exempt', 'zero_rated')),
  UNIQUE (tax_code, province, tax_type)
);

CREATE TABLE tax_rates (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  province        TEXT NOT NULL,
  tax_type        TEXT NOT NULL CHECK (tax_type IN ('GST', 'HST', 'QST', 'PST')),
  rate            NUMERIC(6,4) NOT NULL CHECK (rate >= 0 AND rate <= 1),
  effective_from  DATE NOT NULL,
  effective_to    DATE,
  UNIQUE (province, tax_type, effective_from)
);

-- Bloquer UPDATE et DELETE sur tax_rates (immuable)
CREATE OR REPLACE FUNCTION prevent_tax_rate_mutation()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'Les taux fiscaux sont immuables. Insérer un nouveau taux avec effective_from.';
END;
$$;

CREATE TRIGGER trg_tax_rates_immutable
  BEFORE UPDATE OR DELETE ON tax_rates
  FOR EACH ROW EXECUTE FUNCTION prevent_tax_rate_mutation();

-- ─── Tables métier ──────────────────────────────────────────────────────────

CREATE TABLE services_produits (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id    UUID NOT NULL DEFAULT auth.uid(),
  name        TEXT NOT NULL,
  item_type   TEXT NOT NULL CHECK (item_type IN ('service', 'product')),
  tax_code    TEXT NOT NULL REFERENCES tax_codes(code),
  unit_price  NUMERIC(10,2) NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE factures (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id                    UUID NOT NULL DEFAULT auth.uid(),
  -- TODO: ajouter FK vers Patients quand les types seront alignés (Patients.id = bigint)
  patient_id                  BIGINT,
  invoice_number              INTEGER NOT NULL,
  invoice_date                DATE NOT NULL DEFAULT CURRENT_DATE,
  place_of_supply_province    TEXT NOT NULL
    CHECK (place_of_supply_province IN ('AB','BC','MB','NB','NL','NS','ON','PE','QC','SK','YT','NT','NU')),
  subtotal                    NUMERIC(10,2) NOT NULL CHECK (subtotal >= 0),
  gst_total                   NUMERIC(10,2) NOT NULL DEFAULT 0,
  hst_total                   NUMERIC(10,2) NOT NULL DEFAULT 0,
  qst_total                   NUMERIC(10,2) NOT NULL DEFAULT 0,
  pst_total                   NUMERIC(10,2) NOT NULL DEFAULT 0,
  grand_total                 NUMERIC(10,2) NOT NULL CHECK (grand_total >= 0),
  -- Snapshots des numéros de taxes au moment de l'émission
  gst_number_snapshot         TEXT,
  qst_number_snapshot         TEXT,
  pst_number_snapshot         TEXT,
  tax_engine_version          TEXT NOT NULL DEFAULT '1.0',
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
  finalized_at                TIMESTAMPTZ,
  -- Numéro de facture unique par utilisateur
  UNIQUE (owner_id, invoice_number),
  -- HST est exclusif : si HST > 0, aucune autre taxe
  CHECK (hst_total = 0 OR (gst_total = 0 AND qst_total = 0 AND pst_total = 0)),
  -- QC n'utilise jamais HST
  CHECK (place_of_supply_province != 'QC' OR hst_total = 0)
);

CREATE TABLE facture_lignes (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facture_id              UUID NOT NULL REFERENCES factures(id) ON DELETE CASCADE,
  description             TEXT NOT NULL,
  item_type               TEXT NOT NULL CHECK (item_type IN ('service', 'product')),
  quantity                NUMERIC(10,2) NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit_price              NUMERIC(10,2) NOT NULL,
  line_subtotal           NUMERIC(10,2) NOT NULL CHECK (line_subtotal >= 0),
  -- Snapshot fiscal figé au moment de l'émission
  tax_code_snapshot       TEXT NOT NULL,
  province_snapshot       TEXT NOT NULL
    CHECK (province_snapshot IN ('AB','BC','MB','NB','NL','NS','ON','PE','QC','SK','YT','NT','NU')),
  tax_engine_version      TEXT NOT NULL DEFAULT '1.0',
  -- Taxes appliquées (taux + montant pour chaque type)
  gst_rate                NUMERIC(6,4) NOT NULL DEFAULT 0 CHECK (gst_rate >= 0 AND gst_rate <= 1),
  gst_amount              NUMERIC(10,2) NOT NULL DEFAULT 0,
  hst_rate                NUMERIC(6,4) NOT NULL DEFAULT 0 CHECK (hst_rate >= 0 AND hst_rate <= 1),
  hst_amount              NUMERIC(10,2) NOT NULL DEFAULT 0,
  qst_rate                NUMERIC(6,4) NOT NULL DEFAULT 0 CHECK (qst_rate >= 0 AND qst_rate <= 1),
  qst_amount              NUMERIC(10,2) NOT NULL DEFAULT 0,
  pst_rate                NUMERIC(6,4) NOT NULL DEFAULT 0 CHECK (pst_rate >= 0 AND pst_rate <= 1),
  pst_amount              NUMERIC(10,2) NOT NULL DEFAULT 0,
  line_total              NUMERIC(10,2) NOT NULL CHECK (line_total >= 0),
  -- HST exclusif par ligne aussi
  CHECK (hst_amount = 0 OR (gst_amount = 0 AND qst_amount = 0 AND pst_amount = 0))
);

-- Empêcher toute modification des lignes après finalisation
CREATE OR REPLACE FUNCTION prevent_finalized_line_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM factures
    WHERE id = COALESCE(OLD.facture_id, NEW.facture_id)
      AND finalized_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Modification interdite : facture finalisée';
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_protect_finalized_lines
  BEFORE UPDATE OR DELETE ON facture_lignes
  FOR EACH ROW EXECUTE FUNCTION prevent_finalized_line_change();

-- ─── Index ──────────────────────────────────────────────────────────────────

CREATE INDEX idx_services_produits_owner ON services_produits (owner_id);
CREATE INDEX idx_factures_owner_date ON factures (owner_id, invoice_date);
CREATE INDEX idx_facture_lignes_facture ON facture_lignes (facture_id);
CREATE INDEX idx_tax_code_jurisdictions_lookup ON tax_code_jurisdictions (tax_code, province);

-- ─── RLS ────────────────────────────────────────────────────────────────────

ALTER TABLE tax_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_code_jurisdictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE services_produits ENABLE ROW LEVEL SECURITY;
ALTER TABLE factures ENABLE ROW LEVEL SECURITY;
ALTER TABLE facture_lignes ENABLE ROW LEVEL SECURITY;

-- Tables de référence : lecture pour tout utilisateur authentifié
CREATE POLICY "tax_codes_select" ON tax_codes
  FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "tax_code_jurisdictions_select" ON tax_code_jurisdictions
  FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "tax_rates_select" ON tax_rates
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- services_produits : per-owner
CREATE POLICY "services_produits_select" ON services_produits
  FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "services_produits_insert" ON services_produits
  FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "services_produits_update" ON services_produits
  FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
CREATE POLICY "services_produits_delete" ON services_produits
  FOR DELETE USING (owner_id = auth.uid());

-- factures : per-owner
CREATE POLICY "factures_select" ON factures
  FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "factures_insert" ON factures
  FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "factures_update" ON factures
  FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
CREATE POLICY "factures_delete" ON factures
  FOR DELETE USING (owner_id = auth.uid());

-- facture_lignes : accès via la facture parente
CREATE POLICY "facture_lignes_select" ON facture_lignes FOR SELECT
  USING (EXISTS (SELECT 1 FROM factures WHERE factures.id = facture_lignes.facture_id AND factures.owner_id = auth.uid()));
CREATE POLICY "facture_lignes_insert" ON facture_lignes FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM factures WHERE factures.id = facture_lignes.facture_id AND factures.owner_id = auth.uid()));
CREATE POLICY "facture_lignes_update" ON facture_lignes FOR UPDATE
  USING (EXISTS (SELECT 1 FROM factures WHERE factures.id = facture_lignes.facture_id AND factures.owner_id = auth.uid()));
CREATE POLICY "facture_lignes_delete" ON facture_lignes FOR DELETE
  USING (EXISTS (SELECT 1 FROM factures WHERE factures.id = facture_lignes.facture_id AND factures.owner_id = auth.uid()));
