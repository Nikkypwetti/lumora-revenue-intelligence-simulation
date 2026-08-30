-- ============================================================
-- Lumora Cloud
-- Stage 3D: Raw-to-Reporting Transformation
--
-- Purpose:
-- Transform simulated operational CRM data into the exact
-- governed reporting contract expected by REVINT.
-- ============================================================


-- ============================================================
-- 1. RESET TRANSFORMATION QUALITY RESULTS
--
-- This simulation uses a reproducible full-refresh quality scan.
-- ============================================================

TRUNCATE TABLE quality.transformation_rejections
RESTART IDENTITY;

TRUNCATE TABLE quality.data_quality_issues
RESTART IDENTITY;


-- ============================================================
-- 2. SALES REP DIMENSION
-- ============================================================

INSERT INTO reporting.dim_sales_rep (
    sales_rep_id,
    sales_rep_name,
    email,
    region,
    is_active,
    created_at,
    updated_at
)

SELECT
    rep_id,
    full_name,
    email,
    region,

    CASE
        WHEN LOWER(COALESCE(employment_status, '')) = 'active'
            THEN TRUE
        ELSE FALSE
    END,

    COALESCE(
        source_created_at,
        ingested_at,
        NOW()
    ),

    COALESCE(
        source_updated_at,
        ingested_at,
        NOW()
    )

FROM raw_crm.sales_reps

WHERE rep_id IS NOT NULL
  AND full_name IS NOT NULL

ON CONFLICT (sales_rep_id)
DO UPDATE SET

    sales_rep_name =
        EXCLUDED.sales_rep_name,

    email =
        EXCLUDED.email,

    region =
        EXCLUDED.region,

    is_active =
        EXCLUDED.is_active,

    updated_at =
        EXCLUDED.updated_at;


-- ============================================================
-- 3. ACCOUNT DIMENSION
-- ============================================================

INSERT INTO reporting.dim_account (
    account_id,
    account_name,
    industry,
    segment,
    country,
    is_active,
    created_at,
    updated_at
)

SELECT
    account_id,
    account_name,
    industry,
    segment,
    country,

    CASE
        WHEN LOWER(COALESCE(account_status, '')) = 'active'
            THEN TRUE
        ELSE FALSE
    END,

    COALESCE(
        source_created_at,
        ingested_at,
        NOW()
    ),

    COALESCE(
        source_updated_at,
        ingested_at,
        NOW()
    )

FROM raw_crm.accounts

WHERE account_id IS NOT NULL
  AND account_name IS NOT NULL

ON CONFLICT (account_id)
DO UPDATE SET

    account_name =
        EXCLUDED.account_name,

    industry =
        EXCLUDED.industry,

    segment =
        EXCLUDED.segment,

    country =
        EXCLUDED.country,

    is_active =
        EXCLUDED.is_active,

    updated_at =
        EXCLUDED.updated_at;


-- ============================================================
-- 4. HARD DEAL VALIDATION
--
-- These records are unsafe for governed reporting.
-- Multiple rejection reasons can be recorded for one record.
-- ============================================================

INSERT INTO quality.transformation_rejections (
    entity_type,
    source_record_id,
    reason_code,
    reason_detail,
    source_payload
)

SELECT
    'deal',
    d.deal_id,
    rule.reason_code,
    rule.reason_detail,
    TO_JSONB(d)

FROM raw_crm.deals d

CROSS JOIN LATERAL (

    VALUES

    (
        'MISSING_ACCOUNT_ID',
        d.account_id IS NULL,
        'Deal has no account_id.'
    ),

    (
        'MISSING_SALES_REP',
        d.owner_rep_id IS NULL,
        'Deal has no owner_rep_id.'
    ),

    (
        'MISSING_DEAL_NAME',
        d.deal_name IS NULL
            OR BTRIM(d.deal_name) = '',
        'Deal has no usable deal name.'
    ),

    (
        'MISSING_STAGE',
        d.stage IS NULL
            OR BTRIM(d.stage) = '',
        'Deal has no stage.'
    ),

    (
        'INVALID_STAGE',
        d.stage IS NOT NULL
        AND d.stage NOT IN (
            'Discovery',
            'Qualified',
            'Proposal Sent',
            'Negotiation',
            'Closed Won',
            'Closed Lost'
        ),
        'Deal stage is outside the approved Lumora lifecycle.'
    ),

    (
        'MISSING_AMOUNT',
        d.amount IS NULL,
        'Deal amount is missing.'
    ),

    (
        'NEGATIVE_AMOUNT',
        d.amount IS NOT NULL
            AND d.amount < 0,
        'Deal amount is negative.'
    ),

    (
        'INVALID_PROBABILITY',
        d.probability IS NOT NULL
        AND (
            d.probability < 0
            OR d.probability > 100
        ),
        'Probability must be between 0 and 100.'
    ),

    (
        'MISSING_CREATED_AT',
        d.created_at IS NULL,
        'Deal created_at is missing.'
    ),

    (
        'UNKNOWN_ACCOUNT',
        d.account_id IS NOT NULL
        AND NOT EXISTS (
            SELECT 1
            FROM reporting.dim_account a
            WHERE a.account_id = d.account_id
        ),
        'Deal account does not exist in reporting.dim_account.'
    ),

    (
        'UNKNOWN_SALES_REP',
        d.owner_rep_id IS NOT NULL
        AND NOT EXISTS (
            SELECT 1
            FROM reporting.dim_sales_rep r
            WHERE r.sales_rep_id = d.owner_rep_id
        ),
        'Deal owner does not exist in reporting.dim_sales_rep.'
    )

) AS rule(
    reason_code,
    rule_failed,
    reason_detail
)

