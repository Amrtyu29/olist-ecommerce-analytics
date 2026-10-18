# Resume, LinkedIn and interview pack (Phase 6)

Every number here is printed by a notebook cell or a SQL query in this repo. If you re-run the pipeline and a number moves, update it here too — a recruiter who opens the notebook must find the same figure.

| Number | Where it comes from |
|---|---|
| 99,441 orders · 96,096 customers · 9 tables | `01_data_understanding.ipynb` |
| R$13.2M delivered revenue · 18 SQL queries | `sql/04_analysis_queries.sql` Q03 |
| 4.29 → 2.27 review score, late vs on-time · p < 0.001 · Cliff's δ 0.64 | `05_delivery_vs_reviews.ipynb` |
| 6.7% of orders late · 32.5% of 1–2 star reviews | `05` section 6 |
| 3.0% repeat rate · M+1 retention 0.48% | `04_cohort_retention.ipynb` |
| Repeat buyers R$309 vs R$134 · Potential Loyalists 15.5% of customers / 28% of revenue | `03_rfm_segmentation.ipynb` |
| 17.9% of sellers → 80% of revenue · 20 at-risk top-100 sellers = 8.6% of revenue | `06_seller_product_analysis.ipynb` |
| Level forecast R$0.85M/month, 13.9% hold-out MAPE | `07_sales_forecast.ipynb` |

---

## 1. Resume

### Project line (under a *Projects* heading)

**Olist E-commerce Analytics** — Python (pandas, scipy, statsmodels), SQL (PostgreSQL), Power BI — github.com/Amrtyu29/olist-ecommerce-analytics

### Three bullets (STAR, each with a metric)

