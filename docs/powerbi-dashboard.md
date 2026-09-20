# Power BI Dashboard

## Executive Revenue Overview
$3,311,500 Closed Won Revenue · $2,902,000 Open Pipeline · 190 Open Deals · 54.9% Win Rate.

## Pipeline & Sales Performance
$2,902,000 Open Pipeline · 190 Open Deals · $14,718 Average Won Deal Size · 45 Stale Open Deals.

## Revenue Operations Health
45 Stale Open Deals · 114 Overdue Follow Ups · 72 SLA Breaches · 185 Closed Lost Deals.

## Sales Forecasting & GTM Metrics
The fourth page is built and verified in Power BI using the existing simulated CRM data plus the governed monthly sales-target layer.

Supported metrics: weighted pipeline, forecast vs target, pipeline coverage, period win rate, average won deal size, sales cycle, sales velocity, stage conversion, derived forecast category, and bookings.

ARR/MRR are intentionally excluded because the source model does not contain subscription term or recurring-revenue semantics.

### Verified August 2026 snapshot
- Forecast: **$461,100**
- Revenue target: **$480,000**
- Forecast attainment: **96.1%**
- Pipeline coverage: **1.83x**
- Period win rate: **28.6%**
- Sales velocity: **$10,526/day**
- Average won deal size: **$20,000**
- Average won sales cycle: **79.5 days**

### Verified page visuals
- Forecast vs Revenue Target by Month
- Open Pipeline by Forecast Category
- Historical Stage Conversion
- Forecast & Bookings by Sales Rep
- Month and Sales Rep slicers

Recruiter-safe screenshots live in `evidence/powerbi/`, including:

`evidence/powerbi/04-sales-forecasting-gtm-metrics.png`

See [Sales Forecasting & GTM Metrics](sales-forecasting-gtm-metrics.md) for the data model, verified formulas, simulation baseline, and evidence rules.

The PBIX working file should be backed up outside Git.
