# PostgreSQL 16 setup (Windows)

## 1. Install

1. Download the Windows x86-64 installer for PostgreSQL 16 from EDB:
   https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
2. Run it. Keep the defaults, with these notes:
   - Components: **PostgreSQL Server**, **pgAdmin 4**, **Command Line Tools**. Stack Builder is not needed.
   - Data directory: default is fine.
   - Password for the `postgres` superuser: pick one and remember it.
   - Port: **5432** (default).
   - Locale: default.
3. Finish. The server starts as a Windows service automatically.

## 2. Put `psql` on PATH

The installer does not add the `bin` folder to PATH. In PowerShell (one time):

```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\PostgreSQL\16\bin", "User")
```

Open a **new** terminal, then check:

```powershell
psql --version
```

## 3. Create the database

```powershell
psql -U postgres -c "CREATE DATABASE olist;"
```

Enter the `postgres` password when prompted. To avoid typing it on every command, set it for the session:

```powershell
$env:PGPASSWORD = "your-password"
```

## 4. Build the warehouse

Run **from the repo root** (the `\copy` paths in step 02 are relative to it), in this order:

```powershell
psql -U postgres -d olist -f sql\01_create_tables.sql
psql -U postgres -d olist -f sql\02_load_data.sql
psql -U postgres -d olist -f sql\03_star_schema.sql
psql -U postgres -d olist -f sql\04_analysis_queries.sql
```

Expected checkpoints:

| Step | What you should see |
|---|---|
| 01 | `CREATE TABLE` ×10, no errors |
| 02 | Row counts: orders 99,441 · order_items 112,650 · reviews 98,673 · geography 19,010 · summary 99,440 |
| 03 | Four sanity checks all `t` (true) |
| 04 | 18 result sets; Q03 should show revenue 13,221,498.11 and late_delivery_pct 6.8 |

## 5. Browse in pgAdmin

Open pgAdmin 4 → Servers → PostgreSQL 16 → Databases → olist → Schemas. `stg` holds the loaded CSVs, `dw` holds the star schema (`fact_order_items`, `dim_*`, view `v_orders`).

## 6. Connect Power BI (Phase 4)

Get Data → PostgreSQL database → Server `localhost`, Database `olist` → pick the `dw` tables. If Power BI asks for the Npgsql provider, install it from the link it shows and restart Power BI.

## Troubleshooting

- `psql: error: connection ... failed: password authentication failed` → wrong password; reset it in pgAdmin or re-run the installer's repair.
- `\copy: ERROR: could not open file` → you are not in the repo root; `cd` there and re-run step 02.
- `ERROR: invalid input syntax for type boolean` → the processed CSVs were edited; re-run `notebooks/02_cleaning.ipynb` to regenerate them.
