# MODÈLE DE DONNÉES AGENDA — Ma Clinique Pro V2

## Vue d'ensemble des tables

```
clinics
  └── practitioners (praticiens)
        └── day_settings (paramètres journée)
        └── appointments (rendez-vous)
              └── appointment_slots (créneaux utilisés)
  └── patients
  └── service_types (types de soins)
  └── rooms (salles / ressources)
```

---

## Table : clinics

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | uuid | PK, default gen_random_uuid() | Identifiant clinique |
| name | text | NOT NULL | Nom de la clinique |
| address | text | | Adresse physique |
| phone | text | | Téléphone |
| email | text | UNIQUE | Email admin |
| timezone | text | NOT NULL, default 'America/Montreal' | Fuseau horaire |
| is_active | boolean | default true | Clinique active |
| created_at | timestamptz | default now() | Date création |

---

## Table : practitioners

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | uuid | PK | Identifiant praticien |
| clinic_id | uuid | FK → clinics.id | Clinique d'appartenance |
| user_id | uuid | FK → auth.users.id | Compte Supabase Auth |
| full_name | text | NOT NULL | Nom complet |
| role | text | NOT NULL | 'admin', 'practitioner', 'secretary' |
| specialty | text | | Spécialité médicale |
| color_hex | text | | Couleur calendrier |
| is_active | boolean | default true | Compte actif |
| created_at | timestamptz | default now() | |

---

## Table : patients

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | uuid | PK | Identifiant patient |
| clinic_id | uuid | FK → clinics.id | Clinique |
| full_name | text | NOT NULL | Nom complet |
| birth_date | date | | Date de naissance |
| phone | text | | Téléphone |
| email | text | | Email |
| address | text | | Adresse (pour tournée) |
| lat | float8 | | Latitude GPS |
| lng | float8 | | Longitude GPS |
| notes | text | | Notes cliniques |
| created_at | timestamptz | default now() | |

---

## Table : service_types

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | uuid | PK | Identifiant type de soin |
| clinic_id | uuid | FK → clinics.id | Clinique |
| name | text | NOT NULL | Ex: "Consultation", "Bilan" |
| duration_minutes | int | NOT NULL | Durée par défaut |
| color_hex | text | | Couleur sur calendrier |
| requires_room | boolean | default false | Nécessite une salle |

---

## Table : day_settings

Paramètres de journée par praticien.

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | uuid | PK | |
| practitioner_id | uuid | FK → practitioners.id | |
| day_of_week | int | 0=Lundi, 6=Dimanche | Jour de la semaine |
| start_time | time | NOT NULL | Heure début journée |
| end_time | time | NOT NULL | Heure fin journée |
| lunch_start | time | | Début pause déjeuner |
| lunch_end | time | | Fin pause déjeuner |
| max_appointments | int | | Max RDV par jour |
| is_working_day | boolean | default true | Jour travaillé |

---

## Table : appointments

Table centrale du système.

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | uuid | PK | Identifiant RDV |
| clinic_id | uuid | FK → clinics.id | Clinique |
| practitioner_id | uuid | FK → practitioners.id | Praticien assigné |
| patient_id | uuid | FK → patients.id | Patient |
| service_type_id | uuid | FK → service_types.id | Type de soin |
| room_id | uuid | FK → rooms.id, nullable | Salle (si applicable) |
| start_time | timestamptz | NOT NULL | Début RDV |
| end_time | timestamptz | NOT NULL | Fin RDV |
| status | text | NOT NULL | 'scheduled', 'confirmed', 'completed', 'cancelled', 'no_show' |
| notes | text | | Notes internes |
| ia_suggested | boolean | default false | RDV suggéré par IA |
| ia_score | int | | Score suggestion IA (0-100) |
| created_by | uuid | FK → practitioners.id | Qui a créé le RDV |
| created_at | timestamptz | default now() | |
| updated_at | timestamptz | | |

Index : (practitioner_id, start_time), (patient_id, start_time), (clinic_id, status)

---

## Table : slots (créneaux disponibles)

Créneaux calculés / disponibles par praticien.

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | uuid | PK | |
| practitioner_id | uuid | FK → practitioners.id | |
| slot_date | date | NOT NULL | Date du créneau |
| start_time | time | NOT NULL | Heure début |
| end_time | time | NOT NULL | Heure fin |
| is_available | boolean | default true | Disponible ou non |
| blocked_reason | text | | Raison blocage (si applicable) |

---

## Table : rooms

| Colonne | Type | Contrainte | Description |
|---------|------|-----------|-------------|
| id | uuid | PK | |
| clinic_id | uuid | FK → clinics.id | |
| name | text | NOT NULL | Ex: "Salle 1", "Cabinet principal" |
| capacity | int | default 1 | Capacité |
| is_active | boolean | default true | |

---

## RLS — Row Level Security

```sql
-- Exemple : praticien voit seulement ses RDV
CREATE POLICY "practitioner_own_appointments"
ON appointments FOR ALL
USING (
  practitioner_id = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM practitioners p
    WHERE p.user_id = auth.uid()
    AND p.role = 'admin'
    AND p.clinic_id = appointments.clinic_id
  )
);
```

---

## Fonctions Supabase utiles

```sql
-- Obtenir les créneaux libres d'un praticien pour une date
SELECT * FROM get_available_slots(
  p_practitioner_id := 'uuid-here',
  p_date := '2026-04-01',
  p_duration := 30
);
```
