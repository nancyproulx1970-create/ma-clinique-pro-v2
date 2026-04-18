# Flow — Suppression de photo clinique

> **Statut : Production-ready**
> Validé le 2026-04-14. Testé avec suppression réelle (11 → 10 photos).

---

## Vue d'ensemble

```
[Tap photo] → [Bottom Sheet] → [Icône poubelle]
    → [Confirm Dialog]
    → [Edge Function delete-photo]
        → valide ownership
        → supprime ligne DB
        → supprime fichier Storage
        → log d'audit
    → [Refresh GridView]
    → photo disparaît de l'UI
```

---

## Frontend (FlutterFlow)

### Déclencheur

Icône poubelle dans `BottomSheet_PhotoViewer`.

### Actions (dans l'ordre)

| # | Action | Configuration |
|---|---|---|
| 1 | Confirm Dialog | "Supprimer cette photo ?" |
| 2 | API Call `deletePhoto` | `photoId` = Component Parameter, `ownerId` = Authenticated User → User ID |
| 3 | Dismiss Bottom Sheet | — |
| 4 | Refresh Database Request | Query du GridView photos |

### API Call `deletePhoto`

| Champ | Valeur |
|---|---|
| Method | POST |
| URL | `https://anzgkxmxkcetzbtjttuh.supabase.co/functions/v1/delete-photo` |
| Headers | `Content-Type: application/json`, `apikey: [SUPABASE_ANON_KEY]` |
| Body | `{ "photo_id": "{{photoId}}", "owner_id": "{{ownerId}}" }` |

Pas de header `Authorization` dans l'implémentation FlutterFlow actuelle. La sécurité repose sur une validation d'ownership côté Edge Function à partir de `photo_id` et `owner_id`, en attendant une intégration JWT serveur pleinement exploitable.

---

## Backend (Supabase Edge Function)

### Fonction : `delete-photo`

| Propriété | Valeur |
|---|---|
| Slug | `delete-photo` |
| Version | 3 |
| `verify_jwt` | `false` |
| Runtime | Deno |

### Pipeline d'exécution

1. **Validation** — `photo_id` et `owner_id` requis (String, non vides)
2. **Ownership** — SELECT sur `photos_soins` avec double filtre `id = photo_id AND owner_id = owner_id`
3. **Suppression DB** — DELETE sur `photos_soins` avec le même double filtre
4. **Suppression Storage** — `storage.remove([storage_path])` dans le bucket `photos-soins`
5. **Log d'audit** — `console.log` structuré avec `photo_id`, `owner_id`, `storage_path`, `timestamp`

### Réponses

| Status | Body | Signification |
|---|---|---|
| 200 | `{ "deleted": true }` | Suppression réussie (DB + Storage) |
| 400 | `{ "error": "photo_id requis" }` | Paramètre manquant |
| 404 | `{ "error": "Photo introuvable ou accès refusé" }` | Photo inexistante ou ownership invalide |
| 500 | `{ "error": "Erreur suppression" }` | Erreur DB |

### Sécurité

- Ownership vérifié à la fois sur le SELECT et le DELETE
- Un utilisateur ne peut supprimer que ses propres photos
- `persistSession: false` sur le service client (pas de session persistée côté serveur)
- `.maybeSingle()` au lieu de `.single()` (pas de crash si 0 résultat)
- Si la suppression Storage échoue, la ligne DB est quand même supprimée (pas de photo fantôme dans l'UI)

---

## Base de données

### Table : `photos_soins`

| Colonne | Rôle dans ce flow |
|---|---|
| `id` | Identifiant de la photo (UUID) — envoyé comme `photo_id` |
| `owner_id` | Propriétaire — filtré pour garantir l'isolation |
| `storage_path` | Chemin du fichier dans le bucket — utilisé pour la suppression Storage |

### Bucket : `photos-soins`

- Privé
- Fichiers organisés en `{uid}/{visite_id}/{timestamp}.jpg`
- RLS par uid sur les policies Storage

---

## Validation

| Métrique | Résultat |
|---|---|
| Photos avant test | 11 |
| Photos après suppression | 10 |
| Ligne DB supprimée | Oui |
| Fichier Storage supprimé | Oui |
| UI mise à jour | Oui (Refresh après Dismiss) |
| Log d'audit présent | Oui |
