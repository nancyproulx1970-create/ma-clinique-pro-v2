# Roadmap Ma Clinique Pro V2

## V1 — Stabilisation onboarding (avril-juin 2026)
Cible : 5-15 utilisateurs réels en onboarding contrôlé. Aucun bug critique pendant 1 mois.

### P0 — Bloquant launch
- [ ] #15 Statut 'finalise' au save Enregistrer
- [x] Bug #2 UPSERT NoteObservation (PR #14 mergée)
- [x] EF auto-régénération signed_url + pg_cron
- [x] SessionGuard fix Persisted=TRUE (validation Companion pending)

### P1 — Important
- [ ] #16 Test SessionGuard via Companion
- [ ] #17 Harmoniser boutons IA avec currentBrouillonId
- [ ] #18 Stabilisation AddAppointments

### P2 — À faire
- [ ] #19 Cleanup 4 unused queries
- [ ] #20 Restore-route MVP unlock
- [ ] #21 Build APK + Play Store
- [ ] #22 S3 refactor BottomSheet
- [ ] #24 Auto-save UPSERT NoteObservation

## V2 — Conformité + IA (juillet 2026+)
- [ ] #23 Architecture Share photos Loi 25 + Cliniciel-level
- [ ] Agent IA Vision photos cliniques (cf. memory/reference_roadmap_agents_ia.md)
- [ ] Agent IA Calcul kilométrage fiscal
