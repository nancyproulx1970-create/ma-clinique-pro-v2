# Session 2026-04-20 — Signature Cache-Busting Fix

## Symptôme observé

Après avoir modifié la signature (canvas → Confirmer → snackbar vert), puis
cliqué Enregistrer le profil, au retour sur ProfileSetup l'utilisatrice voit
toujours l'ancienne signature au lieu de la nouvelle.

## Diagnostic

Validé par Claude (mobile) via requêtes SQL Supabase directes :

1. **Bucket Storage** : le fichier `signatures/{uid}/signature_pro.png` contient
   bien la nouvelle signature (timestamp cohérent avec l'upload)
2. **DB** : `profils_professionnels.signature_pro_url` pointe vers le bon fichier
   (`updated_at` cohérent)
3. **URL directe en Chrome Incognito** : affiche bien la nouvelle signature

**Cause racine** : le nom de fichier est fixe (`signature_pro.png`). Le navigateur
(Chrome, webview) met l'image en cache côté client et continue d'afficher la
version cachée. L'URL en DB n'a aucun paramètre de cache-busting — elle est
identique avant et après l'upload.

## Correction appliquée

Ajout d'une méthode `_urlWithCacheBust` dans `_SignatureCanvasState` qui ajoute
un paramètre timestamp à l'URL au moment de l'affichage :

```dart
String _urlWithCacheBust(String url) {
  final separator = url.contains('?') ? '&' : '?';
  return '$url${separator}t=${DateTime.now().millisecondsSinceEpoch}';
}
```

Utilisée dans le `Image.network` du mode aperçu :

```dart
Image.network(
  _urlWithCacheBust(widget.existingSignatureUrl!),
  ...
)
```

Le timestamp est recalculé à chaque `build()` — après un Refresh Database
Request, le widget rebuild et force un re-fetch de l'image (l'URL avec le
nouveau `?t=...` n'est pas en cache).

**Ce qui n'a PAS été modifié** :
- L'URL stockée en DB (pas de cache-busting en DB)
- Le trigger SQL `sync_upload_url_to_profile`
- Les 3 Custom Actions (captureSignature, clearSignature, hasSignatureDrawn)
- Le flow du bouton Confirmer (7 actions)
- Le nom de fichier fixe `signature_pro.png` (architecture validée)

## Étape post-commit — Nancy

1. Ouvrir FlutterFlow → Custom Code → Custom Widgets → SignatureCanvas
2. Remplacer le code par la version du repo (`flutterflow/custom_code/widgets/signature_canvas.dart`)
3. Save → Compile
4. Tester via Chrome mobile (pas webview Facebook) :
   - Signer → Confirmer → Enregistrer → revenir → vérifier que la nouvelle signature s'affiche

## Bug secondaire documenté (non corrigé dans ce commit)

Après avoir signé et cliqué "✓ Terminé", la directive "Appuyez pour signer"
réapparaît par-dessus la signature fraîchement dessinée. Ce bug est purement
UI/state dans le mode édition du widget. À traiter séparément si persistant
après test du cache-busting fix.
