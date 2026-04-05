# MODÈLE DE DONNÉES — Ma Clinique Pro V2

> ⚠️ **Mise à jour [2026-04]** : Ce document reflète l'architecture réelle observée dans le projet FlutterFlow. Le backend principal est **Firebase Firestore** (pas Supabase). Supabase est utilisé en parallèle via RPC pour la logique IA et l'agenda.
>
> ---
>
> ## Vue d'ensemble de l'architecture de données
>
> ```
> Firebase Firestore (base principale)
> ├── users/                          → Profils praticiens
> ├── patients/                       → Dossiers patients
> └── rendez_vous/                    → Soins et rendez-vous
>     └── photos/                     → Photos de soins (sous-collection)
>
> Supabase PostgreSQL (logique IA + agenda)
> ├── RPC: create_agenda_entry        → Création de RDV dans Supabase
> └── RPC: suggerer_creneaux          → Suggestions IA de créneaux
> ```
>
> ---
>
> ## Firebase Firestore
>
> ### Collection : `users`
> Profils des praticiens (infirmières / podologues)
>
> | Champ | Type | Description |
> |-------|------|-------------|
> | `email` | String | Courriel de connexion |
> | `photo_url` | Image Path | Photo de profil |
> | `uid` | String | Identifiant Firebase Auth |
> | `created_time` | DateTime | Date de création du compte |
> | `phone_number` | String | Téléphone professionnel |
> | `infirmiere_nom` | String | Nom complet de l'infirmière/podologue |
> | `titre_pro` | String | Titre professionnel (ex: inf., pod.) |
> | `nom_entreprise` | String | Nom de l'entreprise/clinique |
> | `numero_permis` | String | Numéro de permis professionnel |
> | `signature_url` | Image Path | URL de la signature numérique |
> | `display_name` | String | Nom affiché dans l'app |
> | `prenom` | String | Prénom |
> | `nom` | String | Nom de famille |
>
> ---
>
> ### Collection : `patients`
> Dossiers complets des patients
>
> | Champ | Type | Description |
> |-------|------|-------------|
> | `nom` | String | Nom de famille |
> | `prenom` | String | Prénom |
> | `nom_complet` | String | Nom complet (prénom + nom) |
> | `nom_complet_lower` | String | Nom complet en minuscules (recherche) |
> | `nom_search` | String | Champ de recherche optimisé |
> | `date_naissance` | DateTime | Date de naissance |
> | `adresse` | String | Numéro et rue |
> | `ville` | String | Ville |
> | `code_postal` | String | Code postal |
> | `telephone` | String | Téléphone |
> | `courriel` | String | Adresse courriel |
> | `clinicId` | String | Identifiant de la clinique (multi-tenant) |
> | `rx_actuelle` | String | Médication / prescription actuelle (texte) |
> | `rx_photo_url` | String | URL photo de l'ordonnance |
> | `rx_mise_a_jour` | DateTime | Date de mise à jour de la prescription |
>
> **Notes** :
> - `nom_complet_lower` et `nom_search` permettent la recherche insensible à la casse
> - - `clinicId` assure l'isolation des données par praticienne (multi-tenant)
>   - - Les champs `rx_*` sont spécifiques aux soins podologiques (prescriptions)
>    
>     - ---
>
> ### Collection : `rendez_vous`
> Soins et rendez-vous. Table centrale du système.
>
> | Champ | Type | Description |
> |-------|------|-------------|
> | `nom_patient` | String | Nom du patient (dénormalisé) |
> | `date_rdv` | DateTime | Date et heure du rendez-vous |
> | `heure_fin` | DateTime | Heure de fin calculée |
> | `duree_minutes` | Integer | Durée du soin en minutes |
> | `type_soin` | String | Type de soin (ex: soins podologiques) |
> | `bilan_ou_suivi` | String | Type de visite : "Bilan" ou "Suivi" |
> | `prix` | Double | Prix du soin (avant taxes) |
> | `notes` | String | Notes d'observation clinique |
> | `statut_note` | String | Statut de la note (ex: brouillon, final) |
> | `soin_effectue` | Boolean | Soin complété ou non |
> | `date_soin_effectue` | DateTime | Date/heure de complétion du soin |
> | `patientRef` | Doc Reference (patients) | Référence vers le document patient |
> | `uid` | String | UID de la praticienne propriétaire |
> | `email` | String | Courriel de la praticienne |
> | `display_name` | String | Nom de la praticienne |
> | `photo_url` | Image Path | Photo de la praticienne |
> | `phone_number` | String | Téléphone de la praticienne |
> | `created_time` | DateTime | Date de création du RDV |
>
> **Notes** :
> - Les champs `uid`, `email`, `display_name` dénormalisent les infos de la praticienne pour les requêtes sans JOIN
> - - `bilan_ou_suivi` distingue les bilans annuels des soins de suivi réguliers
>   - - `statut_note` gère le cycle de vie des notes cliniques (IA ou manuelles)
>    
>     - ---
>
> ### Sous-collection : `rendez_vous → photos`
> Photos prises lors d'un soin, avec métadonnées podologiques
>
> | Champ | Type | Description |
> |-------|------|-------------|
> | `imageUrl` | String | URL de la photo (Firebase Storage) |
> | `categorie` | String | Catégorie de la photo (ex: avant, après) |
> | `moment` | String | Moment de la prise (ex: début, fin) |
> | `cote` | String | Côté : gauche / droit |
> | `vue` | String | Vue : dorsale / plantaire / latérale |
> | `orteil` | String | Orteil concerné (ex: hallux, 2e, 3e...) |
> | `patientRef` | Doc Reference (patients) | Référence vers le patient |
> | `rdvRef` | Doc Reference (rendez_vous) | Référence vers le RDV |
> | `createdAt` | DateTime | Date de création |
>
> **Notes** :
> - Structure spécialisée pour la podologie : `cote`, `vue`, `orteil` sont des métadonnées cliniques
> - - Toutes les photos sont stockées dans Firebase Storage
>  
>   - ---
>
> ## Supabase PostgreSQL
>
> ### Fonction RPC : `create_agenda_entry`
> Crée une entrée dans l'agenda Supabase (en complément de Firebase)
>
> **Endpoint** : `POST https://anzgkxmxkcetzbjtjtuh.supabase.co/rest/v1/rpc/create_agenda_entry`
>
> **Paramètres** :
> | Paramètre | Type | Description |
> |-----------|------|-------------|
> | `p_patient_Id` | String | ID du patient |
> | `p_nom_patient` | String | Nom du patient |
> | `p_date` | String | Date du RDV |
> | `p_heure_debut` | String | Heure de début |
> | `p_duree` | Integer | Durée en minutes |
> | `p_type_soin` | String | Type de soin |
> | `p_prix` | Double | Prix du soin |
> | `p_notes_additionnelles` | String | Notes cliniques |
> | `userJWT` | String | JWT de l'utilisateur (auth) |
> | `p_owner_id` | String | ID de la praticienne propriétaire |
>
> ---
>
> ### Fonction RPC : `suggerer_creneaux`
> Suggère des créneaux optimaux selon la ville et la durée du soin
>
> **Endpoint** : `POST https://anzgkxmxkcetzbjtjtuh.supabase.co/rest/v1/rpc/suggerer_creneaux`
>
> **Paramètres** :
> | Paramètre | Type | Description |
> |-----------|------|-------------|
> | `p_owner_id` | String | ID de la praticienne |
> | `p_date` | String | Date souhaitée |
> | `p_duree_minutes` | Integer | Durée du soin en minutes |
> | `p_ville_patient` | String | Ville du patient (pour optimisation tournée) |
>
> **Retour** : `List<Json>` — liste de créneaux avec date, heure, raison (score IA)
>
> ---
>
> ## App State — Variables globales FlutterFlow
>
> Variables persistées dans l'app (gestion de l'état global) :
>
> | Variable | Type | Persisté | Description |
> |----------|------|----------|-------------|
> | `userLogo` | Image Path | true | Logo de la praticienne |
> | `nomChoisi` | String | false | Nom de praticienne sélectionné |
> | `abreviationChoisie` | String | false | Abréviation de praticienne |
> | `isLoggedIn` | Boolean | true | État de connexion |
> | `userEmail` | String | true | Courriel utilisateur |
> | `dateCreation` | DateTime | true | Date de création du compte |
> | `patientSelectionne` | Boolean | false | Patient sélectionné pour RDV |
> | `selectedPatientName` | String | false | Nom du patient sélectionné |
> | `heuresJournee` | List\<String\> | false | Créneaux horaires de la journée |
> | `selectedDate` | DateTime | false | Date sélectionnée dans l'agenda |
> | `selectedDateTime` | DateTime | false | Date+heure sélectionnées |
> | `selectedTimeStr` | String | false | Heure sélectionnée (format texte) |
> | `selectedPatientId` | Integer | false | ID du patient sélectionné |
> | `weekStartDate` | DateTime | false | Début de semaine du calendrier |
> | `weekStartsOnSunday` | Boolean | true | Semaine commence dimanche |
> | `dureeSelectionneeMinutes` | Integer | false | Durée de soin sélectionnée |
> | `selectedRendezVousId` | String | false | ID du RDV sélectionné |
> | `propositionVille` | String | false | Ville pour suggestion IA |
> | `propositionDureeMinutes` | Integer | false | Durée pour suggestion IA |
> | `propositionResultats` | List\<Json\> | false | Résultats des suggestions IA |
>
> ---
>
> ## Modèle prévu (Supabase-only) vs Réalité
>
> | Élément planifié | Statut réel |
> |-----------------|-------------|
> | Table `clinics` (Supabase) | ❌ Non créée — remplacée par `clinicId` dans Firebase |
> | Table `practitioners` (Supabase) | ❌ Non créée — collection `users` dans Firebase |
> | Table `patients` (Supabase) | ❌ Non créée — collection `patients` dans Firebase |
> | Table `appointments` (Supabase) | ⚠️ Partiel — `rendez_vous` Firebase + RPC `create_agenda_entry` Supabase |
> | Table `service_types` (Supabase) | ❌ Non créée — type_soin comme champ texte libre |
> | Table `day_settings` (Supabase) | ❌ Non créée — logique dans `ParametresAgenda` |
> | Table `slots` (Supabase) | ❌ Non créée — gérée par RPC `suggerer_creneaux` |
> | Table `rooms` (Supabase) | ❌ Non applicable — soins à domicile |
> | RPC `create_agenda_entry` | ✅ Opérationnel |
> | RPC `suggerer_creneaux` | ✅ Opérationnel |
> | Photos de soins avec métadonnées | ✅ Implémenté (Firebase Storage + Firestore) |
> | Bilan de santé annuel | ✅ Implémenté (`BilanDeSante_V3`) |
> | Reçu de paiement avec taxes QC | ✅ Implémenté (`RecuPaiement`) |
