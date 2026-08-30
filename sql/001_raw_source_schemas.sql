-- ============================================================
-- Lumora Cloud Revenue Intelligence Production Simulation
-- File: 001_raw_source_schemas.sql
--
-- Purpose:
--   Model the raw operational systems that feed the reporting
--   and Revenue Intelligence layers.
--
-- Design principle:
--   Raw schemas preserve source-system records.
--   Business validation happens later in transformation/reporting.
-- ============================================================


-- ============================================================
-- SOURCE SCHEMAS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS raw_crm;
CREATE SCHEMA IF NOT EXISTS raw_marketing;
CREATE SCHEMA IF NOT EXISTS raw_billing;
CREATE SCHEMA IF NOT EXISTS raw_planning;


-- ============================================================
-- RAW CRM — SALES REPS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw_crm.sales_reps (
    rep_id                  VARCHAR(30) PRIMARY KEY,
    full_name               VARCHAR(150),
    email                   VARCHAR(255),
    team                    VARCHAR(100),
    manager_id              VARCHAR(30),
    region                  VARCHAR(100),
    employment_status       VARCHAR(50),
    hire_date               DATE,
    monthly_quota_default   NUMERIC(14,2),

    source_created_at       TIMESTAMPTZ,
    source_updated_at       TIMESTAMPTZ,
    ingested_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- RAW CRM — ACCOUNTS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw_crm.accounts (
    account_id              VARCHAR(30) PRIMARY KEY,
    account_name            VARCHAR(255),
    industry                VARCHAR(150),
    segment                 VARCHAR(100),
    employee_band           VARCHAR(100),
    annual_revenue          NUMERIC(16,2),
    country                 VARCHAR(100),
    city                    VARCHAR(100),
    owner_rep_id            VARCHAR(30),
    account_status          VARCHAR(50),

    source_created_at       TIMESTAMPTZ,
    source_updated_at       TIMESTAMPTZ,
    ingested_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- RAW CRM — CONTACTS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw_crm.contacts (
    contact_id              VARCHAR(30) PRIMARY KEY,
    account_id              VARCHAR(30),
    first_name              VARCHAR(100),
    last_name               VARCHAR(100),
    email                   VARCHAR(255),
    phone                   VARCHAR(100),
    job_title               VARCHAR(150),
    lifecycle_stage         VARCHAR(100),
    contact_status          VARCHAR(50),
    owner_rep_id            VARCHAR(30),

    source_created_at       TIMESTAMPTZ,
    source_updated_at       TIMESTAMPTZ,
    ingested_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- RAW CRM — DEALS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw_crm.deals (
    deal_id                 VARCHAR(30) PRIMARY KEY,
    account_id              VARCHAR(30),
    primary_contact_id      VARCHAR(30),
    owner_rep_id            VARCHAR(30),

    deal_name               VARCHAR(255),
    product_tier            VARCHAR(100),

    stage                    VARCHAR(100),
    outcome                  VARCHAR(100),

    amount                   NUMERIC(14,2),
    probability              NUMERIC(6,2),
    currency                 VARCHAR(10),

    lead_source              VARCHAR(100),

    created_at               TIMESTAMPTZ,
    qualified_at             TIMESTAMPTZ,
    opportunity_at           TIMESTAMPTZ,
    proposal_sent_at         TIMESTAMPTZ,

    expected_close_date      DATE,
    closed_at                TIMESTAMPTZ,

    last_activity_at         TIMESTAMPTZ,
    next_activity_at         TIMESTAMPTZ,
    first_response_at        TIMESTAMPTZ,
    sla_due_at               TIMESTAMPTZ,

    lost_reason              VARCHAR(255),

    source_updated_at        TIMESTAMPTZ,
    ingested_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- RAW CRM — SALES ACTIVITIES
-- ============================================================

CREATE TABLE IF NOT EXISTS raw_crm.activities (
    activity_id             VARCHAR(40) PRIMARY KEY,
    deal_id                 VARCHAR(30),
    contact_id              VARCHAR(30),
    account_id              VARCHAR(30),
    rep_id                  VARCHAR(30),

    activity_type           VARCHAR(100),
    activity_outcome        VARCHAR(100),

    activity_at             TIMESTAMPTZ,
    next_step_due_at        TIMESTAMPTZ,

    notes_summary           TEXT,

    source_created_at       TIMESTAMPTZ,
    source_updated_at       TIMESTAMPTZ,
    ingested_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- RAW MARKETING — CAMPAIGNS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw_marketing.campaigns (
    campaign_id             VARCHAR(30) PRIMARY KEY,
    campaign_name           VARCHAR(255),
    channel                 VARCHAR(100),
    campaign_type           VARCHAR(100),

    start_date              DATE,
    end_date                DATE,

    budget                  NUMERIC(14,2),
    status                  VARCHAR(50),

    source_created_at       TIMESTAMPTZ,
    source_updated_at       TIMESTAMPTZ,
    ingested_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- RAW MARKETING — LEADS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw_marketing.leads (
    lead_id                 VARCHAR(30) PRIMARY KEY,

    contact_id              VARCHAR(30),
    account_id              VARCHAR(30),
    campaign_id             VARCHAR(30),
    owner_rep_id            VARCHAR(30),

    lead_source             VARCHAR(100),
    lead_status             VARCHAR(100),

    utm_source              VARCHAR(150),
    utm_medium              VARCHAR(150),
    utm_campaign            VARCHAR(150),

    lead_created_at         TIMESTAMPTZ,
    first_response_at       TIMESTAMPTZ,
    mql_at                  TIMESTAMPTZ,
    sql_at                  TIMESTAMPTZ,

    source_updated_at       TIMESTAMPTZ,
    ingested_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- RAW BILLING — INVOICES
-- ============================================================

CREATE TABLE IF NOT EXISTS raw_billing.invoices (
    invoice_id              VARCHAR(40) PRIMARY KEY,
    account_id              VARCHAR(30),
    deal_id                 VARCHAR(30),

    invoice_number          VARCHAR(100),
    invoice_date            DATE,
    due_date                DATE,

    currency                VARCHAR(10),
    invoice_amount          NUMERIC(14,2),
    paid_amount             NUMERIC(14,2),
    outstanding_amount      NUMERIC(14,2),

    invoice_status          VARCHAR(100),

    source_created_at       TIMESTAMPTZ,
    source_updated_at       TIMESTAMPTZ,
    ingested_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- RAW BILLING — PAYMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw_billing.payments (
    payment_id              VARCHAR(40) PRIMARY KEY,
    invoice_id              VARCHAR(40),
    account_id              VARCHAR(30),
    deal_id                 VARCHAR(30),

    payment_date            TIMESTAMPTZ,

    currency                VARCHAR(10),
    payment_amount          NUMERIC(14,2),

    payment_method          VARCHAR(100),
    payment_status          VARCHAR(100),

    source_created_at       TIMESTAMPTZ,
    source_updated_at       TIMESTAMPTZ,
    ingested_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- RAW PLANNING — SALES TARGETS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw_planning.sales_targets (
    target_id               VARCHAR(40) PRIMARY KEY,
    rep_id                  VARCHAR(30),

    target_month            DATE,
    team                    VARCHAR(100),

    revenue_target          NUMERIC(14,2),
    pipeline_target         NUMERIC(14,2),

    source_created_at       TIMESTAMPTZ,
    source_updated_at       TIMESTAMPTZ,
    ingested_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- INGESTION / LOOKUP INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_raw_accounts_owner
    ON raw_crm.accounts(owner_rep_id);

CREATE INDEX IF NOT EXISTS idx_raw_contacts_account
    ON raw_crm.contacts(account_id);

CREATE INDEX IF NOT EXISTS idx_raw_contacts_owner
    ON raw_crm.contacts(owner_rep_id);

CREATE INDEX IF NOT EXISTS idx_raw_deals_account
    ON raw_crm.deals(account_id);

CREATE INDEX IF NOT EXISTS idx_raw_deals_owner
    ON raw_crm.deals(owner_rep_id);

CREATE INDEX IF NOT EXISTS idx_raw_deals_stage
    ON raw_crm.deals(stage);

CREATE INDEX IF NOT EXISTS idx_raw_deals_closed_at
    ON raw_crm.deals(closed_at);

CREATE INDEX IF NOT EXISTS idx_raw_deals_expected_close
    ON raw_crm.deals(expected_close_date);

CREATE INDEX IF NOT EXISTS idx_raw_deals_activity
    ON raw_crm.deals(last_activity_at);

CREATE INDEX IF NOT EXISTS idx_raw_activities_deal
    ON raw_crm.activities(deal_id);

CREATE INDEX IF NOT EXISTS idx_raw_activities_rep
    ON raw_crm.activities(rep_id);

CREATE INDEX IF NOT EXISTS idx_raw_activities_time
    ON raw_crm.activities(activity_at);

CREATE INDEX IF NOT EXISTS idx_raw_leads_source
    ON raw_marketing.leads(lead_source);

CREATE INDEX IF NOT EXISTS idx_raw_leads_campaign
    ON raw_marketing.leads(campaign_id);

CREATE INDEX IF NOT EXISTS idx_raw_invoices_deal
    ON raw_billing.invoices(deal_id);

CREATE INDEX IF NOT EXISTS idx_raw_invoices_account
    ON raw_billing.invoices(account_id);

CREATE INDEX IF NOT EXISTS idx_raw_payments_invoice
    ON raw_billing.payments(invoice_id);

CREATE INDEX IF NOT EXISTS idx_raw_targets_rep_month
    ON raw_planning.sales_targets(rep_id, target_month);
