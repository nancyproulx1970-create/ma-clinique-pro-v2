# PLAN BASE vs PLAN IA — Ma Clinique Pro V2

## Principe de séparation

L'agenda fonctionne SANS IA. La couche IA est un ajout optionnel qui améliore l'expérience.
Si l'appel IA échoue → l'agenda continue de fonctionner normalement.

---

## PLAN BASE — Fonctionnalités sans IA

### Ce que la base fait seule

| Fonctionnalité | Implémentation | Composant |
|---------------|---------------|-----------|
| Prise de RDV manuelle | Formulaire FlutterFlow + INSERT Supabase | FlutterFlow |
| Vue calendrier | Widget calendrier FlutterFlow | FlutterFlow |
| Gestion des slots | Calcul depuis day_settings | Supabase Function |
| Vérification conflits | Check chevauchement en DB | Supabase |
| Notifications confirmation | Trigger Supabase → Edge Function notify | Edge Function |
| Rappels automatiques | Cron Supabase → Edge Function notify | Edge Function |
| Annulation / modification RDV | UPDATE en DB | Supabase |
| Multi-rôles | RLS + JWT claims | Supabase Auth |
| Export agenda | PDF / CSV via Edge Function | Edge Function |

### Ce que la base NE fait PAS
- Suggérer des créneaux optimaux
- Analyser les patterns patient
- Optimiser les tournées
- Détecter les risques de surcharge
- Recommander des actions

---

## PLAN IA — Fonctionnalités avec couche IA

### Architecture de la couche IA

```
FlutterFlow → Edge Function → [Supabase DB + OpenAI API] → Réponse structurée
```

### Edge Functions IA

#### /suggest-slot
**Quand appelé** : Lors de l'ouverture du formulaire de prise de RDV

**Input (JSON)**
```json
{
  "practitioner_id": "uuid",
  "service_type_id": "uuid",
  "patient_id": "uuid",
  "preferred_date_range": { "from": "2026-04-01", "to": "2026-04-07" },
  "preferred_time": "morning"
}
```

**Logique**
1. Récupère les slots disponibles depuis Supabase
2. Récupère l'historique du patient (fréquence, préférences passées)
3. Envoie le contexte à OpenAI avec un prompt structuré
4. Parse la réponse → liste de créneaux avec score

**Output (JSON)**
```json
{
  "suggestions": [
    {
      "start_time": "2026-04-02T09:00:00",
      "end_time": "2026-04-02T09:30:00",
      "score": 92,
      "reason": "Créneau habituel du patient, praticien disponible"
    }
  ]
}
```

---

#### /optimize-route
**Quand appelé** : Fin de journée ou début J-1 pour tournées à domicile

**Input (JSON)**
```json
{
  "practitioner_id": "uuid",
  "date": "2026-04-03",
  "start_location": { "lat": 45.5017, "lng": -73.5673 }
}
```

**Logique**
1. Récupère tous les RDV du jour avec coordonnées GPS patients
2. Appelle l'API de routing (Google Maps ou OpenRoute)
3. Calcule l'ordre optimal (TSP simplifié)
4. Retourne l'itinéraire ordonné avec temps estimés

**Output (JSON)**
```json
{
  "optimized_order": [
    {
      "appointment_id": "uuid",
      "patient_name": "Tremblay, Marie",
      "address": "123 rue Saint-Denis",
      "arrival_time": "09:15",
      "travel_minutes": 12
    }
  ],
  "total_distance_km": 34.2
}
```

---

#### /decision-helper
**Quand appelé** : À la demande du praticien ou automatiquement en cas d'alerte

**Input (JSON)**
```json
{
  "practitioner_id": "uuid",
  "date": "2026-04-03",
  "context": "surcharge"
}
```

**Logique**
1. Analyse la charge du jour (nb RDV, durée totale, type de soins)
2. Compare avec la capacité normale du praticien
3. Génère des recommandations (décaler RDV, ajuster pause, alerter secrétaire)

**Output (JSON)**
```json
{
  "alert_level": "warning",
  "recommendations": [
    "Journée à 115% de capacité - envisager de déplacer 1 RDV",
    "Patient Dupont sans RDV depuis 45 jours - rappel recommandé"
  ]
}
```

---

## Règles de Séparation Base / IA

| Règle | Détail |
|-------|--------|
| IA non bloquante | Si Edge Function IA timeout → fallback sur vue manuelle |
| IA non obligatoire | Prise de RDV possible sans appel IA |
| Logs séparés | Table ia_logs pour tracer tous les appels IA |
| Coût contrôlé | Limite de tokens par appel OpenAI (max 500 tokens output) |
| IA jamais en écriture | Les Edge Functions IA ne font que des SELECT, jamais INSERT/UPDATE |
| Validation humaine | Toute suggestion IA nécessite validation humaine avant commit |

---

## Table : ia_logs

| Colonne | Type | Description |
|---------|------|-------------|
| id | uuid | PK |
| clinic_id | uuid | FK → clinics.id |
| function_name | text | 'suggest-slot', 'optimize-route', etc. |
| input_hash | text | Hash des inputs (pas de données sensibles) |
| tokens_used | int | Tokens OpenAI consommés |
| latency_ms | int | Temps de réponse |
| success | boolean | Appel réussi |
| error_message | text | Si erreur |
| created_at | timestamptz | |
