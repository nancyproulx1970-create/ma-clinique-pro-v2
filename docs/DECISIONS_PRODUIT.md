# DÉCISIONS PRODUIT — Ma Clinique Pro V2

Format : [DATE] - Décision - Raison - Alternatives rejetées

> 📋 **Mise à jour [2026-04]** : Ce document distingue explicitement l'**état actuel** (hybride Firebase + Supabase, héritage temporaire) de l'**architecture cible** (100% Supabase). Firebase est un héritage à retirer progressivement — il ne représente pas la direction finale du projet.
>
> ---
>
> ## Architecture & Stack
>
> ### [2026-03] FlutterFlow comme frontend
> **Décision** : Utiliser FlutterFlow pour toute l'interface (mobile + web)
> **Raison** : Développement rapide, SDK Supabase natif, déploiement iOS/Android/Web simultané
> **Statut** : ✅ Décision finale — inchangée
> **Alternatives rejetées** :
> - Flutter natif : trop long à développer pour une V2 rapide
> - - React Native : pas de maîtrise dans l'équipe
>  
>   - ---
>
> ### [2026-04] Architecture backend — État actuel vs Cible
>
> #### ⚙️ État actuel (hybride temporaire)
>
> Firebase Firestore est actuellement utilisé comme base de données principale dans FlutterFlow. Cette situation est le résultat d'un démarrage rapide utilisant l'intégration native FlutterFlow ↔ Firebase.
>
> **Collections Firebase existantes** :
> - `patients` → dossiers patients
> - - `users` → profils praticiens
>   - - `rendez_vous` → soins et agenda (avec sous-collection `photos`)
>    
>     - **Supabase utilisé en parallèle** via API REST (RPC) :
>     - - `create_agenda_entry` → création de RDV
>       - - `suggerer_creneaux` → suggestions IA de créneaux
>        
>         - **⚠️ Firebase n'est PAS la décision finale** — c'est un héritage temporaire à migrer.
>        
>         - ---
>
> #### 🎯 Architecture cible — 100% Supabase
>
> **Décision** : Supabase (PostgreSQL + Auth + RPC + Storage + Realtime + Edge Functions) est la source de vérité unique et finale
> **Raison** :
> - SQL natif : adapté aux données relationnelles d'un agenda médical (JOINs, RLS par ligne, triggers)
> - - RLS natif : isolation des données par praticienne sans logique applicative
>   - - Edge Functions Deno : logique IA serverless sans infra à gérer
>     - - Supabase Storage : remplacement direct de Firebase Storage
>       - - Supabase Realtime : subscriptions en temps réel (équivalent Firestore)
>         - - SDK Flutter natif dans FlutterFlow : connexion directe sans API REST custom
>           - - Coût maîtrisé : un seul fournisseur, facturation prévisible
>             - **Alternatives rejetées** :
>             - - Firebase permanent : pas de SQL natif, RLS moins fin, deux fournisseurs = complexité accrue
>               - - Architecture hybride permanente : dette technique, synchronisation risquée, deux sources de vérité
>                
>                 - **Règle** : Toute nouvelle fonctionnalité est développée directement en Supabase. Firebase n'est plus alimenté pour les nouvelles données.
>                
>                 - ---
>
> ### [2026-03] Supabase — Structure cible des tables
>
> La structure cible PostgreSQL (Supabase) à atteindre après migration complète :
>
> | Table | Remplace | Priorité migration |
> |-------|----------|--------------------|
> | `users` (= `practitioners`) | Collection Firebase `users` | 🔴 Haute |
> | `patients` | Collection Firebase `patients` | 🔴 Haute |
> | `rendez_vous` | Collection Firebase `rendez_vous` | 🔴 Haute |
> | `photos` | Sous-collection Firebase + Firebase Storage | 🟡 Moyenne |
> | `day_settings` | Logique UI `ParametresAgenda` | 🟡 Moyenne |
> | `service_types` | Champ texte libre `type_soin` | 🟢 Basse |
> | `clinics` | Champ `clinicId` dénormalisé | 🟢 Basse |
> | `appointment_reminders` | Non implémenté | 🟢 Basse |
>
> **RPC / Edge Functions cibles** :
> - `create_agenda_entry` → ✅ Déjà opérationnel
> - - `suggerer_creneaux` → ✅ Déjà opérationnel
>   - - `optimize_route` → 📋 À créer (Phase 3)
>     - - `notify` → 📋 À créer (Phase 2)
>       - - `generate_note_ai` → 📋 À créer (actuellement appel direct OpenAI depuis FlutterFlow)
>        
>         - ---
>
> ### [2026-03] OpenAI comme moteur IA
> **Décision** : OpenAI API (GPT-4o-mini)
> **Implémentation actuelle** : Appel direct depuis FlutterFlow (`GenerateNoteAI` API Call)
> **Cible** : Passer par une Edge Function Supabase (`/generate-note`) pour centraliser la clé API et sécuriser les appels
> **Raison de la cible** : La clé OpenAI ne doit pas être exposée côté client FlutterFlow
> **Statut** : 🟡 À migrer vers Edge Function
> **Alternatives rejetées** :
> - Mistral / LLaMA local : infrastructure trop complexe
> - - Google Gemini : moins testé pour cas d'usage médical
>  
>   - ---
>
> ## Domaine métier
>
> ### [2026-04] Application spécialisée — Podologie à domicile, Québec
> **Décision** : L'application est conçue pour des **podologues / infirmières en soins podologiques à domicile** au Québec
> **Éléments structurants identifiés** :
> - Photos de soins avec métadonnées cliniques : `categorie`, `moment`, `cote`, `vue`, `orteil`
> - - Bilan de santé annuel : Diabète, Vasculaire, Neuropathie
>   - - Prescriptions patients : `rx_actuelle`, `rx_photo_url`, `rx_mise_a_jour`
>     - - Fiscal québécois : TPS (5%) + TVQ (9,975%)
>       - - Profil praticien : `infirmiere_nom`, `titre_pro`, `numero_permis`, `signature_url`
>         - - Tournée à domicile : ancres Domicile + Centre de Stérilisation
>           - - Type de visite : `bilan_ou_suivi`
>            
>             - ---
>
> ## Fonctionnalités IA
>
> ### [2026-04] GenerateNoteAI — Notes cliniques via dictée vocale
> **Décision** : GPT-4o-mini, température 0.3, prompt spécialisé santé
> **État actuel** : API Call direct FlutterFlow → OpenAI (clé exposée côté client) ⚠️
> **Cible** : FlutterFlow → Edge Function Supabase `/generate-note` → OpenAI (clé sécurisée)
> **Statut** : ✅ Fonctionnel / 🟡 Sécurisation à faire
>
> ### [2026-04] suggererCreneaux — Suggestion IA de créneaux
> **Décision** : RPC Supabase `suggerer_creneaux`
> **État actuel** : ✅ Opérationnel (FlutterFlow → Supabase RPC)
> **Cible** : Identique — déjà sur la bonne architecture
>
> ### [2026-04] Assistant Logistique IA — Optimisation de tournée
> **Décision** : Planification tournée avec ancres configurables (Domicile + Stérilisation)
> **État actuel** : Interface opérationnelle dans `ParametresAgenda`
> **Cible** : Edge Function `/optimize-route` avec intégration Google Maps API
> **Statut** : ✅ Interface / 📋 Backend à créer
>
> ---
>
> ## Sécurité & Multi-tenant
>
> ### [2026-03] RLS sur toutes les tables
> **Décision** : Row Level Security activé sur chaque table Supabase
> **Règle** : Toute nouvelle table DOIT avoir une politique RLS avant merge
> **État actuel Firebase** : Security Rules Firestore (à auditer — non documentées dans ce repo)
> **Cible Supabase** : RLS PostgreSQL sur 100% des tables, politiques par `owner_id` / `clinic_id`
>
> ### [2026-03] IA jamais en écriture
> **Décision** : Les fonctions IA font uniquement des SELECT
> **Règle** : Si une Edge Function IA tente d'écrire → rejet PR immédiat
>
> ### [2026-03] IA non-bloquante
> **Décision** : Fallback silencieux si l'IA échoue — l'agenda fonctionne sans IA
>
> ---
>
> ## Notifications
>
> ### [2026-03] Rappels flexibles par praticienne
> **Décision** : Rappels configurables (0 à N rappels par RDV)
> **Architecture cible** :
> - Table Supabase `appointment_reminders`
> - - Table Supabase `practitioner_reminder_defaults`
>   - - Edge Function `/notify` → Firebase Cloud Messaging (V1) → SMS/email (V2)
>     - **Statut** : 📋 Non encore implémenté
>    
>     - ---
>
> ## Paiement & Fiscal
>
> ### [2026-04] Reçus de paiement conformes TPS/TVQ Québec
> **Décision** : Reçus professionnels avec taxes québécoises
> **Implémenté** : Page `RecuPaiement` (TPS 5%, TVQ 9,975%)
> **Cible** : Génération PDF + archivage dans Supabase Storage
>
> ---
>
> ## À Décider
>
> | Sujet | Statut | Échéance |
> |-------|--------|----------|
> | Calendrier de migration Firebase → Supabase | 🔴 Urgent | Phase 2 début |
> | Sécurisation clé OpenAI via Edge Function | 🔴 Urgent | Prochain sprint |
> | Audit Firebase Security Rules existantes | 🔴 Urgent | Avant migration |
> | Export et archivage données Firebase | 🟡 Important | Avant migration |
> | Intégration Google Maps (optimisation tournée) | 🟡 Important | Phase 3 |
> | Modèle de facturation SaaS (Stripe) | 🟢 À planifier | Phase 4 |
> | Notifications push FCM implémentation | 🟢 À planifier | Phase 2 |
