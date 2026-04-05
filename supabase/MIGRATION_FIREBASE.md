# Plan de Migration Firebase → Supabase

> **Objectif** : Migrer progressivement l'architecture actuelle (hybride Firebase + Supabase) vers une architecture 100% Supabase, sans interruption de service et sans perte de données.

> **Principe directeur** : Migration par étapes. L'app reste fonctionnelle à chaque étape. On ne coupe pas Firebase avant que Supabase soit validé pour chaque module.

---

## Inventaire des dépendances Firebase à migrer

| Élément Firebase | Équivalent Supabase cible | Complexité | Priorité |
|-----------------|--------------------------|------------|----------|
| Firebase Auth | Supabase Auth + JWT custom claims | 🔴 Haute | 🔴 Haute |
| Firestore `users` | Table `practitioners` (PostgreSQL) | 🟡 Moyenne | 🔴 Haute |
| Firestore `patients` | Table `patients` (PostgreSQL) | 🟡 Moyenne | 🔴 Haute |
| Firestore `rendez_vous` | Table `rendez_vous` (PostgreSQL) | 🟡 Moyenne | 🔴 Haute |
| Firestore `rendez_vous/photos` | Table `photos` + Supabase Storage | 🔴 Haute | 🟡 Moyenne |
| Firebase Storage (photos) | Supabase Storage (bucket `photos-soins`) | 🟡 Moyenne | 🟡 Moyenne |
| Firebase Security Rules | RLS PostgreSQL | 🟡 Moyenne | 🔴 Haute |
| FlutterFlow → Firebase SDK | FlutterFlow → Supabase SDK | 🔴 Haute | 🔴 Haute |

---

## Plan de migration — 4 étapes progressives

