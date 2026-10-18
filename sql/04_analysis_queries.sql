-- 04_analysis_queries.sql
-- 18 analysis queries against the dw star schema. Each is headed by the business
-- question it answers. Conventions:
--   * Revenue metrics use delivered orders only (is_delivered); funnel and
--     cancellation metrics use all statuses.
--   * Order-level KPIs (AOV, repeat rate, review averages) read dw.v_orders so
--     multi-item orders are counted once. Item-level questions (sellers,
--     products, categories) read dw.fact_order_items.
--   * Time-series queries trim to 2017-01 .. 2018-08 — the months outside that
--     range are partial (see notebook 01).
--
-- Run: psql -U postgres -d olist -f sql/04_analysis_queries.sql
--      (or paste one query at a time into pgAdmin / DBeaver)

------------------------------------------------------------------------------
-- Q01  How are revenue and order volume trending month by month?
------------------------------------------------------------------------------
SELECT
    order_month,
    COUNT(*)                         AS orders,
    ROUND(SUM(revenue), 2)           AS revenue,
    ROUND(SUM(gmv), 2)               AS gmv,
    ROUND(SUM(revenue) / COUNT(*), 2) AS avg_order_value
FROM dw.v_orders
WHERE is_delivered
  AND order_month BETWEEN DATE '2017-01-01' AND DATE '2018-08-01'
GROUP BY order_month
ORDER BY order_month;

------------------------------------------------------------------------------
-- Q02  What is the month-over-month revenue growth?  (window: LAG)
------------------------------------------------------------------------------
WITH monthly AS (
    SELECT order_month, SUM(revenue) AS revenue
    FROM dw.v_orders
    WHERE is_delivered AND order_month BETWEEN DATE '2017-01-01' AND DATE '2018-08-01'
    GROUP BY order_month
)
SELECT
    order_month,
    ROUND(revenue, 2)                                              AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY order_month), 2)             AS prev_month_revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY order_month))
              / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0), 1) AS mom_growth_pct
FROM monthly
ORDER BY order_month;

------------------------------------------------------------------------------
-- Q03  Headline KPIs for the executive page (one row)
------------------------------------------------------------------------------
SELECT
    COUNT(*)                                             AS orders_all_status,
    COUNT(*) FILTER (WHERE is_delivered)                 AS orders_delivered,
    ROUND(SUM(revenue) FILTER (WHERE is_delivered), 2)   AS revenue,
    ROUND(SUM(gmv) FILTER (WHERE is_delivered), 2)       AS gmv,
    ROUND(AVG(revenue) FILTER (WHERE is_delivered), 2)   AS avg_order_value,
    COUNT(DISTINCT customer_unique_id)                   AS customers,
    ROUND(AVG(review_score), 2)                          AS avg_review_score,
    ROUND(100.0 * AVG(CASE WHEN is_late THEN 1 ELSE 0 END) FILTER (WHERE is_delivered AND is_late IS NOT NULL), 1)
                                                         AS late_delivery_pct,
    ROUND(AVG(delivery_days) FILTER (WHERE is_delivered), 1) AS avg_delivery_days
FROM dw.v_orders;

------------------------------------------------------------------------------
-- Q04  Which product categories generate the most revenue?  (top 10 + share)
------------------------------------------------------------------------------
WITH cat AS (
    SELECT p.category, SUM(f.price) AS revenue, COUNT(*) AS items,
           COUNT(DISTINCT f.order_id) AS orders
    FROM dw.fact_order_items f
    JOIN dw.dim_product p USING (product_key)
    WHERE f.is_delivered
    GROUP BY p.category
)
SELECT
    category,
    ROUND(revenue, 2)                                       AS revenue,
    items,
    orders,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 1)        AS revenue_share_pct,
    ROUND(revenue / items, 2)                               AS avg_item_price
FROM cat
ORDER BY revenue DESC
LIMIT 10;

