-- 01_create_tables.sql
-- Staging tables that mirror the cleaned CSVs in data/processed/ (output of
-- notebooks/02_cleaning.ipynb). Column order matches the CSV headers exactly so
-- 02_load_data.sql can COPY without a column list.
--
-- Why stage the *cleaned* files rather than the raw Kaggle CSVs?
--   Typing, de-duplication and translation are documented once, in Python, with
--   before/after counts. SQL then does what SQL is best at: modelling and
--   aggregation. (The raw files stay in data/raw for auditability.)
--
-- Run (from the repo root, after CREATE DATABASE olist):
--   psql -U postgres -d olist -f sql/01_create_tables.sql

DROP SCHEMA IF EXISTS stg CASCADE;
CREATE SCHEMA stg;

CREATE TABLE stg.orders (
    order_id                       TEXT PRIMARY KEY,
    customer_id                    TEXT NOT NULL,
    order_status                   TEXT NOT NULL,
    order_purchase_timestamp       TIMESTAMP NOT NULL,
    order_approved_at              TIMESTAMP,
    order_delivered_carrier_date   TIMESTAMP,
    order_delivered_customer_date  TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP NOT NULL,
    order_month                    DATE NOT NULL,
    delivery_days                  NUMERIC,
    estimated_delivery_days        NUMERIC,
    days_late                      NUMERIC,
    is_late                        BOOLEAN,
    approval_hours                 NUMERIC,
    carrier_days                   NUMERIC,
    is_delivered                   BOOLEAN NOT NULL
);

CREATE TABLE stg.order_items (
    order_id            TEXT NOT NULL,
    order_item_id       INTEGER NOT NULL,
    product_id          TEXT NOT NULL,
    seller_id           TEXT NOT NULL,
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10,2) NOT NULL,
    freight_value       NUMERIC(10,2) NOT NULL,
    is_price_outlier    BOOLEAN NOT NULL,
    is_freight_outlier  BOOLEAN NOT NULL,
    item_total          NUMERIC(10,2) NOT NULL,
    freight_ratio       NUMERIC,
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE stg.customers (
    customer_id               TEXT PRIMARY KEY,
    customer_unique_id        TEXT NOT NULL,
    customer_zip_code_prefix  TEXT NOT NULL,     -- TEXT keeps leading zeros ('01001')
    customer_city             TEXT,
    customer_state            TEXT,
    is_repeat_customer        BOOLEAN NOT NULL
);

CREATE TABLE stg.sellers (
    seller_id               TEXT PRIMARY KEY,
    seller_zip_code_prefix  TEXT NOT NULL,
    seller_city             TEXT,
    seller_state            TEXT
);

CREATE TABLE stg.products (
    product_id                     TEXT PRIMARY KEY,
    product_category_name          TEXT,
    product_name_length            NUMERIC,
    product_description_length     NUMERIC,
    product_photos_qty             NUMERIC,
    product_weight_g               NUMERIC,
    product_length_cm              NUMERIC,
    product_height_cm              NUMERIC,
    product_width_cm               NUMERIC,
    product_category_name_english  TEXT NOT NULL,
    product_volume_cm3             NUMERIC
);

CREATE TABLE stg.payments (
    order_id              TEXT NOT NULL,
    payment_sequential    INTEGER NOT NULL,
    payment_type          TEXT NOT NULL,
    payment_installments  INTEGER NOT NULL,
    payment_value         NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE stg.order_payments_summary (
    order_id           TEXT PRIMARY KEY,
    payment_total      NUMERIC(10,2) NOT NULL,
    n_payments         INTEGER NOT NULL,
    main_payment_type  TEXT NOT NULL,
    max_installments   INTEGER NOT NULL
);

CREATE TABLE stg.reviews (
    review_id                TEXT NOT NULL,
    order_id                 TEXT PRIMARY KEY,   -- one review per order after cleaning
    review_score             SMALLINT NOT NULL,
    review_comment_title     TEXT,
    review_comment_message   TEXT,
    review_creation_date     TIMESTAMP,
    review_answer_timestamp  TIMESTAMP
);

CREATE TABLE stg.geography (
    zip_code_prefix  TEXT PRIMARY KEY,
    lat              DOUBLE PRECISION NOT NULL,
    lng              DOUBLE PRECISION NOT NULL,
    city             TEXT,
    state            TEXT,
    n_samples        INTEGER
);

CREATE TABLE stg.category_translation (
    product_category_name          TEXT PRIMARY KEY,
    product_category_name_english  TEXT NOT NULL
);