WHERE rule.rule_failed;


-- ============================================================
-- 5. GOVERNED DEAL FACT
--
-- Missing/unrecognized lead source is intentionally mapped
-- to LS000 rather than rejecting the deal.
-- ============================================================

INSERT INTO reporting.fact_deals (
    deal_id,
    account_id,
    sales_rep_id,
    lead_source_id,

    deal_name,
    stage,
    outcome,

    amount,
    probability,

    created_at,
    qualified_at,
    opportunity_at,
    proposal_sent_at,

    expected_close_date,
    closed_at,

    last_activity_at,
    next_activity_at,
    first_response_at,
    sla_due_at,

    lost_reason,

    created_timestamp,
    updated_timestamp
)

SELECT
    d.deal_id,

    d.account_id,

    d.owner_rep_id,

    COALESCE(
        ls.lead_source_id,
        'LS000'
    ),

    d.deal_name,

    d.stage,

    d.outcome,

    d.amount,

    d.probability,

    d.created_at,

    d.qualified_at,

    d.opportunity_at,

    d.proposal_sent_at,

    d.expected_close_date,

    d.closed_at,

    d.last_activity_at,

    d.next_activity_at,

    d.first_response_at,

    d.sla_due_at,

    d.lost_reason,

    d.ingested_at,

    COALESCE(
        d.source_updated_at,
        d.ingested_at
    )

FROM raw_crm.deals d

LEFT JOIN reporting.dim_lead_source ls
    ON ls.lead_source_name = d.lead_source
   AND ls.is_active = TRUE

WHERE NOT EXISTS (

    SELECT 1

    FROM quality.transformation_rejections r

    WHERE r.entity_type = 'deal'
      AND r.source_record_id = d.deal_id
)

ON CONFLICT (deal_id)
DO UPDATE SET

    account_id =
        EXCLUDED.account_id,

    sales_rep_id =
        EXCLUDED.sales_rep_id,

    lead_source_id =
        EXCLUDED.lead_source_id,

    deal_name =
        EXCLUDED.deal_name,

    stage =
        EXCLUDED.stage,

    outcome =
        EXCLUDED.outcome,

    amount =
        EXCLUDED.amount,

    probability =
        EXCLUDED.probability,

    created_at =
        EXCLUDED.created_at,

    qualified_at =
        EXCLUDED.qualified_at,

    opportunity_at =
        EXCLUDED.opportunity_at,

    proposal_sent_at =
        EXCLUDED.proposal_sent_at,

    expected_close_date =
        EXCLUDED.expected_close_date,

    closed_at =
        EXCLUDED.closed_at,

    last_activity_at =
        EXCLUDED.last_activity_at,

    next_activity_at =
        EXCLUDED.next_activity_at,

    first_response_at =
        EXCLUDED.first_response_at,

    sla_due_at =
        EXCLUDED.sla_due_at,

    lost_reason =
        EXCLUDED.lost_reason,

    updated_timestamp =
        EXCLUDED.updated_timestamp;


-- ============================================================
-- 6. SOFT QUALITY — ACCOUNTS
-- ============================================================

INSERT INTO quality.data_quality_issues (
    entity_type,
    source_record_id,
    issue_code,
    severity,
    issue_detail
)

SELECT
    'account',
    account_id,
    'MISSING_INDUSTRY',
    'medium',
    'Account industry is missing.'

FROM raw_crm.accounts

WHERE industry IS NULL
   OR BTRIM(industry) = '';


-- ============================================================
-- 7. SOFT QUALITY — CONTACTS
-- ============================================================

INSERT INTO quality.data_quality_issues (
    entity_type,
    source_record_id,
    issue_code,
    severity,
    issue_detail
)