------------------------------------------------------------------------------
-- Q05  What share of customers ever buy again?  (repeat-customer rate)
--      Uses customer_unique_id: customer_id changes every order and would give 0%.
------------------------------------------------------------------------------
WITH per_customer AS (
    SELECT customer_unique_id, COUNT(*) AS orders, SUM(revenue) AS revenue
    FROM dw.v_orders
    WHERE is_delivered
    GROUP BY customer_unique_id
)
SELECT
    COUNT(*)                                                      AS customers,
    COUNT(*) FILTER (WHERE orders > 1)                            AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE orders > 1) / COUNT(*), 2) AS repeat_rate_pct,
    ROUND(100.0 * SUM(revenue) FILTER (WHERE orders > 1) / SUM(revenue), 1)
                                                                  AS revenue_share_from_repeaters_pct,
    ROUND(AVG(orders), 3)                                         AS avg_orders_per_customer
FROM per_customer;

------------------------------------------------------------------------------
-- Q06  How long does delivery take by customer state, and how often is it late?
------------------------------------------------------------------------------
SELECT
    customer_state,
    COUNT(*)                                            AS delivered_orders,
    ROUND(AVG(delivery_days), 1)                        AS avg_delivery_days,
    ROUND(AVG(estimated_delivery_days), 1)              AS avg_promised_days,
    ROUND(100.0 * AVG(CASE WHEN is_late THEN 1 ELSE 0 END), 1) AS late_pct,
    ROUND(AVG(review_score), 2)                         AS avg_review
FROM dw.v_orders
WHERE is_delivered AND is_late IS NOT NULL
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY avg_delivery_days DESC;

------------------------------------------------------------------------------
-- Q07  Is late delivery getting better or worse over time?  (late % by month)
------------------------------------------------------------------------------
SELECT
    order_month,
    COUNT(*)                                                     AS delivered_orders,
    SUM(CASE WHEN is_late THEN 1 ELSE 0 END)                     AS late_orders,
    ROUND(100.0 * AVG(CASE WHEN is_late THEN 1 ELSE 0 END), 1)   AS late_pct,
    ROUND(AVG(delivery_days), 1)                                 AS avg_delivery_days
FROM dw.v_orders
WHERE is_delivered AND is_late IS NOT NULL
  AND order_month BETWEEN DATE '2017-01-01' AND DATE '2018-08-01'
GROUP BY order_month
ORDER BY order_month;

------------------------------------------------------------------------------
-- Q08  Do late deliveries get worse reviews?  (on-time vs late)
------------------------------------------------------------------------------
SELECT
    CASE WHEN is_late THEN 'late' ELSE 'on time' END          AS delivery_status,
    COUNT(*)                                                  AS orders,
    ROUND(AVG(review_score), 2)                               AS avg_review_score,
    ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 1) AS pct_1_2_star,
    ROUND(100.0 * AVG(CASE WHEN review_score = 5 THEN 1 ELSE 0 END), 1)  AS pct_5_star
FROM dw.v_orders
WHERE is_delivered AND is_late IS NOT NULL AND review_score IS NOT NULL
GROUP BY is_late
ORDER BY is_late;

------------------------------------------------------------------------------
-- Q09  How quickly does satisfaction fall as lateness grows?  (days-late buckets)
------------------------------------------------------------------------------
SELECT
    CASE
        WHEN days_late <= 0  THEN '0. on time / early'
        WHEN days_late <= 3  THEN '1. 1-3 days late'
        WHEN days_late <= 7  THEN '2. 4-7 days late'
        WHEN days_late <= 14 THEN '3. 8-14 days late'
        ELSE                      '4. 15+ days late'
    END                                                       AS lateness_bucket,
    COUNT(*)                                                  AS orders,
    ROUND(AVG(review_score), 2)                               AS avg_review_score,
    ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 1) AS pct_1_2_star
