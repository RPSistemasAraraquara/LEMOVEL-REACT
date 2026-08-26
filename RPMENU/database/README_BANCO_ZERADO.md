# Banco zerado RPMENU

Arquivos gerados a partir da estrutura do banco local `RP`:

1. `01_create_database_rpmenu_zerado.sql`
   - Cria o banco `RPMENU_ZERADO` somente se ele ainda nao existir.
   - Nao usa DROP.

2. `02_schema_rpmenu_zerado.sql`
   - Estrutura completa sem dados.
   - Gerado com `pg_dump --schema-only --no-owner --no-privileges`.

## Como restaurar manualmente

```powershell
$env:PGPASSWORD='123'
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -h 127.0.0.1 -p 5432 -U postgres -d postgres -f '01_create_database_rpmenu_zerado.sql'
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -h 127.0.0.1 -p 5432 -U postgres -d RPMENU_ZERADO -f '02_schema_rpmenu_zerado.sql'
```

## Configuracao da API

Para a API apontar para este banco local, use no `RPFood.json`:

```json
"DATABASE_ALIAS": "RPMENU_ZERADO"
```
