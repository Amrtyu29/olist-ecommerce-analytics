# Data dictionary — Olist Brazilian E-commerce dataset

Nine CSV files from Kaggle. One plain-English line per column. Row counts are the published figures and are verified in `notebooks/01_data_understanding.ipynb`.

## olist_orders_dataset.csv (99,441 rows) — one row per order

| Column | Meaning |
|---|---|
| order_id | Unique order identifier (primary key). |
| customer_id | Key to the customers table. **One per order**, not per person — use `customer_unique_id` from customers to identify a person. |
| order_status | Lifecycle status: delivered, shipped, canceled, unavailable, invoiced, processing, created, approved. |
| order_purchase_timestamp | When the customer placed the order. |
| order_approved_at | When payment was approved. |
| order_delivered_carrier_date | When the seller handed the parcel to the carrier. |
| order_delivered_customer_date | When the customer actually received it (null if not delivered). |
| order_estimated_delivery_date | Delivery date promised to the customer at purchase. |

## olist_order_items_dataset.csv (112,650 rows) — one row per item within an order

| Column | Meaning |
|---|---|
| order_id | Key to orders. |
| order_item_id | Sequence number of the item inside the order (1, 2, 3…). Composite key with order_id. |
| product_id | Key to products. |
| seller_id | Key to sellers. |
| shipping_limit_date | Deadline by which the seller must ship the item to the carrier. |
| price | Item price in BRL (excludes freight). |
| freight_value | Freight charged for this item in BRL. |

## olist_customers_dataset.csv (99,441 rows) — one row per order's customer record

| Column | Meaning |
|---|---|
| customer_id | Key used by orders. Unique per order. |
| customer_unique_id | Stable identifier of the actual person. Use this for repeat-purchase, RFM and cohorts. |
| customer_zip_code_prefix | First 5 digits of the customer's postcode. |
| customer_city | City name. |
| customer_state | Two-letter Brazilian state code (SP, RJ, MG…). |

## olist_sellers_dataset.csv (3,095 rows) — one row per seller

| Column | Meaning |
|---|---|
| seller_id | Unique seller identifier. |
| seller_zip_code_prefix | First 5 digits of the seller's postcode. |
| seller_city | City name. |
| seller_state | Two-letter state code. |

## olist_products_dataset.csv (32,951 rows) — one row per product

| Column | Meaning |
|---|---|
| product_id | Unique product identifier. |
| product_category_name | Category in Portuguese; translate via the translation table. |
| product_name_lenght | Number of characters in the product name (sic — misspelt in source). |
| product_description_lenght | Number of characters in the description (sic). |
| product_photos_qty | Number of listing photos. |
| product_weight_g | Weight in grams. |
| product_length_cm | Package length in cm. |
| product_height_cm | Package height in cm. |
| product_width_cm | Package width in cm. |

## olist_order_payments_dataset.csv (103,886 rows) — one row per payment instalment/method per order

| Column | Meaning |
|---|---|
| order_id | Key to orders. An order can have several payment rows (e.g. voucher + card). |
| payment_sequential | Sequence of this payment within the order. |
| payment_type | credit_card, boleto, voucher, debit_card, not_defined. |
| payment_installments | Number of instalments chosen. |
| payment_value | Amount paid in this row, BRL. Sum per order ≈ price + freight. |

## olist_order_reviews_dataset.csv (99,224 rows) — one row per review

| Column | Meaning |
|---|---|
| review_id | Review identifier. **Not unique** — the same review_id can appear against multiple orders. |
| order_id | Key to orders. Some orders have more than one review. |
| review_score | 1 (worst) to 5 (best). |
| review_comment_title | Optional title text (mostly null). |
| review_comment_message | Optional free-text comment (Portuguese, ~60% null). |
| review_creation_date | Date the review survey was sent. |
| review_answer_timestamp | When the customer answered. |

## olist_geolocation_dataset.csv (1,000,163 rows) — one row per postcode-prefix coordinate sample

| Column | Meaning |
|---|---|
| geolocation_zip_code_prefix | 5-digit postcode prefix; joins to customer/seller zip prefixes. Many rows per prefix. |
| geolocation_lat | Latitude. |
| geolocation_lng | Longitude. |
| geolocation_city | City name (inconsistent spelling/accents). |
| geolocation_state | State code. |

## product_category_name_translation.csv (71 rows)

| Column | Meaning |
|---|---|
| product_category_name | Category in Portuguese. |
| product_category_name_english | Category in English. |

## Data-quality issues confirmed in `01_data_understanding.ipynb`

| Issue | Measured | Handled in `02_cleaning.ipynb` |
|---|---|---|
| Orders with no order_items rows | 775 (603 unavailable, 164 canceled) | Kept in `orders`; drop out of the fact table naturally |
| Orders with no payment row | 1 | Kept |
| Delivered orders with null delivery date | 8 | Kept; `is_late` is null for them |
| Review rows sharing a `review_id` | 1,603 | Latest review per order kept (551 rows removed) |
| Orders with more than one review | 547 | As above |
| Geolocation exact duplicate rows | 261,831 of 1,000,163 | De-duplicated, then one row per prefix (19,010) |
| Coordinates outside Brazil | 33 | Dropped |
| Categories without English translation | 2 (pc_gamer, portateis_cozinha...) | Hand-translated |
| Products with null category | 610 | Labelled `unknown` |
| Orders where payments ≠ price + freight by > R$1 | 249 (median diff 0.00) | Kept; `payment_total` carried separately |
| Price / freight IQR outliers | 7.5% / 10.8% of items | Flagged, not dropped |
| Sparse months | Sep–Dec 2016, Sep–Oct 2018 | Trim to 2017-01 → 2018-08 for time series |
| `customer_id` is per order | 99,441 ids for 96,096 people | Use `customer_unique_id` for repeat/RFM/cohorts |

## Processed tables (`data/processed/`)

| File | Rows | Key | Added columns |
|---|---|---|---|
| orders.csv | 99,441 | order_id | order_month, delivery_days, estimated_delivery_days, days_late, is_late, approval_hours, carrier_days, is_delivered |
| order_items.csv | 112,650 | order_id + order_item_id | is_price_outlier, is_freight_outlier, item_total, freight_ratio |
| customers.csv | 99,441 | customer_id | is_repeat_customer; city normalised |
| sellers.csv | 3,095 | seller_id | city normalised |
| products.csv | 32,951 | product_id | product_category_name_english, product_volume_cm3; typo columns renamed to *_length |
| payments.csv | 103,886 | order_id + payment_sequential | not_defined → unknown |
| order_payments_summary.csv | 99,440 | order_id | payment_total, n_payments, main_payment_type, max_installments |
| reviews.csv | 98,673 | order_id | de-duplicated |
| geography.csv | 19,010 | zip_code_prefix | lat, lng, city, state, n_samples |
| category_translation.csv | 73 | product_category_name | +2 hand-translated rows |