FROM dw.v_orders
WHERE is_delivered AND days_late IS NOT NULL AND review_score IS NOT NULL
GROUP BY 1
ORDER BY 1;

------------------------------------------------------------------------------
-- Q10  Which sellers matter most?  Revenue rank + cumulative share (Pareto)
--      (windows: RANK, SUM OVER ORDER BY)
------------------------------------------------------------------------------
WITH seller_rev AS (
    SELECT s.seller_id, s.state, SUM(f.price) AS revenue, COUNT(*) AS items
    FROM dw.fact_order_items f
    JOIN dw.dim_seller s USING (seller_key)
    WHERE f.is_delivered
    GROUP BY s.seller_id, s.state
),
ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY revenue DESC)                                   AS revenue_rank,
           SUM(revenue) OVER (ORDER BY revenue DESC ROWS UNBOUNDED PRECEDING)    AS cum_revenue,
           SUM(revenue) OVER ()                                                  AS total_revenue,
           COUNT(*) OVER ()                                                      AS total_sellers
    FROM seller_rev
)
SELECT
    revenue_rank,
    seller_id,
    state,
    items,
    ROUND(revenue, 2)                                  AS revenue,
    ROUND(100.0 * cum_revenue / total_revenue, 1)      AS cum_revenue_pct,
    ROUND(100.0 * revenue_rank / total_sellers, 1)     AS cum_sellers_pct
FROM ranked
ORDER BY revenue_rank
LIMIT 20;

------------------------------------------------------------------------------
-- Q11  What % of sellers produce 80% of revenue?  (the Pareto headline number)
------------------------------------------------------------------------------
WITH seller_rev AS (
    SELECT seller_key, SUM(price) AS revenue
    FROM dw.fact_order_items WHERE is_delivered GROUP BY seller_key
),
ranked AS (
    SELECT revenue,
           SUM(revenue) OVER (ORDER BY revenue DESC ROWS UNBOUNDED PRECEDING) / SUM(revenue) OVER () AS cum_share,
           ROW_NUMBER() OVER (ORDER BY revenue DESC)                                                AS rn,
           COUNT(*) OVER ()                                                                         AS n
    FROM seller_rev
)
SELECT
    n                                                             AS active_sellers,
    MIN(rn) FILTER (WHERE cum_share >= 0.80)                      AS sellers_for_80pct_revenue,
    ROUND(100.0 * MIN(rn) FILTER (WHERE cum_share >= 0.80) / n, 1) AS pct_of_sellers_for_80pct_revenue
FROM ranked
GROUP BY n;

------------------------------------------------------------------------------
-- Q12  Seller health scorecard: revenue, on-time %, review score (top 15 by revenue)
------------------------------------------------------------------------------
SELECT
    s.seller_id,
    s.state,
    COUNT(DISTINCT f.order_id)                                        AS orders,
    ROUND(SUM(f.price), 2)                                            AS revenue,
    ROUND(100.0 * AVG(CASE WHEN f.is_late THEN 0 ELSE 1 END)
                  FILTER (WHERE f.is_late IS NOT NULL), 1)            AS on_time_pct,
    ROUND(AVG(f.review_score), 2)                                     AS avg_review,
    ROUND(AVG(f.delivery_days), 1)                                    AS avg_delivery_days
FROM dw.fact_order_items f
JOIN dw.dim_seller s USING (seller_key)
WHERE f.is_delivered
GROUP BY s.seller_id, s.state
HAVING COUNT(DISTINCT f.order_id) >= 50
ORDER BY revenue DESC
LIMIT 15;

------------------------------------------------------------------------------
-- Q13  How do customers pay?  (payment-type mix and instalment behaviour)
------------------------------------------------------------------------------
SELECT
    main_payment_type,
    COUNT(*)                                             AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)   AS order_share_pct,
    ROUND(SUM(payment_total), 2)                         AS paid,
    ROUND(100.0 * SUM(payment_total) / SUM(SUM(payment_total)) OVER (), 1) AS value_share_pct,
    ROUND(AVG(payment_total), 2)                         AS avg_ticket,
    ROUND(AVG(max_installments), 1)                      AS avg_installments
