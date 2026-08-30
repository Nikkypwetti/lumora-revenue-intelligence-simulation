-- ============================================================
-- Lumora Cloud
-- Stage 3B: Leads, Deals and Sales Activities
-- ============================================================


-- ============================================================
-- 1. MARKETING LEADS
-- 500 historical leads mapped to existing contacts/accounts
-- ============================================================

WITH generated_leads AS (
    SELECT
        i,

        TIMESTAMPTZ '2025-09-01 08:00:00+00'
            + ((i * 5) % 360) * INTERVAL '1 day'
            + (i % 10) * INTERVAL '1 hour'
            AS lead_created,

        CASE
            WHEN i % 23 = 0
                THEN NULL
            ELSE
                (ARRAY[
                    'Website Form',
                    'LinkedIn',
                    'Outbound Email',
                    'Referral',
                    'Paid Search',
                    'Partner',
                    'Webinar'
                ])[((i - 1) % 7) + 1]
        END AS lead_source
    FROM generate_series(1,500) AS g(i)
)

INSERT INTO raw_marketing.leads (
    lead_id,
    contact_id,
    account_id,
    campaign_id,
    owner_rep_id,
    lead_source,
    lead_status,
    utm_source,
    utm_medium,
    utm_campaign,
    lead_created_at,
    first_response_at,
    mql_at,
    sql_at,
    source_updated_at
)

SELECT
    'LEAD' || LPAD(g.i::TEXT,4,'0'),

    c.contact_id,

    c.account_id,

    'CMP' || LPAD((((g.i - 1) % 12) + 1)::TEXT,3,'0'),

    c.owner_rep_id,

    g.lead_source,

    CASE
        WHEN g.i % 10 = 0 THEN 'Disqualified'
        WHEN g.i % 4 = 0 THEN 'MQL'
        ELSE 'SQL'
    END,

    CASE
        WHEN g.lead_source = 'LinkedIn' THEN 'linkedin'
        WHEN g.lead_source = 'Paid Search' THEN 'google'
        WHEN g.lead_source = 'Outbound Email' THEN 'outbound'
        WHEN g.lead_source = 'Partner' THEN 'partner'
        WHEN g.lead_source = 'Webinar' THEN 'webinar'
        WHEN g.lead_source = 'Referral' THEN 'referral'
        WHEN g.lead_source = 'Website Form' THEN 'website'
        ELSE NULL
    END,

    CASE
        WHEN g.lead_source IN ('LinkedIn','Paid Search')
            THEN 'paid'
        WHEN g.lead_source = 'Outbound Email'
            THEN 'email'
        WHEN g.lead_source IS NULL
            THEN NULL
        ELSE 'organic'
    END,

    'lumora-campaign-' ||
        LPAD((((g.i - 1) % 12) + 1)::TEXT,2,'0'),

    g.lead_created,

    g.lead_created +
        CASE
            WHEN g.i % 9 = 0
                THEN INTERVAL '30 hours'
            ELSE
                (4 + (g.i % 9)) * INTERVAL '1 hour'
        END,

    CASE
        WHEN g.i % 10 = 0
            THEN NULL
        ELSE g.lead_created + INTERVAL '1 day'
    END,

    CASE
        WHEN g.i % 10 = 0 OR g.i % 4 = 0
            THEN NULL
        ELSE g.lead_created + INTERVAL '3 days'
    END,

    NOW()

FROM generated_leads g

JOIN raw_crm.contacts c
    ON c.contact_id =
       'CON' || LPAD(g.i::TEXT,4,'0')

ON CONFLICT (lead_id)
DO UPDATE SET
    contact_id = EXCLUDED.contact_id,
    account_id = EXCLUDED.account_id,
    campaign_id = EXCLUDED.campaign_id,
    owner_rep_id = EXCLUDED.owner_rep_id,
    lead_source = EXCLUDED.lead_source,
    lead_status = EXCLUDED.lead_status,
    first_response_at = EXCLUDED.first_response_at,
    mql_at = EXCLUDED.mql_at,
    sql_at = EXCLUDED.sql_at,
    source_updated_at = NOW();