- Built an end-to-end analytics pipeline on 99k Brazilian marketplace orders across 9 relational tables: cleaned and modelled the data into a PostgreSQL star schema (item-grain fact, 5 dimensions) and wrote 18 analytical SQL queries using CTEs and window functions (LAG for month-over-month growth, RANK and cumulative sums for seller Pareto).
- Tested the hypothesis that late delivery drives poor reviews: late orders scored 2.27 vs 4.29 on time (−2.0 points, Mann–Whitney p < 0.001, Cliff's δ = 0.64), the penalty held in all 21 states and 26 categories, and 6.7% late orders produced 32.5% of all 1–2 star reviews — making logistics, not sellers, the first investment priority.
- Segmented 93k customers with RFM and cohort analysis, finding a 3.0% repeat rate with repeat buyers worth 2.3× one-time buyers; identified 14k "Potential Loyalists" holding 28% of revenue and delivered a one-page recommendation report plus a 4-page, 12-KPI Power BI dashboard design for the Head of Operations.

### Shorter two-bullet variant (if space is tight)

- End-to-end e-commerce analytics on 99k orders / 9 tables: Python cleaning → PostgreSQL star schema → 18 SQL queries (CTEs, window functions) → Power BI dashboard → one-page recommendation report.
- Quantified that late deliveries cut review scores from 4.29 to 2.27 (p < 0.001) and caused a third of all bad reviews despite being 7% of orders; RFM/cohort analysis showed a 3% repeat rate and a 14k-customer segment worth 28% of revenue.

---

## 2. LinkedIn post

> I just finished an end-to-end analytics project on the Olist Brazilian e-commerce dataset — 99k real orders across 9 relational tables — asking one business question: what drives revenue, repeat purchase and customer satisfaction, and where should the business invest first?
>
> Two findings surprised me. First, late delivery is the whole story behind bad reviews: late orders average 2.3 stars versus 4.3 on time, the drop appears in every state and category, and just 7% of orders produce a third of all 1–2 star reviews. Second, retention is almost non-existent — 3% of customers ever reorder — but the few who do are worth 2.3× as much, and half of them come back within a month, so the window to act is the first four weeks after delivery.
>
> What I learned: technically, that an item-grain star schema plus an order-level view is what keeps SQL and Power BI measures honest when orders have multiple items; and as an analyst, that a p-value is the least interesting part of a hypothesis test — the effect size and the within-segment checks are what convince an operations head. Stack: Python (pandas, scipy, statsmodels), PostgreSQL, Power BI. Repo and one-page report in the comments.
>
> #DataAnalytics #SQL #PowerBI #Python

Attach `report/figures/05_score_by_lateness.png` or the Executive dashboard screenshot once built.

---

## 3. Interview questions and model answers

**1. Walk me through the project.**
Olist is a Brazilian marketplace; the public dataset has 99k orders in 9 tables. The question was what drives revenue, repeat purchase and satisfaction. I profiled and cleaned the data in Python (duplicate reviews, 1M geolocation rows, Portuguese categories), modelled it into a PostgreSQL star schema with an item-grain fact table, and wrote 18 SQL queries for the core KPIs. In Python I did RFM segmentation, cohort retention, a hypothesis test on late delivery vs reviews, seller/category analysis and a revenue forecast. Two findings mattered: late delivery cuts review scores by two points and causes a third of bad reviews; and only 3% of customers ever return, but those who do are worth 2.3× as much. The recommendation was to fix on-time delivery in the North-East and bulky categories first, then run a post-delivery second-purchase programme. Everything is in a Power BI dashboard design and a one-page report.

**2. Why a star schema, and why that grain?**
Power BI and most BI questions want one fact table with simple one-to-many joins to dimensions; that is faster and less error-prone than joining nine normalised tables at query time. I chose the order *item* as the grain because seller, product, price and freight only exist per item — an order-grain fact would force me to average or lose them. The trade-off is that order-level metrics (AOV, repeat rate, review score) would double-count multi-item orders, so I added an order-level view, `v_orders`, and the rule is: item questions hit the fact, order questions hit the view. In Power BI the same thing is an `orders` bridge table between `order_items` and the dimensions.

**3. What was the hardest data-quality issue?**
Two that would silently corrupt results. `customer_id` is regenerated for every order, so any repeat-purchase metric on it reads 0% — you must use `customer_unique_id`. And reviews: 547 orders had more than one review and 1,603 rows shared a review_id, so joining reviews to items inflates counts; I kept the latest answered review per order and documented it. Honourable mention: geolocation has a million rows for 19k postcode prefixes, which explodes any join unless you aggregate to one coordinate per prefix first.

**4. Explain RFM and how you chose the segments.**
Recency, Frequency and Monetary value per customer, each scored 1–5, then mapped to named segments. I scored R and M by quintile because that is distribution-free and easy to explain ("5 = top 20% of spenders"). Frequency broke the standard recipe: 97% of customers have exactly one order, so quintiles collapse into one bin. I used fixed thresholds instead — 1 order → 1, 2 → 3, 3 → 4, 4+ → 5 — so that a second purchase, which is rare here, counts as a loyalty signal. Segment rules then follow the usual grid, checked in priority order so each customer lands in exactly one segment. The segment that mattered was Potential Loyalists: recent, high-value, single order — 15% of customers, 28% of revenue, cheapest to convert.

**5. How did you prove late delivery hurts reviews?**
Carefully, and I would say "show an association", not "prove". I compared mean score and the share of 1–2 star reviews for on-time vs late orders (4.29 vs 2.27). Review scores are ordinal and skewed, so I used a Mann–Whitney U test rather than relying on a t-test, and reported Welch's t as a robustness check; both give p effectively zero with n ≈ 96k, which is why I put more weight on effect size — Cliff's delta 0.64, a bootstrap 95% CI of 1.99–2.05 points. Then I checked confounders: the gap holds within all 21 states and all 26 major categories, and there is a dose-response — 1–3 days late costs a star, 4–7 days costs two. The limitation is that it is observational: lateness is not randomly assigned, and part of the fix might be promising more realistic dates rather than shipping faster.

**6. Which SQL window functions did you use and why?**
`LAG()` over month for month-over-month revenue growth, which is cleaner than a self-join. `RANK()` plus `SUM() OVER (ORDER BY revenue DESC ROWS UNBOUNDED PRECEDING)` for the seller Pareto — rank, cumulative revenue and cumulative share in one pass. `ROW_NUMBER()` to generate surrogate keys for the dimensions. I also used `FILTER (WHERE …)` on aggregates for conditional counts such as late-delivery percentage, and CTEs so each query reads top-down as the business question.

**7. How did you forecast, and why not Prophet or SARIMA?**
Twenty monthly points. A seasonal model needs at least two full cycles to estimate a 12-month pattern, so SARIMA or Prophet with yearly seasonality would be fitting noise. I compared three non-seasonal models on a 3-month hold-out — level-only exponential smoothing, damped Holt trend and ARIMA(1,1,1) with drift — against a naive last-3-months average. The trend models extrapolated 2017's growth and overshot by about 30%; the level model came in at 13.9% MAPE, essentially tied with naive. The honest conclusion is that revenue has plateaued at about R$0.85M a month, so the forecast is a run-rate with an 80% band, and I said so in the report rather than dressing it up.

**8. What did the business learn from your dashboard and report?**
Three things with numbers. One: fix late delivery where it clusters — North-East states at 14–21% late and bulky categories — because halving lateness removes one in seven bad reviews. Two: run a second-purchase programme on the 14k Potential Loyalists within four weeks of delivery, since half of repeaters come back inside a month and each point of repeat rate is worth about R$130k a year. Three: a seller-health programme starting with the 20 top-100 sellers in the bottom health quartile, who carry R$1.1M of revenue.

**9. What would you do with more time or data?**
More data: marketing spend and channel to separate acquisition from retention, customer demographics, and 24+ months to model seasonality. More time: a churn/second-purchase propensity model on the RFM features, a causal check on lateness using seller-level variation (e.g. the same seller's on-time vs late orders), and publishing the dashboard to Power BI Service with scheduled refresh from PostgreSQL.

**10. Did you use AI tools?**
Yes, as a pair programmer: boilerplate, notebook scaffolding, reviewing my SQL for mistakes. The analysis design, the choices — item grain, fixed Frequency thresholds, Mann–Whitney over t-test, rejecting the seasonal forecast — were mine and are written up in `docs/decision_log.md` with the alternatives I rejected. I can explain every cell, and I checked every headline number against its notebook output before putting it on the resume.

**Bonus — "Your repeat rate is 3%. Isn't that a failure?"**
It is low, but it is plausible for this business model: Olist sells through large retailers' storefronts, so the shopper often never sees the Olist brand and has no account to return to. The comparable is other marketplace sellers, not a branded store with 20–30% repeat rates. What matters is that it is flat across cohorts — newer customers are no stickier — which tells you growth has been pure acquisition and that the retention lever is untouched.

---

## 4. Checklist before you send

- [ ] Replace `Amrtyu29` with your GitHub username; the repo must be public with the README screenshots in place.
- [ ] Build the `.pbix` from `docs/powerbi_guide.md` and add the four screenshots — recruiters look at images, not notebooks.
- [ ] Re-run notebooks 01–07 once more and diff the numbers in this file against the outputs.
- [ ] Pin the repo on your GitHub profile.