FROM dw.v_orders
WHERE is_delivered AND main_payment_type IS NOT NULL
GROUP BY main_payment_type
ORDER BY orders DESC;

------------------------------------------------------------------------------
-- Q14  What is the order funnel / cancellation rate?  (all statuses)
------------------------------------------------------------------------------
SELECT
    order_status,
    COUNT(*)                                            AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)  AS pct_of_orders
FROM dw.v_orders
GROUP BY order_status
ORDER BY orders DESC;

------------------------------------------------------------------------------
-- Q15  Which categories have the worst reviews and the highest late rates?
------------------------------------------------------------------------------
SELECT
    p.category,
    COUNT(DISTINCT f.order_id)                                      AS orders,
    ROUND(SUM(f.price), 2)                                          AS revenue,
    ROUND(AVG(f.review_score), 2)                                   AS avg_review,
    ROUND(100.0 * AVG(CASE WHEN f.is_late THEN 1 ELSE 0 END)
                  FILTER (WHERE f.is_late IS NOT NULL), 1)          AS late_pct,
    ROUND(AVG(f.freight_value / NULLIF(f.price, 0)) * 100, 1)       AS freight_to_price_pct
FROM dw.fact_order_items f
JOIN dw.dim_product p USING (product_key)
WHERE f.is_delivered
GROUP BY p.category
HAVING COUNT(DISTINCT f.order_id) >= 200
ORDER BY avg_review ASC
LIMIT 10;

------------------------------------------------------------------------------
-- Q16  Where are the customers?  Revenue, orders and AOV by state (for the map)
------------------------------------------------------------------------------
SELECT
    customer_state,
    COUNT(*)                                            AS orders,
    COUNT(DISTINCT customer_unique_id)                  AS customers,
    ROUND(SUM(revenue), 2)                              AS revenue,
    ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS revenue_share_pct,
    ROUND(AVG(revenue), 2)                              AS avg_order_value,
    ROUND(AVG(freight), 2)                              AS avg_freight
FROM dw.v_orders
WHERE is_delivered
GROUP BY customer_state
ORDER BY revenue DESC;

------------------------------------------------------------------------------
-- Q17  Where does time go between purchase and delivery?  (stage breakdown)
--      approval -> handed to carrier -> delivered, vs the promise
------------------------------------------------------------------------------
SELECT
    ROUND(AVG(approval_hours) / 24, 2)                       AS avg_days_to_approve,
    ROUND(AVG(carrier_days - approval_hours / 24), 2)        AS avg_days_seller_to_carrier,
    ROUND(AVG(delivery_days - carrier_days), 2)              AS avg_days_in_transit,
    ROUND(AVG(delivery_days), 2)                             AS avg_days_total,
    ROUND(AVG(estimated_delivery_days), 2)                   AS avg_days_promised,
    ROUND(AVG(estimated_delivery_days - delivery_days), 2)   AS avg_days_early
FROM dw.v_orders
WHERE is_delivered AND delivery_days IS NOT NULL AND carrier_days IS NOT NULL AND approval_hours IS NOT NULL;

------------------------------------------------------------------------------
-- Q18  Which days of the week do customers buy on?  (for staffing / campaigns)
------------------------------------------------------------------------------
SELECT
    d.iso_weekday,
    d.weekday_name,
    COUNT(*)                                             AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)   AS pct_of_orders,
    ROUND(SUM(v.revenue), 2)                             AS revenue
FROM dw.v_orders v
JOIN dw.dim_date d USING (date_key)
WHERE v.is_delivered
GROUP BY d.iso_weekday, d.weekday_name
ORDER BY d.iso_weekday;