-- ============================================================
-- 2. SALES OPPORTUNITIES
--
-- Exactly 100 deals per sales rep.
--
-- Performance profiles:
--
-- Amina:   45 won / 25 lost / 30 open
-- David:   30 won / 35 lost / 35 open
-- Sarah:   40 won / 30 lost / 30 open
-- Michael: 50 won / 20 lost / 30 open
-- Daniel:  35 won / 35 lost / 30 open
-- Jessica: 25 won / 40 lost / 35 open
--
-- This deliberately creates different win rates and pipeline.
-- ============================================================

WITH rep_rules AS (

    SELECT *
    FROM (
        VALUES
            ('SR001',1,45,25),
            ('SR002',2,30,35),
            ('SR003',3,40,30),
            ('SR004',4,50,20),
            ('SR005',5,35,35),
            ('SR006',6,25,40)
    ) AS r(
        rep_id,
        rep_num,
        won_count,
        lost_count
    )
),

base AS (

    SELECT
        i,

        r.rep_id,
        r.rep_num,
        r.won_count,
        r.lost_count,

        (((i - 1) / 6) + 1)::INTEGER AS rep_deal_number,

        (((i * 11 + r.rep_num * 17 - 1) % 500) + 1)
            AS contact_number

    FROM generate_series(1,600) AS g(i)

    JOIN rep_rules r
        ON r.rep_num = ((i - 1) % 6) + 1
),

classified AS (

    SELECT
        b.*,

        ((contact_number - 1) % 150) + 1
            AS account_number,

        CASE
            WHEN rep_deal_number <= won_count
                THEN 'Closed Won'

            WHEN rep_deal_number <= won_count + lost_count
                THEN 'Closed Lost'

            ELSE NULL
        END AS outcome_value

    FROM base b
),

dated AS (

    SELECT
        c.*,

        CASE
            WHEN outcome_value IS NULL THEN

                TIMESTAMPTZ '2026-04-01 09:00:00+00'
                + (
                    (
                        rep_deal_number * 3
                        + rep_num * 11
                    ) % 145
                  ) * INTERVAL '1 day'

            ELSE

                TIMESTAMPTZ '2025-09-01 09:00:00+00'
                + (
                    (
                        rep_deal_number * 5
                        + rep_num * 17
                    ) % 275
                  ) * INTERVAL '1 day'
        END AS created_value

    FROM classified c
),

staged AS (

    SELECT
        d.*,

        CASE
            WHEN outcome_value = 'Closed Won'
                THEN 'Closed Won'

            WHEN outcome_value = 'Closed Lost'
                THEN 'Closed Lost'

            WHEN rep_deal_number % 4 = 0
                THEN 'Discovery'

            WHEN rep_deal_number % 4 = 1
                THEN 'Qualified'

            WHEN rep_deal_number % 4 = 2
                THEN 'Proposal Sent'

            ELSE 'Negotiation'
        END AS stage_value,

        CASE
            WHEN outcome_value IS NULL
                THEN NULL

            ELSE
                created_value
                + (
                    15
                    + (
                        (
                            rep_deal_number * 7
                            + rep_num * 5
                        ) % 70
                      )
                  ) * INTERVAL '1 day'
        END AS closed_value

    FROM dated d
),

enriched AS (

    SELECT
        s.*,

        CASE
            WHEN rep_num <= 3
                 AND rep_deal_number % 4 <> 0
                THEN 'Starter'

            WHEN rep_num <= 3
                THEN 'Growth'

            WHEN rep_deal_number % 3 = 0
                THEN 'Scale'

            ELSE 'Growth'
        END AS product_value,

        CASE
            WHEN outcome_value IS NOT NULL
                THEN closed_value - (
                    (rep_deal_number % 5) + 1
                ) * INTERVAL '1 day'

            WHEN rep_deal_number % 4 = 0
                THEN GREATEST(
                    created_value + INTERVAL '2 days',

                    TIMESTAMPTZ '2026-08-01 00:00:00+00'
                    - (
                        (rep_deal_number % 15) + 1
                      ) * INTERVAL '1 day'
                )

            ELSE GREATEST(
                created_value + INTERVAL '2 days',

                TIMESTAMPTZ '2026-08-30 00:00:00+00'
                - (
                    (rep_deal_number % 10) + 1
                  ) * INTERVAL '1 day'
            )
        END AS last_activity_value

    FROM staged s
)

