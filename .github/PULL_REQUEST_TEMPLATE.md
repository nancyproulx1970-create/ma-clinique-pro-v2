## Description
<!-- Décrivez les changements apportés par cette PR -->

## Type de changement
- [ ] 🐛 Bug fix
- [ ] ✨ Nouvelle fonctionnalité
- [ ] 🔧 Refactoring
- [ ] 📝 Documentation
- [ ] 🗄️ Migration base de données
- [ ] 🤖 Edge Function / IA

## Issue(s) liée(s)
Fixes #

## Phase
- [ ] Phase 1 — Base Agenda
- [ ] Phase 2 — Couche IA
- [ ] Phase 3 — Optimisation & Scale

## Checklist

### Général
- [ ] Le code compile sans erreurs
- [ ] Les changements ont été testés manuellement
- [ ] Pas de console.log ou données sensibles dans le code

### Base de données (si applicable)
- [ ] Migration SQL ajoutée dans `/supabase/migrations/`
- [ ] RLS vérifié et testé sur la/les table(s) modifiée(s)
- [ ] Index ajoutés si nécessaire

### Edge Function (si applicable)
- [ ] JWT vérifié en entrée
- [ ] Pas d'écriture en DB depuis une Edge Function IA
- [ ] Fallback géré si appel IA échoue
- [ ] Logs dans ia_logs si appel OpenAI

### FlutterFlow (si applicable)
- [ ] Testé sur iOS OU Android OU Web
- [ ] Pas de données sensibles exposées dans l'UI
- [ ] Gestion des états vides et d'erreur

### Documentation
- [ ] `docs/` mis à jour si l'architecture change
- [ ] `docs/DECISIONS_PRODUIT.md` mis à jour si nouvelle décision

## Screenshots / Démo
<!-- Si applicable, ajouter des captures d'écran ou une vidéo courte -->
