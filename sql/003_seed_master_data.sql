-- ============================================================
-- Lumora Cloud
-- Historical Simulation Bootstrap
-- Stage 3A: Master Data
-- ============================================================


-- ============================================================
-- 1. SALES REPRESENTATIVES
-- ============================================================

INSERT INTO raw_crm.sales_reps (
    rep_id,
    full_name,
    email,
    team,
    manager_id,
    region,
    employment_status,
    hire_date,
    monthly_quota_default,
    source_created_at,
    source_updated_at
)
VALUES
(
    'SR001',
    'Amina Yusuf',
    'amina.yusuf@lumora.example',
    'SMB',
    'MGR001',
    'EMEA',
    'Active',
    DATE '2024-02-12',
    70000,
    TIMESTAMPTZ '2024-02-12 09:00:00+00',
    NOW()
),
(
    'SR002',
    'David Cole',
    'david.cole@lumora.example',
    'SMB',
    'MGR001',
    'North America',
    'Active',
    DATE '2024-05-06',
    65000,
    TIMESTAMPTZ '2024-05-06 09:00:00+00',
    NOW()
),
(
    'SR003',
    'Sarah Malik',
    'sarah.malik@lumora.example',
    'SMB',
    'MGR001',
    'EMEA',
    'Active',
    DATE '2025-01-20',
    60000,
    TIMESTAMPTZ '2025-01-20 09:00:00+00',
    NOW()
),
(
    'SR004',
    'Michael James',
    'michael.james@lumora.example',
    'Mid-Market',
    'MGR001',
    'North America',
    'Active',
    DATE '2023-09-11',
    100000,
    TIMESTAMPTZ '2023-09-11 09:00:00+00',
    NOW()
),
(
    'SR005',
    'Daniel Okafor',
    'daniel.okafor@lumora.example',
    'Mid-Market',
    'MGR001',
    'EMEA',
    'Active',
    DATE '2024-03-18',
    95000,
    TIMESTAMPTZ '2024-03-18 09:00:00+00',
    NOW()
),
(
    'SR006',
    'Jessica Brown',
    'jessica.brown@lumora.example',
    'Mid-Market',
    'MGR001',
    'North America',
    'Active',
    DATE '2025-02-03',
    90000,
    TIMESTAMPTZ '2025-02-03 09:00:00+00',
    NOW()
)
ON CONFLICT (rep_id)
DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    team = EXCLUDED.team,
    manager_id = EXCLUDED.manager_id,
    region = EXCLUDED.region,
    employment_status = EXCLUDED.employment_status,
    monthly_quota_default = EXCLUDED.monthly_quota_default,
    source_updated_at = NOW();


-- ============================================================
-- 2. MARKETING CAMPAIGNS
-- ============================================================

INSERT INTO raw_marketing.campaigns (
    campaign_id,
    campaign_name,
    channel,
    campaign_type,
    start_date,
    end_date,
    budget,
    status,
    source_created_at,
    source_updated_at
)
VALUES
('CMP001','Q4 SaaS Growth Webinar','Webinar','Demand Generation',DATE '2025-10-01',DATE '2025-10-31',12000,'Completed',NOW(),NOW()),
('CMP002','LinkedIn Operations Leaders','LinkedIn','Paid Social',DATE '2025-11-01',DATE '2025-12-15',18000,'Completed',NOW(),NOW()),
('CMP003','Year-End Referral Program','Referral','Referral',DATE '2025-12-01',DATE '2025-12-31',8000,'Completed',NOW(),NOW()),
('CMP004','January Pipeline Launch','Paid Search','Paid Search',DATE '2026-01-01',DATE '2026-01-31',22000,'Completed',NOW(),NOW()),
('CMP005','RevOps Leaders Webinar','Webinar','Demand Generation',DATE '2026-02-01',DATE '2026-02-28',14000,'Completed',NOW(),NOW()),
('CMP006','Outbound Growth Sprint','Outbound Email','Outbound',DATE '2026-03-01',DATE '2026-03-31',9000,'Completed',NOW(),NOW()),
('CMP007','Scale Operations Search','Paid Search','Paid Search',DATE '2026-04-01',DATE '2026-04-30',24000,'Completed',NOW(),NOW()),
('CMP008','Partner Growth Program','Partner','Partner',DATE '2026-05-01',DATE '2026-06-30',16000,'Completed',NOW(),NOW()),
('CMP009','Summer SaaS Webinar','Webinar','Demand Generation',DATE '2026-06-01',DATE '2026-06-30',13000,'Completed',NOW(),NOW()),
('CMP010','LinkedIn Mid-Market Push','LinkedIn','Paid Social',DATE '2026-07-01',DATE '2026-07-31',21000,'Completed',NOW(),NOW()),
('CMP011','August Website Conversion','Website Form','Inbound',DATE '2026-08-01',DATE '2026-08-31',15000,'Active',NOW(),NOW()),
('CMP012','Q3 Partner Acceleration','Partner','Partner',DATE '2026-07-01',DATE '2026-09-30',20000,'Active',NOW(),NOW())
ON CONFLICT (campaign_id)
DO UPDATE SET
    campaign_name = EXCLUDED.campaign_name,
    channel = EXCLUDED.channel,
    campaign_type = EXCLUDED.campaign_type,
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    budget = EXCLUDED.budget,
    status = EXCLUDED.status,
    source_updated_at = NOW();


