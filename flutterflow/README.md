# FlutterFlow Custom Code — Backup

> **Source of truth: FlutterFlow editor.**
> This directory is a versioned backup of Custom Widgets and Custom Actions
> created in FlutterFlow. The actual runtime code lives in FlutterFlow's
> proprietary build system, not in this repo.

## Purpose

- Version control for Custom Dart code that FlutterFlow doesn't track in Git
- Reference for recreating widgets/actions if the FlutterFlow project is reset
- Code review and documentation alongside the Supabase backend code

## Structure

```
flutterflow/
└── custom_code/
    ├── widgets/          # Custom Widgets (StatefulWidget)
    │   └── signature_canvas.dart
    └── actions/          # Custom Actions (async functions)
        ├── capture_signature.dart
        ├── clear_signature.dart
        └── has_signature_drawn.dart
```

## Dependencies

| Package | Version | Used by |
|---------|---------|---------|
| `signature` | `^5.4.0` | SignatureCanvas, all signature actions |

## Important

- When updating code in FlutterFlow, **also update the corresponding file here**
- FlutterFlow auto-generates imports at the top of each file — do not include
  imports for `structs/index.dart`, `enums/enums.dart`, or `actions/actions.dart`
  as these files do not exist in this project