### Étape 0 — Préparation (avant tout)
**Durée estimée** : 1-2 jours
**Risque** : Nul (aucune modification de l'app)

#### Actions
- [ ] **Auditer les Firebase Security Rules** actuelles et les documenter dans ce repo
- [ ] **Exporter toutes les données Firebase** (patients, users, rendez_vous, photos)
  ```bash
    # Export Firestore
      gcloud firestore export gs://<bucket>/backup-$(date +%Y%m%d)
        ```
        - [ ] **Photographier l'état actuel** : lister tous les documents par collection, compter les enregistrements
        - [ ] **Créer le projet Supabase staging** (séparé de production) pour tester la migration
        - [ ] **Documenter la clé OpenAI** utilisée dans FlutterFlow (pour la sécuriser en Étape 2)

        ---

        ### Étape 1 — Schéma Supabase + données en double écriture
        **Durée estimée** : 1-2 semaines
        **Risque** : Faible (Firebase reste actif, Supabase en parallèle)
        **Principe** : Les nouvelles données sont écrites dans Supabase ET Firebase. Firebase reste la source de lecture.

        #### 1a. Créer le schéma PostgreSQL Supabase

        ```sql
        -- Table: practitioners (remplace users Firebase)
        CREATE TABLE practitioners (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            firebase_uid TEXT UNIQUE,           -- lien temporaire avec Firebase Auth
              email TEXT UNIQUE NOT NULL,
                display_name TEXT,
                  prenom TEXT,
                    nom TEXT,
                      infirmiere_nom TEXT,
                        titre_pro TEXT,
                          nom_entreprise TEXT,
                            numero_permis TEXT,
                              photo_url TEXT,
                                signature_url TEXT,
                                  phone_number TEXT,
                                    clinic_id UUID REFERENCES clinics(id),
                                      role TEXT NOT NULL DEFAULT 'praticienne' CHECK (role IN ('admin', 'praticienne', 'secretaire')),
                                        is_active BOOLEAN DEFAULT true,
                                          created_at TIMESTAMPTZ DEFAULT now()
                                          );

                                          -- Table: clinics
                                          CREATE TABLE clinics (
                                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                              name TEXT NOT NULL,
                                                address TEXT,
                                                  phone TEXT,
                                                    email TEXT UNIQUE,
                                                      timezone TEXT NOT NULL DEFAULT 'America/Montreal',
                                                        is_active BOOLEAN DEFAULT true,
                                                          created_at TIMESTAMPTZ DEFAULT now()
                                                          );

                                                          -- Table: patients
                                                          CREATE TABLE patients (
                                                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                                              firebase_id TEXT UNIQUE,            -- lien temporaire avec Firestore
                                                                clinic_id UUID REFERENCES clinics(id),
                                                                  owner_id UUID REFERENCES practitioners(id),
                                                                    nom TEXT NOT NULL,
                                                                      prenom TEXT NOT NULL,
                                                                        nom_complet TEXT GENERATED ALWAYS AS (prenom || ' ' || nom) STORED,
                                                                          nom_search TEXT GENERATED ALWAYS AS (lower(prenom || ' ' || nom)) STORED,
                                                                            date_naissance DATE,
                                                                              adresse TEXT,
                                                                                ville TEXT,
                                                                                  code_postal TEXT,
                                                                                    telephone TEXT,
                                                                                      courriel TEXT,
                                                                                        rx_actuelle TEXT,
                                                                                          rx_photo_url TEXT,
                                                                                            rx_mise_a_jour TIMESTAMPTZ,
                                                                                              created_at TIMESTAMPTZ DEFAULT now(),
                                                                                                updated_at TIMESTAMPTZ DEFAULT now()
                                                                                                );

                                                                                                -- Table: rendez_vous
                                                                                                CREATE TABLE rendez_vous (
                                                                                                  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                                                                                    firebase_id TEXT UNIQUE,            -- lien temporaire avec Firestore
                                                                                                      clinic_id UUID REFERENCES clinics(id),
                                                                                                        owner_id UUID REFERENCES practitioners(id),
                                                                                                          patient_id UUID REFERENCES patients(id),
                                                                                                            nom_patient TEXT NOT NULL,          -- dénormalisé pour perf
                                                                                                              date_rdv TIMESTAMPTZ NOT NULL,
                                                                                                                heure_fin TIMESTAMPTZ,
                                                                                                                  duree_minutes INTEGER NOT NULL DEFAULT 45,
                                                                                                                    type_soin TEXT NOT NULL,
                                                                                                                      bilan_ou_suivi TEXT CHECK (bilan_ou_suivi IN ('Bilan', 'Suivi')),
                                                                                                                        prix NUMERIC(10,2),
                                                                                                                          notes TEXT,
                                                                                                                            statut_note TEXT DEFAULT 'brouillon' CHECK (statut_note IN ('brouillon', 'final')),
                                                                                                                              soin_effectue BOOLEAN DEFAULT false,
                                                                                                                                date_soin_effectue TIMESTAMPTZ,
                                                                                                                                  created_at TIMESTAMPTZ DEFAULT now(),
                                                                                                                                    updated_at TIMESTAMPTZ DEFAULT now()
                                                                                                                                    );
                                                                                                                                    
                                                                                                                                    -- Table: photos (sous-collection rendez_vous/photos Firebase)
                                                                                                                                    CREATE TABLE photos (
                                                                                                                                      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                                                                                                                        firebase_id TEXT UNIQUE,            -- lien temporaire avec Firestore
                                                                                                                                          rendez_vous_id UUID REFERENCES rendez_vous(id) ON DELETE CASCADE,
                                                                                                                                            patient_id UUID REFERENCES patients(id),
                                                                                                                                              owner_id UUID REFERENCES practitioners(id),
                                                                                                                                                image_url TEXT NOT NULL,            -- URL Supabase Storage
                                                                                                                                                  categorie TEXT,
                                                                                                                                                    moment TEXT,
                                                                                                                                                      cote TEXT CHECK (cote IN ('gauche', 'droit', 'les deux')),
                                                                                                                                                        vue TEXT CHECK (vue IN ('dorsale', 'plantaire', 'latérale', 'autre')),
                                                                                                                                                          orteil TEXT,
                                                                                                                                                            created_at TIMESTAMPTZ DEFAULT now()
                                                                                                                                                            );
                                                                                                                                                            
                                                                                                                                                            -- Table: day_settings
                                                                                                                                                            CREATE TABLE day_settings (
                                                                                                                                                              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                                                                                                                                                practitioner_id UUID REFERENCES practitioners(id),
                                                                                                                                                                  day_of_week INTEGER CHECK (day_of_week BETWEEN 0 AND 6),
                                                                                                                                                                    start_time TIME NOT NULL,
                                                                                                                                                                      end_time TIME NOT NULL,
                                                                                                                                                                        lunch_start TIME,
                                                                                                                                                                          lunch_end TIME,
                                                                                                                                                                            max_appointments INTEGER,
                                                                                                                                                                              is_working_day BOOLEAN DEFAULT true,
                                                                                                                                                                                UNIQUE (practitioner_id, day_of_week)
                                                                                                                                                                                );
                                                                                                                                                                                
                                                                                                                                                                                -- Table: appointment_reminders
                                                                                                                                                                                CREATE TABLE appointment_reminders (
                                                                                                                                                                                  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                                                                                                                                                                    rendez_vous_id UUID REFERENCES rendez_vous(id) ON DELETE CASCADE,
                                                                                                                                                                                      practitioner_id UUID REFERENCES practitioners(id),
                                                                                                                                                                                        delay_minutes INTEGER NOT NULL,     -- délai avant RDV (ex: 1440 = 24h)
                                                                                                                                                                                          channel TEXT NOT NULL DEFAULT 'push' CHECK (channel IN ('push', 'sms', 'email')),
                                                                                                                                                                                            sent_at TIMESTAMPTZ,
                                                                                                                                                                                              created_at TIMESTAMPTZ DEFAULT now()
                                                                                                                                                                                              );
                                                                                                                                                                                              
                                                                                                                                                                                              -- Table: practitioner_reminder_defaults
                                                                                                                                                                                              CREATE TABLE practitioner_reminder_defaults (
                                                                                                                                                                                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                                                                                                                                                                                  practitioner_id UUID REFERENCES practitioners(id) UNIQUE,
                                                                                                                                                                                                    reminder_delays INTEGER[] DEFAULT '{1440, 120}',  -- délais par défaut en minutes
                                                                                                                                                                                                      channel TEXT DEFAULT 'push'
                                                                                                                                                                                                      );
                                                                                                                                                                                                      ```
                                                                                                                                                                                                      
                                                                                                                                                                                                      #### 1b. Configurer RLS sur toutes les tables
                                                                                                                                                                                                      
                                                                                                                                                                                                      ```sql
                                                                                                                                                                                                      -- Activer RLS
                                                                                                                                                                                                      ALTER TABLE practitioners ENABLE ROW LEVEL SECURITY;
                                                                                                                                                                                                      ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
                                                                                                                                                                                                      ALTER TABLE rendez_vous ENABLE ROW LEVEL SECURITY;
                                                                                                                                                                                                      ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
                                                                                                                                                                                                      ALTER TABLE day_settings ENABLE ROW LEVEL SECURITY;
                                                                                                                                                                                                      ALTER TABLE appointment_reminders ENABLE ROW LEVEL SECURITY;
                                                                                                                                                                                                      
                                                                                                                                                                                                      -- Politique patients : praticienne voit seulement ses patients
                                                                                                                                                                                                      CREATE POLICY "praticienne_own_patients" ON patients
                                                                                                                                                                                                        FOR ALL USING (owner_id = auth.uid());
                                                                                                                                                                                                        
                                                                                                                                                                                                        -- Politique rendez_vous : praticienne voit seulement ses RDV
                                                                                                                                                                                                        CREATE POLICY "praticienne_own_rdv" ON rendez_vous
                                                                                                                                                                                                          FOR ALL USING (owner_id = auth.uid());
                                                                                                                                                                                                          
                                                                                                                                                                                                          -- Politique photos : praticienne voit seulement ses photos
                                                                                                                                                                                                          CREATE POLICY "praticienne_own_photos" ON photos
                                                                                                                                                                                                            FOR ALL USING (owner_id = auth.uid());
                                                                                                                                                                                                            ```
                                                                                                                                                                                                            
                                                                                                                                                                                                            #### 1c. Migrer les données Firebase → Supabase
                                                                                                                                                                                                            ```bash
                                                                                                                                                                                                            # Script de migration (à créer dans supabase/scripts/migrate_firebase.py)
                                                                                                                                                                                                            # 1. Exporter Firestore en JSON
                                                                                                                                                                                                            # 2. Transformer le schéma (Firestore → PostgreSQL)
                                                                                                                                                                                                            # 3. Insérer dans Supabase via service_key
                                                                                                                                                                                                            # 4. Conserver firebase_id pour traçabilité
                                                                                                                                                                                                            ```
                                                                                                                                                                                                            
                                                                                                                                                                                                            - [ ] Créer et tester le script de migration sur staging
                                                                                                                                                                                                            - [ ] Valider l'intégrité des données migrées (compter les enregistrements)
                                                                                                                                                                                                            - [ ] Migrer les photos Firebase Storage → Supabase Storage
                                                                                                                                                                                                            
                                                                                                                                                                                                            ---
                                                                                                                                                                                                            
                                                                                                                                                                                                            ### Étape 2 — Sécuriser l'IA + migrer l'auth
                                                                                                                                                                                                            **Durée estimée** : 1 semaine
                                                                                                                                                                                                            **Risque** : Moyen (modifications FlutterFlow requises)
                                                                                                                                                                                                            
                                                                                                                                                                                                            #### 2a. Créer Edge Function `/generate-note`
                                                                                                                                                                                                            ```typescript
                                                                                                                                                                                                            // supabase/functions/generate-note/index.ts
                                                                                                                                                                                                            import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
                                                                                                                                                                                                            
                                                                                                                                                                                                            serve(async (req) => {
                                                                                                                                                                                                              const { noteUtilisateur } = await req.json()
                                                                                                                                                                                                              
                                                                                                                                                                                                                const response = await fetch("https://api.openai.com/v1/chat/completions", {
                                                                                                                                                                                                                    method: "POST",
                                                                                                                                                                                                                        headers: {
                                                                                                                                                                                                                              "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
                                                                                                                                                                                                                                    "Content-Type": "application/json",
                                                                                                                                                                                                                                        },
                                                                                                                                                                                                                                            body: JSON.stringify({
                                                                                                                                                                                                                                                  model: "gpt-4o-mini",
                                                                                                                                                                                                                                                        temperature: 0.3,
                                                                                                                                                                                                                                                              messages: [
                                                                                                                                                                                                                                                                      { role: "system", content: "Tu es un assistant clinique intelligent..." },
                                                                                                                                                                                                                                                                              { role: "user", content: noteUtilisateur }
                                                                                                                                                                                                                                                                                    ]
                                                                                                                                                                                                                                                                                        })
                                                                                                                                                                                                                                                                                          })
                                                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                                            const data = await response.json()
                                                                                                                                                                                                                                                                                              return new Response(JSON.stringify(data), {
                                                                                                                                                                                                                                                                                                  headers: { "Content-Type": "application/json" }
                                                                                                                                                                                                                                                                                                    })
                                                                                                                                                                                                                                                                                                    })
                                                                                                                                                                                                                                                                                                    ```
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    - [ ] Déployer `/generate-note` sur Supabase
                                                                                                                                                                                                                                                                                                    - [ ] Mettre à jour FlutterFlow : remplacer l'API Call OpenAI direct par l'appel à l'Edge Function
                                                                                                                                                                                                                                                                                                    - [ ] Supprimer la clé OpenAI du côté client FlutterFlow
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    #### 2b. Migrer Firebase Auth → Supabase Auth
                                                                                                                                                                                                                                                                                                    - [ ] Créer les comptes Supabase Auth pour les utilisateurs existants
                                                                                                                                                                                                                                                                                                    - [ ] Configurer les custom claims JWT (rôle: praticienne/admin/secretaire)
                                                                                                                                                                                                                                                                                                    - [ ] Mettre à jour FlutterFlow : utiliser Supabase Auth au lieu de Firebase Auth
                                                                                                                                                                                                                                                                                                    - [ ] Tester le flux complet login → access token → RLS
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    ---
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    ### Étape 3 — Basculer FlutterFlow sur Supabase SDK
                                                                                                                                                                                                                                                                                                    **Durée estimée** : 2-3 semaines
                                                                                                                                                                                                                                                                                                    **Risque** : Élevé (refactoring FlutterFlow complet)
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    #### Actions par page
                                                                                                                                                                                                                                                                                                    - [ ] `Connexion` → Supabase Auth (signInWithPassword)
                                                                                                                                                                                                                                                                                                    - [ ] `AjouterPatient` / `ListePatients` / `DossierPatient` → queries Supabase `patients`
                                                                                                                                                                                                                                                                                                    - [ ] `AddAppointments` / `AppointmentDetails` → queries Supabase `rendez_vous`
                                                                                                                                                                                                                                                                                                    - [ ] `DetailVisite` → queries Supabase `rendez_vous` + `photos`
                                                                                                                                                                                                                                                                                                    - [ ] `NoteObservationCopy` → Edge Function `/generate-note` (déjà fait en Étape 2)
                                                                                                                                                                                                                                                                                                    - [ ] `BilanDeSante_V3` → champs patients Supabase
                                                                                                                                                                                                                                                                                                    - [ ] `RecuPaiement` → données Supabase
                                                                                                                                                                                                                                                                                                    - [ ] `ParametresAgenda` → table `day_settings` Supabase
                                                                                                                                                                                                                                                                                                    - [ ] `ProfileSetup` → table `practitioners` Supabase
                                                                                                                                                                                                                                                                                                    - [ ] Photos → Supabase Storage (upload + URL signée)
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    #### Validation par page
                                                                                                                                                                                                                                                                                                    - [ ] Tester chaque page sur staging avec données Supabase
                                                                                                                                                                                                                                                                                                    - [ ] Vérifier que RLS fonctionne correctement (isolation par praticienne)
                                                                                                                                                                                                                                                                                                    - [ ] Tests de régression (aucune fonctionnalité dégradée)
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    ---
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    ### Étape 4 — Désactiver Firebase
                                                                                                                                                                                                                                                                                                    **Durée estimée** : 1 jour
                                                                                                                                                                                                                                                                                                    **Risque** : Faible si Étapes 1-3 sont validées
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    #### Actions
                                                                                                                                                                                                                                                                                                    - [ ] Archiver le backup Firebase final
                                                                                                                                                                                                                                                                                                    - [ ] Désactiver Firebase Firestore (mode lecture seule puis off)
                                                                                                                                                                                                                                                                                                    - [ ] Désactiver Firebase Storage après transfert complet des photos
                                                                                                                                                                                                                                                                                                    - [ ] Désactiver Firebase Auth après migration complète des utilisateurs
                                                                                                                                                                                                                                                                                                    - [ ] Supprimer l'intégration Firebase de FlutterFlow
                                                                                                                                                                                                                                                                                                    - [ ] Supprimer les champs `firebase_id` des tables Supabase (migration nettoyage)
                                                                                                                                                                                                                                                                                                    - [ ] Mettre à jour la documentation (supprimer toutes les références Firebase)
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    ---
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    ## Critères de succès de la migration
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    | Critère | Mesure |
                                                                                                                                                                                                                                                                                                    |---------|--------|
                                                                                                                                                                                                                                                                                                    | Zéro perte de données | 100% des documents Firebase retrouvés dans Supabase |
                                                                                                                                                                                                                                                                                                    | Continuité de service | 0 interruption visible pour l'utilisateur |
                                                                                                                                                                                                                                                                                                    | RLS validé | 100% des tables avec politiques testées |
                                                                                                                                                                                                                                                                                                    | Performance | Temps de réponse équivalents ou meilleurs |
                                                                                                                                                                                                                                                                                                    | Sécurité | Clé OpenAI côté serveur uniquement |
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    ---
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    ## Risques et mitigations
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    | Risque | Probabilité | Impact | Mitigation |
                                                                                                                                                                                                                                                                                                    |--------|-------------|--------|-----------|
                                                                                                                                                                                                                                                                                                    | Perte de données lors de l'export | Faible | Critique | Backup Firebase avant toute migration |
                                                                                                                                                                                                                                                                                                    | Désynchronisation Firebase/Supabase | Moyenne | Élevé | Double écriture en Étape 1, validation journalière |
                                                                                                                                                                                                                                                                                                    | Breaking change FlutterFlow | Élevée | Élevé | Tests par page sur staging avant bascule prod |
                                                                                                                                                                                                                                                                                                    | Performances Supabase dégradées | Faible | Moyen | Index PostgreSQL, monitoring temps de réponse |
                                                                                                                                                                                                                                                                                                    | Firebase Auth migration incomplète | Moyenne | Élevé | Migration user par user, pas de coupure brutale |
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    ---
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    ## Ressources
                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                    - [Supabase Flutter SDK](https://supabase.com/docs/reference/dart/introduction)
                                                                                                                                                                                                                                                                                                    - [FlutterFlow + Supabase](https://docs.flutterflow.io/data-and-backend/supabase)
                                                                                                                                                                                                                                                                                                    - [Firebase to Supabase Migration Guide](https://supabase.com/docs/guides/migrations/firebase-auth)
                                                                                                                                                                                                                                                                                                    - [Supabase Storage](https://supabase.com/docs/guides/storage)
