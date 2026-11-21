SELECT pg_advisory_xact_lock(271828, 17) AS locked \gset
SELECT NOT EXISTS (SELECT FROM pg_namespace WHERE nspname = 'analytics') AS needs_install \gset
\if :needs_install
\ir sql/base/01_schema.sql
\ir sql/base/02_seed.sql
\ir sql/03_analytics.sql
\endif
