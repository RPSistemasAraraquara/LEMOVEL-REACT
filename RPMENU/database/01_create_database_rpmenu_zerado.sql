-- RPMENU - cria banco zerado sem apagar banco existente.
-- Execute conectado no banco postgres:
-- psql -h 127.0.0.1 -p 5432 -U postgres -d postgres -f 01_create_database_rpmenu_zerado.sql

SELECT 'CREATE DATABASE "RPMENU_ZERADO" WITH OWNER postgres ENCODING ''UTF8'' TEMPLATE template0'
WHERE NOT EXISTS (
  SELECT 1
  FROM pg_database
  WHERE datname = 'RPMENU_ZERADO'
)\gexec