SELECT
    'contact',
    contact_id,
    'MISSING_PHONE',
    'low',
    'Contact phone is missing.'

FROM raw_crm.contacts

WHERE phone IS NULL
   OR BTRIM(phone) = '';


INSERT INTO quality.data_quality_issues (
    entity_type,
    source_record_id,
    issue_code,
    severity,
    issue_detail
)

SELECT
    'contact',
    contact_id,
    'MISSING_JOB_TITLE',
    'medium',
    'Contact job title is missing.'

FROM raw_crm.contacts

WHERE job_title IS NULL
   OR BTRIM(job_title) = '';


INSERT INTO quality.data_quality_issues (
    entity_type,
    source_record_id,
    issue_code,
    severity,
    issue_detail
)

SELECT
    'contact',
    contact_id,
    'DUPLICATE_EMAIL',
    'high',
    'Contact email is shared by more than one CRM contact.'

FROM (

    SELECT
        contact_id,
        email,

        COUNT(*) OVER (
            PARTITION BY LOWER(email)
        ) AS email_count

    FROM raw_crm.contacts

    WHERE email IS NOT NULL
      AND BTRIM(email) <> ''

) duplicates

WHERE email_count > 1;


-- ============================================================
-- 8. SOFT QUALITY — DEAL ATTRIBUTION
-- ============================================================

INSERT INTO quality.data_quality_issues (
    entity_type,
    source_record_id,
    issue_code,
    severity,
    issue_detail
)

SELECT
    'deal',
    deal_id,
    'MISSING_LEAD_SOURCE',
    'medium',
    'Lead source is missing; reporting maps this deal to LS000 / Unknown.'

FROM raw_crm.deals

WHERE lead_source IS NULL
   OR BTRIM(lead_source) = '';


-- ============================================================
-- 9. SOFT QUALITY — STALE OPEN DEALS
--
-- Simulation snapshot date: 2026-08-30
-- Stale threshold: >14 days without activity
-- ============================================================

INSERT INTO quality.data_quality_issues (
    entity_type,
    source_record_id,
    issue_code,
    severity,
    issue_detail
)

SELECT
    'deal',
    deal_id,
    'STALE_OPEN_DEAL',
    'high',
    'Open opportunity has had no activity for more than 14 days.'

FROM raw_crm.deals

WHERE outcome IS NULL

  AND (
      last_activity_at IS NULL

      OR last_activity_at <
         TIMESTAMPTZ '2026-08-16 00:00:00+00'
  );


-- ============================================================
-- 10. SOFT QUALITY — MISSING EXPECTED CLOSE DATE
-- ============================================================

INSERT INTO quality.data_quality_issues (
    entity_type,
    source_record_id,
    issue_code,
    severity,
    issue_detail
)

SELECT
    'deal',
    deal_id,
    'MISSING_EXPECTED_CLOSE_DATE',
    'high',
    'Open opportunity is missing its expected close date.'

FROM raw_crm.deals

WHERE outcome IS NULL
  AND expected_close_date IS NULL;


-- ============================================================
-- 11. SOFT QUALITY — SLA FAILURE
-- ============================================================

INSERT INTO quality.data_quality_issues (
    entity_type,
    source_record_id,
    issue_code,
    severity,
    issue_detail
)

SELECT
    'deal',
    deal_id,
    'FIRST_RESPONSE_SLA_MISSED',
    'high',
    'First response occurred after the configured SLA due time.'

FROM raw_crm.deals

WHERE first_response_at IS NOT NULL
  AND sla_due_at IS NOT NULL
  AND first_response_at > sla_due_at;


-- ============================================================
-- 12. SOFT QUALITY — LOST REASON
-- ============================================================

INSERT INTO quality.data_quality_issues (
    entity_type,
    source_record_id,
    issue_code,
    severity,
    issue_detail
)

SELECT
    'deal',
    deal_id,
    'MISSING_LOST_REASON',
    'medium',
    'Closed Lost opportunity has no lost reason.'

FROM raw_crm.deals

WHERE outcome = 'Closed Lost'

  AND (
      lost_reason IS NULL
      OR BTRIM(lost_reason) = ''
  );


-- ============================================================
-- 13. SOFT QUALITY — NEXT ACTIVITY
-- ============================================================

INSERT INTO quality.data_quality_issues (
    entity_type,
    source_record_id,
    issue_code,
    severity,
    issue_detail
)

SELECT
    'deal',
    deal_id,
    'MISSING_NEXT_ACTIVITY',
    'high',
    'Open opportunity has no next activity scheduled.'

FROM raw_crm.deals

WHERE outcome IS NULL
  AND next_activity_at IS NULL;
