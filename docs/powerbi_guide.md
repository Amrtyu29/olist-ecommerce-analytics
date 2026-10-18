# Power BI dashboard build guide (Phase 4)

Four pages, twelve KPIs, one story: *late delivery is the lever*. This guide gives the data model, every DAX measure with its reasoning, the visuals per page, slicers, the colour theme and how to export for GitHub. Build time is roughly 4–6 hours.

## 0. Before you open Power BI

- Data source: either the processed CSVs in `data/processed/` (simplest, no server needed) **or** PostgreSQL `localhost / olist` schema `dw` (nicer for the interview story). The field names below are the CSV names; the `dw` tables carry the same columns.
- Import the theme: View → Themes → Browse for themes → `dashboard/olist_theme.json`.
- Save as `dashboard/olist_dashboard.pbix`.

## 1. Load these tables

| Power BI table name | Source file | Rows | Role |
|---|---|---|---|
| `orders` | orders.csv ⨝ customers.csv ⨝ order_payments_summary.csv ⨝ reviews.csv (merge in Power Query, see 1a) | 99,441 | Order-grain facts: status, lateness, payment, review |
| `order_items` | order_items.csv | 112,650 | Item-grain facts: price, freight, seller, product |
| `dim_date` | generated in DAX (see 1b) | 852 | Calendar |
| `dim_product` | products.csv | 32,951 | Category (English) |
| `dim_seller` | sellers.csv | 3,095 | Seller state/city |
| `dim_geography` | geography.csv | 19,010 | Lat/lng per zip prefix (for maps) |
| `rfm_segments` | rfm_segments.csv | 93,358 | One row per customer_unique_id |
| `cohort_retention` | cohort_retention_long.csv | ~210 | Cohort × month-offset retention % |
| `delivery_by_bucket` | delivery_vs_review_by_bucket.csv | 5 | Pre-aggregated for the Operations page |
| `seller_scorecard` | seller_scorecard.csv | 2,970 | Seller health table |
| `seller_pareto` | seller_pareto.csv | 2,970 | Cumulative % for the Pareto chart |
| `revenue_forecast` | revenue_forecast.csv | 26 | Actual + 6-month forecast |

**1a. Build `orders` in Power Query.** Load orders.csv, then *Merge Queries* (left outer) three times: customers on `customer_id` (expand `customer_unique_id`, `customer_state`, `customer_city`), order_payments_summary on `order_id` (expand `payment_total`, `main_payment_type`, `max_installments`), reviews on `order_id` (expand `review_score`). Then merge rfm_segments on `customer_unique_id` and expand `segment` only. Set `order_purchase_timestamp` to Date/Time and add a column `order_date = Date.From([order_purchase_timestamp])`. Why merge rather than relate: Power BI relationships want one-to-many; these are all one-to-one at order grain, so a merge is cleaner and faster.

**1b. Date table.** Modeling → New table:

```dax
dim_date =
ADDCOLUMNS (
    CALENDAR ( DATE ( 2016, 9, 1 ), DATE ( 2019, 2, 28 ) ),
    "Year", YEAR ( [Date] ),
    "Month", FORMAT ( [Date], "YYYY-MM" ),
    "MonthStart", DATE ( YEAR ( [Date] ), MONTH ( [Date] ), 1 ),
    "MonthName", FORMAT ( [Date], "MMM YYYY" ),
    "Weekday", FORMAT ( [Date], "ddd" ),
    "WeekdayNo", WEEKDAY ( [Date], 2 )
)
```

Right-click → *Mark as date table* on `[Date]`. Sort `MonthName` by `MonthStart`.

## 2. Relationships (Model view)

| From (many) | To (one) | Cardinality | Filter direction |
|---|---|---|---|
| orders[order_date] | dim_date[Date] | many-to-one | single |
| order_items[order_id] | orders[order_id] | many-to-one | **both** (so a category slicer filters orders and vice versa) |
| order_items[product_id] | dim_product[product_id] | many-to-one | single |
| order_items[seller_id] | dim_seller[seller_id] | many-to-one | single |
| orders[customer_zip_code_prefix] | dim_geography[zip_code_prefix] | many-to-one | single |
| orders[customer_unique_id] | rfm_segments[customer_unique_id] | many-to-one | single |

