# Photo Viewer — Architecture d'implémentation

> **Statut : S1 implémenté (production-acceptable, UX à itérer pré-launch)**
> Sprint : J2.14 — 2026-04-27
> Testé sur : Samsung Galaxy (device Nancy)

---

## Composant

`BottomSheet_PhotoViewer_Old` — affiche une photo clinique en grand depuis le `GridView` de `NoteObservation` avec support pinch-to-zoom.

## Architecture

```
BottomSheet_PhotoViewer_Old (Component)
  │
  ├── Component Parameter: imageUrl (String, required)
  │     └── Reçue depuis GridView item au tap
  │
  ├── Container parent
  │     ├── Width  = Screen Width (Global Properties)
  │     ├── Height = Screen Width  (carré garanti, anti-overflow)
  │     ├── BorderRadius = 8
  │     └── Clip Content = ON (antiAlias — contient le zoom dans la bordure)
  │
  └── ZoomableImage (Custom Widget)
        ├── imageUrl  ← Component Parameter
        ├── width     = Screen Width
        └── height    = Screen Width
```

## Custom Widget : ZoomableImage

Wrapper natif Flutter `InteractiveViewer` + `Image.network`.

### Paramètres

| Param | Type | Required | Rôle |
|-------|------|----------|------|
| `imageUrl` | `String` | ✅ | URL signée Supabase Storage |
| `width` | `double?` | ❌ | Bornage horizontal (laissé nullable côté Dart, fourni par FF) |
| `height` | `double?` | ❌ | Bornage vertical (idem) |

### Comportement

