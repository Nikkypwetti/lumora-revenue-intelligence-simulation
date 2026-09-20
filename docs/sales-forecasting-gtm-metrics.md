# Sales Forecasting & GTM Metrics — Power BI Upgrade

## Scope
This is an upgrade to the existing Lumora Revenue Intelligence project, not a separate reporting project.

The page uses the existing simulated CRM, planning, billing and reporting data. All figures are simulation outputs, not client-performance claims.

## Status
**Built and verified in Power BI.**

Recruiter-safe evidence:

`evidence/powerbi/04-sales-forecasting-gtm-metrics.png`

## Source support
| Metric | Supported? | Source / rule |
|---|---|---|
| Weighted pipeline | Yes | Open deal amount × probability |
| Forecast vs target | Yes | Closed-won bookings + weighted open pipeline versus monthly revenue target |
| Pipeline coverage | Yes | Open pipeline expected in period ÷ revenue target |
| Win rate | Yes | Closed Won ÷ (Closed Won + Closed Lost) |
| Average deal size | Yes | Closed-won bookings ÷ Closed Won deal count |
| Sales cycle | Yes | Average days from deal created_at to closed_at |
| Sales velocity | Yes | Open opportunities × historical win rate × historical average won deal size ÷ historical average won sales cycle days |
| Conversion by stage | Yes | Milestone timestamps and Closed Won outcome |
| Forecast category | Derived | Pipeline / Best Case / Commit from existing probability and outcome |
| Bookings | Yes | `fact_deals.amount` for Closed Won deals |
| ARR / MRR | No | Excluded: source model has no subscription term / recurring revenue contract |

## Verified baseline from the 600-deal simulation
- Closed Won deals: **225**
- Closed Lost deals: **185**
- Open deals: **190**
- Bookings / Closed Won Revenue: **$3,311,500**
- Open pipeline: **$2,902,000**
- Weighted open pipeline: **$1,352,700**
- Historical win rate: **54.9%**
- Historical average won deal size: **$14,718**
- Historical average won sales cycle: **50.6 days**
- Historical sales velocity baseline: **about $30,301/day**

### Open pipeline by forecast category
| Forecast category | Open deals | Pipeline | Weighted pipeline |
|---|---:|---:|---:|
| Pipeline | 94 | $1,633,500 | $455,900 |
| Best Case | 46 | $590,000 | $354,000 |
| Commit | 50 | $678,500 | $542,800 |

### Historical stage conversion evidence
| Funnel milestone | Deals | Step conversion |
|---|---:|---:|
| Created | 600 | — |
| Qualified | 550 | 91.7% |
| Opportunity | 550 | 100.0% |
| Proposal | 506 | 92.0% |
| Closed Won | 225 | 44.5% from Proposal |

Created → Closed Won is **37.5%**. The 100% Qualified → Opportunity step is a property of the deterministic simulation and should not be presented as a client-performance claim.

## Verified August 2026 forecast snapshot
The planning model provides six monthly rep targets totaling **$480,000 revenue target per month** and **$1,440,000 pipeline target per month**.

For August 2026:
- Bookings: **$40,000**
- Open pipeline expected to close in August: **$879,500**
- Weighted pipeline expected to close in August: **$421,100**
- Forecast: **$461,100**
- Forecast vs target: **-$18,900**
- Forecast attainment: **96.1%**
- Pipeline coverage: **1.83x**
- Period Closed Won deals: **2**
- Period Closed Lost deals: **5**
- Period win rate: **28.6%**
- Period average won deal size: **$20,000**
- Period average won sales cycle: **79.5 days**
- Forecast open deal count: **66**
- Sales velocity: **about $10,526/day**

### August 2026 open pipeline by forecast category
| Forecast category | Pipeline |
|---|---:|
| Pipeline | $481,000 |
| Commit | $225,000 |
| Best Case | $173,500 |
| **Total** | **$879,500** |

## Power BI data model
Imported tables:
- `fact_deals`
- `dim_sales_rep`
- `dim_lead_source`
- `dim_account`
- `fact_sales_targets`
- `Date`

Relationships used by the forecasting page:
- Active: `dim_sales_rep[sales_rep_id]` 1 → * `fact_sales_targets[sales_rep_id]`
- Active: `Date[Date]` 1 → * `fact_sales_targets[target_month]`
- Inactive: `Date[Date]` 1 → * `fact_deals[Closed Date]`
- Inactive: `Date[Date]` 1 → * `fact_deals[Expected Close Date]`

The inactive deal-date relationships are activated inside the appropriate measures with `USERELATIONSHIP`.

## Date table and helper columns
```DAX
Date =
CALENDAR(
    DATE(2025, 9, 1),
    DATE(2026, 11, 30)
)

Month Start =
DATE(
    YEAR('Date'[Date]),
    MONTH('Date'[Date]),
    1
)

Month Label =
FORMAT('Date'[Date], "MMM yyyy")
```

`Month Label` is sorted by `Month Start`.

```DAX
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
    ISBLANK(fact_deals[expected_close_date]),
    BLANK(),
    DATE(
        YEAR(fact_deals[expected_close_date]),
        MONTH(fact_deals[expected_close_date]),
        DAY(fact_deals[expected_close_date])
    )
)
```

## Forecast category calculated column
```DAX
Forecast Category =
VAR Outcome =
    TRIM(
        COALESCE(fact_deals[outcome], "")
    )
RETURN
SWITCH(
    TRUE(),
    Outcome = "Closed Won", "Closed",
    Outcome = "Closed Lost", "Omitted",
    fact_deals[probability] >= 80, "Commit",
    fact_deals[probability] >= 60, "Best Case",
    "Pipeline"
)
```

