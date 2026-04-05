# ROADMAP AGENDA IA — Ma Clinique Pro V2

> ⚠️ **Mise à jour [2026-04]** : La roadmap a été révisée pour refléter l'état réel du projet. Plusieurs fonctionnalités de phases 2 et 3 ont été développées en avance sur le plan initial.
>
> ---
>
> ## Statut des Phases (révisé)
>
> | Phase | Nom | Statut | Notes |
> |-------|-----|--------|-------|
> | 1 | Base Agenda (sans IA) | 🟡 En cours | Noyau fonctionnel, quelques éléments à compléter |
> | 2 | Couche IA - Notes et Créneaux | ✅ Partiellement opérationnel | GenerateNoteAI + suggererCreneaux en production |
> | 3 | Optimisation Tournée | ✅ Interface opérationnelle | Assistant Logistique IA livré en avance |
> | 4 | Multi-cliniques / SaaS | 📋 À faire | Sprint 6-7 |
> | 5 | Patient Self-Booking | 📋 À faire | Sprint 8 |
>
> ---
>
> ## Phase 1 — Base Agenda (Sprint 1-2)
>
> ### Objectif
> Agenda fonctionnel. Prise de RDV manuelle, gestion des soins, vues calendrier, dossier patient.
>
> ### Livré ✅
> - [x] Architecture Firebase Firestore (patients, users, rendez_vous, photos)
> - [ ] - [x] Authentification Firebase Auth
> - [ ] - [x] CRUD patients complet (`AjouterPatient`, `ListePatients`, `DossierPatient`)
> - [ ] - [x] CRUD rendez-vous (`AddAppointments`, `AppointmentDetails`)
> - [ ] - [x] Vue calendrier (`Page_Calendrier` avec `AgendaPremiumWidget`)
> - [ ] - [x] Vue hebdomadaire (weekStartDate, weekStartsOnSunday dans App State)
> - [ ] - [x] Dossier patient complet avec historique des visites
> - [ ] - [x] Détail de visite avec photos (`DetailVisite`)
> - [ ] - [x] Prise de photos de soins avec métadonnées podologiques (côté, vue, orteil)
> - [ ] - [x] Bilan de santé annuel (`BilanDeSante_V3`) avec antécédents médicaux
> - [ ] - [x] Profil praticien (`ProfileSetup`, `GuardProfileSetup`)
> - [ ] - [x] LockScreen / Connexion / ResetPassword
> - [ ] - [x] Reçu de paiement avec TPS + TVQ québécoises (`RecuPaiement`)
> - [ ] - [x] BottomSheet créneaux (`BottomSheet_Creneaux`)
> - [ ] - [x] BottomSheet domicile (`BottomSheet_Domicile`)
> - [ ] - [x] BottomSheet stérilisation (`BottomSheet_Sterilisation`)
> - [ ] - [x] Notifications push basiques (architecture FCM planifiée)
>
> - [ ] ### En cours / À compléter 🟡
> - [ ] - [ ] RLS / Security Rules Firebase (à auditer)
> - [ ] - [ ] Auth multi-rôles (admin, praticien, secrétaire)
> - [ ] - [ ] Paramètres journée par praticien (day_settings)
> - [ ] - [ ] Configuration environnements dev/staging/prod (#12)
>
> - [ ] ---
>
> - [ ] ## Phase 2 — Couche IA : Notes et Créneaux (Sprint 3-4)
>
> - [ ] ### Objectif
> - [ ] IA pour notes cliniques (dictée vocale) et suggestions de créneaux intelligents.
>
> - [ ] ### Livré ✅
> - [ ] - [x] `GenerateNoteAI` — API OpenAI GPT-4o-mini pour notes cliniques
> - [ ]   - Page `NoteObservationCopy` avec dictée vocale → note structurée
> - [ ]     - Bouton "Améliorer IA", zone "Suggestion IA"
> - [ ]   - Temperature 0.3, prompt système spécialisé santé
> - [ ]   - [x] `suggererCreneaux` — RPC Supabase `suggerer_creneaux`
> - [ ]     - BottomSheet_Propositions : ville + durée → liste de créneaux
> - [ ]   - Variables App State : propositionResultats, propositionVille, propositionDureeMinutes
> - [ ]   - [x] `CreateAgendaEntry` — RPC Supabase `create_agenda_entry`
> - [ ]     - Création de RDV dans Supabase avec JWT auth
>
> - [ ] ### À compléter 🟡
> - [ ] - [ ] Tests unitaires sur la logique de suggestion
> - [ ] - [ ] Logs des suggestions pour amélioration continue
> - [ ] - [ ] Score de pertinence affiché dans l'interface
> - [ ] - [ ] Tableau de bord IA — aide à la décision clinicien (#10)
> - [ ] - [ ] Gestion des patients CRUD complet (#11)
>
> - [ ] ---
>
> - [ ] ## Phase 3 — Optimisation Tournée (Sprint 5)
>
> - [ ] ### Objectif
> - [ ] Pour les soins à domicile : calculer l'ordre optimal des visites journalières.
>
> - [ ] ### Livré en avance ✅
> - [ ] - [x] `ParametresAgenda` — Assistant Logistique IA
> - [ ]   - Configuration ancre Domicile (point départ/retour)
> - [ ]     - Configuration Centre de Stérilisation (passage obligatoire)
> - [ ]   - Préférences de planification (heure de début, nombre de patients)
> - [ ]     - Description : "L'IA organise automatiquement vos tournées en optimisant les trajets GPS et en respectant vos contraintes horaires"
>
> - [ ] ### À compléter 🟡
> - [ ] - [ ] Intégration API géolocalisation (Google Maps ou OpenRoute)
> - [ ] - [ ] Export tournée (PDF ou lien partageable)
> - [ ] - [ ] Edge Function /optimize-route opérationnelle (#9)
>
> - [ ] ---
>
> - [ ] ## Phase 4 — Multi-cliniques SaaS (Sprint 6-7)
>
> - [ ] ### Objectif
> - [ ] Support de plusieurs cliniques indépendantes avec isolation des données.
>
> - [ ] ### Livré partiellement ✅
> - [ ] - [x] `clinicId` sur la collection `patients` (isolation basique)
>
> - [ ] ### À faire 📋
> - [ ] - [ ] Tableau de bord admin par clinique
> - [ ] - [ ] Facturation par clinique (Stripe ou équivalent)
> - [ ] - [ ] Onboarding automatisé nouvelle clinique
> - [ ] - [ ] Décision architecture : Firebase multi-tenant vs Supabase
>
> - [ ] ---
>
> - [ ] ## Phase 5 — Patient Self-Booking (Sprint 8)
>
> - [ ] ### Objectif
> - [ ] Permettre aux patients de prendre RDV eux-mêmes via l'app ou un lien public.
>
> - [ ] ### À faire 📋
> - [ ] - [ ] Page publique de prise de RDV (sans connexion)
> - [ ] - [ ] Validation praticien avant confirmation
> - [ ] - [ ] Rappels automatiques patient (SMS / email)
> - [ ] - [ ] Annulation libre jusqu'à J-1
>
> - [ ] ---
>
> - [ ] ## Pages FlutterFlow — Inventaire complet
>
> - [ ] | Page / Composant | Type | Statut | Description |
> - [ ] |-----------------|------|--------|-------------|
> - [ ] | `Connexion` | Page | ✅ | Login Firebase Auth |
> - [ ] | `ResetPassword` | Page | ✅ | Réinitialisation mot de passe |
> - [ ] | `LockScreen` | Page | ✅ | Écran de verrouillage |
> - [ ] | `ProfileSetup` | Page | ✅ | Configuration profil praticien |
> - [ ] | `GuardProfileSetup` | Page | ✅ | Garde du profil (redirection si incomplet) |
> - [ ] | `Accueil` | Page | ✅ | Page d'accueil principale |
> - [ ] | `Page_Calendrier` | Page | ✅ | Calendrier mensuel + hebdomadaire (AgendaPremiumWidget) |
> - [ ] | `AddAppointments` | Page | ✅ | Formulaire ajout rendez-vous |
> - [ ] | `AppointmentDetails` | Page | ✅ | Détail d'un rendez-vous |
> - [ ] | `AjouterPatient` | Page | ✅ | Formulaire nouveau patient |
> - [ ] | `ListePatients` | Page | ✅ | Liste et recherche patients |
> - [ ] | `DossierPatient` | Page | ✅ | Dossier complet + historique soins |
> - [ ] | `DetailVisite` | Page | ✅ | Détail d'un soin + photos |
> - [ ] | `NoteObservationCopy` | Page | ✅ | Notes cliniques + IA (GenerateNoteAI) |
> - [ ] | `BilanDeSante_V3` | Page | ✅ | Bilan de santé annuel podologique |
> - [ ] | `ParametresAgenda` | Page | ✅ | Assistant Logistique IA + ancres tournée |
> - [ ] | `RecuPaiement` | Page | ✅ | Reçu de paiement TPS+TVQ |
> - [ ] | `BottomSheet_Propositions` | Composant | ✅ | Suggestions créneaux IA |
> - [ ] | `BottomSheet_Creneaux` | Composant | ✅ | Sélection de créneaux |
> - [ ] | `BottomSheet_Domicile` | Composant | ✅ | Configuration ancre domicile |
> - [ ] | `BottomSheet_Sterilisation` | Composant | ✅ | Configuration ancre stérilisation |
>
> - [ ] ---
>
> - [ ] ## API Calls — Inventaire
>
> - [ ] | Nom | Méthode | Endpoint | Statut |
> - [ ] |-----|---------|----------|--------|
> - [ ] | `CreateAgendaEntry` | POST | `supabase.co/rest/v1/rpc/create_agenda_entry` | ✅ Opérationnel |
> - [ ] | `suggererCreneaux` | POST | `supabase.co/rest/v1/rpc/suggerer_creneaux` | ✅ Opérationnel |
> - [ ] | `GenerateNoteAI` | POST | `api.openai.com/v1/chat/completions` | ✅ Opérationnel |
>
> - [ ] ---
>
> - [ ] ## Dépendances Techniques
>
> - [ ] | Dépendance | Pourquoi | Phase | Statut |
> - [ ] |-----------|---------|-------|--------|
> - [ ] | Firebase Auth | Authentification | Phase 1 | ✅ En production |
> - [ ] | Firebase Firestore | Base de données principale | Phase 1 | ✅ En production |
> - [ ] | Firebase Storage | Photos de soins | Phase 1 | ✅ En production |
> - [ ] | Supabase (project `anzgkxmxkcetzbjtjtuh`) | RPC IA + agenda | Phase 1-2 | ✅ En production |
> - [ ] | OpenAI API (GPT-4o-mini) | Notes cliniques IA | Phase 2 | ✅ En production |
> - [ ] | Google Maps API | Optimisation tournée | Phase 3 | 📋 À intégrer |
> - [ ] | Stripe | Facturation SaaS | Phase 4 | 📋 À intégrer |
>
> - [ ] ---
>
> - [ ] ## Critères de Qualité
>
> - [ ] - Temps de réponse `GenerateNoteAI` < 3s
> - [ ] - Temps de réponse `suggererCreneaux` < 2s
> - [ ] - Firebase Security Rules vérifiées sur toutes les collections
> - [ ] - Aucune donnée patient exposée entre praticiens
> - [ ] - Reçu de paiement conforme TPS/TVQ Québec
