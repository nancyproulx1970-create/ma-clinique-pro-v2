# ARCHITECTURE AGENDA IA — Ma Clinique Pro V2

## Stack Technique

| Couche | Technologie | Rôle |
|--------|-------------|------|
| Frontend | FlutterFlow | UI/UX mobile & web |
| Backend | Supabase (PostgreSQL) | Base de données, Auth, Realtime |
| Serverless | Supabase Edge Functions (Deno) | Logique métier, appels IA |
| IA | OpenAI API / Mistral AI | Suggestions, optimisation, aide décision |
| Storage | Supabase Storage | Documents, photos patients |
| Auth | Supabase Auth (JWT) | Authentification multi-rôles |

---

## Architecture Globale

```
FlutterFlow App
     │
     ├── Supabase Client (SDK Flutter)
     │        ├── Auth → Row Level Security (RLS)
     │        ├── Database → Tables PostgreSQL
     │        ├── Realtime → Subscriptions agenda live
     │        └── Storage → Documents
     │
     └── Edge Functions (Deno)
              ├── /suggest-slot → IA : suggestion créneaux
              ├── /optimize-route → IA : optimisation tournée
              ├── /decision-helper → IA : aide décision clinicien
              └── /notify → Notifications push / SMS
```

---

## Modules Fonctionnels

### 1. Agenda Core
- Gestion des rendez-vous (CRUD)
- Slots disponibles par praticien / salle
- Paramètres de journée (horaires, pauses, durées par type)
- Vue calendrier jour / semaine / mois

### 2. Couche IA (Edge Functions)
- Suggestion de créneaux : analyse dispo + historique patient + préférences praticien
- Optimisation tournée : pour visites à domicile, calcul itinéraire optimal
- Aide décision : alertes sur conflits, surcharge, rappels de suivi

### 3. Multi-rôles
- Admin clinique : gestion globale
- Praticien : agenda personnel
- Secrétaire : prise de RDV
- Patient : auto-booking (phase 2)

### 4. Notifications
- Rappels automatiques (J-1, H-2)
- Confirmation RDV
- Alertes internes (annulation, modification)

---

## Flux de Données — Prise de RDV avec IA

1. Secrétaire ouvre le formulaire RDV
2. FlutterFlow → Edge Function /suggest-slot
3. Edge Function → Supabase DB (slots dispo, historique)
4. Edge Function → OpenAI API (analyse + suggestion)
5. Réponse : liste de créneaux suggérés avec score
6. Secrétaire valide → INSERT rendez-vous en DB
7. Supabase Realtime → mise à jour agenda en temps réel
8. Edge Function /notify → SMS/Push confirmation

---

## Sécurité et RLS

- Chaque praticien ne voit que ses propres RDV
- Admin voit tout
- RLS activé sur toutes les tables sensibles
- JWT vérifié côté Edge Function avant tout appel IA

---

## Environnements

| Env | Usage |
|-----|-------|
| dev | Développement local |
| staging | Tests QA |
| prod | Production |
