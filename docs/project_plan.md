# Project plan (source: E-commerce Analytics Resume Project — Plan & Prompts.docx, 18 Oct 2026)

E-commerce Analytics Resume Project — Plan & Prompts
Oct 18, 2026 · @Vivek R
1. Project overview
Build an end-to-end sales and customer analytics project on the Olist Brazilian E-commerce dataset (public on Kaggle, ~100k real orders, 2016–2018, 9 related tables). You take raw CSVs, model them in SQL, analyse in Python, publish a Power BI dashboard, and write a one-page business recommendation. Total effort: about 4–5 weeks at 1–2 hours a day.
Business question the project answers: "What drives revenue, repeat purchase and customer satisfaction on the marketplace, and where should the business invest first?"
Dataset: Olist Brazilian E-commerce Public Dataset — tables: orders, order_items, customers, sellers, products, payments, reviews, geolocation, product_category_translation.
Final deliverables
Deliverable
What it is
Where it lives
SQL data model
Cleaned star schema (fact_orders + dimensions) with 15–20 analysis queries
GitHub /sql
Python analysis notebooks
Cleaning, RFM segmentation, cohort retention, delivery vs review, seller ranking, sales forecast
GitHub /notebooks
Power BI dashboard
3–4 pages: Executive KPIs, Customers, Operations/Delivery, Sellers & Products
.pbix on GitHub + screenshots in README
Insight report
1-page findings + 3 recommendations, written for a business head
PDF in GitHub /report
GitHub repo
Clean README with problem, approach, results, screenshots
Linked from resume
Resume line it produces (sample): "Built an end-to-end e-commerce analytics pipeline on 100k+ orders (SQL, Python, Power BI): modelled 9 raw tables into a star schema, segmented 96k customers with RFM, and found late deliveries drove a 1.5-point drop in review scores — delivered a 12-KPI executive dashboard and recommendations." (Replace the numbers with your real results.)
2. Tools, setup and folder structure
Use the standard MNC analyst stack — these are the exact names that appear in Accenture, Deloitte, TCS, Amazon and Flipkart analyst JDs.
Tool
Use in this project
Install / cost
Python 3.11+ (pandas, numpy, matplotlib, seaborn, scikit-learn, statsmodels)
Cleaning, analysis, forecasting
Free — Anaconda or pip
Jupyter Notebook / VS Code
Writing and presenting analysis
Free
PostgreSQL 16 (or SQLite if setup is painful)
Star schema + analysis queries
Free
Power BI Desktop (Windows) — or Tableau Public if you are on Mac/Linux
Dashboard
Free
Git + GitHub
Version control and portfolio hosting
Free
Kaggle account
Download the dataset
Free
Assumption: you have Windows, so the plan says Power BI. If not, swap in Tableau Public everywhere — the plan does not change.
Week-1 setup checklist
☐ Install Anaconda (Python + Jupyter) and create an environment olist with the libraries above
☐ Install PostgreSQL and pgAdmin (or DBeaver); create a database olist
☐ Install Power BI Desktop from the Microsoft Store
☐ Create a GitHub account (if needed) and a public repo olist-ecommerce-analytics
☐ Download the 9 CSVs from Kaggle into data/raw/
Folder structure (create this on day one and commit it)
olist-ecommerce-analytics/├── README.md├── data/│   ├── raw/            # original Kaggle CSVs (add to .gitignore if > 100 MB)│   └── processed/      # cleaned CSVs / parquet exported for Power BI├── sql/│   ├── 01_create_tables.sql│   ├── 02_load_data.sql│   ├── 03_star_schema.sql│   └── 04_analysis_queries.sql├── notebooks/│   ├── 01_data_understanding.ipynb│   ├── 02_cleaning.ipynb│   ├── 03_rfm_segmentation.ipynb│   ├── 04_cohort_retention.ipynb│   ├── 05_delivery_vs_reviews.ipynb│   ├── 06_seller_product_analysis.ipynb│   └── 07_sales_forecast.ipynb├── dashboard/│   ├── olist_dashboard.pbix│   └── screenshots/├── report/│   └── insight_report.pdf└── requirements.txt
3. Phase-by-phase plan (6 phases, ~4–5 weeks)
Six phases run in a straight line; each one produces something you commit to GitHub the same week.
Phase
When
Output
Hours
1. Data acquisition & understanding
Week 1
Data dictionary, ER diagram, quality report
5–6
2. Cleaning & SQL data model
Week 1–2
Clean tables, star schema in PostgreSQL, 15–20 SQL queries
8–10
3. Analysis in Python
Week 2–3
5 notebooks: RFM, cohorts, delivery vs reviews, sellers/products, forecast
10–12
4. Power BI dashboard
Week 3–4
4-page interactive dashboard
6–8
5. Insight report
Week 4
1-page PDF with 3 recommendations
3–4
6. GitHub & resume packaging
Week 4–5
README, screenshots, resume bullets, LinkedIn post
3–4
Phase 1 — Data acquisition & understanding
Download the 9 CSVs; load each into pandas and record rows, columns, dtypes, nulls, duplicates.
Draw the ER diagram (how orders links to order_items, customers, payments, reviews, sellers, products).
Write data_dictionary.md — one line per column, in plain English.
Note known issues: duplicate review rows, orders with no items, missing delivery dates, Portuguese category names, geolocation duplicates.
Output: notebooks/01_data_understanding.ipynb + data_dictionary.md + ER diagram image.
Phase 2 — Cleaning & SQL data model
In Python: fix dtypes (dates), drop exact duplicates, translate categories to English, flag outliers in price/freight, keep only delivered orders for revenue metrics (keep all for funnel/cancellation analysis).
Export clean CSVs to data/processed/.
In PostgreSQL: create raw tables, load with COPY, then build a star schema — fact_order_items (grain: one row per item) + dim_customer, dim_seller, dim_product, dim_date, dim_geography.
Write 15–20 analysis queries using JOINs, GROUP BY, CTEs and window functions: monthly revenue, AOV, top categories, repeat-customer rate, average delivery days by state, late-delivery %, review score by delivery status, seller revenue rank with RANK(), month-over-month growth with LAG().
Output: sql/01–04*.sql + notebooks/02_cleaning.ipynb.
Phase 3 — Analysis in Python
RFM segmentation — recency, frequency, monetary per customer; score 1–5 on each; label segments (Champions, Loyal, At Risk, Lost, New). Report segment size and revenue share.
Cohort retention — group customers by first-purchase month; build a retention heatmap. Olist retention is famously low (~3%) — that itself is a finding.
Delivery vs reviews — compare review score for on-time vs late orders; by days-late bucket; by state. Quantify the drop.
Seller & product analysis — Pareto (what % of sellers make 80% of revenue), category margins proxy (price vs freight), worst-rated categories.
Sales forecast — monthly revenue with Prophet or SARIMA; 6-month forecast with confidence band. Keep it simple and explain limitations.
Output: notebooks 03–07, each ending with a 3-bullet "So what" cell.
Phase 4 — Power BI dashboard
Connect Power BI to the processed CSVs (or PostgreSQL directly); build the model with relationships matching the star schema.
Write DAX measures: Total Revenue, Orders, AOV, Repeat Rate %, Avg Review Score, Late Delivery %, MoM Growth %.
Pages: Executive (KPI cards + revenue trend + category bar), Customers (RFM segments, cohort matrix, state map), Operations (delivery days by state, late % vs review score), Sellers & Products (Pareto, top/bottom sellers).
Add slicers (date, state, category), consistent colours, and a title/subtitle on every page.
Output: dashboard/olist_dashboard.pbix + 4 PNG screenshots.
Phase 5 — Insight report
One page, written for a Head of Operations: situation → 3 key findings with numbers → 3 recommendations → expected impact.
Export to PDF.
Output: report/insight_report.pdf.
Phase 6 — GitHub & resume packaging
Write the README (outline in section 5), add dashboard screenshots and the report link.
Pin the repo on your GitHub profile; add the link to your resume and LinkedIn.
Write 2–3 resume bullets with real numbers from your analysis.
Prepare interview answers (section 5).
4. Ready-to-paste prompts for Fable
Start every new session with the context prompt, then paste the prompt for the step you are on. Attach the relevant files (CSV samples, your notebook, your SQL) so the answer fits your actual data. Always ask for an explanation along with the code — you must be able to explain every line in an interview.
Context prompt (paste first in every session)
I am building a data analytics portfolio project for data analyst roles at MNCs.Project: end-to-end sales & customer analytics on the Olist Brazilian E-commerce dataset (Kaggle, ~100k orders, 9 tables: orders, order_items, customers, sellers, products, payments, reviews, geolocation, category_translation).Stack: Python (pandas, matplotlib, seaborn, scikit-learn), PostgreSQL, Power BI, GitHub.Business question: what drives revenue, repeat purchase and customer satisfaction, and where should the business invest first?Repo structure: data/raw, data/processed, sql/, notebooks/, dashboard/, report/.I am an intermediate Python user and comfortable with SQL. Explain the reasoning behind each step briefly so I can defend it in interviews. Keep code clean, commented and production-style.
Prompt 1 — Data understanding (Phase 1)
Here are the first 5 rows and df.info() of each of the 9 Olist CSVs [paste or attach].1. Write a notebook `01_data_understanding.ipynb` that loads all 9 files, and for each prints shape, dtypes, null %, duplicate count and 3 sample rows.2. Explain the relationships between the tables and draw an ER diagram (Mermaid is fine).3. Produce a data_dictionary.md with one plain-English line per column.4. List every data-quality issue you can detect, with the query/code that proves it and a recommended fix.
Prompt 2 — Cleaning (Phase 2a)
Using the data-quality issues found earlier [paste the list], write `02_cleaning.ipynb` that:- converts all timestamp columns to datetime,- removes exact duplicates (especially in reviews and geolocation),- translates product_category_name to English using the translation table,- adds derived columns: delivery_days, estimated_delivery_days, is_late (bool), days_late, order_month,- flags price and freight outliers with IQR but does not drop them (add an is_outlier flag),- saves clean tables to data/processed/ as CSV.Show before/after row counts for every table and explain each cleaning decision in a markdown cell.
Prompt 3 — SQL star schema and queries (Phase 2b)
Design a star schema in PostgreSQL for the cleaned Olist data: fact_order_items (grain = one row per order item) and dimensions dim_customer, dim_seller, dim_product, dim_date, dim_geography.1. Write 01_create_tables.sql (raw tables), 02_load_data.sql (COPY from data/processed), 03_star_schema.sql (CREATE TABLE AS SELECT with proper keys).2. Write 04_analysis_queries.sql with at least 15 queries covering: monthly revenue and order count, average order value, MoM growth using LAG(), top 10 categories by revenue, repeat-customer rate, average delivery days by state, late-delivery % by month, average review score by on-time vs late, seller revenue ranking with RANK() and cumulative % (Pareto), payment-type mix, cancellation rate.Use CTEs and window functions where natural. Comment every query with the business question it answers.
Prompt 4 — RFM segmentation (Phase 3)
Write `03_rfm_segmentation.ipynb` on the cleaned Olist data: compute Recency (days since last order as of the dataset's max date), Frequency (orders), Monetary (total payment) per customer_unique_id. Score each 1–5 with quantiles, build an RFM score, and map to segments: Champions, Loyal, Potential Loyalist, New, At Risk, Hibernating, Lost. Output a table of segment size, % of customers, revenue and % of revenue, plus a bar chart. End with 3 business insights and 2 recommended actions per key segment. Export the customer-segment table to data/processed/rfm_segments.csv for Power BI.
Prompt 5 — Cohort retention (Phase 3)
Write `04_cohort_retention.ipynb`: assign each customer to a cohort by first-purchase month, compute monthly retention for the next 12 months, and plot a retention heatmap (seaborn). Also compute overall repeat-purchase rate. Olist retention is known to be very low — explain why that is plausible for a marketplace and what a business should do about it. Export the cohort matrix as CSV.
Prompt 6 — Delivery vs reviews (Phase 3)
Write `05_delivery_vs_reviews.ipynb` that tests the hypothesis "late delivery lowers review scores". Compare mean review score and % of 1–2 star reviews for on-time vs late orders; break down by days-late buckets (1–3, 4–7, 8–14, 15+), by customer state, and by product category. Run a simple statistical test (t-test or Mann-Whitney) and explain the result in plain English. Produce 3 charts and quantify the impact in one sentence suitable for a resume bullet. Export the summary tables for Power BI.
Prompt 7 — Sellers & products (Phase 3)
Write `06_seller_product_analysis.ipynb`: Pareto analysis of sellers (what % generate 80% of revenue), top/bottom 10 sellers by revenue and by review score, category-level revenue, average price, freight-to-price ratio and review score, and the categories with highest cancellation or late-delivery rates. Finish with a 'seller health scorecard' table combining revenue, on-time %, and avg review. Give 3 insights and 2 recommendations.
Prompt 8 — Sales forecast (Phase 3)
Write `07_sales_forecast.ipynb`: aggregate delivered-order revenue by month, visualise trend and seasonality, split the last 3 months as a test set, fit a simple model (Prophet or SARIMA — pick one and justify), report MAPE on the test set, then forecast 6 months ahead with a confidence interval. Explain limitations honestly (short history, marketplace growth phase). Export the forecast to CSV.
Prompt 9 — Power BI dashboard (Phase 4)
I have these processed tables [list them] and this star schema [paste]. Guide me step by step to build a 4-page Power BI dashboard: Executive (KPI cards: Revenue, Orders, AOV, Avg Review, Late %, Repeat %; revenue trend line; top categories bar), Customers (RFM segment bar, cohort matrix, customers by state map), Operations (avg delivery days by state, late % vs avg review scatter, late % trend), Sellers & Products (Pareto chart, seller scorecard table).Give me: the data model relationships to set, the DAX for every measure (with explanation), the visuals and fields for each page, slicers, and a simple professional colour theme. Then tell me how to export high-quality screenshots and the .pbix for GitHub.
Prompt 10 — Insight report (Phase 5)
Here are the key numbers from my analysis [paste: revenue, repeat rate, retention, RFM segment shares, late-delivery impact on reviews, seller Pareto, forecast]. Write a one-page insight report for a Head of Operations at Olist: a 2-line situation summary, 3 key findings each with a number, 3 prioritised recommendations with expected impact, and 1 line on data limitations. Business tone, no jargon, under 400 words. Format it as a document I can export to PDF.
Prompt 11 — README and resume (Phase 6)
Here are my notebooks, SQL files, dashboard screenshots and the insight report [attach]. Write:1. A professional README.md: title, one-line summary, business problem, dataset, tools, approach (with the architecture flow raw CSV → Python cleaning → PostgreSQL star schema → Power BI), key findings with numbers, dashboard screenshots section, how to reproduce, and project structure.2. Three resume bullets (STAR style, each with a metric) for a Data Analyst role.3. A short LinkedIn post announcing the project.4. Ten likely interview questions about this project with model answers.
Debugging / help prompt (any time)
I'm on [phase/notebook]. Here is my code and the error/output [paste]. Explain what is wrong, fix it, and tell me how to avoid it next time. Keep the fix minimal.
5. How to present it
The project only counts if a recruiter can see it in 30 seconds and you can talk about it for 15 minutes.
Resume bullets (template — replace with your real numbers)
Built an end-to-end e-commerce analytics pipeline on 100k+ orders: cleaned and modelled 9 raw tables into a PostgreSQL star schema and wrote 20+ analytical SQL queries (CTEs, window functions).
Segmented 96k customers using RFM analysis and cohort retention in Python; identified that the top 15% of customers generated ~40% of revenue and overall repeat rate was under 3%.
Quantified that late deliveries reduced average review scores by 1.5 points (4.3 → 2.8) and were concentrated in 3 states; delivered a 4-page Power BI dashboard with 12 KPIs and a prioritised recommendation report.
Put it under a Projects heading with the GitHub link and the tech stack in brackets: Olist E-commerce Analytics — Python, SQL (PostgreSQL), Power BI — github.com/Amrtyu29/olist-ecommerce-analytics.
GitHub README outline
Title + one-line summary + badges (Python, PostgreSQL, Power BI)
Business problem (3 lines)
Dataset (link, size, tables)
Architecture: raw CSV → Python cleaning → PostgreSQL star schema → Python analysis → Power BI
Key findings (5 bullets with numbers)
Dashboard screenshots (4 images)
Recommendations (3 bullets)
How to reproduce (environment, load order, run order)
Project structure (the folder tree)
Limitations and next steps
LinkedIn post (short)
Three short paragraphs: what you built and why, the 2 most surprising findings with numbers, and what you learned (one technical, one business). Attach the executive dashboard screenshot. Tag #DataAnalytics #SQL #PowerBI #Python.
Interview questions to be ready for
Question
What they want to hear
Walk me through the project.
Problem → data → approach → 2 findings → recommendation, in under 2 minutes.
Why a star schema?
Simpler joins for BI, one fact grain, fast aggregations in Power BI; mention the grain decision (order item).
What was the hardest data-quality issue?
Duplicate reviews / multiple items per order inflating revenue; how you detected and fixed it.
Explain RFM and how you chose segments.
Quantile scoring, why 5 bins, how segments map to business actions.
How did you prove late delivery hurts reviews?
Comparison of means, bucket analysis, the statistical test and its limitation (correlation, not causation).
Which SQL window function did you use and why?
LAG() for MoM growth, RANK() + cumulative sum for Pareto.
What would you do with more time/data?
Customer demographics, marketing spend, a churn model, real-time dashboard refresh.
What did the business learn from your dashboard?
The 3 recommendations and their expected impact.
Did you use AI tools?
Yes — as a pair programmer for boilerplate and review; you designed the analysis and can explain every line. Honest and confident.
6. Plus points and mistakes to avoid
One deep, well-presented project beats three shallow notebooks. These are the details that separate a shortlisted profile from an ignored one.
Plus points that make it stand out
Real, messy, relational data (9 tables) rather than a single clean CSV — mention "joined 9 tables" explicitly.
A business question in the title and a recommendation at the end — analysts are hired to drive decisions, not to make charts.
SQL that shows CTEs and window functions, not just SELECT * — many candidates fail the SQL round.
A hypothesis you tested (late delivery → low reviews) with a statistical test — shows analytical rigour.
A published dashboard with screenshots in the README — recruiters rarely open a .pbix, so the images do the selling.
Honest limitations section — interviewers trust candidates who know what their analysis cannot say.
Every notebook ends with a "So what" cell: 3 bullets of business meaning.
Optional extras if time allows: publish the dashboard to Power BI Service / Tableau Public for a live link; add a simple Streamlit app; write a Medium post.
Mistakes to avoid
Copying a Kaggle notebook — interviewers recognise them. Your business framing and conclusions must be your own.
Dumping 40 charts with no story. Four pages, twelve KPIs, three findings.
Pasting Fable's code without understanding it. Before committing any cell, be able to explain it in one sentence; if you can't, ask for an explanation first.
Inflated or invented numbers on the resume. Every metric must be reproducible from your notebook.
Committing the raw 100 MB CSVs to GitHub — use .gitignore and link to Kaggle.
Leaving the README for last and never writing it. Write it in Phase 1 and update it each week.
Over-engineering (Airflow, dbt, Spark) before the basics are solid. Ship the core project first; extras come after.

