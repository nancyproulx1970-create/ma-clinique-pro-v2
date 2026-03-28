# ROADMAP AGENDA IA — Ma Clinique Pro V2

## Statut des Phases

| Phase | Nom | Statut | Deadline |
|-------|-----|--------|----------|
| 1 | Base Agenda (sans IA) | En cours | Sprint 1-2 |
| 2 | Couche IA - Suggestions | À faire | Sprint 3-4 |
| 3 | Optimisation Tournée | À faire | Sprint 5 |
| 4 | Multi-cliniques / SaaS | À faire | Sprint 6-7 |
| 5 | Patient Self-Booking | À faire | Sprint 8 |

---

## Phase 1 — Base Agenda (Sprint 1-2)

### Objectif
Agenda fonctionnel sans IA. Prise de RDV manuelle, gestion des slots, vues calendrier.

### Livrables
- [ ] Modèle de données Supabase (rendez-vous, slots, praticiens, patients)
- [ ] RLS configuré sur toutes les tables
- [ ] Auth multi-rôles (admin, praticien, secrétaire)
- [ ] CRUD rendez-vous dans FlutterFlow
- [ ] Vue calendrier jour / semaine
- [ ] Paramètres journée par praticien (horaires, durées, pauses)
- [ ] Notifications push basiques (confirmation RDV)

---

## Phase 2 — Couche IA : Suggestions de Créneaux (Sprint 3-4)

### Objectif
Edge Function qui analyse les dispos et suggère les meilleurs créneaux.

### Livrables
- [ ] Edge Function /suggest-slot opérationnelle
- [ ] Intégration OpenAI API (ou Mistral) avec prompt structuré
- [ ] Score de pertinence par créneau suggéré
- [ ] Interface FlutterFlow affichant les suggestions
- [ ] Logs des suggestions pour amélioration continue
- [ ] Tests unitaires sur la logique de suggestion

### Logique IA
- Input : type de soin, durée, praticien, préférences patient, historique
- Output : liste de créneaux avec score (0-100) + raison

---

## Phase 3 — Optimisation Tournée (Sprint 5)

### Objectif
Pour les soins à domicile : calculer l'ordre optimal des visites.

### Livrables
- [ ] Edge Function /optimize-route opérationnelle
- [ ] Intégration API géolocalisation (Google Maps ou OpenRoute)
- [ ] Interface de validation de tournée pour praticien
- [ ] Export tournée (PDF ou lien partageable)

---

## Phase 4 — Multi-cliniques SaaS (Sprint 6-7)

### Objectif
Support de plusieurs cliniques indépendantes avec isolation des données.

### Livrables
- [ ] Concept multi-tenant dans Supabase (clinic_id sur toutes les tables)
- [ ] Tableau de bord admin par clinique
- [ ] Facturation par clinique (Stripe ou équivalent)
- [ ] Onboarding automatisé nouvelle clinique

---

## Phase 5 — Patient Self-Booking (Sprint 8)

### Objectif
Permettre aux patients de prendre RDV eux-mêmes via l'app ou un lien public.

### Livrables
- [ ] Page publique de prise de RDV (sans connexion)
- [ ] Validation praticien avant confirmation
- [ ] Rappels automatiques patient (SMS / email)
- [ ] Annulation libre jusqu'à J-1

---

## Dépendances Techniques

| Dépendance | Pourquoi | Phase |
|------------|----------|-------|
| Supabase pro plan | Edge Functions + Realtime | Phase 1 |
| OpenAI API key | Suggestions IA | Phase 2 |
| Google Maps API | Optimisation tournée | Phase 3 |
| Stripe | Facturation SaaS | Phase 4 |

---

## Critères de Qualité

- Temps de réponse Edge Function < 2s
- Disponibilité Supabase > 99.5%
- RLS vérifié sur 100% des tables avec données patient
- Aucune donnée patient exposée entre cliniques