Leave `cohort_retention`, `delivery_by_bucket`, `seller_scorecard`, `seller_pareto`, `revenue_forecast` **unrelated** — they are pre-aggregated and drive their own visuals. Do not relate `dim_date` to `revenue_forecast`; use its own `month` column.

Why this shape: it is the star schema from `sql/03_star_schema.sql` with the order grain as a bridge, which keeps item-level measures (revenue, freight, seller) and order-level measures (AOV, repeat rate, review) correct at the same time.

## 3. DAX measures

Create a blank table `_Measures` (Enter Data, one dummy column, then hide it) to hold these.

```dax
-- Volume ------------------------------------------------------------
Orders = DISTINCTCOUNT ( orders[order_id] )

Delivered Orders = CALCULATE ( [Orders], orders[is_delivered] = TRUE () )

Customers = DISTINCTCOUNT ( orders[customer_unique_id] )

-- Money (delivered orders only; price = merchandise revenue) -----------
Total Revenue =
CALCULATE ( SUM ( order_items[price] ), orders[is_delivered] = TRUE () )

GMV = CALCULATE ( SUM ( order_items[item_total] ), orders[is_delivered] = TRUE () )

Freight = CALCULATE ( SUM ( order_items[freight_value] ), orders[is_delivered] = TRUE () )

AOV = DIVIDE ( [Total Revenue], [Delivered Orders] )
-- Average order value = revenue / delivered orders, not / items.

Freight to Price % = DIVIDE ( [Freight], [Total Revenue] )

-- Growth -------------------------------------------------------------
Revenue PM =
CALCULATE ( [Total Revenue], DATEADD ( dim_date[Date], -1, MONTH ) )

MoM Growth % = DIVIDE ( [Total Revenue] - [Revenue PM], [Revenue PM] )
-- DATEADD needs the marked date table; this is the DAX twin of SQL LAG().

-- Satisfaction -------------------------------------------------------
Avg Review Score = AVERAGE ( orders[review_score] )

1-2 Star % =
DIVIDE (
    CALCULATE ( [Orders], orders[review_score] <= 2 ),
    CALCULATE ( [Orders], NOT ISBLANK ( orders[review_score] ) )
)

-- Delivery -----------------------------------------------------------
Late Orders = CALCULATE ( [Orders], orders[is_late] = TRUE () )

Late Delivery % =
DIVIDE (
    [Late Orders],
    CALCULATE ( [Orders], orders[is_delivered] = TRUE (), NOT ISBLANK ( orders[is_late] ) )
)
-- Denominator = delivered orders with a known delivery date (8 delivered orders have none).

Avg Delivery Days =
CALCULATE ( AVERAGE ( orders[delivery_days] ), orders[is_delivered] = TRUE () )

Avg Days Late (late only) =
CALCULATE ( AVERAGE ( orders[days_late] ), orders[is_late] = TRUE () )

-- Retention ----------------------------------------------------------
Repeat Customers =
COUNTROWS (
    FILTER (
        VALUES ( orders[customer_unique_id] ),
        CALCULATE ( [Delivered Orders] ) > 1
    )
)

Repeat Rate % = DIVIDE ( [Repeat Customers], [Customers] )
-- Uses customer_unique_id; customer_id would always give 0 %.

-- Sellers ------------------------------------------------------------
Active Sellers = CALCULATE ( DISTINCTCOUNT ( order_items[seller_id] ), orders[is_delivered] = TRUE () )

Sellers for 80% Revenue =
VAR t = TOPN ( 1, FILTER ( seller_pareto, seller_pareto[cum_revenue_pct] >= 80 ), seller_pareto[cum_revenue_pct], ASC )
RETURN MAXX ( t, seller_pareto[cum_sellers_pct] )
```

Format: currency measures as `R$ #,0` (set Model → Format), percentages with 1 decimal, review score with 2 decimals.

## 4. Pages

Every page: title (24 pt, left), one-line subtitle in grey stating the question, slicer row across the top (`dim_date[MonthName]` as a between-slider on `MonthStart`, `orders[customer_state]`, `dim_product[product_category_name_english]`), consistent 16 px gutters.

### Page 1 — Executive  *"How is the marketplace performing?"*

