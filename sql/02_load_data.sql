-- 02_load_data.sql
-- Load the cleaned CSVs from data/processed/ into the stg schema.
--
-- Uses psql's \copy (client-side) rather than server-side COPY, so the files
-- are read by psql from YOUR working directory and the Postgres service account
-- needs no file permissions. Run from the repo root:
--
--   psql -U postgres -d olist -f sql/02_load_data.sql
--
-- CSV conventions produced by pandas: header row, empty string = NULL,
-- booleans as True/False (accepted by Postgres BOOLEAN).

\echo 'Loading stg.orders'
\copy stg.orders FROM 'data/processed/orders.csv' WITH (FORMAT csv, HEADER true, NULL '')

\echo 'Loading stg.order_items'
\copy stg.order_items FROM 'data/processed/order_items.csv' WITH (FORMAT csv, HEADER true, NULL '')

\echo 'Loading stg.customers'
\copy stg.customers FROM 'data/processed/customers.csv' WITH (FORMAT csv, HEADER true, NULL '')

\echo 'Loading stg.sellers'
\copy stg.sellers FROM 'data/processed/sellers.csv' WITH (FORMAT csv, HEADER true, NULL '')

\echo 'Loading stg.products'
\copy stg.products FROM 'data/processed/products.csv' WITH (FORMAT csv, HEADER true, NULL '')

\echo 'Loading stg.payments'
\copy stg.payments FROM 'data/processed/payments.csv' WITH (FORMAT csv, HEADER true, NULL '')

\echo 'Loading stg.order_payments_summary'
\copy stg.order_payments_summary FROM 'data/processed/order_payments_summary.csv' WITH (FORMAT csv, HEADER true, NULL '')

\echo 'Loading stg.reviews'
\copy stg.reviews FROM 'data/processed/reviews.csv' WITH (FORMAT csv, HEADER true, NULL '')

\echo 'Loading stg.geography'
\copy stg.geography FROM 'data/processed/geography.csv' WITH (FORMAT csv, HEADER true, NULL '')

\echo 'Loading stg.category_translation'
\copy stg.category_translation FROM 'data/processed/category_translation.csv' WITH (FORMAT csv, HEADER true, NULL '')

-- Row-count check: should match the audit table at the end of 02_cleaning.ipynb
SELECT 'orders' AS tbl, COUNT(*) FROM stg.orders
UNION ALL SELECT 'order_items',            COUNT(*) FROM stg.order_items
UNION ALL SELECT 'customers',              COUNT(*) FROM stg.customers
UNION ALL SELECT 'sellers',                COUNT(*) FROM stg.sellers
UNION ALL SELECT 'products',               COUNT(*) FROM stg.products
UNION ALL SELECT 'payments',               COUNT(*) FROM stg.payments
UNION ALL SELECT 'order_payments_summary', COUNT(*) FROM stg.order_payments_summary
UNION ALL SELECT 'reviews',                COUNT(*) FROM stg.reviews
UNION ALL SELECT 'geography',              COUNT(*) FROM stg.geography
UNION ALL SELECT 'category_translation',   COUNT(*) FROM stg.category_translation;
