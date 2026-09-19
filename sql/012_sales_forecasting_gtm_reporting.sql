-- ============================================================
-- Lumora Cloud Revenue Intelligence Production Simulation
-- File: 012_sales_forecasting_gtm_reporting.sql
--
-- Purpose:
--   Extend the governed reporting layer with sales targets and
--   deterministic forecast-ready views for the Power BI
--   Sales Forecasting & GTM Metrics page.
--
-- Important:
--   raw_crm.deals.amount remains sales booking / contract value.
--   No ARR or MRR is derived because the source model does not
--   contain subscription term or recurring-revenue semantics.
-- ============================================================

CREATE TABLE IF NOT EXISTS reporting.fact_sales_targets (
    target_id           TEXT PRIMARY KEY,
    sales_rep_id        TEXT NOT NULL,
    target_month        DATE NOT NULL,
    team                TEXT NOT NULL,
    revenue_target      NUMERIC(14,2) NOT NULL CHECK (revenue_target >= 0),
    pipeline_target     NUMERIC(14,2) NOT NULL CHECK (pipeline_target >= 0),
    created_timestamp   TIMESTAMPTZ NOT NULL,
    updated_timestamp   TIMESTAMPTZ NOT NULL,

    CONSTRAINT fact_sales_targets_sales_rep_fkey
        FOREIGN KEY (sales_rep_id)
        REFERENCES reporting.dim_sales_rep(sales_rep_id),

    CONSTRAINT fact_sales_targets_rep_month_key
        UNIQUE (sales_rep_id, target_month)
);

CREATE INDEX IF NOT EXISTS idx_reporting_sales_targets_month
    ON reporting.fact_sales_targets(target_month);

CREATE INDEX IF NOT EXISTS idx_reporting_sales_targets_rep
    ON reporting.fact_sales_targets(sales_rep_id);

INSERT INTO reporting.fact_sales_targets (
    target_id,
    sales_rep_id,
    target_month,
    team,
    revenue_target,
    pipeline_target,
    created_timestamp,
    updated_timestamp
)
SELECT
    t.target_id,
    t.rep_id,
    t.target_month,
    t.team,
    t.revenue_target,
    t.pipeline_target,
    COALESCE(t.source_created_at, t.ingested_at, NOW()),
    COALESCE(t.source_updated_at, t.ingested_at, NOW())
FROM raw_planning.sales_targets t
JOIN reporting.dim_sales_rep r
  ON r.sales_rep_id = t.rep_id
ON CONFLICT (target_id)
DO UPDATE SET
    sales_rep_id = EXCLUDED.sales_rep_id,
    target_month = EXCLUDED.target_month,
    team = EXCLUDED.team,
    revenue_target = EXCLUDED.revenue_target,
    pipeline_target = EXCLUDED.pipeline_target,
    updated_timestamp = EXCLUDED.updated_timestamp;

CREATE OR REPLACE VIEW reporting.vw_open_deal_forecast AS
SELECT
    d.deal_id,
    d.sales_rep_id,
    d.account_id,
    d.lead_source_id,
    d.deal_name,
    d.stage,
    d.amount,
    d.probability,
    d.expected_close_date,
    DATE_TRUNC('month', d.expected_close_date)::DATE AS forecast_month,
    CASE
        WHEN d.stage = 'Negotiation' OR d.probability >= 80
            THEN 'Commit'
        WHEN d.stage = 'Proposal Sent' OR d.probability >= 60
            THEN 'Best Case'
        ELSE 'Pipeline'
    END AS forecast_category,
    ROUND(d.amount * COALESCE(d.probability, 0) / 100.0, 2)
        AS weighted_pipeline_amount
FROM reporting.fact_deals d
WHERE d.outcome IS NULL;

CREATE OR REPLACE VIEW reporting.vw_monthly_sales_forecast AS
WITH target AS (
    SELECT
        target_month,
        sales_rep_id,
        team,
        revenue_target,
        pipeline_target
    FROM reporting.fact_sales_targets
),
bookings AS (
    SELECT
        DATE_TRUNC('month', closed_at)::DATE AS target_month,
        sales_rep_id,
        SUM(amount)::NUMERIC(14,2) AS bookings,
        COUNT(*)::INTEGER AS won_deals
    FROM reporting.fact_deals
    WHERE outcome = 'Closed Won'
      AND closed_at IS NOT NULL
    GROUP BY 1,2
),
pipeline AS (
    SELECT
        DATE_TRUNC('month', expected_close_date)::DATE AS target_month,
        sales_rep_id,
        SUM(amount)::NUMERIC(14,2) AS open_pipeline,
        SUM(
            amount * COALESCE(probability, 0) / 100.0
        )::NUMERIC(14,2) AS weighted_pipeline,
        COUNT(*)::INTEGER AS open_deals
    FROM reporting.fact_deals
    WHERE outcome IS NULL
      AND expected_close_date IS NOT NULL
    GROUP BY 1,2
)
SELECT
    t.target_month,
    t.sales_rep_id,
    t.team,
    t.revenue_target,
    t.pipeline_target,
    COALESCE(b.bookings, 0)::NUMERIC(14,2) AS bookings,
    COALESCE(b.won_deals, 0)::INTEGER AS won_deals,
    COALESCE(p.open_pipeline, 0)::NUMERIC(14,2) AS open_pipeline,
    COALESCE(p.weighted_pipeline, 0)::NUMERIC(14,2) AS weighted_pipeline,
    COALESCE(p.open_deals, 0)::INTEGER AS open_deals,
    (
        COALESCE(b.bookings, 0)
        + COALESCE(p.weighted_pipeline, 0)
    )::NUMERIC(14,2) AS forecast_value,
    (
        COALESCE(b.bookings, 0)
        + COALESCE(p.weighted_pipeline, 0)
        - t.revenue_target
    )::NUMERIC(14,2) AS forecast_vs_target,
    ROUND(
        100.0 * (
            COALESCE(b.bookings, 0)
            + COALESCE(p.weighted_pipeline, 0)
        ) / NULLIF(t.revenue_target, 0),
        2
    ) AS forecast_attainment_pct,
    ROUND(
        COALESCE(p.open_pipeline, 0)
        / NULLIF(t.revenue_target, 0),
        2
    ) AS pipeline_coverage_ratio
FROM target t
LEFT JOIN bookings b
  ON b.target_month = t.target_month
 AND b.sales_rep_id = t.sales_rep_id
LEFT JOIN pipeline p
  ON p.target_month = t.target_month
 AND p.sales_rep_id = t.sales_rep_id;

GRANT SELECT
ON reporting.fact_sales_targets,
   reporting.vw_open_deal_forecast,
   reporting.vw_monthly_sales_forecast
TO lumora_reporting_ro;

COMMENT ON VIEW reporting.vw_open_deal_forecast IS
'Open Lumora deals with deterministic forecast categories and probability-weighted pipeline.';

COMMENT ON VIEW reporting.vw_monthly_sales_forecast IS
'Monthly per-rep bookings, targets, open pipeline, weighted forecast, attainment and coverage for Power BI.';
