# Ma Clinique Pro V2

> Application SaaS pour cliniques — Agenda intelligent avec couche IA

![Stack](https://img.shields.io/badge/Frontend-FlutterFlow-blue)
![Stack](https://img.shields.io/badge/Backend-Supabase-green)
![Stack](https://img.shields.io/badge/IA-OpenAI-orange)
![Status](https://img.shields.io/badge/Status-En%20développement-yellow)

---

## Description

**Ma Clinique Pro V2** est une application SaaS destinée aux cliniques et praticiens de santé.
Elle combine un agenda médical complet avec une couche IA pour optimiser la prise de rendez-vous,
suggérer des créneaux intelligents et aider les praticiens dans leur organisation quotidienne.

---

## Stack Technique

| Couche | Technologie |
|--------|-------------|
| Frontend | FlutterFlow (mobile iOS/Android + web) |
| Base de données | Supabase (PostgreSQL) |
| Authentification | Supabase Auth + JWT custom claims |
| Temps réel | Supabase Realtime |
| Serverless | Supabase Edge Functions (Deno/TypeScript) |
| IA | OpenAI API (GPT-4o-mini) |
| Notifications | Firebase Cloud Messaging (push) |

---

## Documentation

Tous les documents de référence sont dans le dossier `/docs` :

| Fichier | Contenu |
|---------|---------|
| [ARCHITECTURE_AGENDA_IA.md](./docs/ARCHITECTURE_AGENDA_IA.md) | Architecture complète, flux de données, sécurité |
| [ROADMAP_AGENDA_IA.md](./docs/ROADMAP_AGENDA_IA.md) | Phases de développement et livrables |
| [MODELE_DONNEES_AGENDA.md](./docs/MODELE_DONNEES_AGENDA.md) | Schéma de base de données complet (SQL) |
| [PLAN_BASE_VS_PLAN_IA.md](./docs/PLAN_BASE_VS_PLAN_IA.md) | Séparation Base/IA, spec des Edge Functions |
| [DECISIONS_PRODUIT.md](./docs/DECISIONS_PRODUIT.md) | Décisions d'architecture documentées |

---

## Structure du Repo

```
ma-clinique-pro-v2/
├── docs/                          # Documentation projet
│   ├── ARCHITECTURE_AGENDA_IA.md
│   ├── ROADMAP_AGENDA_IA.md
│   ├── MODELE_DONNEES_AGENDA.md
│   ├── PLAN_BASE_VS_PLAN_IA.md
│   └── DECISIONS_PRODUIT.md
├── supabase/                      # Configuration Supabase
│   ├── migrations/                # Scripts SQL de migration
│   └── functions/                 # Edge Functions Deno
│       ├── suggest-slot/          # IA : suggestion de créneaux
│       ├── optimize-route/        # IA : optimisation tournées
│       ├── decision-helper/       # IA : aide à la décision
│       └── notify/                # Notifications push/SMS
├── .github/
│   ├── ISSUE_TEMPLATE/            # Templates d'issues
│   └── PULL_REQUEST_TEMPLATE.md   # Template de PR
├── CONTRIBUTING.md                # Guide de contribution
└── README.md                      # Ce fichier
```

---

## Prérequis

- [Supabase CLI](https://supabase.com/docs/guides/cli) >= 1.0
- [Deno](https://deno.land/) >= 1.40 (pour les Edge Functions)
- Compte [FlutterFlow](https://flutterflow.io)
- Compte [OpenAI](https://platform.openai.com) (clé API)
- [Flutter SDK](https://flutter.dev) >= 3.0 (optionnel, pour dev local)

---

## Installation — Environnement de développement

### 1. Cloner le repo

```bash
git clone https://github.com/nancyproulx1970-create/ma-clinique-pro-v2.git
cd ma-clinique-pro-v2
```

### 2. Configurer Supabase (dev)

```bash
# Installer Supabase CLI
npm install -g supabase

# Initialiser et lier au projet dev
supabase login
supabase link --project-ref <DEV_PROJECT_REF>

# Appliquer les migrations
supabase db push
```

### 3. Variables d'environnement pour les Edge Functions

Créer un fichier `.env.local` (ne jamais committer) :

```env
OPENAI_API_KEY=sk-...
FCM_SERVER_KEY=...
GOOGLE_MAPS_API_KEY=...
```

Déployer les secrets sur Supabase :

```bash
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set FCM_SERVER_KEY=...
```

### 4. Déployer les Edge Functions

```bash
supabase functions deploy suggest-slot
supabase functions deploy notify
```

### 5. Connecter FlutterFlow

Dans FlutterFlow → Settings → Supabase :
- URL : `https://<DEV_PROJECT_REF>.supabase.co`
- Anon Key : depuis le dashboard Supabase → Settings → API

---

## Environnements

| Env | Référence Supabase | Usage |
|-----|-------------------|-------|
| dev | projet-dev | Développement local |
| staging | projet-staging | Tests QA |
| prod | projet-prod | Production |

---

## Roadmap

| Phase | Contenu | Statut |
|-------|---------|--------|
| Phase 1 | Base Agenda (CRUD, calendrier, auth, notifications) | 🚧 En cours |
| Phase 2 | Couche IA (suggestions créneaux, aide décision) | 📋 Planifié |
| Phase 3 | Optimisation tournée, SaaS multi-cliniques | 📋 Planifié |

Voir la [roadmap détaillée](./docs/ROADMAP_AGENDA_IA.md) et les [issues GitHub](https://github.com/nancyproulx1970-create/ma-clinique-pro-v2/issues).

---

## Contribuer

Voir [CONTRIBUTING.md](./CONTRIBUTING.md) pour les conventions de branches, commits et process de PR.

---

## Sécurité

- Row Level Security (RLS) activé sur toutes les tables
- JWT vérifié côté Edge Function avant tout traitement
- Aucune donnée patient partagée entre cliniques
- Secrets jamais commitées dans le repo

---

*Ma Clinique Pro V2 — Développé avec FlutterFlow + Supabase*
