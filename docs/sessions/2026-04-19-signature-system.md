# Session 2026-04-19 — Signature System

## Context

Replaced the native FlutterFlow Signature widget (hardcoded to Firebase Storage)
with a custom signature system built on `package:signature` v5.4.0 and Supabase Storage.

### Medical-legal requirements

The professional signature is automatically appended to:
- SOAP clinical notes (notes d'observation)
- Late notes (notes tardives)
- With authentication metadata: date/time, name, title, OIIAQ matricule

Per Quebec OIIAQ documentation standards. Subject to professional audits
and potential legal proceedings.

## Architecture

```
SignatureCanvas (Custom Widget)
  │
  ├── Preview mode: Image.network(existingSignatureUrl)
  │   └── "Modifier" button → switch to edit mode
  │
  └── Edit mode: Signature canvas (package:signature)
      ├── "Appuyez pour signer" overlay (anti-scroll protection)
      ├── IgnorePointer blocks touch when not editing
      └── "Terminé" badge exits edit mode

captureSignature (Custom Action)
  └── SignatureCanvasController.instance → toPngBytes() → FFUploadedFile

uploadSignatureToSupabase (Custom Action — pre-existing)
  └── Supabase.storage.from('signatures').uploadBinary('{uid}/signature_pro.png')

Trigger SQL: sync_upload_url_to_profile (pre-existing)
  └── AFTER INSERT ON storage.objects → UPDATE profils_professionnels.signature_pro_url
```

### Flow: Confirmer button (7 actions)

```
1. hasSignatureDrawn → hasDrawn (bool)
2. Conditional: hasDrawn
   TRUE:
     3. captureSignature → signatureFile (FFUploadedFile)
     4. uploadSignatureToSupabase(signatureFile, currentUserUid)
     5. Wait 1 second (trigger SQL sync)
     6. Refresh Database Request → profileQuery
     7. Snackbar "Signature enregistrée"
   FALSE:
     3. Snackbar "Veuillez signer avant de confirmer"
```

### Flow: Effacer button

```
1. clearSignature (resets canvas)
```

## Singleton pattern

`SignatureCanvasController.instance` (static global) shared between
the Custom Widget and all Custom Actions. This avoids FlutterFlow's
limitation of not being able to pass controllers between widgets
and actions directly.

## Anti-scroll protection

The canvas uses an explicit edit mode (DocuSign/Adobe Sign pattern):
- Default: overlay blocks all touch events → scroll works normally
- Tap on canvas: overlay disappears, drawing is enabled
- "Terminé" badge: exits edit mode, overlay returns
- Zero tolerance for parasitic strokes from accidental scroll

## Key decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Package | `signature` v5.4.0 (not `hand_signature`) | Already installed in project |
| penStrokeWidth | 2.5 | Optimal for printed clinical documents |
| Anti-scroll | Explicit edit mode | 100% prevention, DocuSign standard |
| Preview mode | Image.network in same widget | Single widget, two modes |
| hasSignatureDrawn | Separate bool action | Avoids FlutterFlow type mismatch on nullable FFUploadedFile |
| Canvas size | 380x160 default | Comfortable on mobile, compact on page |

## Files

| File | Location | Role |
|------|----------|------|
| `signature_canvas.dart` | `flutterflow/custom_code/widgets/` | Canvas + preview widget |
| `capture_signature.dart` | `flutterflow/custom_code/actions/` | Export PNG bytes |
| `clear_signature.dart` | `flutterflow/custom_code/actions/` | Reset canvas |
| `has_signature_drawn.dart` | `flutterflow/custom_code/actions/` | Bool guard for conditional |
| `upload_signature_to_supabase.dart` | FlutterFlow only (pre-existing) | Upload to Storage |
| `auto_sync_upload_urls.sql` | `supabase/migrations/20260408110001` | Trigger: write URL to DB |

## Tests validated

- Samsung Galaxy S21 FE (Android 16) — Run Mode
- Samsung tablet — Run Mode
- Multiple sign + confirm + reload cycles
- Upload confirmed via Supabase logs (POST 200 + ObjectCreated:Post)
- Trigger SQL confirmed (rows_updated=1)

## Known limitations

- Canvas is write-only: always blank at page load (by design)
- Preview mode depends on existingSignatureUrl from profileQuery
- FlutterFlow webview (Facebook/Messenger) caches aggressively — test in Chrome
- No landscape rotation support (removed for simplicity)

## Migration plan (old photo system)

| Phase | Action | Status |
|-------|--------|--------|
| 1 | Canvas deployed alongside old photo system | Done |
| 2 | Cohabitation for 2 weeks | In progress |
| 3 | Hide old photo upload button | Pending |
| 4 | Remove old photo system after validation | Pending |