| Visual | Fields | Note |
|---|---|---|
| 6 KPI cards (one row) | Total Revenue · Delivered Orders · AOV · Avg Review Score · Late Delivery % · Repeat Rate % | Card titles in sentence case |
| Line chart | X `dim_date[MonthStart]`, Y Total Revenue | Trim axis to 2017-01..2018-08 via slicer default; annotate Nov-2017 |
| Column chart | X `dim_date[MonthStart]`, Y MoM Growth % | Conditional colour: negative = orange |
| Bar chart (top 10) | Y `product_category_name_english`, X Total Revenue | Top-N filter = 10 |
| Donut | Legend `main_payment_type`, value Orders | Keep 4 slices |

### Page 2 — Customers  *"Who buys, and do they come back?"*

| Visual | Fields | Note |
|---|---|---|
| Bar chart | Y `rfm_segments[segment]`, X Customers; tooltip Total Revenue | Sort by a custom order column if you want Champions on top |
| 100 % stacked bar | Axis = "Customers" / "Revenue", legend = segment | Shows the 15 % → 28 % Potential-Loyalist story |
| Matrix | Rows `cohort_retention[cohort]`, columns `months_since_first`, values `retention_pct` | Conditional formatting: background colour scale, blue ramp |
| Filled map | Location `orders[customer_state]`, colour Total Revenue | Or bubble map with dim_geography lat/lng |
| KPI cards | Customers · Repeat Rate % · Repeat Customers | |

### Page 3 — Operations  *"Where does delivery fail, and what does it cost?"*

| Visual | Fields | Note |
|---|---|---|
| Bar chart | Y `customer_state`, X Avg Delivery Days; tooltip Late Delivery % | Sort descending |
| Scatter | X Late Delivery %, Y Avg Review Score, size Orders, detail `customer_state` | The "North-East" cluster shows top-left |
| Column chart | X `delivery_by_bucket[late_bucket]`, Y `avg_score` | The dose-response chart; colour first bar blue, rest orange |
| Line chart | X `MonthStart`, Y Late Delivery % | Shows the Nov-2017 and Feb-2018 spikes |
| KPI cards | Late Delivery % · Avg Delivery Days · Avg Days Late (late only) · 1-2 Star % | |

### Page 4 — Sellers & Products  *"Which sellers and categories need attention?"*

| Visual | Fields | Note |
|---|---|---|
| Line + area | X `seller_pareto[cum_sellers_pct]`, Y `cum_revenue_pct` | Add constant lines at 80 % (Y) and the Sellers-for-80 % value (X) |
| Table | `seller_scorecard`: seller_id, state, orders, revenue, on_time_pct, avg_review, cancel_pct, health_score | Conditional data bars on health_score; filter `low_volume = False`; sort by revenue |
| Bar chart | Y category, X Avg Review Score | Bottom-10 filter, orange |
| Bar chart | Y category, X Freight to Price % | Top-10 filter |
| KPI cards | Active Sellers · Sellers for 80 % Revenue · Freight to Price % | |

## 5. Theme and formatting rules

`dashboard/olist_theme.json` sets the palette (colour-blind-validated: blue, orange, aqua, yellow, magenta, green, violet, red), a light surface, grey gridlines and Segoe UI. Rules to keep by hand:

- One colour per page unless colour carries meaning (blue = normal, orange = problem/late).
- No dual-axis charts. Two measures of different scale → two visuals.
- Data labels only on KPI cards and the bucket chart; everything else uses tooltips.
- Axis titles off when the visual title already says what is on the axis.

## 6. Export for GitHub

1. Set each page to the default slicer state you want in the screenshot (full date range, all states).
2. View → *Page view* → *Fit to page*, then File → Export → *Export to PDF* (vector, every page). Open the PDF, use Snipping Tool at 100 % zoom (or Edge's PDF viewer) to save `dashboard/screenshots/01_executive.png` … `04_sellers_products.png` at ≥ 1600 px wide.
3. Save the `.pbix`. It is ~40–60 MB with the data imported; that is under GitHub's 100 MB limit, but add it to Git LFS if the repo grows.
4. Optional live link: *Publish* to Power BI Service → *Publish to web* (public) → paste the link in the README.

## 7. Checks before you call it done

- Executive KPIs must reproduce `sql/04_analysis_queries.sql` Q03: revenue 13,221,498, delivered 96,478, AOV 137.04, avg review 4.09, late 6.8 %.
- Repeat Rate % should read 3.0 %; if it reads 0 % you related on `customer_id` instead of `customer_unique_id`.
- Page 3 bucket chart: 4.29 → 3.29 → 2.10 → 1.67 → 1.72.
