# Signature Canvas — Architecture d'implémentation

> **Statut : Production-ready**
> Implémenté le 2026-04-20. Testé sur Samsung Galaxy S21 FE (Android 16).

---

## Architecture choisie : widget autonome + triggers

Le Custom Widget `SignatureCanvas` est entièrement autonome :
- Il crée et gère son propre `SignatureController` en interne
- Il uploade directement vers Supabase Storage (pas de Custom Action intermédiaire)
- Il communique avec la page via des **triggers boolean** (Page State)
- Aucune classe ni variable partagée entre widget et actions

### Pourquoi PAS de Custom Actions pour le controller

FlutterFlow a 3 limitations qui empêchent le partage de state :

1. **Custom Widgets** : refusent 2 classes publiques dans le même fichier
   → "SignatureCanvas can not be parsed"

2. **Custom Actions** : refusent les classes (factory pattern, singleton)
   → "Unknown error compiling custom code"

3. **Custom Code Files** : ne supportent pas les packages externes ni les imports manuels
   → Conçus pour des data models simples uniquement

4. **Widget callbacks** : `Future Function()` ne compile pas
   → FlutterFlow ne supporte que les VoidCallback sans paramètres via le type "Action"

La seule architecture qui compile : tout est interne au widget.

---

## Trigger SQL : sync_upload_url_to_profile

Fichier : `supabase/migrations/20260408110001_auto_sync_upload_urls.sql`

Quand un fichier est uploadé dans le bucket `signatures`, ce trigger :
1. Détecte le nouveau fichier via `AFTER INSERT ON storage.objects`
2. Construit l'URL publique
3. Met à jour `profils_professionnels.signature_pro_url` pour le propriétaire

Le widget n'a pas besoin de faire un Update Row — le trigger gère la persistance en DB.

---

## Paramètres du widget

| Paramètre | Type | Default | Rôle |
|---|---|---|---|
| `width` | double? | 600 | Largeur du canvas |
| `height` | double? | 200 | Hauteur du canvas |
| `penColor` | Color? | black | Couleur du trait |
| `backgroundColor` | Color? | white | Fond du canvas |
| `existingSignatureUrl` | String? | null | URL de la signature existante (mode aperçu) |
| `userId` | String? | null | UID pour le path d'upload |
| `triggerExport` | bool? | null | Déclenche l'export + upload quand passe à true |
| `triggerClear` | bool? | null | Efface le canvas quand passe à true |

---

## Page State sur ProfileSetup

| Variable | Type | Default |
|---|---|---|
| `triggerExport` | Boolean | false |
| `triggerClear` | Boolean | false |

---

## Bindings du widget sur ProfileSetup

| Paramètre widget | Source |
|---|---|
| `existingSignatureUrl` | `profileQuery → First → signature_pro_url` |
| `userId` | `Authenticated User → User ID` |
| `triggerExport` | `Page State → triggerExport` |
| `triggerClear` | `Page State → triggerClear` |

---

## Flow bouton Confirmer

```
Action 1 : Update Page State → triggerExport = true
Action 2 : Wait 2000 ms
Action 3 : Refresh Database Request → profileQuery
Action 4 : Update Page State → triggerExport = false
Action 5 : Snackbar "Signature enregistrée"
```

## Flow bouton Effacer

```
Action 1 : Update Page State → triggerClear = true
Action 2 : Wait 100 ms
Action 3 : Update Page State → triggerClear = false
```

---

## Spécifications techniques

| Spec | Valeur | Raison |
|---|---|---|
| Canvas display | 600 × 200 px | Confortable pour noms composés sur mobile |
| Export PNG | 1200 × 400 px | Haute résolution pour impression documents officiels |
| penStrokeWidth | 3.0 | Lisible après impression, adapté signatures |
| Bucket | `signatures` (public) | URL publique directe sans signed URL |
| Fichier | `{userId}/signature_pro.png` | Nom fixe, upsert à chaque upload |
| Cache-busting | `?t={timestamp}` sur l'URL d'affichage | Empêche Chrome de cacher l'ancienne version |

---

## Modes du widget

### Mode aperçu (existingSignatureUrl non vide)
- Affiche l'image existante via `Image.network`
- Bouton "Modifier" en bas à droite → bascule en mode édition

### Mode édition — inactif (default)
- Overlay "Appuyez pour signer" bloque les touches
- Le scroll de la page fonctionne normalement à travers le widget
- Tap sur le canvas → active le mode édition

### Mode édition — actif
- Bordure bleue, badge "✓ Terminé" en haut à droite
- Signature dessinée au doigt/stylet
- Tap "✓ Terminé" → verrouille le dessin, overlay réapparaît

### Mode upload
- Spinner de chargement pendant l'upload vers Supabase

---

## Custom Actions supprimées

| Action | Raison de suppression |
|---|---|
| `initSignatureController` | FlutterFlow refuse les classes dans les Custom Actions |
| `captureSignature` | Logique intégrée dans le widget |
| `clearSignature` | Logique intégrée dans le widget |
| `hasSignatureDrawn` | Plus nécessaire (le widget vérifie internement) |

`uploadSignatureToSupabase` est conservée en backup mais plus utilisée.

---

## Contexte médico-légal

La signature est apposée automatiquement sur :
- Notes d'observation SOAP
- Notes tardives
- Accompagnée de : date/heure, nom, titre professionnel, matricule OIIAQ

Enjeux :
- Dossiers sujets à audit OIIAQ
- Preuves potentielles en procédures légales
- Zéro tolérance aux traits parasites (anti-scroll protection)
- Export HD pour lisibilité sur documents imprimés