INSERT INTO raw_crm.deals (
    deal_id,
    account_id,
    primary_contact_id,
    owner_rep_id,
    deal_name,
    product_tier,
    stage,
    outcome,
    amount,
    probability,
    currency,
    lead_source,
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
    source_updated_at
)

SELECT

    'DL' || LPAD(i::TEXT,4,'0'),

    'ACC' || LPAD(account_number::TEXT,4,'0'),

    'CON' || LPAD(contact_number::TEXT,4,'0'),

    rep_id,

    'Lumora Opportunity ' || LPAD(i::TEXT,4,'0'),

    product_value,

    stage_value,

    outcome_value,

    CASE
        WHEN product_value = 'Starter'
            THEN 4500 + (rep_deal_number % 10) * 500

        WHEN product_value = 'Growth'
            THEN 10000 + (rep_deal_number % 13) * 1000

        ELSE
            22000 + (rep_deal_number % 15) * 1500
    END,

    CASE stage_value
        WHEN 'Discovery' THEN 20
        WHEN 'Qualified' THEN 40
        WHEN 'Proposal Sent' THEN 60
        WHEN 'Negotiation' THEN 80
        WHEN 'Closed Won' THEN 100
        WHEN 'Closed Lost' THEN 0
        ELSE NULL
    END,

    'USD',

    CASE
        WHEN rep_deal_number % 29 = 0
            THEN NULL

        ELSE
            (ARRAY[
                'Website Form',
                'LinkedIn',
                'Outbound Email',
                'Referral',
                'Paid Search',
                'Partner',
                'Webinar'
            ])[((i - 1) % 7) + 1]
    END,

    created_value,

    CASE
        WHEN stage_value = 'Discovery'
            THEN NULL
        ELSE created_value + INTERVAL '3 days'
    END,

    CASE
        WHEN stage_value = 'Discovery'
            THEN NULL
        ELSE created_value + INTERVAL '5 days'
    END,

    CASE
        WHEN stage_value IN (
            'Proposal Sent',
            'Negotiation',
            'Closed Won',
            'Closed Lost'
        )
            THEN created_value + INTERVAL '10 days'
        ELSE NULL
    END,

    CASE
        WHEN outcome_value IS NOT NULL
            THEN closed_value::DATE

        WHEN rep_deal_number % 37 = 0
            THEN NULL

        ELSE
            DATE '2026-08-01'
            + (
                (
                    rep_deal_number * 4
                    + rep_num * 7
                ) % 95
              )::INTEGER
    END,

    closed_value,

    last_activity_value,

    CASE
        WHEN outcome_value IS NOT NULL
            THEN NULL

        WHEN rep_deal_number % 11 = 0
            THEN NULL

        ELSE
            last_activity_value
            + (
                (rep_deal_number % 12) + 1
              ) * INTERVAL '1 day'
    END,

    created_value +
        CASE
            WHEN rep_deal_number % 8 = 0
                THEN INTERVAL '32 hours'
            ELSE INTERVAL '6 hours'
        END,

    created_value + INTERVAL '24 hours',

    CASE
        WHEN outcome_value <> 'Closed Lost'
            THEN NULL

        WHEN rep_deal_number % 13 = 0
            THEN NULL

        ELSE
            (ARRAY[
                'Price too high',
                'Competitor selected',
                'Budget unavailable',
                'Timing changed'
            ])[((rep_deal_number - 1) % 4) + 1]
    END,

    COALESCE(
        closed_value,
        last_activity_value,
        created_value
    ) + INTERVAL '1 hour'

