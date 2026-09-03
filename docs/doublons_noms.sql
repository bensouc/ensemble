-- Inventaire des doublons de noms — domaine, exercice, niveau.
-- À passer AVANT de poser ou de resserrer un index unique. Lecture seule.
-- Contexte et mode d'emploi : docs/unicite_des_noms.md
--
--   ssh ubuntu@137.74.112.70 'sudo docker exec -i ce7zx18p6oici2ucx95v5khs \
--     psql -U postgres -d postgres' < docs/doublons_noms.sql
--
-- Quatre Postgres tournent sur ce VPS : ce7zx18p6oici2ucx95v5khs est celui
-- d'Ensemble. La section 0 est là pour rendre une erreur de conteneur visible.

\pset border 2

\echo
\echo == 0. Controle d identite de la base : si ca casse, mauvais conteneur ==
SELECT current_database()                                   AS base,
       (SELECT COUNT(*) FROM schools)                       AS ecoles,
       (SELECT COUNT(*) FROM users)                         AS utilisateurs,
       (SELECT COUNT(*) FROM classrooms)                    AS classes,
       (SELECT MAX(version) FROM schema_migrations)         AS derniere_migration;

\echo
\echo == 1. Doublons EXACTS = ce que l index unique refuserait ==
SELECT 'domains (grade_id, name)' AS cible,
       COUNT(*)          AS groupes,
       SUM(n)            AS lignes_concernees,
       SUM(n) - COUNT(*) AS lignes_a_traiter
  FROM (SELECT grade_id, name, COUNT(*) n FROM domains GROUP BY 1, 2 HAVING COUNT(*) > 1) t
UNION ALL
SELECT 'challenges (skill_id, name)', COUNT(*), SUM(n), SUM(n) - COUNT(*)
  FROM (SELECT skill_id, name, COUNT(*) n FROM challenges GROUP BY 1, 2 HAVING COUNT(*) > 1) t
UNION ALL
SELECT 'grades (school_id, name)', COUNT(*), SUM(n), SUM(n) - COUNT(*)
  FROM (SELECT school_id, name, COUNT(*) n FROM grades GROUP BY 1, 2 HAVING COUNT(*) > 1) t;

\echo
\echo == 2. Noms NULL ou vides ==
SELECT 'domains' AS cible, COUNT(*) FROM domains WHERE name IS NULL OR btrim(name) = ''
UNION ALL SELECT 'challenges', COUNT(*) FROM challenges WHERE name IS NULL OR btrim(name) = ''
UNION ALL SELECT 'grades', COUNT(*) FROM grades WHERE name IS NULL OR btrim(name) = '';

\echo
\echo == 3. Quasi-doublons, casse et espaces ignores, non bloquants ==
SELECT 'domains' AS cible, COUNT(*) AS groupes
  FROM (SELECT grade_id, lower(btrim(name)) k FROM domains GROUP BY 1, 2 HAVING COUNT(*) > 1) t
UNION ALL
SELECT 'challenges', COUNT(*)
  FROM (SELECT skill_id, lower(btrim(name)) k FROM challenges GROUP BY 1, 2 HAVING COUNT(*) > 1) t
UNION ALL
SELECT 'grades', COUNT(*)
  FROM (SELECT school_id, lower(btrim(name)) k FROM grades GROUP BY 1, 2 HAVING COUNT(*) > 1) t;

\echo
\echo == 4. Volume total, pour situer ==
SELECT 'domains' AS cible, COUNT(*) FROM domains
UNION ALL SELECT 'challenges', COUNT(*) FROM challenges
UNION ALL SELECT 'grades', COUNT(*) FROM grades;

\echo
\echo == 5. Doublons de domaines en detail, avec ce qui pend dessous ==
SELECT d.grade_id, d.name, d.id,
       (SELECT COUNT(*) FROM skills s WHERE s.domain_id = d.id)            AS competences,
       (SELECT COUNT(*) FROM belts b WHERE b.domain_id = d.id)             AS ceintures,
       (SELECT COUNT(*) FROM work_plan_domains w WHERE w.domain_id = d.id) AS plans
  FROM domains d
  JOIN (SELECT grade_id, name FROM domains GROUP BY 1, 2 HAVING COUNT(*) > 1) dup
    ON dup.grade_id = d.grade_id AND dup.name = d.name
 ORDER BY d.grade_id, d.name, d.id;

\echo
\echo == 6. Doublons exercices en detail, avec usage dans les plans ==
SELECT c.skill_id, c.name, c.id, c.for_belt,
       (SELECT COUNT(*) FROM work_plan_skills w WHERE w.challenge_id = c.id) AS plans
  FROM challenges c
  JOIN (SELECT skill_id, name FROM challenges GROUP BY 1, 2 HAVING COUNT(*) > 1) dup
    ON dup.skill_id = c.skill_id AND dup.name = c.name
 ORDER BY c.skill_id, c.name, c.id;

\echo
\echo == 7. Doublons de niveaux en detail ==
SELECT g.school_id, g.name, g.id, g.grade_level,
       (SELECT COUNT(*) FROM domains d WHERE d.grade_id = g.id)    AS domaines,
       (SELECT COUNT(*) FROM classrooms c WHERE c.grade_id = g.id) AS classes
  FROM grades g
  JOIN (SELECT school_id, name FROM grades GROUP BY 1, 2 HAVING COUNT(*) > 1) dup
    ON dup.school_id = g.school_id AND dup.name = g.name
 ORDER BY g.school_id, g.name, g.id;
