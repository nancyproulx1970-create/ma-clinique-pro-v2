# Guide de contribution — Ma Clinique Pro V2

## Branches

| Préfixe | Usage | Exemple |
|---------|-------|---------|
| `feature/` | Nouvelle fonctionnalité | `feature/suggest-slot-ia` |
| `fix/` | Correction de bug | `fix/rdv-conflict-check` |
| `docs/` | Documentation uniquement | `docs/update-architecture` |
| `db/` | Migration base de données | `db/add-appointment-reminders` |
| `chore/` | Maintenance, dépendances | `chore/update-supabase-cli` |

**Règle** : Toujours créer une branche depuis `main`. Ne jamais committer directement sur `main`.

---

## Convention de Commits (Conventional Commits)

Format : `type(scope): description courte`

| Type | Usage |
|------|-------|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `docs` | Documentation |
| `db` | Migration SQL |
| `refactor` | Refactoring sans changement de comportement |
| `test` | Ajout ou modification de tests |
| `chore` | Tâches de maintenance |

**Exemples :**
```
feat(suggest-slot): add OpenAI integration for slot suggestions
fix(rls): correct policy for secretary role on appointments
docs(architecture): update Edge Functions diagram
db(reminders): add appointment_reminders and practitioner_reminder_defaults tables
```

---

## Process de PR

1. Créer une branche depuis `main` avec le bon préfixe
2. Faire les changements + commits conventionnels
3. Ouvrir une PR avec le template fourni
4. Remplir la checklist complète
5. Attendre la review (minimum 1 approbation)
6. Merger en squash merge

---

## Règles impératives

### Sécurité
- **Jamais** committer de clés API, tokens ou secrets
- **Jamais** désactiver le RLS sur une table de production
- Tester le RLS avec 2 comptes différents avant de merger

### IA
- Les Edge Functions IA ne font **jamais** de INSERT/UPDATE en DB
- Toujours implémenter un fallback si l'appel IA échoue
- Logger chaque appel dans la table `ia_logs`

### Base de données
- Chaque changement de schéma = une migration dans `/supabase/migrations/`
- Nommer les migrations : `YYYYMMDD_description.sql`
- Tester la migration sur dev avant staging

---

## Structure des Edge Functions

```
supabase/functions/<nom-function>/
├── index.ts          # Point d'entrée principal
├── types.ts          # Types TypeScript
├── prompts.ts        # Prompts IA (si applicable)
└── README.md         # Doc de la fonction
```

---

## Questions ?

Ouvrir une issue avec le template "Décision Produit" ou contacter l'équipe.
