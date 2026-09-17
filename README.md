# Retail Sales & Customer Analytics Pipeline

An end-to-end analytics project covering data cleaning, customer segmentation, and business intelligence dashboarding — built on the UCI Online Retail II dataset (~1M transactions, UK-based online gift retailer, Dec 2009–Dec 2011).

**Tools used:** SQL (MySQL) · Python (pandas) · Power BI

---

## Project Overview

This project simulates a real retail analytics workflow:

1. **SQL** — Load, clean, and validate ~1 million raw transaction records; run exploratory business queries
2. **Python** — Compute RFM (Recency, Frequency, Monetary) scores and segment customers into actionable groups
3. **Power BI** — Build an interactive two-page executive dashboard for sales performance and customer segmentation

---

## Repository Structure

```
retail-sales-customer-analytics/
├── sql/
│   └── retail_sql_analysis.sql       # Schema, cleaning, and business queries
├── python/
│   └── retail_rfm_analysis.ipynb     # Data cleaning + RFM segmentation
├── powerbi/
│   └── DashBoard [Retail Analytics].pbix
├── images/
│   ├── executive_overview.png
│   └── customer_segmentation.png
└── README.md
```

---

## Key Insights

**Sales performance**
- Total revenue analyzed: **£17.7M** across **805,531** cleaned transactions
- Strong seasonality: revenue peaks every **October–November** (holiday buying), consistent across both 2010 and 2011
- **97% of revenue comes from the UK** (£14.7M of ~£17M) — minimal international diversification
- Top revenue product ("Regency Cakestand") sells fewer units at a higher price point than the top volume product ("White Hanging Heart T-Light Holder") — different pricing tiers

**Customer behavior**
- **72.4% repeat purchase rate** across 5,878 customers — strong underlying loyalty
- One customer (ID 16446) placed just 2 orders totaling **£168K** — a clear wholesale-buyer outlier distinct from typical retail customers

**RFM segmentation**
- **22% of customers ("Champions") generate 68% of total revenue** — classic Pareto concentration
- **1,628 customers (~28%) are "At Risk" or "Lost,"** representing **£1.45M** in historical revenue — a concrete retention target
- Segments identified: Champions, Loyal Customers, New Customers, At Risk, Lost, Promising, Needs Attention

---

## Dashboard Preview

### Executive Overview
Sales KPIs, monthly revenue trend, top products, and revenue by country.

![Executive Overview](images/executive_overview.png)

### Customer Segmentation
RFM-based customer segments, revenue contribution by segment, and recency-vs-monetary analysis.

![Customer Segmentation](images/customer_segmentation.png)

---

## How to Reproduce

1. Download the [Online Retail II dataset](https://archive.ics.uci.edu/dataset/502/online+retail+ii) (or via Kaggle)
2. Run `sql/retail_sql_analysis.sql` in MySQL to load and clean the data
3. Run `python/retail_rfm_analysis.ipynb` to compute RFM segments (connects to the MySQL `clean_transactions` view via SQLAlchemy)
4. Open `powerbi/DashBoard [Retail Analytics].pbix` in Power BI Desktop, refresh data sources to point to your local CSV exports

---

## Author

Immadi sathwik