- `InteractiveViewer` : `minScale = 1.0`, `maxScale = 4.0`, pan + scale activés
- `BoxFit.contain` (hardcodé — voir [Décisions architecturales](#décisions-architecturales))
- `loadingBuilder` : `CircularProgressIndicator` pendant download
- `errorBuilder` : icône `broken_image` si URL invalide/expirée

### Pourquoi InteractiveViewer (natif Flutter) plutôt qu'un package externe

- Zéro dépendance pub à maintenir
- Performance native (gesture detector intégré au framework)
- Aucune incompatibilité FF connue
- Suffisant pour pinch + pan ; ne couvre pas (encore) le double-tap-to-zoom

---

## Décisions architecturales

### 1. `BoxFit.contain` (non `cover`) — non négociable

**Contrainte clinique / médico-légale** : les photos documentent des lésions (plaies, mycoses, callosités, mélanomes potentiels). `BoxFit.cover` remplit le cadre mais **coupe les bords** — risque de masquer une partie de la lésion documentée.

`contain` garde l'image entière visible, quitte à afficher des bandes noires sur les côtés (acceptable). Toute photo doit pouvoir être restituée intégralement pour un audit OIIAQ ou une procédure légale (conservation 5+ ans).

**Cette décision s'applique à TOUS les viewers de photos cliniques dans l'app — `cover` est interdit dans ce contexte.**

### 2. Container parent en carré `Screen Width × Screen Width`

Choix pragmatique S1 (court terme) :
- Vrai carré garanti (pas de surprise overflow selon padding parent)
- Adaptatif (s'ajuste à toute taille d'écran)
- ZoomableImage et Container partagent strictement les mêmes dimensions = aucun conflit de bornage pour `InteractiveViewer`

**Limite connue** : photos portrait (format vertical) n'occupent qu'environ 3/5 de la surface du carré. Acceptable temporairement, à remplacer par S3 (cf. [Backlog](#backlog-technique)).

### 3. `Enforce Width and Height = ON` côté FlutterFlow

Bien que `width` et `height` soient `double?` côté Dart, FF 6.6.56 exige des dimensions concrètes au runtime pour les Custom Widgets. Tenter de désactiver ce toggle laisse les erreurs rouges en place. Garder ON + valeurs `Screen Width` est la voie stable.

### 4. Pas de Custom Function `MediaQuery.of(context).size`

L'usage de `Global Properties → Screen Width` natif FF est suffisant et lisible. Introduire une Custom Function ajouterait une couche de complexité sans gain pour ce cas. Réservé au refactor S3 si nécessaire.

---

## Contraintes médico-légales

| Contrainte | Implication technique |
|------------|----------------------|
| Photo doit rester visible **intégralement** | `BoxFit.contain` obligatoire, pas de crop |
| Conservation 5+ ans (OIIAQ Québec) | Storage Supabase = source de vérité, signed URLs régénérables (cf. EF `generate-photo-urls`) |
| Photo doit être identifiable patient/visite | `imageUrl` doit toujours être traçable vers `photos_soins.id` (binding GridView) |
| Pas de modification destructive | Aucune action de la viewer ne réécrit la photo (lecture seule + delete optionnel) |

---

## Limites connues (S1)

| # | Limite | Sévérité | Workaround |
|---|--------|----------|------------|
| L1 | Largeur visuelle insuffisante pour photos portrait (~3/5 du carré) | Moyenne UX | Pinch-to-zoom compense partiellement |
| L2 | Freeze occasionnels lors du pinch sur device Samsung | Haute UX | Hot Restart si freeze (rare) — voir S3 pour fix permanent |
| L3 | Pas de double-tap-to-zoom | Faible | Geste pinch suffit |
| L4 | Bouton "Envoyer" du BottomSheet occupe de l'espace vertical | Moyenne UX | À compacter dans S3 |
| L5 | BottomSheet hauteur totale ~600-700px alloue ~100-200px d'espace vide | Faible | Refactor layout dans S3 |

---

## Backlog technique

### S3 — Refactor BottomSheet_PhotoViewer (P2 pré-launch)

Objectif : maximiser la surface image utile dans le BottomSheet sans compromettre l'intégrité clinique.

**Scope :**
- Container photo : passer de carré fixe à `MediaQuery.size.height - <réservé actions>` (utilise toute la hauteur dispo)
- Conserver `BoxFit.contain` (non négociable)
- Compacter les actions : `IconButton` (Annuler / Envoyer / Supprimer) au lieu de boutons texte
- Layout : barre d'actions compacte en bas, photo prend le reste
- Considérer `SafeArea` pour bords haut/bas

**Critère d'acceptation** :
- Photo portrait occupe ≥ 80% de la hauteur disponible du BottomSheet
- Aucun crop d'image
- Pinch-to-zoom toujours fluide

### Optimisation perf pinch-to-zoom (P2 pré-launch)

Hypothèses sur les freeze actuels (à diagnostiquer) :
- **Résolution native trop élevée** : photos uploadées en pleine résolution (smartphone moderne ~12 Mpx ≈ 4-8 Mo). Décoder + scale en mémoire = coûteux pour `InteractiveViewer`.
- **`Image.network` non caché** : chaque ouverture du BottomSheet retélécharge.
- **`ClipRect` du Container parent** : redraw à chaque frame de zoom (compositing layer).

**Pistes :**

1. **Génération de variantes côté upload** (Edge Function ou trigger) :
   - `original` (full resolution, conservation médico-légale)
   - `medium` (1024px max edge, viewer pinch)
   - `thumbnail` (256px, GridView)
   - Servir `medium` au PhotoViewer, `thumbnail` au GridView, `original` à la demande (export PDF dossier)

2. **`CachedNetworkImage`** au lieu de `Image.network` dans `ZoomableImage` :
   - Cache disque local FF
   - Évite re-download à chaque ouverture
   - Dépendance pub : `cached_network_image` (déjà couramment utilisée en FF)

3. **`RepaintBoundary`** autour de `InteractiveViewer` :
   - Isole la zone de redraw lors du zoom
   - Réduit la charge GPU

4. **Précharge** (`precacheImage`) au moment du tap GridView :
   - L'image est déjà décodée quand le BottomSheet s'ouvre

**Critère d'acceptation** :
- Aucun freeze visible sur device Samsung milieu de gamme
- Temps d'ouverture du BottomSheet < 300ms
- Zoom fluide à 60fps minimum

### Évolutions UX possibles (P3, post-launch)

- Double-tap-to-zoom (zoom rapide à 2x sur le point tappé)
- Swipe horizontal pour passer à la photo suivante du GridView (galerie native)
- Bouton "Plein écran" (sortir du BottomSheet en route dédiée)
- Annotations cliniques sur photo (cercles, flèches — feature V2 IA Vision)

---

## Références

- Custom Widget ZoomableImage : `flutterflow/custom_code/widgets/zoomable_image.dart`
- Component parent : `flutterflow/components/bottom_sheet_photo_viewer_old.ff`
- Source des photos : table `photos_soins` (Supabase)
- Régénération URLs signées : Edge Function `generate-photo-urls` (1 an d'expiration)
- Décision pricing/IA Vision (annotations futures) : voir [`ROADMAP_AGENDA_IA.md`](./ROADMAP_AGENDA_IA.md)
