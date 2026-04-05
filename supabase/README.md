# Supabase — Ma Clinique Pro V2

> **Note architecturale [2026-04]** : Supabase est utilisé en complément de Firebase Firestore dans ce projet. Firebase est la base de données principale (patients, users, rendez_vous). Supabase héberge les fonctions RPC pour la logique IA et l'agenda.

## Projet Supabase

- **Project ID** : `anzgkxmxkcetzbjtjtuh`
- **URL** : `https://anzgkxmxkcetzbjtjtuh.supabase.co`
- **Region** : (à confirmer)
- **Environnement** : Production

## Fonctions RPC disponibles

### `create_agenda_entry`

Crée une entrée dans l'agenda Supabase avec validation JWT.

**Endpoint** : `POST /rest/v1/rpc/create_agenda_entry`

**Headers requis** :
```
apikey: <SUPABASE_ANON_KEY>
Content-Type: application/json
Authorization: Bearer <userJWT>
```

**Body** :
```json
{
  "p_patient_Id": "<string>",
    "p_nom_patient": "<string>",
      "p_date": "<string>",
        "p_heure_debut": "<string>",
          "p_duree": <integer>,
            "p_type_soin": "<string>",
              "p_prix": <double>,
                "p_notes_additionnelles": "<string>",
                  "userJWT": "<string>",
                    "p_owner_id": "<string>"
                    }
                    ```

                    ---

                    ### `suggerer_creneaux`

                    Analyse l'agenda existant et suggère des créneaux optimaux en tenant compte de la localisation du patient.

                    **Endpoint** : `POST /rest/v1/rpc/suggerer_creneaux`

                    **Headers requis** :
                    ```
                    apikey: <SUPABASE_ANON_KEY>
                    Content-Type: application/json
                    Authorization: Bearer <userJWT>
                    ```

                    **Body** :
                    ```json
                    {
                      "p_owner_id": "<string>",
                        "p_date": "<string>",
                          "p_duree_minutes": <integer>,
                            "p_ville_patient": "<string>"
                            }
                            ```

                            **Retour** : `List<Json>` avec pour chaque créneau :
                            - `date` : date du créneau
                            - `heure` : heure de début
                            - `raison` : explication IA du choix du créneau

                            ---

                            ## Structure du dossier (à compléter)

                            ```
                            supabase/
                            ├── README.md                          ← Ce fichier
                            ├── migrations/                        ← Scripts SQL (à créer)
                            │   └── README.md
                            └── functions/                         ← Edge Functions (à créer)
                                ├── create_agenda_entry/
                                    └── suggerer_creneaux/
                                    ```

                                    > ℹ️ Les migrations SQL et le code source des Edge Functions doivent être ajoutés ici pour assurer la reproductibilité du projet. Actuellement, les fonctions sont déployées directement sur le projet Supabase sans être versionnées dans ce repo.

                                    ## Sécurité

                                    - Toutes les fonctions RPC vérifient le JWT avant traitement
                                    - Le `p_owner_id` est validé contre le JWT pour éviter l'usurpation
                                    - Les données retournées sont filtrées par `owner_id`

                                    ## Variables d'environnement requises

                                    Créer un fichier `.env.local` (jamais committer) :

                                    ```env
                                    SUPABASE_URL=https://anzgkxmxkcetzbjtjtuh.supabase.co
                                    SUPABASE_ANON_KEY=<votre_anon_key>
                                    SUPABASE_SERVICE_KEY=<votre_service_key>
                                    OPENAI_API_KEY=sk-...
                                    ```

                                    ## Prochaines étapes

                                    - [ ] Exporter le schéma SQL des tables Supabase existantes
                                    - [ ] Versionner le code source des fonctions RPC
                                    - [ ] Ajouter les migrations SQL pour reproductibilité
                                    - [ ] Documenter les politiques RLS en place
