# Entity-relationship diagram — raw Olist tables

`orders` is the hub. Every other transactional table hangs off `order_id`; `customers`, `sellers` and `products` are lookup tables; `geolocation` joins to both customers and sellers on the postcode prefix.

```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : places
    ORDERS ||--|{ ORDER_ITEMS : contains
    ORDERS ||--|{ ORDER_PAYMENTS : "paid by"
    ORDERS ||--o{ ORDER_REVIEWS : "reviewed in"
    PRODUCTS ||--o{ ORDER_ITEMS : "sold as"
    SELLERS ||--o{ ORDER_ITEMS : fulfils
    CATEGORY_TRANSLATION ||--o{ PRODUCTS : translates
    GEOLOCATION }o--o{ CUSTOMERS : "zip prefix"
    GEOLOCATION }o--o{ SELLERS : "zip prefix"

    CUSTOMERS {
        string customer_id PK
        string customer_unique_id
        string customer_zip_code_prefix
        string customer_city
        string customer_state
    }
    ORDERS {
        string order_id PK
        string customer_id FK
        string order_status
        datetime order_purchase_timestamp
        datetime order_approved_at
        datetime order_delivered_carrier_date
        datetime order_delivered_customer_date
        datetime order_estimated_delivery_date
    }
    ORDER_ITEMS {
        string order_id FK
        int order_item_id
        string product_id FK
        string seller_id FK
        datetime shipping_limit_date
        float price
        float freight_value
    }
    ORDER_PAYMENTS {
        string order_id FK
        int payment_sequential
        string payment_type
        int payment_installments
        float payment_value
    }
    ORDER_REVIEWS {
        string review_id
        string order_id FK
        int review_score
        string review_comment_title
        string review_comment_message
        datetime review_creation_date
        datetime review_answer_timestamp
    }
    PRODUCTS {
        string product_id PK
        string product_category_name FK
        int product_name_lenght
        int product_description_lenght
        int product_photos_qty
        float product_weight_g
        float product_length_cm
        float product_height_cm
        float product_width_cm
    }
    SELLERS {
        string seller_id PK
        string seller_zip_code_prefix
        string seller_city
        string seller_state
    }
    GEOLOCATION {
        string geolocation_zip_code_prefix
        float geolocation_lat
        float geolocation_lng
        string geolocation_city
        string geolocation_state
    }
    CATEGORY_TRANSLATION {
        string product_category_name PK
        string product_category_name_english
    }
```

## Grain notes (drive the star-schema design in Phase 2)

| Table | Grain | Consequence |
|---|---|---|
| orders | 1 row per order | Hub for status and timestamps. |
| order_items | 1 row per item in an order | **Chosen fact grain.** Revenue = sum(price); multi-item orders must not be double-counted when joining payments. |
| payments | 1+ rows per order | Aggregate to order level before joining to items. |
| reviews | 0–n rows per order | Deduplicate; keep latest review per order. |
| customers | 1 row per order | `customer_unique_id` is the real customer key → dim_customer. |
| geolocation | many rows per zip prefix | Aggregate to mean lat/lng per prefix → dim_geography. |