-- ============================================================
-- 3. MONTHLY SALES TARGETS
-- September 2025 through August 2026
-- ============================================================

INSERT INTO raw_planning.sales_targets (
    target_id,
    rep_id,
    target_month,
    team,
    revenue_target,
    pipeline_target,
    source_created_at,
    source_updated_at
)
SELECT
    'TGT-' ||
        sr.rep_id ||
        '-' ||
        TO_CHAR(month_start, 'YYYYMM'),

    sr.rep_id,

    month_start::DATE,

    sr.team,

    sr.monthly_quota_default,

    sr.monthly_quota_default * 3,

    month_start,

    NOW()

FROM raw_crm.sales_reps sr

CROSS JOIN generate_series(
    TIMESTAMPTZ '2025-09-01 00:00:00+00',
    TIMESTAMPTZ '2026-08-01 00:00:00+00',
    INTERVAL '1 month'
) AS months(month_start)

ON CONFLICT (target_id)
DO UPDATE SET
    revenue_target = EXCLUDED.revenue_target,
    pipeline_target = EXCLUDED.pipeline_target,
    source_updated_at = NOW();


-- ============================================================
-- 4. ACCOUNTS
-- 150 simulated B2B organizations
-- Some intentionally lack industry for data-quality testing.
-- ============================================================

WITH generated_accounts AS (

    SELECT
        i,

        ARRAY[
            'Northstar',
            'BrightBridge',
            'Vertex',
            'Summit',
            'ClearPath',
            'Nova',
            'BluePeak',
            'Evergreen',
            'Horizon',
            'Atlas'
        ] AS prefixes,

        ARRAY[
            'Analytics',
            'Systems',
            'Health',
            'Logistics',
            'Finance',
            'Consulting',
            'Labs',
            'Software',
            'Networks',
            'Solutions'
        ] AS suffixes,

        ARRAY[
            'Technology',
            'Financial Services',
            'Healthcare',
            'Professional Services',
            'Logistics',
            'E-Commerce'
        ] AS industries

    FROM generate_series(1,150) AS g(i)
)

INSERT INTO raw_crm.accounts (
    account_id,
    account_name,
    industry,
    segment,
    employee_band,
    annual_revenue,
    country,
    city,
    owner_rep_id,
    account_status,
    source_created_at,
    source_updated_at
)

