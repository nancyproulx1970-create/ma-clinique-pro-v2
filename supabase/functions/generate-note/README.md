# Edge Function — generate-note

## Objectif

Générer une note clinique professionnelle via OpenAI GPT-4o-mini,  
**sans jamais exposer la clé OpenAI côté client (FlutterFlow).**

La clé API OpenAI est stockée exclusivement dans les **Secrets Supabase**  
et n'est jamais transmise au mobile ou visible dans le code FlutterFlow.

---

## Sécurité

| Avant (problème) | Après (solution) |
|---|---|
| Clé OpenAI dans l'API Call FlutterFlow (exposée) | Clé OpenAI dans les Secrets Supabase (serveur uniquement) |
| Tout le monde peut appeler OpenAI avec votre clé | Seuls les utilisateurs authentifiés Supabase peuvent appeler l'endpoint |
| Aucune traçabilité d'usage | Logs dans la table `ia_logs` |

---

## Endpoint

```
POST https://<SUPABASE_PROJECT_ID>.supabase.co/functions/v1/generate-note
```

### En-têtes requis

```
Authorization: Bearer <SUPABASE_USER_JWT>
Content-Type: application/json
```

### Corps de la requête (JSON)

```json
{
  "patient_nom": "Tremblay",
    "patient_prenom": "Marie",
      "date_visite": "2025-06-15",
        "type_soin": "Soins podologiques à domicile",
          "observations": "Onychomycose modérée aux orteils 1 et 2 du pied droit. Hyperkeratose plantaire bilatérale.",
            "antecedents": "Diabète type 2, hypertension",
              "medicaments": "Metformine 500mg, Ramipril 5mg",
                "rendez_vous_id": "uuid-du-rdv-optionnel"
                }
                ```

                ### Champs obligatoires
                - `patient_nom`
                - `patient_prenom`
                - `date_visite` (format ISO 8601 : YYYY-MM-DD)
                - `observations`

                ### Champs facultatifs
                - `type_soin` (défaut générique si omis)
                - `antecedents`
                - `medicaments`
                - `rendez_vous_id` (UUID — lie la note au RDV dans les logs)

                ### Réponse (200 OK)

                ```json
                {
                  "note": "Le 15 juin 2025, visite à domicile auprès de Mme Marie Tremblay...",
                    "tokens_used": 312
                    }
                    ```

                    ### Codes d'erreur

                    | Code | Signification |
                    |---|---|
                    | 401 | Token JWT manquant ou invalide |
                    | 400 | Champs obligatoires manquants |
                    | 502 | Erreur OpenAI (quota, modèle, réseau) |
                    | 500 | Erreur interne serveur (config manquante) |

                    ---

                    ## Déploiement étape par étape

                    ### Prérequis
                    - [Supabase CLI](https://supabase.com/docs/guides/cli) installé
                    - Accès au projet Supabase (ID: `anzgkxmxkcetzbjtjtuh`)
                    - Clé API OpenAI disponible

                    ### Étape 1 — Configurer le secret OpenAI dans Supabase

                    ```bash
                    supabase secrets set OPENAI_API_KEY=sk-votre-cle-openai --project-ref anzgkxmxkcetzbjtjtuh
                    ```

                    **OU** via le tableau de bord Supabase :  
                    `Settings → Edge Functions → Secrets → Add secret`  
                    - Nom : `OPENAI_API_KEY`  
                    - Valeur : votre clé `sk-...`

                    ### Étape 2 — Lier le projet local

                    ```bash
                    supabase link --project-ref anzgkxmxkcetzbjtjtuh
                    ```

                    ### Étape 3 — Déployer la fonction

                    ```bash
                    supabase functions deploy generate-note --project-ref anzgkxmxkcetzbjtjtuh
                    ```

                    ### Étape 4 — Vérifier le déploiement

                    Dans le tableau de bord Supabase :  
                    `Edge Functions → generate-note → Logs`

                    Ou via curl :
                    ```bash
                    curl -X POST \
                      https://anzgkxmxkcetzbjtjtuh.supabase.co/functions/v1/generate-note \
                        -H "Authorization: Bearer VOTRE_JWT_UTILISATEUR" \
                          -H "Content-Type: application/json" \
                            -d '{
                                "patient_nom": "Test",
                                    "patient_prenom": "Patient",
                                        "date_visite": "2025-06-01",
                                            "observations": "Test de déploiement de la fonction."
                                              }'
                                              ```

                                              ---

                                              ## Mise à jour dans FlutterFlow

                                              Après déploiement, modifier l'API Call `GenerateNoteAI` dans FlutterFlow :

                                              ### Avant
                                              ```
                                              URL: https://api.openai.com/v1/chat/completions
                                              Header: Authorization: Bearer sk-VOTRE_CLE_OPENAI  ← DANGER
                                              ```

                                              ### Après
                                              ```
                                              URL: https://anzgkxmxkcetzbjtjtuh.supabase.co/functions/v1/generate-note
                                              Header: Authorization: Bearer [Supabase User JWT]  ← SÉCURISÉ
                                              ```

                                              **Corps de la requête :**
                                              ```json
                                              {
                                                "patient_nom": "[Variable FlutterFlow]",
                                                  "patient_prenom": "[Variable FlutterFlow]",
                                                    "date_visite": "[Variable FlutterFlow]",
                                                      "type_soin": "[Variable FlutterFlow]",
                                                        "observations": "[Variable FlutterFlow]"
                                                        }
                                                        ```

                                                        **Réponse :** lire le champ `note` dans le JSON retourné.

                                                        ---

                                                        ## Table `ia_logs` requise

                                                        Cette fonction journalise automatiquement chaque appel dans Supabase.  
                                                        Créer la table avec ce SQL :

                                                        ```sql
                                                        CREATE TABLE ia_logs (
                                                          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                                            user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
                                                              fonction TEXT NOT NULL,
                                                                tokens_entree INTEGER DEFAULT 0,
                                                                  tokens_sortie INTEGER DEFAULT 0,
                                                                    rendez_vous_id UUID REFERENCES rendez_vous(id) ON DELETE SET NULL,
                                                                      created_at TIMESTAMPTZ DEFAULT now()
                                                                      );

                                                                      -- RLS
                                                                      ALTER TABLE ia_logs ENABLE ROW LEVEL SECURITY;

                                                                      -- Une clinicienne ne voit que ses propres logs
                                                                      CREATE POLICY "ia_logs_user_select" ON ia_logs
                                                                        FOR SELECT USING (auth.uid() = user_id);

                                                                        -- Seule la service role peut insérer (depuis l'Edge Function)
                                                                        CREATE POLICY "ia_logs_service_insert" ON ia_logs
                                                                          FOR INSERT WITH CHECK (true);
                                                                          ```

                                                                          ---

                                                                          ## Architecture de sécurité

                                                                          ```
                                                                          FlutterFlow (mobile)
                                                                              │
                                                                                  │  POST /functions/v1/generate-note
                                                                                      │  Authorization: Bearer <JWT Supabase>
                                                                                          ▼
                                                                                          Supabase Edge Function (Deno)
                                                                                              │  ✅ Vérifie le JWT
                                                                                                  │  ✅ Valide les champs
                                                                                                      │  ✅ Lit OPENAI_API_KEY depuis les secrets (jamais exposée)
                                                                                                          │
                                                                                                              ├──► OpenAI API (appel serveur-à-serveur)
                                                                                                                  │         model: gpt-4o-mini
                                                                                                                      │         temperature: 0.3
                                                                                                                          │
                                                                                                                              ├──► Supabase DB (log dans ia_logs)
                                                                                                                                  │
                                                                                                                                      └──► Retourne { note, tokens_used } à FlutterFlow
                                                                                                                                      ```
                                                                                                                                      
                                                                                                                                      ---
                                                                                                                                      
                                                                                                                                      ## Fallback (si l'Edge Function échoue)
                                                                                                                                      
                                                                                                                                      Dans FlutterFlow, implémenter un fallback :
                                                                                                                                      1. Appeler l'Edge Function → si erreur (timeout, 5xx)
                                                                                                                                      2. Afficher un champ texte vide que la clinicienne remplit manuellement
                                                                                                                                      3. **Ne jamais bloquer la création de la visite à cause de l'IA**
                                                                                                                                      
                                                                                                                                      ---
                                                                                                                                      
                                                                                                                                      *Créé le : 2026-04-05*  
                                                                                                                                      *Auteur : Architecture Ma Clinique Pro V2*
