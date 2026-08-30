-- ============================================================
-- Lumora Cloud Revenue Intelligence Simulation
-- Governed Reporting Layer
--
-- This schema matches the reporting contract expected by
-- the existing REVINT Revenue Intelligence Agent.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS reporting;
CREATE SCHEMA IF NOT EXISTS quality;


-- ============================================================
-- SALES REP DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS reporting.dim_sales_rep (
    sales_rep_id       TEXT PRIMARY KEY,
    sales_rep_name     TEXT NOT NULL,
    email              TEXT,
    region             TEXT,
    is_active          BOOLEAN NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL,
    updated_at         TIMESTAMPTZ NOT NULL
);


-- ============================================================
-- ACCOUNT DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS reporting.dim_account (
    account_id         TEXT PRIMARY KEY,
    account_name       TEXT NOT NULL,
    industry           TEXT,
    segment            TEXT,
    country            TEXT,
    is_active          BOOLEAN NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL,
    updated_at         TIMESTAMPTZ NOT NULL
);


-- ============================================================
-- LEAD SOURCE DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS reporting.dim_lead_source (
    lead_source_id     TEXT PRIMARY KEY,
    lead_source_name   TEXT NOT NULL,
    source_category    TEXT,
    is_active          BOOLEAN NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL,
    updated_at         TIMESTAMPTZ NOT NULL
);


-- ============================================================
-- DEAL FACT TABLE
--
-- Contract matches the existing REVINT reporting.fact_deals.
-- ============================================================

CREATE TABLE IF NOT EXISTS reporting.fact_deals (
    deal_id               TEXT PRIMARY KEY,
    account_id            TEXT NOT NULL,
    sales_rep_id          TEXT NOT NULL,
    lead_source_id        TEXT NOT NULL,

    deal_name             TEXT NOT NULL,
    stage                 TEXT NOT NULL,
    outcome               TEXT,

    amount                NUMERIC NOT NULL
                          CONSTRAINT fact_deals_amount_check
                          CHECK (amount >= 0),

    probability           NUMERIC
                          CONSTRAINT fact_deals_probability_check
                          CHECK (
                              probability IS NULL
                              OR (
                                  probability >= 0
                                  AND probability <= 100
                              )
                          ),

    created_at            TIMESTAMPTZ NOT NULL,
    qualified_at          TIMESTAMPTZ,
    opportunity_at        TIMESTAMPTZ,
    proposal_sent_at      TIMESTAMPTZ,

    expected_close_date   DATE,
    closed_at             TIMESTAMPTZ,

    last_activity_at      TIMESTAMPTZ,
    next_activity_at      TIMESTAMPTZ,
    first_response_at     TIMESTAMPTZ,
    sla_due_at            TIMESTAMPTZ,

    lost_reason           TEXT,

    created_timestamp     TIMESTAMPTZ NOT NULL,
    updated_timestamp     TIMESTAMPTZ NOT NULL,

    CONSTRAINT fact_deals_account_id_fkey
        FOREIGN KEY (account_id)
        REFERENCES reporting.dim_account(account_id),

    CONSTRAINT fact_deals_sales_rep_id_fkey
        FOREIGN KEY (sales_rep_id)
        REFERENCES reporting.dim_sales_rep(sales_rep_id),

    CONSTRAINT fact_deals_lead_source_id_fkey
        FOREIGN KEY (lead_source_id)
        REFERENCES reporting.dim_lead_source(lead_source_id)
);


-- ============================================================
-- INDEXES FOR CURRENT APPROVED REVINT REPORTS
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_reporting_closed_won_period
    ON reporting.fact_deals(outcome, closed_at);

CREATE INDEX IF NOT EXISTS idx_reporting_open_pipeline_period
    ON reporting.fact_deals(outcome, expected_close_date);

CREATE INDEX IF NOT EXISTS idx_reporting_deals_sales_rep
    ON reporting.fact_deals(sales_rep_id);

CREATE INDEX IF NOT EXISTS idx_reporting_deals_account
    ON reporting.fact_deals(account_id);

CREATE INDEX IF NOT EXISTS idx_reporting_deals_lead_source
    ON reporting.fact_deals(lead_source_id);


-- ============================================================
-- HARD TRANSFORMATION REJECTIONS
--
-- These records cannot safely enter governed reporting.
-- ============================================================

CREATE TABLE IF NOT EXISTS quality.transformation_rejections (
    rejection_id       BIGSERIAL PRIMARY KEY,
    entity_type        TEXT NOT NULL,
    source_record_id   TEXT,
    reason_code        TEXT NOT NULL,
    reason_detail      TEXT,
    source_payload     JSONB,
    rejected_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quality_rejection_record
    ON quality.transformation_rejections(source_record_id);


-- ============================================================
-- SOFT DATA QUALITY ISSUES
--
-- The record can remain reportable but needs RevOps attention.
-- ============================================================

CREATE TABLE IF NOT EXISTS quality.data_quality_issues (
    issue_id           BIGSERIAL PRIMARY KEY,
    entity_type        TEXT NOT NULL,
    source_record_id   TEXT NOT NULL,
    issue_code         TEXT NOT NULL,

    severity           TEXT NOT NULL
                       CHECK (
                           severity IN (
                               'low',
                               'medium',
                               'high'
                           )
                       ),

    issue_detail       TEXT,

    detected_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at        TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_quality_issue_record
    ON quality.data_quality_issues(
        entity_type,
        source_record_id
    );


-- ============================================================
-- GOVERNED LEAD SOURCE REFERENCE DATA
-- ============================================================

INSERT INTO reporting.dim_lead_source (
    lead_source_id,
    lead_source_name,
    source_category,
    is_active,
    created_at,
    updated_at
)
VALUES

    (
        'LS000',
        'Unknown',
        'Unknown',
        TRUE,
        NOW(),
        NOW()
    ),

    (
        'LS001',
        'Website Form',
        'Inbound',
        TRUE,
        NOW(),
        NOW()
    ),

    (
        'LS002',
        'LinkedIn',
        'Inbound',
        TRUE,
        NOW(),
        NOW()
    ),

    (
        'LS003',
        'Outbound Email',
        'Outbound',
        TRUE,
        NOW(),
        NOW()
    ),

    (
        'LS004',
        'Referral',
        'Referral',
        TRUE,
        NOW(),
        NOW()
    ),

    (
        'LS005',
        'Paid Search',
        'Paid',
        TRUE,
        NOW(),
        NOW()
    ),

    (
        'LS006',
        'Partner',
        'Partner',
        TRUE,
        NOW(),
        NOW()
    ),

    (
        'LS007',
        'Webinar',
        'Inbound',
        TRUE,
        NOW(),
        NOW()
    )

ON CONFLICT (lead_source_id)
DO UPDATE SET

    lead_source_name =
        EXCLUDED.lead_source_name,

    source_category =
        EXCLUDED.source_category,

    is_active =
        EXCLUDED.is_active,

    updated_at =
        NOW();
