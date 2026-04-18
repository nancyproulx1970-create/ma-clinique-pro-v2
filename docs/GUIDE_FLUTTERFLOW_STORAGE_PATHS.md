# Guide — Chemins de stockage Supabase dans FlutterFlow

> **Contexte** : Les uploads actuels utilisent des noms de fichiers plats (`{timestamp}.jpg`)
> sans dossier par utilisateur. Cela empêche l'isolation stricte par praticienne.
>
> Ce guide décrit les changements à faire dans FlutterFlow **avant** toute migration
> des fichiers existants.

---

## Règle universelle

Chaque fichier uploadé doit commencer par l'UID de la praticienne connectée :

```
{bucket}/{uid}/{nom_du_fichier}
```

Dans FlutterFlow, l'UID est accessible via :
```
currentUserUid   (variable globale Supabase Auth)
```

---

## Les 4 buckets et leurs règles

### 1. `signatures` — Privé · 2 MB · Signatures uniquement

**Contient :**
- Signature professionnelle (apparaît sur les reçus et dossiers cliniques)
- Signature de consentement patient

**Chemin attendu :**
```
signatures/{uid}/signature_pro.png
signatures/{uid}/signature_patient_{patient_id}.png
```

**Colonnes DB à mettre à jour après upload :**
- `profils_professionnels.signature_pro_url`
- `Recus_Officiels.signature_pro_url`
- `Dossier_Clinique.signature_professionnelle`
- `Patients.signature_aprouvee`

**Dans FlutterFlow — action Upload File :**
1. Bucket : `signatures`
2. Chemin (path) : `[currentUserUid]/signature_pro.png`
   - Pour la signature patient : `[currentUserUid]/signature_patient_[patientId].png`
3. Après upload : sauvegarder l'URL publique signée dans la colonne DB correspondante

---

### 2. `clinic-assets` — Public · 5 MB · Logos uniquement

**Contient :**
- Logo de la clinique (affiché sur les reçus, visible par les patients)

**Ce bucket est PUBLIC** — les fichiers sont accessibles sans authentification.
C'est intentionnel pour les logos affichés sur des documents partagés.

**Chemin attendu :**
```
clinic-assets/{uid}/logo.png
```

**Colonnes DB à mettre à jour après upload :**
- `profils_professionnels.logo_clinique_url`
- `profils_professionnels.logo_clinique`

**Dans FlutterFlow — action Upload File :**
1. Bucket : `clinic-assets`
2. Chemin (path) : `[currentUserUid]/logo.png`
3. Après upload : sauvegarder l'URL publique dans `logo_clinique_url`

> ⚠️ Ne pas uploader de signatures dans `clinic-assets`. Ce bucket est public.

---

### 3. `soins_photos` — Privé · 10 MB · Photos cliniques

**Contient :**
- Photos prises lors des soins podologiques
- Liées à un patient et à un rendez-vous précis

**Chemin attendu :**
```
soins_photos/{uid}/{patient_id}/{agenda_id}_{timestamp}.jpg
```

**Colonne DB à mettre à jour après upload :**
- `Photos_Soins.url_photo`
- Simultanément, renseigner `Photos_Soins.patient_id` et `Photos_Soins.agenda_id`

**Dans FlutterFlow — action Upload File :**
1. Bucket : `soins_photos`
2. Chemin (path) : `[currentUserUid]/[selectedPatientId]/[selectedRendezVousId]_[timestamp].jpg`
3. Après upload : insérer une ligne dans `Photos_Soins` avec :
   - `url_photo` = URL retournée
   - `patient_id` = ID du patient sélectionné
   - `agenda_id` = ID du RDV en cours
   - `owner_id` = `currentUserUid`

---

### 4. `patient-photos` — Privé · 20 MB · Documents patients

**Contient :**
- Photos de prescriptions / ordonnances
- Reçus de dépenses (`Depenses.photo_recu`)
- Autres documents patients non cliniques

**Chemin attendu :**
```
patient-photos/{uid}/{timestamp}.jpg
```

**Colonnes DB à mettre à jour après upload :**
- `Depenses.photo_recu`

**Dans FlutterFlow — action Upload File :**
1. Bucket : `patient-photos`
2. Chemin (path) : `[currentUserUid]/[timestamp].jpg`
3. Après upload : sauvegarder l'URL dans la colonne correspondante

---

## Pages FlutterFlow à modifier

| Page | Upload concerné | Bucket actuel | Bucket cible | Chemin cible |
|------|----------------|---------------|--------------|--------------|
| `ProfileSetup` / `ProfilPro` | Signature professionnelle | `clinic-assets` | `signatures` | `{uid}/signature_pro.png` |
| `ProfileSetup` / `ProfilPro` | Logo clinique | `clinic-assets` | `clinic-assets` | `{uid}/logo.png` |
| `DetailVisite` / `NoteObservation` | Photos de soins | `soins_photos` | `soins_photos` | `{uid}/{patient_id}/{rdv_id}_{ts}.jpg` |
| `AjouterPatient` / `DossierPatient` | Signature consentement | `clinic-assets` | `signatures` | `{uid}/signature_patient_{id}.png` |
| `RecuPaiement` | Signature sur reçu | `clinic-assets` | `signatures` | `{uid}/signature_pro.png` |
| `Depenses` | Photo reçu dépense | `patient-photos` | `patient-photos` | `{uid}/{ts}.jpg` |

---

## Ordre de travail recommandé

1. **Modifier chaque page dans FlutterFlow** selon le tableau ci-dessus
2. **Tester** en créant un compte de test — vérifier que les uploads arrivent dans le bon bucket avec le bon chemin
3. **Vérifier l'isolation** : connecter deux comptes différents et confirmer qu'aucun ne peut voir les fichiers de l'autre
4. **Valider** en production sur votre propre compte
5. **Ensuite seulement** : migrer les fichiers existants vers les nouveaux chemins (étape séparée)

---

## Accès aux fichiers privés depuis FlutterFlow

Pour les buckets privés (`signatures`, `soins_photos`, `patient-photos`), les URLs
ne sont pas publiques. Il faut utiliser des **signed URLs** (URLs temporaires signées).

Dans FlutterFlow, utiliser l'API Supabase Storage :
```
GET /storage/v1/object/sign/{bucket}/{path}
Body: { "expiresIn": 3600 }  ← valide 1 heure
```

Ou via le SDK Supabase Flutter (si vous utilisez du custom code) :
```dart
final signedUrl = await supabase.storage
  .from('signatures')
  .createSignedUrl('${uid}/signature_pro.png', 3600);
```

---

## Récapitulatif des buckets

| Bucket | Visibilité | Taille max | Types acceptés | Isolation |
|--------|-----------|------------|----------------|-----------|
| `clinic-assets` | **Public** | 5 MB | PNG, JPEG, WebP | Par uid dans le chemin |
| `signatures` | Privé | 2 MB | PNG, JPEG, WebP | Par uid dans le chemin |
| `patient-photos` | Privé | 20 MB | JPEG, PNG | Par uid dans le chemin |
| `soins_photos` | Privé | 10 MB | JPEG, PNG, WebP, HEIC | Par uid dans le chemin |
