-- Contrôle d'après-déploiement : la migration des index uniques est-elle
-- passée, et les trois index sont-ils là, uniques et valides. Lecture seule.
-- Contexte : docs/unicite_des_noms.md
--
--   ssh ubuntu@137.74.112.70 'sudo docker exec -i ce7zx18p6oici2ucx95v5khs \
--     psql -U postgres -d postgres' < docs/verif_index_unicite.sql

\pset border 2

\echo
\echo == La migration est-elle passee ==
SELECT version FROM schema_migrations WHERE version = '20260903120000';

\echo
\echo == Les trois index sont-ils la, et valides ==
SELECT c.relname AS index_nom, i.indisunique AS unique, i.indisvalid AS valide
  FROM pg_class c
  JOIN pg_index i ON i.indexrelid = c.oid
 WHERE c.relname IN ('index_domains_on_grade_id_and_name',
                     'index_challenges_on_skill_id_and_name',
                     'index_grades_on_school_id_and_name')
 ORDER BY c.relname;
