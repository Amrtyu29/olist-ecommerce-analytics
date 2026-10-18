-- 03_star_schema.sql
-- Dimensional model in schema dw.
--
--   fact_order_items  grain = one row per order item (112,650 rows)
--      |-- dim_date        (order purchase date)
--      |-- dim_customer    (one row per customer_id, carries customer_unique_id)
--      |-- dim_seller
--      |-- dim_product     (English category)
--      |-- dim_geography   (zip prefix -> lat/lng/city/state; used by customer & seller)
--   v_orders           convenience view: one row per order, for order-level KPIs
--
-- Design choices (see docs/decision_log.md):
--   * Item grain, not order grain: seller, product and freight only exist per item.
--   * Order-level attributes (status, timestamps, payment type, review score) are
--     carried on the fact as DEGENERATE dimensions so most dashboard questions need
--     no join at all. Order-level *metrics* (AOV, repeat rate, review averages) must
--     use v_orders to avoid counting multi-item orders several times.
--   * Revenue   = SUM(price)              (merchandise value, what sellers earn)
--     GMV       = SUM(price + freight)    (what customers pay)
--   * Surrogate integer keys for dims make Power BI relationships fast and simple.
--
-- Run: psql -U postgres -d olist -f sql/03_star_schema.sql

DROP SCHEMA IF EXISTS dw CASCADE;
CREATE SCHEMA dw;

------------------------------------------------------------------------------
-- dim_date : one row per calendar day covering the data range
------------------------------------------------------------------------------
CREATE TABLE dw.dim_date AS
SELECT
    CAST(TO_CHAR(d, 'YYYYMMDD') AS INTEGER)   AS date_key,
    CAST(d AS DATE)                           AS full_date,
    EXTRACT(YEAR  FROM d)::INTEGER            AS year,
    EXTRACT(QUARTER FROM d)::INTEGER          AS quarter,
    EXTRACT(MONTH FROM d)::INTEGER            AS month,
    TO_CHAR(d, 'Mon')                         AS month_name,
    CAST(DATE_TRUNC('month', d) AS DATE)      AS month_start,
    TO_CHAR(d, 'YYYY-MM')                     AS year_month,
    EXTRACT(ISODOW FROM d)::INTEGER           AS iso_weekday,
    TO_CHAR(d, 'Dy')                          AS weekday_name,
    EXTRACT(ISODOW FROM d) >= 6               AS is_weekend
FROM generate_series(DATE '2016-09-01', DATE '2018-12-31', INTERVAL '1 day') AS g(d);

ALTER TABLE dw.dim_date ADD PRIMARY KEY (date_key);

------------------------------------------------------------------------------
-- dim_geography : one row per zip prefix
------------------------------------------------------------------------------
CREATE TABLE dw.dim_geography AS
SELECT
    ROW_NUMBER() OVER (ORDER BY zip_code_prefix)::INTEGER AS geography_key,
    zip_code_prefix,
    city,
    state,
    lat,
    lng
FROM stg.geography;

ALTER TABLE dw.dim_geography ADD PRIMARY KEY (geography_key);
CREATE UNIQUE INDEX ux_dim_geography_zip ON dw.dim_geography (zip_code_prefix);

------------------------------------------------------------------------------
-- dim_customer : one row per customer_id (order-level id) with the person id
--                and geography. ~0.3% of zip prefixes have no geolocation row;
--                those customers keep their city/state from the customers file.
------------------------------------------------------------------------------
CREATE TABLE dw.dim_customer AS
SELECT
    ROW_NUMBER() OVER (ORDER BY c.customer_id)::INTEGER AS customer_key,
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix                          AS zip_code_prefix,
    c.customer_city                                     AS city,
    c.customer_state                                    AS state,
    g.geography_key,
    c.is_repeat_customer
FROM stg.customers c
LEFT JOIN dw.dim_geography g ON g.zip_code_prefix = c.customer_zip_code_prefix;

ALTER TABLE dw.dim_customer ADD PRIMARY KEY (customer_key);
CREATE UNIQUE INDEX ux_dim_customer_id ON dw.dim_customer (customer_id);
CREATE INDEX ix_dim_customer_unique ON dw.dim_customer (customer_unique_id);

------------------------------------------------------------------------------
-- dim_seller
------------------------------------------------------------------------------
CREATE TABLE dw.dim_seller AS
SELECT
    ROW_NUMBER() OVER (ORDER BY s.seller_id)::INTEGER AS seller_key,
    s.seller_id,
    s.seller_zip_code_prefix                          AS zip_code_prefix,
    s.seller_city                                     AS city,
    s.seller_state                                    AS state,
    g.geography_key
FROM stg.sellers s
LEFT JOIN dw.dim_geography g ON g.zip_code_prefix = s.seller_zip_code_prefix;

ALTER TABLE dw.dim_seller ADD PRIMARY KEY (seller_key);
CREATE UNIQUE INDEX ux_dim_seller_id ON dw.dim_seller (seller_id);

