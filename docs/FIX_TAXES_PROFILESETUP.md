# Fix — Hydratation des champs taxes dans ProfileSetup

> **Statut : Résolu et validé**
> Bug résolu le 2026-04-18 après 4 jours de diagnostic.

---

## Contexte du bug

### Symptômes observés

- Le Switch "Inscrit aux taxes" s'affichait OFF au chargement malgré `Inscrit_aux_taxes = true` en DB
- Les TextFields numéro fédéral et provincial restaient vides au chargement malgré des valeurs en DB
- Le champ provincial était masqué (sa Conditional Visibility dépend du Switch étant ON)
- En activant manuellement le Switch, les TextFields apparaissaient mais vides
- Le Save fonctionnait parfaitement — les valeurs écrites en DB étaient correctes

### Stack concerné

- Page : ProfileSetup (FlutterFlow)
- Table : `profils_professionnels` (Supabase)
- Colonnes : `province_code`, `Inscrit_aux_taxes`, `numero_tps`, `numero_tvq`

---

## Cause racine identifiée

Trois problèmes distincts mais liés, tous causés par le timing de premier build en Flutter :

### 1. Widget State lu au Page Load

`afficherChampProvincial` était calculé à partir de `DropDownProvince` (un Widget State). Au moment du On Page Load, le Dropdown n'est pas encore monté dans l'arbre de widgets — sa valeur est `null`. Les 4 conditions OR (`== 'QC'`, `== 'BC'`, etc.) évaluaient toutes à `false`, ce qui causait un crash silencieux du Rebuild Current Page et bloquait l'hydratation de tous les champs suivants.

### 2. Initial Value des TextFields figée

En Flutter, `TextFormField.initialValue` est lu **une seule fois** au premier build du widget. Même si le Page State est mis à jour par l'Action Update Page State, les TextFields ne relisent pas leur Initial Value — ils gardent la valeur du premier rendu (la valeur par défaut du Page State, soit `""`).

### 3. Switch Initial Value figée

Le même problème que les TextFields, mais pire : `Set Form Field` ne fonctionne pas de manière fiable sur les Switch/Toggle widgets dans FlutterFlow. Le Switch gardait sa valeur par défaut (`false`) indépendamment du Page State.

---

## Solution appliquée

### Fix 1 — Remplacer DropDownProvince par Custom Function

```
AVANT : afficherChampProvincial = If/Then/Else (DropDownProvince == 'QC'/'BC'/'SK'/'MB')
APRÈS : afficherChampProvincial = calculerAfficherProvincial(profileQuery.First.province_code)
```

Lecture directe du Backend Query au lieu du Widget State. Élimine la dépendance au widget non monté.

### Fix 2 — Set Form Field pour les TextFields

Ajout de deux actions Set Form Field après l'Update Page State :

```
Set Form Field → champFederal = profileQuery.First.numero_tps (Rebuild Current Page)
Set Form Field → champProvincial = profileQuery.First.numero_tvq (Rebuild Current Page)
```

Force les TextFields à prendre la valeur DB après le premier build.

### Fix 3 — Binding direct DB pour le Switch

```
AVANT : Switch Initial Value = Page State → inscritAuxTaxes
APRÈS : Switch Initial Value = profileQuery.First.Inscrit_aux_taxes
```

Le Switch lit directement le résultat du Backend Query au premier build. Pas de Page State intermédiaire, pas de race condition.

Les actions On Toggle (Update Page State `inscritAuxTaxes`) restent en place pour que la Conditional Visibility et le Save continuent de fonctionner.

---

## Flow On Page Load final

```
Action 1 : Query Rows → profileQuery
Conditional : profileQuery is not empty
  TRUE :
    Action 2 : Update Page State (7 champs taxes)
      - afficherChampProvincial = calculerAfficherProvincial(profileQuery.First.province_code)
      - provinceSelectionnee = profileQuery.First.province_code
      - inscritAuxTaxes = profileQuery.First.Inscrit_aux_taxes
      - numeroFederalInput = profileQuery.First.numero_tps
      - numeroProvincialInput = profileQuery.First.numero_tvq
      - labelFederal = calculerLabelFederal(profileQuery.First.province_code)
      - labelProvincial = calculerLabelProvincial(profileQuery.First.province_code)
    Action 3 : Set Form Field → champFederal = profileQuery.First.numero_tps
    Action 4 : Set Form Field → champProvincial = profileQuery.First.numero_tvq
    Actions 5-14 : Set Form Field → autres champs profil (nom, prénom, etc.)
    Conditional 2 : signature URL
```

---

## Scope du test

### Testé et validé

- Profil QC avec `Inscrit_aux_taxes = true`
- Multiples cycles Save + Reload avec valeurs différentes (999/888, 123/456, 444/333, 789/001)
- Aucune régression sur les autres champs (nom, prénom, téléphone, signature)
- Synchro bidirectionnelle DB ↔ UI confirmée

### À valider en beta

- Nouveau compte sans profil en DB (branche FALSE du Conditional)
- Provinces HST (ON, NB, NS, NL, PE) — champ provincial masqué
- Provinces PST (BC, SK, MB) — champ provincial avec label "PST"
- Provinces sans taxe provinciale (AB, YT, NT, NU)
- Utilisateur avec `Inscrit_aux_taxes = false`
- Profil avec `numero_tps` ou `numero_tvq` null

---

## Leçons architecturales

### Règles pour les futures pages FlutterFlow + Supabase

1. **Ne jamais lire un Widget State au Page Load.** Le widget n'est pas encore monté. Utiliser `profileQuery.First.colonne` ou une Custom Function alimentée par le Backend Query.

2. **Initial Value se fige au premier build.** Les TextFields, Dropdowns et Switches ne relisent pas leur Initial Value après un Update Page State. C'est un comportement fondamental de Flutter, pas un bug FlutterFlow.

3. **Set Form Field fonctionne pour TextField et Dropdown**, mais pas de manière fiable pour Switch/Toggle. Pour les Switches, binder l'Initial Value directement sur le résultat du Backend Query.

4. **Un crash silencieux dans une action bloque les actions suivantes.** Toujours vérifier que les références de widgets dans les Set Form Field sont valides (pas orphelines).

### Pattern recommandé

```
On Page Load :
  1. Backend Query → profileQuery
  2. Update Page State (toutes les variables, depuis profileQuery.First)
  3. Set Form Field (pour chaque TextField — force la valeur après premier build)

Widgets :
  - TextFields : Initial Value = Page State, Set Form Field au Load
  - Switches : Initial Value = profileQuery.First.colonne (binding direct DB)
  - Dropdowns : Initial Value = Page State, Set Form Field au Load
  - Conditional Visibility : toujours sur Page State (jamais Widget State)

Save :
  - Update Row avec les Page State comme source
```
