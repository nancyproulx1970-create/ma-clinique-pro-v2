# Session 2026-04-27 — Pinch-to-zoom (J2.14)

## Context

Sprint J2.14 du plan de stabilisation V1. Objectif : ajouter le pinch-to-zoom au `BottomSheet_PhotoViewer_Old` pour permettre à Nancy de visualiser les détails cliniques (plaies, ongles, callosités, mycoses) sans avoir à exporter l'image.

Pré-existant : Custom Widget `ZoomableImage` déjà présent dans le projet FF mais non intégré dans le viewer.

## Problème initial

- Le `BottomSheet_PhotoViewer_Old` affichait la photo via un `Image` widget natif FF, dimensionné `Width: infinity, Height: 350`.
- Aucun support gesture (pinch / pan).
- Photo trop petite pour examen clinique des détails.
- Photos portrait visibles à ~3/5 de la zone, pas adapté à l'usage métier.

## Solution implémentée (S1)

### Étapes

1. Wrap du widget `Image` dans un `Container` parent (BorderRadius 8, Clip Content ON).
2. Suppression de l'`Image` natif, remplacé par le Custom Widget `ZoomableImage`.
3. Binding `imageUrl` du `ZoomableImage` sur le Component Parameter `imageUrl` (String) du BottomSheet.
4. Configuration des dimensions : `Container` et `ZoomableImage` à `Screen Width × Screen Width` (carré adaptatif).
5. `Enforce Width and Height = ON` (requis par FF 6.6.56 pour Custom Widgets).

### Résultat technique

- ✅ Compilation FF sans erreur
- ✅ Photo affichée sur device Samsung
- ✅ Pinch-to-zoom fonctionnel (1x à 4x)
- ✅ Pan disponible quand zoomé
- ✅ Bordure 8px préservée (Clip antiAlias contient le zoom)

### UX résiduelle

- ⚠️ Photos portrait n'occupent que ~3/5 de la zone visible (carré + `BoxFit.contain`)
- ⚠️ Freeze occasionnels lors du pinch (probablement résolution native trop élevée)

## Décisions

| Décision | Justification |
|----------|---------------|
| `BoxFit.contain` (non `cover`) | Médico-légal : ne jamais cropper une lésion documentée |
| Carré `Screen Width × Screen Width` | S1 quick win : pas de refactor du BottomSheet ce soir |
| Garder `Enforce Width and Height ON` | FF 6.6.56 exige des bounds finis pour Custom Widgets ; valeurs nullables Dart ne suffisent pas |
| Ne pas modifier le code Dart de `ZoomableImage` | Code production-ready (loadingBuilder + errorBuilder), risque régression nul |
| S3 backloggé (P2 pré-launch) | Refactor complet (photo full-height + boutons compactés + optim perf) à faire à tête reposée |

## Issues résiduelles documentées

- L1 — Largeur visuelle insuffisante (portrait ~3/5)
- L2 — Freeze occasionnels au pinch
- L3 — Pas de double-tap-to-zoom
- L4 — Bouton "Envoyer" prend de l'espace vertical
- L5 — ~100-200px d'espace vide dans le BottomSheet

Détail dans [`PHOTO_VIEWER_IMPLEMENTATION.md`](../PHOTO_VIEWER_IMPLEMENTATION.md#limites-connues-s1).

## Backlog

- S3 (P2 pré-launch) — Refactor BottomSheet : photo full-height + actions compactes
- Optim perf — Variantes d'image (`thumbnail` / `medium` / `original`) + `CachedNetworkImage` + `RepaintBoundary`
- Évolutions UX (P3) — Double-tap-to-zoom, swipe galerie, fullscreen dédié

Détail dans [`PHOTO_VIEWER_IMPLEMENTATION.md`](../PHOTO_VIEWER_IMPLEMENTATION.md#backlog-technique).

## Fichiers touchés

- `flutterflow/components/bottom_sheet_photo_viewer_old.ff` (config FF Studio — pas de fichier source versionné)
- `docs/PHOTO_VIEWER_IMPLEMENTATION.md` (créé)
- `docs/sessions/2026-04-27-pinch-to-zoom-j214.md` (ce fichier)

## Suite immédiate

Sprint terminé pour aujourd'hui. Prochaine session : décider entre S3 (refactor BottomSheet) ou autre P0/P1 du backlog selon disponibilité Nancy.
