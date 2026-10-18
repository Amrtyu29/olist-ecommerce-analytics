# Olist E-commerce Analytics — What drives revenue, repeat purchase and satisfaction?

![Python](https://img.shields.io/badge/Python-3.11+-blue) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791) ![Power BI](https://img.shields.io/badge/Power%20BI-Desktop-F2C811)

End-to-end sales and customer analytics on ~100k real marketplace orders: raw CSVs → Python cleaning → PostgreSQL star schema → Python analysis → Power BI dashboard → one-page recommendation report.

> **Status:** Phases 1–3 and 5 complete; Phase 4 (Power BI) has a full build guide and theme but the `.pbix` and screenshots are still to be produced in Power BI Desktop. Notebooks 01–07 run end to end; `sql/01–04` build a star schema and 18 analysis queries (validated with DuckDB; the PostgreSQL run itself is not yet confirmed — see [docs/postgres_setup.md](docs/postgres_setup.md)).

## Business problem

Olist is a Brazilian marketplace that connects small sellers to large online stores. Leadership wants to know **what drives revenue, repeat purchase and customer satisfaction, and where to invest first** — in sellers, in logistics, or in customer retention.

## Dataset

[Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle) — 99,441 orders from Sept 2016 to Oct 2018 across 9 related tables: orders, order_items, customers, sellers, products, payments, reviews, geolocation and a category translation table. Raw CSVs are ~120 MB and are not committed; see [data/raw/README.md](data/raw/README.md).

Full column reference: [docs/data_dictionary.md](docs/data_dictionary.md). Table relationships: [docs/er_diagram.md](docs/er_diagram.md).

## Architecture

```
Kaggle CSVs (9)  →  Python cleaning (pandas)  →  data/processed/*.csv
                                                        │
                        PostgreSQL raw tables  ←  COPY  ┘
                                │
                        star schema: fact_order_items + dim_customer, dim_seller,
                                     dim_product, dim_date, dim_geography
                                │
          ┌─────────────────────┴──────────────────────┐
   SQL analysis queries                       Python notebooks
   (CTEs, LAG, RANK, Pareto)        (RFM, cohorts, delivery vs reviews,
                                      sellers/products, forecast)
                                                │
                                        Power BI dashboard (4 pages)
                                                │
                                        Insight report (1 page PDF)
```

## Key findings

Every number below is printed by a cell in the named notebook.

- **Late delivery is the biggest driver of bad reviews** ([05](notebooks/05_delivery_vs_reviews.ipynb)). On-time orders average 4.29 stars, late orders 2.27 — a 2.0-point drop (Mann–Whitney p < 0.001, Cliff's δ = 0.64, bootstrap 95% CI 1.99–2.05). The penalty holds in all 21 states and all 26 major categories. Late orders are 6.7% of volume but 32.5% of all 1–2 star reviews; fixing lateness alone would lift the marketplace average from 4.16 to 4.29.
- **Satisfaction collapses within the first week late.** 1–3 days late → 3.29 stars; 4–7 days → 2.10; 8+ days → 1.7.
- **Retention is near zero and flat** ([04](notebooks/04_cohort_retention.ipynb)). Only 3.0% of customers ever reorder; month+1 retention averages 0.48% and is no better for 2018 cohorts than 2017 ones. Half of those who do reorder do so within 28 days.
- **Repeat buyers are worth 2.3× a one-time buyer** ([03](notebooks/03_rfm_segmentation.ipynb)): R$309 vs R$134 lifetime spend. The 14,446 "Potential Loyalists" (recent, high-value, one order) produce 28% of revenue and are the cheapest segment to convert.
- **Revenue is concentrated in sellers** ([06](notebooks/06_seller_product_analysis.ipynb)). 17.9% of sellers make 80% of revenue; the top 20 make 21%. Twenty top-100 sellers sit in the bottom health quartile and carry 8.6% of revenue.
- **Growth has plateaued** ([07](notebooks/07_sales_forecast.ipynb)). Revenue grew 6.5× over 2017 then flattened at R$0.85–1.0M/month. Trend models overshoot by ~30% on hold-out; a level model (13.9% MAPE) forecasts a flat R$0.85M/month run-rate, ~R$5.1M over the next six months (80% band R$3.6–6.6M).

Figures for every finding are in [report/figures](report/figures).

## Dashboard

Build instructions, data model, every DAX measure and the page layouts are in [docs/powerbi_guide.md](docs/powerbi_guide.md); the colour theme is [dashboard/olist_theme.json](dashboard/olist_theme.json).

_Screenshots of the 4 pages go in `dashboard/screenshots/` and are embedded here once the .pbix is built._

## Recommendations

From the one-page [insight report](report/insight_report.pdf) ([Markdown source](report/insight_report.md)):

1. **Fix on-time delivery where it fails** — North-East routes and bulky categories; region- and category-specific promise dates; carrier capacity before November. Halving lateness removes 1 in 7 bad reviews and lifts the average score from 4.16 to 4.23.
2. **Post-delivery second-purchase programme for Potential Loyalists** (14,446 customers, 28% of revenue) within four weeks of delivery, A/B tested. Each 1-point rise in repeat rate ≈ 930 orders ≈ R$130k a year.
3. **Seller-health programme** starting with the 20 top-100 sellers in the bottom health quartile (8.6% of revenue ≈ R$1.1M); monthly scorecard and 30-day improvement plans.

## How to reproduce

```bash
# 1. Environment (Windows, PowerShell)
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt

# 2. Data — needs a Kaggle account and ~/.kaggle/kaggle.json
.venv\Scripts\python.exe scripts\download_data.py

# 3. Run notebooks in order 01 → 07 (Jupyter) — each writes to data/processed/

# 4. PostgreSQL: run sql/01 → 04 in order against a database named `olist`

# 5. Open dashboard/olist_dashboard.pbix in Power BI Desktop and refresh
```

## Project structure

```
olist-ecommerce-analytics/
├── README.md
├── requirements.txt
├── data/
│   ├── raw/            # Kaggle CSVs (git-ignored)
│   └── processed/      # cleaned tables + analysis outputs for Power BI
├── docs/
│   ├── project_plan.md
│   ├── data_dictionary.md
│   ├── er_diagram.md
│   └── decision_log.md # analytical choices and why
├── scripts/
│   ├── download_data.py
│   └── run_sql.ps1     # builds the Postgres warehouse end to end
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_load_data.sql
│   ├── 03_star_schema.sql
│   └── 04_analysis_queries.sql
├── notebooks/
│   ├── 01_data_understanding.ipynb
│   ├── 02_cleaning.ipynb
│   ├── 03_rfm_segmentation.ipynb
│   ├── 04_cohort_retention.ipynb
│   ├── 05_delivery_vs_reviews.ipynb
│   ├── 06_seller_product_analysis.ipynb
│   └── 07_sales_forecast.ipynb
├── dashboard/
│   ├── olist_theme.json
│   ├── olist_dashboard.pbix   # to be built (Phase 4)
│   └── screenshots/
└── report/
    ├── insight_report.md / .pdf
    └── figures/               # charts from notebooks 03–07
```

## Presenting the project

Resume bullets, a LinkedIn post and ten interview questions with model answers are in [docs/resume_and_interview.md](docs/resume_and_interview.md).

## Limitations and next steps

- Observational data: late delivery is *associated* with low reviews; the within-state and within-category checks rule out the obvious confounders but not all of them.
- Twenty months of history: no seasonal model is defensible, so the forecast is a run-rate with a wide band.
- `customer_id` is per order; person-level analysis relies on `customer_unique_id`, which Olist derives from name/document matching.
- Next: build the `.pbix` from the guide, add screenshots, publish to Power BI Service for a live link, and (with more data) a churn model and marketing-spend regressors for the forecast.
