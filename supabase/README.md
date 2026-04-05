# Supabase — Ma Clinique Pro V2

> 🎯 **Supabase est la source de vérité cible du projet.** L'architecture finale est 100% Supabase (PostgreSQL + Auth + Storage + Realtime + Edge Functions). Firebase est un héritage temporaire en cours de migration. Voir `MIGRATION_FIREBASE.md` pour le plan détaillé.
>
> ---
>
> ## Projet Supabase
>
> - **Project ID** : `anzgkxmxkcetzbjtjtuh`
> - - **URL** : `https://anzgkxmxkcetzbjtjtuh.supabase.co`
>   - - **Région** : (à confirmer)
>     - - **Environnement actif** : Production (staging + dev à créer)
>      
>       - ---
>
> ## Structure du dossier
>
> ```
> supabase/
> ├── README.md                    ← Ce fichier — vue d'ensemble
> ├── MIGRATION_FIREBASE.md        ← Plan de migration Firebase → Supabase (4 étapes)
> ├── migrations/                  ← Scripts SQL de migration (à créer)
> │   ├── 001_create_clinics.sql
> │   ├── 002_create_practitioners.sql
> │   ├── 003_create_patients.sql
> │   ├── 004_create_rendez_vous.sql
> │   ├── 005_create_photos.sql
> │   ├── 006_create_day_settings.sql
> │   ├── 007_create_reminders.sql
> │   └── 008_rls_policies.sql
> └── functions/                   ← Edge Functions Deno (à créer / versionner)
>     ├── create-agenda-entry/     ← ✅ Déployée
>     ├── suggerer-creneaux/       ← ✅ Déployée
>     ├── generate-note/           ← 📋 À créer (sécuriser OpenAI)
>     ├── optimize-route/          ← 📋 À créer (Phase 3)
>     └── notify/                  ← 📋 À créer (Phase 2)
> ```
>
> ---
>
> ## Fonctions RPC actuellement déployées
>
> ### `create_agenda_entry` ✅
> Crée une entrée RDV avec validation JWT.
>
> **Endpoint** : `POST /rest/v1/rpc/create_agenda_entry`
>
> **Headers** :
> ```
> apikey: <SUPABASE_ANON_KEY>
> Content-Type: application/json
> Authorization: Bearer <userJWT>
> ```
>
> **Paramètres** :
> ```json
> {
>   "p_patient_Id": "<string>",
>   "p_nom_patient": "<string>",
>   "p_date": "<string>",
>   "p_heure_debut": "<string>",
>   "p_duree": 45,
>   "p_type_soin": "<string>",
>   "p_prix": 85.00,
>   "p_notes_additionnelles": "<string>",
>   "userJWT": "<string>",
>   "p_owner_id": "<string>"
> }
> ```
>
> ---
>
> ### `suggerer_creneaux` ✅
> Suggère des créneaux optimaux en tenant compte de la ville du patient.
>
> **Endpoint** : `POST /rest/v1/rpc/suggerer_creneaux`
>
> **Paramètres** :
> ```json
> {
>   "p_owner_id": "<string>",
>   "p_date": "<string>",
>   "p_duree_minutes": 45,
>   "p_ville_patient": "<string>"
> }
> ```
>
> **Retour** : `List<Json>` — `[{ date, heure, raison }]`
>
> ---
>
> ## Edge Functions à créer (cible)
>
> ### `/generate-note` 📋
> Proxy sécurisé vers OpenAI — remplacera l'appel direct depuis FlutterFlow.
> - Input : `noteUtilisateur` (texte / dictée vocale)
> - - Output : note clinique structurée (observations, actes, recommandations)
>   - - Sécurité : clé OpenAI côté serveur uniquement
>    
>     - ### `/optimize-route` 📋
>     - Optimisation de tournée à domicile.
>     - - Input : liste de patients avec adresses + ancres (domicile, stérilisation)
>       - - Output : ordre optimal des visites + itinéraire
>         - - Dépendance : Google Maps API
>          
>           - ### `/notify` 📋
>           - Envoi de notifications push / SMS / email.
>           - - Input : rendez_vous_id, channel, message
>             - - Output : confirmation d'envoi
>               - - Dépendance : Firebase Cloud Messaging (V1), Twilio (V2)
>                
>                 - ---
>
> ## Architecture cible PostgreSQL
>
> Tables à créer dans l'ordre (voir `MIGRATION_FIREBASE.md` pour le SQL complet) :
>
> 1. `clinics` — cliniques (multi-tenant)
> 2. 2. `practitioners` — profils praticiens / infirmières
>    3. 3. `patients` — dossiers patients
>       4. 4. `rendez_vous` — soins et agenda
>          5. 5. `photos` — photos de soins avec métadonnées podologiques
>             6. 6. `day_settings` — paramètres journée par praticienne
>                7. 7. `service_types` — types de soins
>                   8. 8. `appointment_reminders` — rappels configurables
>                      9. 9. `practitioner_reminder_defaults` — configuration rappels par défaut
>                        
>                         10. **RLS activé sur toutes les tables** — isolation par `owner_id` et `clinic_id`.
>                        
>                         11. ---
>                        
>                         12. ## Variables d'environnement
>
> Créer un fichier `.env.local` (jamais committer — protégé par `.gitignore`) :
>
> ```env
> SUPABASE_URL=https://anzgkxmxkcetzbjtjtuh.supabase.co
> SUPABASE_ANON_KEY=<votre_anon_key>
> SUPABASE_SERVICE_KEY=<votre_service_key>
> OPENAI_API_KEY=sk-...
> GOOGLE_MAPS_API_KEY=...
> FCM_SERVER_KEY=...
> ```
>
> Déployer les secrets sur Supabase :
> ```bash
> supabase secrets set OPENAI_API_KEY=sk-...
> supabase secrets set GOOGLE_MAPS_API_KEY=...
> supabase secrets set FCM_SERVER_KEY=...
> ```
>
> ---
>
> ## Prochaines actions prioritaires
>
> - [ ] **🔴 URGENT** : Créer l'Edge Function `/generate-note` (sécuriser la clé OpenAI)
> - [ ] - [ ] **🔴 URGENT** : Créer le schéma SQL complet dans `migrations/`
> - [ ] - [ ] Créer le projet Supabase staging (tests migration)
> - [ ] - [ ] Exporter les données Firebase pour migration
> - [ ] - [ ] Versionner le code source des fonctions RPC existantes
