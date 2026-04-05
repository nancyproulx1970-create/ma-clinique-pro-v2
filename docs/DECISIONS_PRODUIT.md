# DÉCISIONS PRODUIT — Ma Clinique Pro V2

Format : [DATE] - Décision - Raison - Alternatives rejetées

> ⚠️ **Mise à jour [2026-04]** : Ce document a été révisé pour refléter l'architecture réelle du projet telle qu'observée dans FlutterFlow et Supabase. Des écarts importants existent entre la planification initiale et ce qui a été construit.
>
> ---
>
> ## Architecture & Stack
>
> ### [2026-03] FlutterFlow comme frontend
> **Décision** : Utiliser FlutterFlow pour toute l'interface (mobile + web)
> **Raison** : Développement rapide, SDK Supabase natif, déploiement iOS/Android/Web simultané
> **Alternatives rejetées** :
> - Flutter natif : trop long à développer pour une V2 rapide
> - - React Native : pas de maîtrise dans l'équipe
>  
>   - ### [2026-04] ⚠️ ÉCART — Firebase Firestore utilisé comme base principale (pas Supabase)
>   - **Décision réelle** : Firebase Firestore est la base de données principale utilisée dans FlutterFlow
>   - **Raison** : Le SDK Firebase est nativement intégré dans FlutterFlow et a été utilisé pour les collections principales
>   - **Collections Firebase créées** :
>   - - `patients` : dossiers patients complets
>     - - `users` : profils praticiens
>       - - `rendez_vous` : agenda et soins
>         - - `rendez_vous → photos` : sous-collection photos de soins
>           - **Supabase utilisé en parallèle** via API REST (RPC functions) pour :
>           - - `create_agenda_entry` : création de RDV dans Supabase
>             - - `suggerer_creneaux` : suggestions IA de créneaux
>               - **Conséquence** : Architecture hybride Firebase + Supabase, pas Supabase-only comme prévu
>              
>               - ### [2026-03] Supabase pour les fonctions IA et la logique agenda
>               - **Décision** : Supabase Edge Functions + RPC pour la couche IA et l'agenda
>               - **Raison** : Fonctions serverless Deno, appels RPC pour logique complexe
> **Implémenté** :
> - `create_agenda_entry` : RPC Supabase pour créer un RDV (paramètres : p_patient_Id, p_nom_patient, p_date, p_heure_debut, p_duree, p_type_soin, p_prix, p_notes_additionnelles, userJWT, p_owner_id)
> - - `suggerer_creneaux` : RPC Supabase pour suggestions IA (paramètres : p_owner_id, p_date, p_duree_minutes, p_ville_patient)
>  
>   - ### [2026-03] OpenAI comme moteur IA
>   - **Décision** : OpenAI API (GPT-4o-mini) via appel direct depuis FlutterFlow
>   - **Raison** : Qualité de raisonnement, API stable, coût maîtrisé en V1
>   - **Implémenté** : API Call `GenerateNoteAI` → `https://api.openai.com/v1/chat/completions`
>   - - Modèle : `gpt-4o-mini`
>     - - Temperature : 0.3
>       - - Variable : `noteUtilisateur` (dictée vocale ou texte libre)
>         - - Rôle système : assistant clinique intelligent pour professionnels de la santé, spécialisé en dictée vocale → notes cliniques structurées (observations, actes, recommandations)
>           - **Alternatives rejetées** :
>           - - Mistral / LLaMA local : infrastructure trop complexe
>             - - Google Gemini : moins testé pour cas d'usage médical
>              
>               - ---
>
> ## Domaine métier
>
> ### [2026-04] ⚠️ ÉCART — Application spécialisée podologie à domicile (pas clinique générique)
> **Décision réelle** : L'application est conçue spécifiquement pour des **podologues / infirmières en soins podologiques à domicile** au Québec
> **Éléments observés qui confirment cette spécialisation** :
> - Champs patients : `rx_actuelle`, `rx_photo_url`, `rx_mise_a_jour` (prescriptions)
> - - Photos de soins avec métadonnées : `categorie`, `moment`, `cote`, `vue`, `orteil`
>   - - Bilan de santé : Diabète, Vasculaire, Neuropathie, antécédents médicaux spécifiques
>     - - Reçu de paiement : TPS (5%) + TVQ (9,975%) — fiscal québécois
>       - - Profil praticien : `infirmiere_nom`, `titre_pro`, `numero_permis`, `signature_url`
>         - - Optimization de tournée : ancres Domicile + Centre de Stérilisation
>           - - Collection `rendez_vous` → champ `bilan_ou_suivi` (type de visite)
>            
>             - ---
>
> ## Fonctionnalités IA
>
> ### [2026-04] GenerateNoteAI — Notes cliniques via dictée vocale
> **Décision** : Intégration directe de l'API OpenAI dans FlutterFlow via API Call
> **Flux** : Praticienne dicte ou écrit une observation → bouton "Améliorer IA" → GPT-4o-mini structure la note → affichage dans zone "Suggestion IA"
> **Page** : `NoteObservationCopy`
> **Statut** : ✅ Opérationnel
>
> ### [2026-04] suggererCreneaux — Suggestion IA de créneaux
> **Décision** : RPC Supabase `suggerer_creneaux` appelé depuis FlutterFlow
> **Flux** : Praticienne ouvre `BottomSheet_Propositions` → saisit ville + durée → clique "Voir les suggestions" → liste de créneaux avec date, raison, heure
> **Variables App State** : `propositionResultats (List<Json>)`, `propositionVille`, `propositionDureeMinutes`
> **Statut** : ✅ Opérationnel (interface complète)
>
> ### [2026-04] Assistant Logistique IA — Optimisation de tournée
> **Décision** : Module de planification de tournée avec ancres configurables
> **Flux** : Configuration Domicile (départ/retour) + Centre de Stérilisation (passage obligatoire) → IA organise la tournée en optimisant trajets GPS + contraintes horaires
> **Page** : `ParametresAgenda`
> **Statut** : ✅ Interface opérationnelle (Phase 3 avancée par rapport au plan initial)
>
> ---
>
> ## Sécurité & Multi-tenant
>
> ### [2026-03] RLS sur toutes les tables Supabase
> **Décision** : Row Level Security activé sur chaque table Supabase
> **Raison** : Isolation des données par clinique/praticienne sans logique applicative complexe
> **Règle** : Toute nouvelle table DOIT avoir une politique RLS avant merge
> **Note** : Firebase utilise les Security Rules comme équivalent pour les collections Firestore
>
> ### [2026-03] IA jamais en écriture
> **Décision** : Les fonctions IA font uniquement des SELECT — jamais INSERT/UPDATE/DELETE
> **Raison** : L'IA est un outil d'aide à la décision, pas un acteur autonome sur les données patients
> **Règle** : Si une fonction IA tente d'écrire → rejet PR immédiat
>
> ### [2026-03] IA non-bloquante
> **Décision** : Si l'appel IA échoue → fallback silencieux vers la vue manuelle
> **Raison** : L'agenda doit fonctionner à 100% sans IA — la couche IA est une amélioration optionnelle
> **Règle** : Aucun écran ne dépend d'une réponse IA pour s'afficher
>
> ---
>
> ## Notifications
>
> ### [2026-03] Système de notifications — Rappels flexibles
> **Décision** : Rappels configurables par praticienne
> **Architecture retenue** :
> - Table `appointment_reminders` — rappels associés à un RDV spécifique
> - - Table `practitioner_reminder_defaults` — configuration par défaut par praticienne
>   - - Trigger automatique : copie les défauts dans chaque nouveau RDV
>     - - Canal V1 : Push uniquement (FCM)
>       - - Canal V2 : SMS + email (Phase 2+)
>         - **Statut** : 📋 Planifié — non encore implémenté dans Firebase/FlutterFlow
>        
>         - ---
>
> ## Paiement & Fiscal
>
> ### [2026-04] Reçu de paiement avec taxes québécoises
> **Décision** : Génération de reçus professionnels avec TPS + TVQ
> **Raison** : Contexte fiscal québécois, professionnel de santé indépendant
> **Implémenté** : Page `RecuPaiement` avec TPS (5%), TVQ (9,975%), total, solde
> **Statut** : ✅ Interface opérationnelle
>
> ---
>
> ## À Décider
>
> | Sujet | Statut | Échéance |
> |-------|--------|----------|
> | Migration Firebase → Supabase ou maintien hybride | 🔴 Décision urgente | Phase 2 |
> | Intégration agenda externe (Google Cal) | Pas encore décidé | Phase 3 |
> | Modèle de facturation SaaS | Pas encore décidé | Phase 3 |
> | Notifications push (FCM) — implémentation | En attente | Phase 2 |
> | Authentification multi-rôles (admin, praticien, secrétaire) | En attente | Phase 2 |
