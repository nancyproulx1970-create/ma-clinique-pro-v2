-- ============================================================
-- Migration: drop_buggy_overlap_trigger
-- ============================================================
-- Problème : trigger_check_agenda_overlap s'exécute AVANT les triggers
-- qui calculent heure_fin (ordre alphabétique : 'c' avant 's').
-- Sur INSERT, heure_fin est NULL quand check_agenda_overlap s'exécute,
-- donc la condition (NEW.heure_fin > heure_debut) ne filtre rien.
--
-- trigger_verifier_chevauchement (exécuté en dernier, 'v') recalcule
-- correctement heure_fin à partir de duree — c'est le bon à garder.
--
-- Résultat : deux triggers de chevauchement actifs simultanément,
-- le premier bugué, le second correct. On supprime le premier.
-- ============================================================

DROP TRIGGER IF EXISTS trigger_check_agenda_overlap ON "Agenda";

-- La fonction est conservée (elle pourrait être utilitaire ailleurs)
-- mais n'est plus attachée comme trigger sur Agenda.
