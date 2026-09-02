BEGIN;

CREATE SCHEMA IF NOT EXISTS ingestion
    AUTHORIZATION revint_admin;

CREATE TABLE IF NOT EXISTS ingestion.sync_runs (
    run_id                  BIGSERIAL PRIMARY KEY,
    workflow_execution_id   TEXT,
    sync_scope              TEXT NOT NULL DEFAULT 'all',
    run_status              TEXT NOT NULL DEFAULT 'running'
        CHECK (
            run_status IN (
                'running',
                'succeeded',
                'failed',
                'partial'
            )
        ),
    started_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at            TIMESTAMPTZ,
    rows_extracted          INTEGER NOT NULL DEFAULT 0
        CHECK (rows_extracted >= 0),
    rows_upserted           INTEGER NOT NULL DEFAULT 0
        CHECK (rows_upserted >= 0),
    rows_rejected           INTEGER NOT NULL DEFAULT 0
        CHECK (rows_rejected >= 0),
    error_message           TEXT,
    run_metadata            JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ingestion.sync_run_entities (
    entity_run_id           BIGSERIAL PRIMARY KEY,

    run_id                  BIGINT NOT NULL
        REFERENCES ingestion.sync_runs(run_id),

    entity_key              TEXT NOT NULL,

    start_watermark         TIMESTAMPTZ,
    start_primary_key       TEXT,

    end_watermark           TIMESTAMPTZ,
    end_primary_key         TEXT,

    rows_extracted          INTEGER NOT NULL DEFAULT 0
        CHECK (rows_extracted >= 0),

    rows_upserted           INTEGER NOT NULL DEFAULT 0
        CHECK (rows_upserted >= 0),

    entity_status           TEXT NOT NULL DEFAULT 'running'
        CHECK (
            entity_status IN (
                'running',
                'succeeded',
                'failed'
            )
        ),

    error_message           TEXT,

    started_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at            TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS ingestion.sync_checkpoints (
    entity_key              TEXT PRIMARY KEY,

    source_database         TEXT NOT NULL,
    source_schema           TEXT NOT NULL,
    source_table            TEXT NOT NULL,

    target_schema           TEXT NOT NULL,
    target_table            TEXT NOT NULL,

    primary_key_column      TEXT NOT NULL,
    watermark_column        TEXT NOT NULL
        DEFAULT 'source_updated_at',

    last_watermark          TIMESTAMPTZ NOT NULL,
    last_primary_key        TEXT NOT NULL,

    checkpoint_status       TEXT NOT NULL DEFAULT 'ready'
        CHECK (
            checkpoint_status IN (
                'ready',
                'running',
                'failed'
            )
        ),

    last_successful_run_id  BIGINT
        REFERENCES ingestion.sync_runs(run_id),

    last_synced_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO ingestion.sync_checkpoints (
    entity_key,
    source_database,
    source_schema,
    source_table,
    target_schema,
    target_table,
    primary_key_column,
    watermark_column,
    last_watermark,
    last_primary_key
)

SELECT
    'crm.sales_reps',
    'lumora_source_systems',
    'crm',
    'sales_reps',
    'raw_crm',
    'sales_reps',
    'rep_id',
    'source_updated_at',
    source_updated_at,
    rep_id::text
FROM (
    SELECT source_updated_at, rep_id
    FROM raw_crm.sales_reps
    ORDER BY source_updated_at DESC, rep_id DESC
    LIMIT 1
) q

UNION ALL

SELECT
    'crm.accounts',
    'lumora_source_systems',
    'crm',
    'accounts',
    'raw_crm',
    'accounts',
    'account_id',
    'source_updated_at',
    source_updated_at,
    account_id::text
FROM (
    SELECT source_updated_at, account_id
    FROM raw_crm.accounts
    ORDER BY source_updated_at DESC, account_id DESC
    LIMIT 1
) q

UNION ALL

SELECT
    'crm.contacts',
    'lumora_source_systems',
    'crm',
    'contacts',
    'raw_crm',
    'contacts',
    'contact_id',
    'source_updated_at',
    source_updated_at,
    contact_id::text
FROM (
    SELECT source_updated_at, contact_id
    FROM raw_crm.contacts
    ORDER BY source_updated_at DESC, contact_id DESC
    LIMIT 1
) q

UNION ALL

SELECT
    'crm.deals',
    'lumora_source_systems',
    'crm',
    'deals',
    'raw_crm',
    'deals',
    'deal_id',
    'source_updated_at',
    source_updated_at,
    deal_id::text
FROM (
    SELECT source_updated_at, deal_id
    FROM raw_crm.deals
    ORDER BY source_updated_at DESC, deal_id DESC
    LIMIT 1
) q

UNION ALL

SELECT
    'crm.activities',
    'lumora_source_systems',
    'crm',
    'activities',
    'raw_crm',
    'activities',
    'activity_id',
    'source_updated_at',
    source_updated_at,
    activity_id::text
FROM (
    SELECT source_updated_at, activity_id
    FROM raw_crm.activities
    ORDER BY source_updated_at DESC, activity_id DESC
    LIMIT 1
) q

UNION ALL

SELECT
    'marketing.campaigns',
    'lumora_source_systems',
    'marketing',
    'campaigns',
    'raw_marketing',
    'campaigns',
    'campaign_id',
    'source_updated_at',
    source_updated_at,
    campaign_id::text
FROM (
    SELECT source_updated_at, campaign_id
    FROM raw_marketing.campaigns
    ORDER BY source_updated_at DESC, campaign_id DESC
    LIMIT 1
) q

UNION ALL

SELECT
    'marketing.leads',
    'lumora_source_systems',
    'marketing',
    'leads',
    'raw_marketing',
    'leads',
    'lead_id',
    'source_updated_at',
    source_updated_at,
    lead_id::text
FROM (
    SELECT source_updated_at, lead_id
    FROM raw_marketing.leads
    ORDER BY source_updated_at DESC, lead_id DESC
    LIMIT 1
) q

UNION ALL

SELECT
    'billing.invoices',
    'lumora_source_systems',
    'billing',
    'invoices',
    'raw_billing',
    'invoices',
    'invoice_id',
    'source_updated_at',
    source_updated_at,
    invoice_id::text
FROM (
    SELECT source_updated_at, invoice_id
    FROM raw_billing.invoices
    ORDER BY source_updated_at DESC, invoice_id DESC
    LIMIT 1
) q

UNION ALL

SELECT
    'billing.payments',
    'lumora_source_systems',
    'billing',
    'payments',
    'raw_billing',
    'payments',
    'payment_id',
    'source_updated_at',
    source_updated_at,
    payment_id::text
FROM (
    SELECT source_updated_at, payment_id
    FROM raw_billing.payments
    ORDER BY source_updated_at DESC, payment_id DESC
    LIMIT 1
) q

UNION ALL

SELECT
    'planning.sales_targets',
    'lumora_source_systems',
    'planning',
    'sales_targets',
    'raw_planning',
    'sales_targets',
    'target_id',
    'source_updated_at',
    source_updated_at,
    target_id::text
FROM (
    SELECT source_updated_at, target_id
    FROM raw_planning.sales_targets
    ORDER BY source_updated_at DESC, target_id DESC
    LIMIT 1
) q

ON CONFLICT (entity_key)
DO NOTHING;

COMMIT;