FROM enriched

ON CONFLICT (deal_id)
DO UPDATE SET

    account_id = EXCLUDED.account_id,
    primary_contact_id = EXCLUDED.primary_contact_id,
    owner_rep_id = EXCLUDED.owner_rep_id,

    deal_name = EXCLUDED.deal_name,
    product_tier = EXCLUDED.product_tier,

    stage = EXCLUDED.stage,
    outcome = EXCLUDED.outcome,

    amount = EXCLUDED.amount,
    probability = EXCLUDED.probability,
    currency = EXCLUDED.currency,

    lead_source = EXCLUDED.lead_source,

    created_at = EXCLUDED.created_at,
    qualified_at = EXCLUDED.qualified_at,
    opportunity_at = EXCLUDED.opportunity_at,
    proposal_sent_at = EXCLUDED.proposal_sent_at,

    expected_close_date = EXCLUDED.expected_close_date,
    closed_at = EXCLUDED.closed_at,

    last_activity_at = EXCLUDED.last_activity_at,
    next_activity_at = EXCLUDED.next_activity_at,

    first_response_at = EXCLUDED.first_response_at,
    sla_due_at = EXCLUDED.sla_due_at,

    lost_reason = EXCLUDED.lost_reason,
    source_updated_at = EXCLUDED.source_updated_at;


-- ============================================================
-- 3. SALES ACTIVITIES
--
-- Deals 1-200 receive four activities.
-- Deals 201-600 receive three.
--
-- Total = 2,000 activity records.
-- ============================================================

WITH deal_activity_plan AS (

    SELECT
        d.*,

        SUBSTRING(d.deal_id FROM 3)::INTEGER AS deal_number,

        CASE
            WHEN SUBSTRING(d.deal_id FROM 3)::INTEGER <= 200
                THEN 4
            ELSE 3
        END AS activity_count

    FROM raw_crm.deals d
),

generated_activities AS (

    SELECT
        d.*,
        n.activity_number,

        d.created_at
        + (
            (d.last_activity_at - d.created_at)
            * (
                n.activity_number::DOUBLE PRECISION
                /
                d.activity_count::DOUBLE PRECISION
              )
          ) AS activity_time

    FROM deal_activity_plan d

    CROSS JOIN LATERAL generate_series(
        1,
        d.activity_count
    ) AS n(activity_number)
)

INSERT INTO raw_crm.activities (
    activity_id,
    deal_id,
    contact_id,
    account_id,
    rep_id,
    activity_type,
    activity_outcome,
    activity_at,
    next_step_due_at,
    notes_summary,
    source_created_at,
    source_updated_at
)

SELECT

    'ACT-' ||
        deal_id ||
        '-' ||
        activity_number,

    deal_id,

    primary_contact_id,

    account_id,

    owner_rep_id,

    (ARRAY[
        'Email',
        'Call',
        'Meeting',
        'Demo'
    ])[((activity_number - 1) % 4) + 1],

    CASE
        WHEN activity_number = activity_count
             AND outcome = 'Closed Won'
            THEN 'Successful'

        WHEN activity_number = activity_count
             AND outcome = 'Closed Lost'
            THEN 'Unsuccessful'

        WHEN activity_number = activity_count
             AND outcome IS NULL
            THEN 'Follow-up Required'

        ELSE 'Completed'
    END,

    activity_time,

    CASE
        WHEN outcome IS NULL
            THEN activity_time + INTERVAL '7 days'
        ELSE NULL
    END,

    'Simulated sales activity for ' || deal_id,

    activity_time,

    activity_time

FROM generated_activities

ON CONFLICT (activity_id)
DO UPDATE SET

    activity_outcome = EXCLUDED.activity_outcome,
    activity_at = EXCLUDED.activity_at,
    next_step_due_at = EXCLUDED.next_step_due_at,
    notes_summary = EXCLUDED.notes_summary,
    source_updated_at = EXCLUDED.source_updated_at;
