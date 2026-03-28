# DÉCISIONS PRODUIT — Ma Clinique Pro V2

Format : [DATE] - Décision - Raison - Alternatives rejetées

---

## Architecture & Stack

### [2026-03] FlutterFlow comme frontend
**Décision** : Utiliser FlutterFlow pour toute l'interface (mobile + web)
**Raison** : Développement rapide, SDK Supabase natif, déploiement iOS/Android/Web simultané
**Alternatives rejetées** :
- Flutter natif : trop long à développer pour une V2 rapide
- React Native : pas de maîtrise dans l'équipe

---

### [2026-03] Supabase comme backend principal
**Décision** : Supabase (PostgreSQL + Auth + Edge Functions + Realtime)
**Raison** : All-in-one, RLS natif, Edge Functions Deno pour la couche IA, plan gratuit pour démarrer
**Alternatives rejetées** :
- Firebase : pas de SQL natif, moins adapté aux données relationnelles d'un agenda médical

---

### [2026-03] OpenAI comme moteur IA
**Décision** : OpenAI API (GPT-4o) via Edge Functions Supabase
**Raison** : Qualité de raisonnement, API stable, coût maîtrisé en V1
**Alternatives rejetées** :
- Mistral / LLaMA local : infrastructure trop complexe pour une V2 rapide
- Google Gemini : moins testé pour ce type de cas d'usage médical

---

## Sécurité & Multi-tenant

### [2026-03] RLS sur toutes les tables
**Décision** : Row Level Security activé sur chaque table Supabase
**Raison** : Isolation des données par clinique/praticienne sans logique applicative complexe
**Règle** : Toute nouvelle table DOIT avoir une politique RLS avant merge

---

### [2026-03] IA jamais en écriture
**Décision** : Les Edge Functions IA font uniquement des SELECT — jamais INSERT/UPDATE/DELETE
**Raison** : L'IA est un outil d'aide à la décision, pas un acteur autonome sur les données patients
**Règle** : Si une Edge Function IA tente d'écrire → rejet PR immédiat

---

### [2026-03] IA non-bloquante
**Décision** : Si l'appel IA échoue → fallback silencieux vers la vue manuelle
**Raison** : L'agenda doit fonctionner à 100% sans IA — la couche IA est une amélioration optionnelle
**Règle** : Aucun écran ne dépend d'une réponse IA pour s'afficher

---

## Notifications

### [2026-03] Système de notifications — Rappels flexibles
**Décision** : Rappels configurables par praticienne (0 à N rappels), copiés automatiquement dans chaque RDV
**Spec initiale abandonnée** : Rappels fixes J-1 / H-2 imposés à chaque rendez-vous
**Architecture retenue** :
- Table `appointment_reminders` — rappels associés à un RDV spécifique
- Table `practitioner_reminder_defaults` — configuration par défaut par praticienne
- Trigger automatique : copie les défauts dans chaque nouveau RDV
**Délais disponibles** : 10 min, 30 min, 1 h, 2 h, 24 h, 48 h avant le RDV
**Canal V1** : Push uniquement (FCM — Firebase Cloud Messaging)
**Canal V2** : SMS + email (Phase 2+)
**Raison** :
- Pas de friction dans le formulaire RDV
- Chaque praticienne configure ses défauts une seule fois dans ses paramètres
- 0 rappel = état valide (certaines praticiennes ne veulent pas de rappels)
**Règle** : L'Edge Function `/notify` ne fait jamais d'INSERT direct — elle lit `appointment_reminders` et déclenche l'envoi uniquement

---

## À Décider

| Sujet | Statut | Échéance |
|-------|--------|----------|
| Optimisation tournée (algo route) | En évaluation | Phase 2 |
| Intégration agenda externe (Google Cal) | Pas encore décidé | Phase 3 |
| Modèle de facturation SaaS | Pas encore décidé | Phase 3 |
