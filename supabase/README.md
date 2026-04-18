# Supabase — Ma Clinique Pro V2

Supabase est la base de données principale du projet (PostgreSQL 17).
Firebase est en cours d'abandon progressif.

---

## Projet

| Champ | Valeur |
|-------|--------|
| **Project ID** | `anzgkxmxkcetzbtjttuh` |
| **URL** | `https://anzgkxmxkcetzbtjttuh.supabase.co` |
| **Région** | `ca-central-1` (Canada) |
| **PostgreSQL** | 17.6 |
| **Environnement** | Production (unique — staging à créer) |

---

## Structure du dossier

```
supabase/
├── config.toml                  ← Configuration Supabase CLI (local dev)
├── README.md                    ← Ce fichier
├── MIGRATION_FIREBASE.md        ← Plan de migration Firebase → Supabase
├── GUIDE_SETUP_STAGING.md       ← Guide création environnement staging
├── migrations/                  ← Scripts SQL versionnés (appliqués via CLI ou CI)
│   ├── 20260406100001_fix_dossier_clinique_patient_id_zero.sql
│   ├── 20260406100002_add_fk_constraints.sql
│   ├── 20260406100003_drop_buggy_overlap_trigger.sql
│   └── 20260406100004_add_updated_at.sql
└── functions/
    └── generate-note/           ← Edge Function — génération de notes cliniques IA
        ├── index.ts
        └── README.md
```

> Les 30 migrations précédentes existent dans l'historique Supabase mais pas
> dans ce repo (créées avant l'initialisation du versionnement local).
> Les nouvelles migrations vont ici à partir de `20260406*`.

---

## Schéma actuel (tables publiques)

| Table | Lignes | Description |
|-------|--------|-------------|
| `Patients` | 9 | Dossiers patients (démographie + prescription) |
| `Agenda` | 20 | Rendez-vous planifiés |
| `Dossier_Clinique` | 6 | Notes SOAP par visite |
| `Photos_Soins` | 0 | Photos de soins podologiques |
| `profils_professionnels` | 2 | Profils praticiens |
| `Parametres_Agenda` | 1 | Horaires et préférences par praticienne |
| `Zones_Geographiques` | 6 | Zones de tournée à domicile |
| `Jours_Bloques` | 2 | Plages de congé / indisponibilité |
| `Lexique_Clinique` | 5 | Glossaire clinique personnalisé |
| `Soins` | 0 | Soins facturés |
| `Recus_Officiels` | 0 | Reçus avec taxes QC (TPS/TVQ) |
| `Finances` | 0 | Transactions financières |
| `Depenses` | 0 | Dépenses professionnelles |
| `Registre_Kilometrage` | 0 | Journal kilométrique |
| `Inventaire` | 0 | Stock produits |
| `ia_logs` | 10 | Logs d'utilisation IA (tokens, durée, statut) |

---

## Fonctions RPC

| Fonction | Sécurité | Description |
|----------|----------|-------------|
| `create_agenda_entry` | SECURITY DEFINER | Crée un RDV depuis FlutterFlow |
| `suggerer_creneaux` | SECURITY DEFINER | Suggère des créneaux disponibles par ville |
| `profil_est_complet` | SECURITY DEFINER | Vérifie si le profil praticienne est complet |
| `upsert_profil` | SECURITY DEFINER | Crée ou met à jour le profil praticienne |
| `handle_new_user_profile` | SECURITY DEFINER | Trigger auth → création profil auto au signup |

---

## Edge Functions déployées

| Fonction | Endpoint | Description |
|----------|----------|-------------|
| `generate-note` | `/functions/v1/generate-note` | Génération note clinique via OpenAI GPT-4o-mini |

---

## Setup local (développement)

### Prérequis
```bash
npm install -g supabase
supabase --version  # doit afficher >= 1.x
```

### Lier le projet
```bash
supabase login
supabase link --project-ref anzgkxmxkcetzbtjttuh
```

### Appliquer les migrations
```bash
# Appliquer toutes les migrations en attente sur la base liée
supabase db push

# Voir l'état des migrations
supabase migration list
```

### Déployer une Edge Function
```bash
supabase functions deploy generate-note
```

### Gérer les secrets (Edge Functions)
```bash
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets list
```

---

## Variables d'environnement requises

Voir `.env.example` à la racine du projet.

| Variable | Utilisée par | Obligatoire |
|----------|-------------|-------------|
| `SUPABASE_URL` | FlutterFlow, CLI | Oui |
| `SUPABASE_ANON_KEY` | FlutterFlow | Oui |
| `SUPABASE_SERVICE_ROLE_KEY` | Scripts migration, admin | Oui |
| `OPENAI_API_KEY` | Edge Function `generate-note` | Oui |
| `GOOGLE_MAPS_API_KEY` | Phase 3 (tournées) | Non (futur) |

---

## CI/CD

Le fichier `.github/workflows/supabase-migrations.yml` automatise :
- **Pull Request** → dry-run des migrations en local
- **Push sur `main`** → application des migrations + déploiement Edge Functions

Secrets GitHub Actions à configurer :
- `SUPABASE_ACCESS_TOKEN` — token personnel Supabase
- `SUPABASE_DB_PASSWORD` — mot de passe base de données

Variable GitHub Actions :
- `SUPABASE_PROJECT_REF` = `anzgkxmxkcetzbtjttuh`