------------------------------------------------------------------------------
-- dim_product
------------------------------------------------------------------------------
CREATE TABLE dw.dim_product AS
SELECT
    ROW_NUMBER() OVER (ORDER BY product_id)::INTEGER AS product_key,
    product_id,
    product_category_name                            AS category_pt,
    product_category_name_english                    AS category,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_volume_cm3
FROM stg.products;

ALTER TABLE dw.dim_product ADD PRIMARY KEY (product_key);
CREATE UNIQUE INDEX ux_dim_product_id ON dw.dim_product (product_id);

------------------------------------------------------------------------------
-- fact_order_items : grain = one order item
------------------------------------------------------------------------------
CREATE TABLE dw.fact_order_items AS
SELECT
    -- keys
    oi.order_id,
    oi.order_item_id,
    CAST(TO_CHAR(o.order_purchase_timestamp, 'YYYYMMDD') AS INTEGER) AS date_key,
    c.customer_key,
    s.seller_key,
    p.product_key,
    -- degenerate order attributes
    o.order_status,
    o.is_delivered,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    o.delivery_days,
    o.days_late,
    o.is_late,
    pay.main_payment_type,
    pay.max_installments,
    r.review_score,
    -- measures
    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value       AS item_total,
    oi.is_price_outlier,
    oi.is_freight_outlier,
    -- share of the order's payment attributable to this item (for payment-based revenue)
    CASE WHEN o_tot.order_item_total > 0
         THEN pay.payment_total * (oi.price + oi.freight_value) / o_tot.order_item_total
    END                               AS payment_allocated
FROM stg.order_items oi
JOIN stg.orders o                       ON o.order_id = oi.order_id
JOIN dw.dim_customer c                  ON c.customer_id = o.customer_id
JOIN dw.dim_seller s                    ON s.seller_id = oi.seller_id
JOIN dw.dim_product p                   ON p.product_id = oi.product_id
LEFT JOIN stg.order_payments_summary pay ON pay.order_id = oi.order_id
LEFT JOIN stg.reviews r                  ON r.order_id = oi.order_id
LEFT JOIN (
    SELECT order_id, SUM(price + freight_value) AS order_item_total
    FROM stg.order_items GROUP BY order_id
) o_tot ON o_tot.order_id = oi.order_id;

ALTER TABLE dw.fact_order_items ADD PRIMARY KEY (order_id, order_item_id);
CREATE INDEX ix_fact_date     ON dw.fact_order_items (date_key);
CREATE INDEX ix_fact_customer ON dw.fact_order_items (customer_key);
CREATE INDEX ix_fact_seller   ON dw.fact_order_items (seller_key);
CREATE INDEX ix_fact_product  ON dw.fact_order_items (product_key);

------------------------------------------------------------------------------
-- v_orders : one row per order (use for AOV, repeat rate, review averages)
------------------------------------------------------------------------------
CREATE VIEW dw.v_orders AS
SELECT
    o.order_id,
    CAST(TO_CHAR(o.order_purchase_timestamp, 'YYYYMMDD') AS INTEGER) AS date_key,
    o.order_month,
    c.customer_key,
    c.customer_unique_id,
    c.state                              AS customer_state,
    o.order_status,
    o.is_delivered,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    o.delivery_days,
    o.estimated_delivery_days,
    o.days_late,
    o.is_late,
    o.approval_hours,
    o.carrier_days,
    pay.payment_total,
    pay.main_payment_type,
    pay.max_installments,
    r.review_score,
    agg.n_items,
    agg.revenue,
    agg.freight,
    agg.gmv
FROM stg.orders o
JOIN dw.dim_customer c                   ON c.customer_id = o.customer_id
LEFT JOIN stg.order_payments_summary pay ON pay.order_id = o.order_id
LEFT JOIN stg.reviews r                  ON r.order_id = o.order_id
LEFT JOIN (
    SELECT order_id,
           COUNT(*)                   AS n_items,
           SUM(price)                 AS revenue,
           SUM(freight_value)         AS freight,
           SUM(price + freight_value) AS gmv
    FROM stg.order_items GROUP BY order_id
) agg ON agg.order_id = o.order_id;

------------------------------------------------------------------------------
-- Sanity checks
------------------------------------------------------------------------------
SELECT 'fact rows = stg.order_items rows' AS check_name,
       (SELECT COUNT(*) FROM dw.fact_order_items) = (SELECT COUNT(*) FROM stg.order_items) AS passed
UNION ALL
SELECT 'every fact row has a date_key in dim_date',
       NOT EXISTS (SELECT 1 FROM dw.fact_order_items f LEFT JOIN dw.dim_date d USING (date_key) WHERE d.date_key IS NULL)
UNION ALL
SELECT 'fact revenue = stg revenue',
       (SELECT SUM(price) FROM dw.fact_order_items) = (SELECT SUM(price) FROM stg.order_items)
UNION ALL
SELECT 'v_orders rows = stg.orders rows',
       (SELECT COUNT(*) FROM dw.v_orders) = (SELECT COUNT(*) FROM stg.orders);
