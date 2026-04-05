# ARCHITECTURE AGENDA IA — Ma Clinique Pro V2

> 📋 **Mise à jour [2026-04]** : Ce document distingue l'**architecture actuelle** (hybride Firebase + Supabase, temporaire) de l'**architecture cible** (100% Supabase). Lire les deux sections pour comprendre le plan d'évolution.
>
> ---
>
> ## Stack Technique
>
> | Couche | Technologie | Rôle |
> |--------|-------------|------|
> | Frontend | FlutterFlow | UI/UX mobile iOS/Android + web |
> | Auth | Supabase Auth (JWT) | Authentification multi-rôles — **cible** |
> | Auth actuel | Firebase Auth | Authentification actuelle — à migrer |
> | Base de données cible | Supabase (PostgreSQL) | Source de vérité finale |
> | Base de données actuelle | Firebase Firestore | Héritage temporaire — à migrer |
> | Serverless | Supabase Edge Functions (Deno) | Logique métier, appels IA |
> | IA | OpenAI API (GPT-4o-mini) | Notes cliniques, suggestions, optimisation |
> | Storage cible | Supabase Storage | Photos de soins — cible |
> | Storage actuel | Firebase Storage | Héritage temporaire — à migrer |
> | Realtime | Supabase Realtime | Subscriptions agenda en temps réel |
>
> ---
>
> ## ⚙️ Architecture Actuelle (hybride — temporaire)
>
> ```
> FlutterFlow App
> │
> ├── Firebase Auth ──────────────────────────────── Authentification (actuelle)
> │
> ├── Firebase Firestore ─────────────────────────── Base de données principale (actuelle)
> │   ├── /users          → Profils praticiens
> │   ├── /patients       → Dossiers patients
> │   └── /rendez_vous    → Soins et agenda
> │       └── /photos     → Photos de soins (sous-collection)
> │
> ├── Firebase Storage ───────────────────────────── Photos (actuel)
> │
> └── Supabase (via API REST) ────────────────────── Logique IA + agenda
>     ├── RPC: create_agenda_entry  → Création RDV
>     └── RPC: suggerer_creneaux    → Suggestions IA créneaux
>
> OpenAI API ─────────────────────────────────────── Appel direct depuis FlutterFlow ⚠️
> └── GenerateNoteAI (clé API exposée côté client)
> ```
>
> **Problèmes de l'architecture actuelle :**
> - Deux sources de vérité (Firebase + Supabase) → risque de désynchronisation
> - - Clé OpenAI exposée dans FlutterFlow (côté client) → risque de sécurité
>   - - Firebase ne supporte pas SQL natif → pas de JOINs, RLS moins fin
>     - - Deux fournisseurs cloud = coûts et complexité doublés
>       - - Firebase Security Rules non documentées dans ce repo
>        
>         - ---
>
> ## 🎯 Architecture Cible (100% Supabase)
>
> ```
> FlutterFlow App
> │
> ├── Supabase Auth (JWT + custom claims) ─────────── Auth multi-rôles
> │   ├── Rôle: admin        → accès total clinique
> │   ├── Rôle: praticienne  → accès ses propres données
> │   └── Rôle: secrétaire   → prise de RDV uniquement
> │
> ├── Supabase Client SDK ──────────────────────────── Connexion directe (pas d'API REST custom)
> │   ├── Database (PostgreSQL)
> │   │   ├── practitioners   → profils praticiens
> │   │   ├── patients        → dossiers patients
> │   │   ├── rendez_vous     → soins et agenda
> │   │   ├── photos          → métadonnées photos de soins
> │   │   ├── day_settings    → paramètres journée praticien
> │   │   ├── service_types   → types de soins
> │   │   ├── clinics         → cliniques (multi-tenant)
> │   │   └── appointment_reminders → rappels configurables
> │   │
> │   ├── Row Level Security (RLS) ──────────────────── Sur 100% des tables
> │   │   ├── Praticienne voit uniquement ses données (owner_id)
> │   │   ├── Isolation par clinique (clinic_id)
> │   │   └── Admin voit tout dans sa clinique
> │   │
> │   ├── Supabase Realtime ──────────────────────────── Agenda live
> │   │   └── Subscription sur rendez_vous → mise à jour calendrier temps réel
> │   │
> │   └── Supabase Storage ───────────────────────────── Photos de soins
> │       └── Bucket: photos-soins (privé, accès via JWT)
> │
> └── Supabase Edge Functions (Deno) ───────────────── Logique métier + IA
>     ├── /create-agenda-entry  → Création RDV avec validation
>     ├── /suggerer-creneaux    → Suggestions IA créneaux (Google Maps + logique agenda)
>     ├── /generate-note        → Notes cliniques IA (OpenAI — clé sécurisée côté serveur)
>     ├── /optimize-route       → Optimisation tournée (Google Maps API)
>     └── /notify               → Notifications push (FCM) + SMS + email
> ```
>
> ---
>
> ## Modules Fonctionnels
>
> ### 1. Agenda Core
> - Gestion des soins (CRUD) avec historique par patient
> - - Créneaux disponibles par praticienne / type de soin
>   - - Paramètres de journée (horaires, pauses, durées par type de soin)
>     - - Vue calendrier mensuel / hebdomadaire
>       - - Bilan de santé annuel (spécifique podologie)
>         - - Reçu de paiement avec TPS/TVQ québécoises
>          
>           - ### 2. Couche IA (Edge Functions)
>           - - **GenerateNoteAI** → dictée vocale → note clinique structurée (observations, actes, recommandations)
>             - - **suggererCreneaux** → analyse agenda + localisation patient → créneaux optimaux avec explication
>               - - **optimizeRoute** → tournée à domicile → ordre optimal des visites (Google Maps + ancres)
>                 - - **decisionHelper** → alertes conflits, surcharge, rappels de suivi
>                  
>                   - ### 3. Gestion documentaire spécialisée (podologie)
>                   - - Photos de soins avec métadonnées cliniques (côté, vue, orteil, catégorie, moment)
>                     - - Prescriptions patients (rx_actuelle, rx_photo_url, rx_mise_a_jour)
>                       - - Bilan de santé : antécédents médicaux (Diabète, Vasculaire, Neuropathie...)
>                         - - Signature numérique praticienne sur reçus
>                          
>                           - ### 4. Multi-rôles
>                           - - Admin clinique : gestion globale
>                             - - Praticienne : agenda + dossiers patients
>                               - - Secrétaire : prise de RDV
>                                 - - Patient : auto-booking (Phase 5)
>                                  
>                                   - ### 5. Notifications
>                                   - - Rappels configurables par praticienne (0 à N, délais flexibles)
>                                     - - Canal V1 : Push (FCM)
>                                       - - Canal V2 : SMS + email
>                                        
>                                         - ---
>
> ## Flux de Données — Prise de RDV avec IA (cible)
>
> ```
> 1. Praticienne ouvre formulaire RDV
> 2. FlutterFlow → Edge Function /suggerer-creneaux
>    ├── Paramètres : owner_id, date, duree_minutes, ville_patient
>    ├── Supabase DB → SELECT créneaux disponibles
>    ├── Google Maps API → calcul distances
>    └── Réponse : liste créneaux [date, heure, raison, score]
> 3. Praticienne sélectionne un créneau
> 4. FlutterFlow → Edge Function /create-agenda-entry
>    ├── Validation JWT (owner_id vérifié)
>    ├── INSERT rendez_vous dans Supabase
>    └── Trigger → Edge Function /notify → FCM push patient
> 5. Supabase Realtime → mise à jour calendrier en temps réel
> ```
>
> ---
>
> ## Flux de Données — Note Clinique IA (cible)
>
> ```
> 1. Praticienne dicte ou saisit une observation (page NoteObservationCopy)
> 2. FlutterFlow → Edge Function /generate-note
>    ├── Paramètre : noteUtilisateur (texte libre / dictée)
>    ├── Supabase Edge Function → OpenAI API (clé sécurisée côté serveur)
>    │   ├── model: gpt-4o-mini
>    │   ├── temperature: 0.3
>    │   └── system: assistant clinique spécialisé podologie
>    └── Réponse : note structurée (observations, actes, recommandations)
> 3. Praticienne valide → UPDATE rendez_vous.notes dans Supabase
> ```
>
> ---
>
> ## Sécurité
>
> | Règle | Description |
> |-------|-------------|
> | RLS activé | Sur 100% des tables Supabase |
> | JWT vérifié | Côté Edge Function avant tout traitement |
> | IA lecture seule | Les Edge Functions IA ne font jamais d'INSERT/UPDATE/DELETE |
> | Clés API côté serveur | OpenAI, Google Maps → jamais exposées dans FlutterFlow |
> | Isolation par clinique | clinic_id + RLS → aucune donnée patient partagée entre cliniques |
> | Secrets versionnés | Jamais commitées dans le repo (via Supabase Secrets) |
>
> ---
>
> ## Environnements
>
> | Env | Supabase Project | Firebase Project | Usage |
> |-----|-----------------|-----------------|-------|
> | production | `anzgkxmxkcetzbjtjtuh` | (actuel) | Production |
> | staging | À créer | — | Tests QA |
> | dev | À créer | — | Développement local |
>
> > ℹ️ Pendant la migration : Firebase et Supabase coexistent en production. Les nouvelles données vont dans Supabase. Firebase est progressivement vidé selon le plan de migration (`supabase/MIGRATION_FIREBASE.md`).