## Verified forecasting measures
```DAX
Revenue Target =
SUM(fact_sales_targets[revenue_target])

Bookings =
CALCULATE(
    SUM(fact_deals[amount]),
    fact_deals[outcome] = "Closed Won",
    USERELATIONSHIP('Date'[Date], fact_deals[Closed Date])
)

Forecast Open Pipeline =
CALCULATE(
    SUM(fact_deals[amount]),
    fact_deals[outcome] = BLANK(),
    USERELATIONSHIP('Date'[Date], fact_deals[Expected Close Date])
)

Weighted Pipeline =
CALCULATE(
    SUMX(
        fact_deals,
        fact_deals[amount] * DIVIDE(fact_deals[probability], 100)
    ),
    fact_deals[outcome] = BLANK(),
    USERELATIONSHIP('Date'[Date], fact_deals[Expected Close Date])
)

Forecast =
COALESCE([Bookings], 0) + COALESCE([Weighted Pipeline], 0)

Forecast vs Target =
[Forecast] - [Revenue Target]

Forecast Attainment % =
DIVIDE([Forecast], [Revenue Target])

Pipeline Coverage =
DIVIDE([Forecast Open Pipeline], [Revenue Target])

Pipeline Coverage Display =
FORMAT([Pipeline Coverage], "0.00x")

Won Deals =
CALCULATE(
    COUNTROWS(fact_deals),
    fact_deals[outcome] = "Closed Won",
    USERELATIONSHIP('Date'[Date], fact_deals[Closed Date])
)

Lost Deals =
CALCULATE(
    COUNTROWS(fact_deals),
    fact_deals[outcome] = "Closed Lost",
    USERELATIONSHIP('Date'[Date], fact_deals[Closed Date])
)

Period Win Rate =
DIVIDE(
    [Won Deals],
    [Won Deals] + [Lost Deals],
    0
)

Period Average Won Deal Size =
DIVIDE(
    [Bookings],
    [Won Deals],
    0
)

Period Average Won Sales Cycle Days =
CALCULATE(
    AVERAGEX(
        FILTER(
            fact_deals,
            TRIM(fact_deals[outcome]) = "Closed Won"
                && NOT ISBLANK(fact_deals[closed_at])
        ),
        DATEDIFF(
            fact_deals[created_at],
            fact_deals[closed_at],
            DAY
        )
    ),
    USERELATIONSHIP('Date'[Date], fact_deals[Closed Date])
)

Historical Win Rate =
CALCULATE(
    [Win Rate],
    REMOVEFILTERS('Date')
)

Historical Avg Won Deal Size =
CALCULATE(
    [Average Won Deal Size],
    REMOVEFILTERS('Date')
)

Historical Avg Won Sales Cycle Days =
CALCULATE(
    AVERAGEX(
        FILTER(
            fact_deals,
            TRIM(fact_deals[outcome]) = "Closed Won"
                && NOT ISBLANK(fact_deals[closed_at])
        ),
        DATEDIFF(
            fact_deals[created_at],
            fact_deals[closed_at],
            DAY
        )
    ),
    REMOVEFILTERS('Date')
)

Forecast Open Deal Count =
CALCULATE(
    COUNTROWS(fact_deals),
    FILTER(
        fact_deals,
        LEN(TRIM(COALESCE(fact_deals[outcome], ""))) = 0
    ),
    USERELATIONSHIP('Date'[Date], fact_deals[Expected Close Date])
)

Sales Velocity =
DIVIDE(
    [Forecast Open Deal Count]
        * [Historical Win Rate]
        * [Historical Avg Won Deal Size],
    [Historical Avg Won Sales Cycle Days]
)
```

## Historical funnel
Disconnected table:

```DAX
Funnel Stages =
DATATABLE(
    "Stage", STRING,
    "Sort", INTEGER,
    {
        {"Created", 1},
        {"Qualified", 2},
        {"Opportunity", 3},
        {"Proposal", 4},
        {"Closed Won", 5}
    }
)
```

`Funnel Stages[Stage]` is sorted by `Funnel Stages[Sort]`.

```DAX
Funnel Deal Count =
SWITCH(
    SELECTEDVALUE('Funnel Stages'[Stage]),
    "Created", COUNTROWS(fact_deals),
    "Qualified", CALCULATE(COUNTROWS(fact_deals), NOT ISBLANK(fact_deals[qualified_at])),
    "Opportunity", CALCULATE(COUNTROWS(fact_deals), NOT ISBLANK(fact_deals[opportunity_at])),
    "Proposal", CALCULATE(COUNTROWS(fact_deals), NOT ISBLANK(fact_deals[proposal_sent_at])),
    "Closed Won", [Closed Won Deals]
)
```

The Month slicer interaction is disabled for this historical funnel so it remains an all-company historical view.

## Verified page layout
Top KPI cards:
1. Forecast
2. Revenue Target
3. Forecast Attainment
4. Pipeline Coverage
5. Period Win Rate
6. Sales Velocity / Day
7. Avg Won Deal Size
8. Avg Sales Cycle (Days)

Main visuals:
- Forecast vs Revenue Target by Month
- Open Pipeline by Forecast Category
- Historical Stage Conversion
- Forecast & Bookings by Sales Rep

Slicers:
- Month dropdown
- Sales Rep dropdown

The Forecast vs Revenue Target visual is fixed to the target period **Sep 2025–Aug 2026** and ignores the Month slicer so the full trend remains visible.

## Portfolio evidence rule
The fourth Power BI page is now verified. Use this recruiter-safe evidence path:

`evidence/powerbi/04-sales-forecasting-gtm-metrics.png`
