# Sales Forecasting & GTM Metrics — Power BI Upgrade

## Scope
This is an upgrade to the existing Lumora Revenue Intelligence project, not a separate reporting project.

The new page should use the existing simulated CRM, planning, billing and reporting data and remain explicit that all figures are simulation outputs.

## Source support
| Metric | Supported? | Source / rule |
|---|---|---|
| Weighted pipeline | Yes | Open deal amount × probability |
| Forecast vs target | Yes | Closed-won bookings + weighted open pipeline versus monthly revenue target |
| Pipeline coverage | Yes | Open pipeline expected in period ÷ revenue target |
| Win rate | Yes | Closed Won ÷ (Closed Won + Closed Lost) |
| Average deal size | Yes | Closed-won bookings ÷ Closed Won deal count |
| Sales cycle | Yes | Average days from deal created_at to closed_at |
| Sales velocity | Yes | Open opportunities × historical win rate × average won deal size ÷ average won sales cycle days |
| Conversion by stage | Yes | Milestone timestamps and Closed Won outcome |
| Forecast category | Derived | Pipeline / Best Case / Commit from existing stage and probability |
| Bookings | Yes | raw_crm.deals.amount for Closed Won deals |
| ARR / MRR | No | Excluded: source model has no subscription term / recurring revenue contract |

## Verified baseline from the current 600-deal simulation
- Closed Won deals: **225**
- Closed Lost deals: **185**
- Open deals: **190**
- Bookings / Closed Won Revenue: **$3,311,500**
- Open pipeline: **$2,902,000**
- Weighted open pipeline: **$1,352,700**
- Win rate: **54.9%**
- Average won deal size: **$14,718**
- Average won sales cycle: **50.6 days**
- Sales velocity baseline: **about $30,301/day**

### Open pipeline by forecast category
| Forecast category | Open deals | Pipeline | Weighted pipeline |
|---|---:|---:|---:|
| Pipeline (Discovery + Qualified) | 94 | $1,633,500 | $455,900 |
| Best Case (Proposal Sent) | 46 | $590,000 | $354,000 |
| Commit (Negotiation) | 50 | $678,500 | $542,800 |

### Stage conversion evidence
| Funnel milestone | Deals | Step conversion |
|---|---:|---:|
| Created | 600 | — |
| Qualified | 550 | 91.7% |
| Opportunity | 550 | 100.0% |
| Proposal | 506 | 92.0% |
| Closed Won | 225 | 44.5% from Proposal |

The 100% Qualified → Opportunity step is a property of the deterministic simulation and should not be presented as a client-performance claim.

## August 2026 forecast snapshot
The planning model provides six monthly rep targets totaling **$480,000 revenue target per month** and **$1,440,000 pipeline target per month**.

For August 2026:
- Bookings: **$40,000**
- Open pipeline expected to close in August: **$879,500**
- Weighted pipeline expected to close in August: **$421,100**
- Forecast = bookings + weighted pipeline: **$461,100**
- Forecast vs target: **-$18,900**
- Forecast attainment: **96.1%**
- Pipeline coverage: **1.83×** ($879,500 ÷ $480,000)

## Power BI data model
Add `fact_sales_targets.csv` (or `reporting.fact_sales_targets` from PostgreSQL) and relate it to `dim_sales_rep` by `sales_rep_id`.

Create a Date table and use it for target month, deal closed date and expected close date. Use inactive deal-date relationships with `USERELATIONSHIP` so one date slicer can drive bookings and forecast-period pipeline correctly.

## Date helper columns and calendar
Create date-only helper columns in `fact_deals` before building the measures:

```DAX
Created Date =
DATE(
    YEAR(fact_deals[created_at]),
    MONTH(fact_deals[created_at]),
    DAY(fact_deals[created_at])
)

Closed Date =
IF(
    ISBLANK(fact_deals[closed_at]),
    BLANK(),
    DATE(
        YEAR(fact_deals[closed_at]),
        MONTH(fact_deals[closed_at]),
        DAY(fact_deals[closed_at])
    )
)

Expected Close Date =
IF(
    ISBLANK(fact_deals[Expected Close Date]),
    BLANK(),
    DATE(
        YEAR(fact_deals[Expected Close Date]),
        MONTH(fact_deals[Expected Close Date]),
        DAY(fact_deals[Expected Close Date])
    )
)
```

Create and mark a Date table:

```DAX
Date =
CALENDAR(
    DATE(2025, 9, 1),
    DATE(2026, 11, 30)
)

Month Start =
DATE(YEAR('Date'[Date]), MONTH('Date'[Date]), 1)

Month Label =
FORMAT('Date'[Date], "MMM yyyy")
```

Relationships:
- Active: `Date[Month Start]` → `fact_sales_targets[target_month]`
- Inactive: `Date[Date]` → `fact_deals[Closed Date]`
- Inactive: `Date[Date]` → `fact_deals[Expected Close Date]`

Use `Month Label` as the page slicer and sort it by `Month Start`.

## Forecast category calculated column
```DAX
Forecast Category =
SWITCH(
    TRUE(),
    fact_deals[outcome] = "Closed Won", "Closed",
    fact_deals[outcome] = "Closed Lost", "Omitted",
    fact_deals[probability] >= 80, "Commit",
    fact_deals[probability] >= 60, "Best Case",
    "Pipeline"
)
```

## Core measures
```DAX
Bookings =
CALCULATE(
    SUM(fact_deals[amount]),
    fact_deals[outcome] = "Closed Won",
    USERELATIONSHIP('Date'[Date], fact_deals[Closed Date])
)

Revenue Target =
SUM(fact_sales_targets[revenue_target])

Open Pipeline =
CALCULATE(
    SUM(fact_deals[amount]),
    ISBLANK(fact_deals[outcome]),
    USERELATIONSHIP('Date'[Date], fact_deals[Expected Close Date])
)

Weighted Pipeline =
CALCULATE(
    SUMX(
        fact_deals,
        fact_deals[amount] * DIVIDE(fact_deals[probability], 100)
    ),
    ISBLANK(fact_deals[outcome]),
    USERELATIONSHIP('Date'[Date], fact_deals[Expected Close Date])
)

Forecast =
[Bookings] + [Weighted Pipeline]

Forecast vs Target =
[Forecast] - [Revenue Target]

Forecast Attainment % =
DIVIDE([Forecast], [Revenue Target])

Pipeline Coverage =
DIVIDE([Open Pipeline], [Revenue Target])

Won Deals =
CALCULATE(
    COUNTROWS(fact_deals),
    fact_deals[outcome] = "Closed Won"
)

Lost Deals =
CALCULATE(
    COUNTROWS(fact_deals),
    fact_deals[outcome] = "Closed Lost"
)

Win Rate =
DIVIDE([Won Deals], [Won Deals] + [Lost Deals])

Average Won Deal Size =
DIVIDE([Bookings], [Won Deals])

Average Won Sales Cycle Days =
AVERAGEX(
    FILTER(fact_deals, fact_deals[outcome] = "Closed Won"),
    DATEDIFF(fact_deals[Created Date], fact_deals[Closed Date], DAY)
)

Historical Win Rate =
CALCULATE([Win Rate], REMOVEFILTERS('Date'))

Historical Avg Won Deal Size =
CALCULATE([Average Won Deal Size], REMOVEFILTERS('Date'))

Historical Avg Won Sales Cycle Days =
CALCULATE([Average Won Sales Cycle Days], REMOVEFILTERS('Date'))

Open Deal Count =
CALCULATE(
    COUNTROWS(fact_deals),
    ISBLANK(fact_deals[outcome]),
    USERELATIONSHIP('Date'[Date], fact_deals[Expected Close Date])
)

Sales Velocity =
DIVIDE(
    [Open Deal Count]
        * [Historical Win Rate]
        * [Historical Avg Won Deal Size],
    [Historical Avg Won Sales Cycle Days]
)
```

## Page layout
Top KPI cards:
1. Forecast
2. Revenue Target
3. Forecast Attainment %
4. Pipeline Coverage
5. Win Rate
6. Sales Velocity

Main visuals:
- Clustered column: Forecast vs Target by month
- Stacked/clustered bar: Pipeline by Forecast Category
- Funnel: Created → Qualified → Opportunity → Proposal → Closed Won
- Bar chart: Forecast / bookings by sales rep
- KPI cards: Average Won Deal Size and Average Won Sales Cycle Days
- Month and Sales Rep slicers

## Portfolio evidence rule
Do not add a fourth Power BI screenshot to the portfolio until the page has actually been built and verified in Power BI. Once verified, save a recruiter-safe screenshot as:

`evidence/powerbi/04-sales-forecasting-gtm-metrics.png`

Then update the portfolio case study to describe it as verified evidence.