SELECT

    'ACC' || LPAD(i::TEXT,4,'0'),

    prefixes[((i - 1) % 10) + 1]
        || ' '
        || suffixes[((i * 3 - 1) % 10) + 1]
        || ' '
        || LPAD(i::TEXT,3,'0'),

    CASE
        WHEN i % 17 = 0
            THEN NULL
        ELSE industries[((i - 1) % 6) + 1]
    END,

    CASE
        WHEN i % 3 = 0
            THEN 'Mid-Market'
        ELSE 'SMB'
    END,

    CASE
        WHEN i % 3 = 0
            THEN '201-500'
        WHEN i % 2 = 0
            THEN '51-200'
        ELSE '11-50'
    END,

    500000 + (i * 125000),

    CASE ((i - 1) % 5)
        WHEN 0 THEN 'United States'
        WHEN 1 THEN 'United Kingdom'
        WHEN 2 THEN 'Nigeria'
        WHEN 3 THEN 'Canada'
        ELSE 'Germany'
    END,

    CASE ((i - 1) % 5)
        WHEN 0 THEN 'Austin'
        WHEN 1 THEN 'London'
        WHEN 2 THEN 'Lagos'
        WHEN 3 THEN 'Toronto'
        ELSE 'Berlin'
    END,

    'SR' || LPAD((((i - 1) % 6) + 1)::TEXT,3,'0'),

    CASE
        WHEN i % 37 = 0
            THEN 'Inactive'
        ELSE 'Active'
    END,

    TIMESTAMPTZ '2025-09-01 09:00:00+00'
        + ((i * 2) % 330) * INTERVAL '1 day',

    TIMESTAMPTZ '2026-08-30 09:00:00+00'
        - (i % 30) * INTERVAL '1 day'

FROM generated_accounts

ON CONFLICT (account_id)
DO UPDATE SET
    account_name = EXCLUDED.account_name,
    industry = EXCLUDED.industry,
    segment = EXCLUDED.segment,
    employee_band = EXCLUDED.employee_band,
    annual_revenue = EXCLUDED.annual_revenue,
    country = EXCLUDED.country,
    city = EXCLUDED.city,
    owner_rep_id = EXCLUDED.owner_rep_id,
    account_status = EXCLUDED.account_status,
    source_updated_at = EXCLUDED.source_updated_at;


-- ============================================================
-- 5. CONTACTS
-- 500 CRM contacts
--
-- Controlled imperfections:
--   - occasional duplicate email
--   - occasional missing phone
--   - occasional missing job title
-- ============================================================

INSERT INTO raw_crm.contacts (
    contact_id,
    account_id,
    first_name,
    last_name,
    email,
    phone,
    job_title,
    lifecycle_stage,
    contact_status,
    owner_rep_id,
    source_created_at,
    source_updated_at
)

SELECT

    'CON' || LPAD(i::TEXT,4,'0'),

    a.account_id,

    (ARRAY[
        'Alex',
        'Jordan',
        'Taylor',
        'Morgan',
        'Casey',
        'Jamie',
        'Riley',
        'Cameron',
        'Avery',
        'Parker'
    ])[((i - 1) % 10) + 1],

    (ARRAY[
        'Adams',
        'Bennett',
        'Clark',
        'Davis',
        'Evans',
        'Foster',
        'Green',
        'Harris',
        'Irwin',
        'Johnson'
    ])[((i * 3 - 1) % 10) + 1],

    CASE
        WHEN i % 83 = 0
            THEN 'contact'
                 || LPAD((i - 1)::TEXT,4,'0')
                 || '@example.invalid'
        ELSE 'contact'
                 || LPAD(i::TEXT,4,'0')
                 || '@example.invalid'
    END,

    CASE
        WHEN i % 29 = 0
            THEN NULL
        ELSE '+1-555-'
             || LPAD((1000 + i)::TEXT,4,'0')
    END,

    CASE
        WHEN i % 31 = 0
            THEN NULL
        ELSE
            (ARRAY[
                'Operations Manager',
                'Revenue Operations Manager',
                'Sales Director',
                'Finance Manager',
                'COO',
                'Head of Sales'
            ])[((i - 1) % 6) + 1]
    END,

    CASE
        WHEN i % 7 = 0 THEN 'Customer'
        WHEN i % 5 = 0 THEN 'Opportunity'
        WHEN i % 3 = 0 THEN 'SQL'
        ELSE 'MQL'
    END,

    'Active',

    a.owner_rep_id,

    a.source_created_at + INTERVAL '2 days',

    a.source_updated_at

FROM generate_series(1,500) AS g(i)

JOIN raw_crm.accounts a
    ON a.account_id =
       'ACC' ||
       LPAD((((i - 1) % 150) + 1)::TEXT,4,'0')

ON CONFLICT (contact_id)
DO UPDATE SET
    account_id = EXCLUDED.account_id,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    job_title = EXCLUDED.job_title,
    lifecycle_stage = EXCLUDED.lifecycle_stage,
    owner_rep_id = EXCLUDED.owner_rep_id,
    source_updated_at = EXCLUDED.source_updated_at;
