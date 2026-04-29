# Bug #2 — NoteObservation UPSERT + Lazy Mount Pattern

> **Statut : Résolu (2026-04-28)**
> Cause : INSERT systématique au lieu d'UPDATE + timing build/query en FlutterFlow.
> Pattern utilisé : **lazy widget mounting** pour contrôler le timing des Backend Queries.

---

## Problème

À chaque save de NoteObservation :
- INSERT systématique d'une nouvelle row dans `Dossier_Clinique` au lieu d'UPDATE de la row existante
- → 20+ rows en doublon pour la même visite (constaté pour Mario : 20 brouillons pour `agenda_id` unique)
- À l'ouverture de NoteObservation, le brouillon existant n'était **jamais rechargé** → champ note vide à chaque retour
- Confirmé par les utilisateurs : note "disparaît" après navigation hors/retour de la page

## Cause root (2 problèmes combinés)

### 1. Aucune contrainte UNIQUE sur `Dossier_Clinique`
La table acceptait N rows pour `(patient_id, agenda_id, statut='brouillon')`. Le bouton "Enregistrer au dossier" faisait `INSERT` à chaque clic, sans check préalable.

### 2. Timing build/query en FlutterFlow
Quand la page NoteObservation se charge :
1. Le widget tree se construit immédiatement
2. `WrapperNoteTexte` se monte → sa Backend Query se déclenche
3. **Mais l'INSERT n'a pas encore eu lieu** (l'Action Flow `On Page Load` s'exécute en async)
4. La query retourne `null` → `TF_NoteTexte` créé avec `Initial Value = null` → champ vide
5. PUIS l'Action Flow se termine, mais `TF_NoteTexte` est **déjà monté** et son controller interne ignore les changements ultérieurs d'`Initial Value`

## Solution

### Migration DB

```sql
-- Cleanup données de test (22 rows orphelines / doublons)
DELETE FROM public."Dossier_Clinique";

-- Garantir 1 brouillon max par (patient + agenda)
CREATE UNIQUE INDEX IF NOT EXISTS dossier_clinique_unique_brouillon
  ON public."Dossier_Clinique" (patient_id, agenda_id)
  WHERE statut = 'brouillon';
```

