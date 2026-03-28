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
- Backend custom (Node.js) : trop de maintenance pour une équipe réduite

---

### [2026-03] OpenAI comme provider IA principal
**Décision** : OpenAI API (GPT-4o-mini pour la production)
**Raison** : Meilleure qualité de réponse structurée JSON, latence acceptable, coût contrôlé avec mini
**Alternatives rejetées** :
- Mistral : envisagé comme fallback si coûts OpenAI trop élevés
- Modèle local : trop complexe à héberger pour une V2

**Plan B** : Mistral API activée si coût OpenAI > 50$/mois

---

### [2026-03] Architecture multi-tenant par clinic_id (pas de schéma séparé)
**Décision** : Toutes les tables ont un clinic_id + RLS par clinic_id
**Raison** : Plus simple à maintenir, migrations plus faciles, Supabase gère bien la séparation via RLS
**Alternatives rejetées** :
- Un schéma PostgreSQL par clinique : trop complexe à gérer avec Supabase
- Un projet Supabase par clinique : trop cher et complexe à l'onboarding

---

## Modèle de Données

### [2026-03] Table slots pré-calculée vs calcul à la volée
**Décision** : Calcul des slots à la volée depuis day_settings (pas de table slots pré-remplie)
**Raison** : Évite la synchronisation entre day_settings et slots si horaires changent
**Note** : Si performances insuffisantes → table slots avec cache Redis (reconsidérer en Phase 2)

---

### [2026-03] Coordonnées GPS sur la table patients
**Décision** : Champs lat/lng directement sur patients (pas de table addresses séparée)
**Raison** : Simplicité pour la Phase 1. Une adresse par patient suffit pour la V2.
**Évolution prévue** : Table addresses séparée si multi-adresses nécessaire en Phase 3+

---

## IA

### [2026-03] IA jamais en écriture directe
**Décision** : Les Edge Functions IA font uniquement des SELECT. Aucun INSERT/UPDATE depuis l'IA.
**Raison** : Sécurité et traçabilité. Toute action IA doit être validée par un humain.
**Règle** : Cette décision est NON négociable pour toutes les phases.

---

### [2026-03] Fallback gracieux si IA indisponible
**Décision** : Si l'appel IA échoue (timeout, erreur API), l'UI affiche la vue manuelle sans message d'erreur visible
**Raison** : L'IA est un bonus, pas une dépendance critique
**Implémentation** : try/catch dans Edge Function, réponse vide → FlutterFlow affiche la grille standard

---

### [2026-03] Logs IA dans table ia_logs (pas dans les RDV)
**Décision** : Les métadonnées IA (tokens, latence, score) stockées dans ia_logs, pas dans appointments
**Raison** : Séparation des responsabilités. appointments reste propre et simple.
**Exception** : Champ ia_suggested (boolean) et ia_score (int) restent dans appointments pour filtrage rapide.

---

## UX / Produit

### [2026-03] Vue calendrier par défaut = Semaine
**Décision** : La vue par défaut de l'agenda est la vue semaine (7 jours)
**Raison** : Meilleure vision d'ensemble pour la secrétaire / praticien
**Option** : Praticien peut changer sa préférence de vue dans les paramètres

---

### [2026-03] Pas de patient self-booking en Phase 1
**Décision** : Phase 1 = prise de RDV par la secrétaire uniquement
**Raison** : Simplifier la V2 et valider le core avant d'ouvrir au patient
**Phase 5** : Patient self-booking avec page publique + validation praticien

---

### [2026-03] Statuts RDV : 5 états
**Décision** : scheduled → confirmed → completed | cancelled | no_show
**Raison** : Couvre 95% des cas cliniques sans complexité inutile
**Règle** : Pas d'ajout de statuts sans discussion d'équipe documentée ici

---

## À Décider

| Sujet | Deadline | Responsable |
|-------|----------|-------------|
| Provider SMS pour rappels (Twilio vs AWS SNS) | Sprint 2 | Tech lead |
| Plan Stripe pour facturation SaaS | Sprint 6 | Fondateur |
| Langue de l'interface IA (FR ou EN prompt) | Sprint 3 | Product |
| RGPD / Loi 25 Québec - données patients | Avant prod | Légal |