L'index est **partiel** (`WHERE statut = 'brouillon'`) : il garantit l'unicité des brouillons sans empêcher plusieurs rows `finalise` (cas d'avenants).

### Architecture FlutterFlow — Pattern Lazy Mount

```
NoteObservation Scaffold
└── ListView
    └── Column
        ├── Photos GridView
        ├── WrapperNoteTexte                ← Conditional Visibility: pageReady == true
        │   ├── Backend Query: Dossier_Clinique (Single Row)
        │   ├── CardNoteTexte
        │   │   └── TF_NoteTexte             ← Initial Value: query.observations
        │   └── ... (boutons IA, etc.)
        └── ...
```

**Pourquoi lazy mount** : on **empêche** WrapperNoteTexte de se monter avant que l'INSERT ait eu lieu. Comme la Backend Query du widget ne se déclenche qu'au mount, on contrôle son timing.

### Page States

| Nom | Type | Default | Persisted | Rôle |
|-----|------|---------|-----------|------|
| `currentBrouillonId` | String (UUID) | vide | OFF | ID du brouillon en cours pour cette page |
| `pageReady` | Boolean | `false` | OFF | Trigger pour mount lazy de WrapperNoteTexte |
| `noteTexte` | String | vide | OFF (existant) | Sync pour BoutonAmeliorerIA |

### On Page Load — Action Flow

```
1. Query Rows existingBrouillon (Dossier_Clinique, filtres patient_id + agenda_id + statut='brouillon' + owner_id)

2. Conditional: existingBrouillon.id Is Set
   ├── TRUE:
   │   ├── Update Page State currentBrouillonId = existingBrouillon.First.id
   │   └── Update Page State noteTexte = existingBrouillon.First.observations
   └── FALSE:
       ├── Insert Row Dossier_Clinique (patient_id, agenda_id) → newBrouillon
       ├── Update Page State currentBrouillonId = newBrouillon.id
       └── Update Page State noteTexte = newBrouillon.observations

3. API generatePhotoUrls (existant, intact)

4. Update Page State pageReady = true (Rebuild Page = ON)
   → WrapperNoteTexte devient visible → Backend Query se déclenche → trouve le brouillon
   → TF_NoteTexte se monte avec Initial Value = observations correctes ✅
```

### Bouton "Enregistrer au dossier" — refactor

**Avant** (bug) :
```
On Tap
  └── Conditional: noteId Is Set
        ├── TRUE: Update Row WHERE id=noteId
        └── FALSE: Insert Row + Update Page State noteId  ← bug: créait des doublons
```

**Après** (fix) :
```
On Tap
  ├── Update Row(s) Dossier_Clinique
  │     - Filter: id = currentBrouillonId
  │     - Set: observations = TF_NoteTexte
  └── Show Snack Bar
```

**Garanties** :
- Au moment du clic, `currentBrouillonId` est toujours défini (set au On Page Load)
- L'index UNIQUE DB empêche tout doublon même en cas de race condition
- Plus jamais d'INSERT depuis le bouton — toujours UPDATE

---

## Pattern réutilisable — Lazy Widget Mounting

Ce pattern résout les **timing issues entre Action Flow async et Backend Queries attachées aux widgets**.

### Quand l'utiliser

- Une page doit faire un INSERT/SELECT au load **avant** que des widgets enfants affichent leurs données
- Les Backend Queries attachées à des widgets ne supportent pas `Refresh Database Request` (erreur "non single time query")
- Le `TextEditingController` du TextField n'est pas exposé dans Widget State

### Recette

1. **Page State `pageReady`** (Boolean, default `false`)
2. **Conditional Visibility** sur le widget parent qui contient les queries → `pageReady == true`
3. **À la fin de l'Action Flow `On Page Load`** : `Update Page State pageReady = true` avec `Rebuild Page = ON`
4. Le user voit un délai imperceptible (<500ms) entre arrivée sur la page et apparition du widget

### Pourquoi ça marche

- Tant que `pageReady=false`, le widget n'est pas dans le tree → sa Backend Query NE SE DÉCLENCHE PAS
- Les Action Flow ont le temps de faire INSERT/SELECT et set les Page States
- Quand `pageReady` passe à `true`, le widget se monte pour la 1ère fois → Backend Query déclenchée → données fraîches → enfants reçoivent leurs `Initial Value` correctement

### Approches qui n'ont PAS marché (documentées pour mémoire)

| Approche | Pourquoi échec |
|----------|----------------|
| Update Page State + Rebuild Page = ON | Le `TextEditingController` du TextField conserve son état initial, ignore le rebuild |
| `Refresh Database Request` sur la query attached widget | Erreur FF : "Refresh database request action called on a widget with no request or that does not allow refresh (such as a non single time query)" |
| Custom Action Dart avec `controller.text = value` | Le `TextEditingController` de `TF_NoteTexte` n'est pas exposé dans Widget State (selon version FF) |
| Bind direct sur Backend Query avec controller existant | Même problème : Initial Value lue une seule fois au mount |

---

## Limites connues

- **Délai visuel <500ms** entre arrivée sur la page et apparition de la zone note. Acceptable, peut être masqué par un skeleton si nécessaire en V2.
- **Statut reste `brouillon`** : actuellement le bouton "Enregistrer au dossier" ne change pas le statut. Si la page Dossier Patient filtre sur `statut='finalise'`, les brouillons n'apparaissent pas. Fix prévu dans sous-sprint suivant.
- **Auto-save désactivé** : la save reste manuelle via le bouton. Auto-save UPSERT au focus loss ou debounced timer prévu en V2.

---

## Références

- Migration DB : `cleanup_dossier_clinique_dupes_and_add_unique_brouillon_index` (Supabase)
- Mémoire architecture notes : [`reference_workflow_notes_clinical.md`](../memory/...) — workflow brouillon → finalise
- Mémoire ProfileSetup : [`reference_profile_setup_dropdowns_et_note_simple.md`](../memory/...) — note = 1 seul champ `observations`
- Session log : [`docs/sessions/2026-04-28-bug2-upsert-lazy-mount.md`](./sessions/2026-04-28-bug2-upsert-lazy-mount.md)
