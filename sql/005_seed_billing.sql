-- ============================================================
-- Lumora Cloud
-- Stage 3C: Billing Simulation
--
-- Purpose:
-- Convert Closed Won CRM deals into realistic invoices and
-- payments while preserving the distinction between:
--
--   Sales bookings
--   Invoiced value
--   Cash collected
-- ============================================================


-- ============================================================
-- 1. INVOICES
--
-- Closed Won deals are ranked deterministically.
--
-- Every 20th won deal:
--   no invoice yet
--
-- Every 10th invoiced deal:
--   overdue / unpaid
--
-- Every 6th invoiced deal:
--   partially paid
--
-- Remaining invoices:
--   fully paid
-- ============================================================

WITH won_deals AS (

    SELECT
        d.*,

        ROW_NUMBER() OVER (
            ORDER BY d.deal_id
        ) AS won_rn

    FROM raw_crm.deals d

    WHERE d.outcome = 'Closed Won'
),

invoice_source AS (

    SELECT *
    FROM won_deals
    WHERE won_rn % 20 <> 0
)

INSERT INTO raw_billing.invoices (
    invoice_id,
    account_id,
    deal_id,

    invoice_number,
    invoice_date,
    due_date,

    currency,
    invoice_amount,
    paid_amount,
    outstanding_amount,

    invoice_status,

    source_created_at,
    source_updated_at
)

SELECT

    'INV' || LPAD(won_rn::TEXT,5,'0'),

    account_id,

    deal_id,

    'LUM-' || TO_CHAR(closed_at, 'YYYY')
        || '-'
        || LPAD(won_rn::TEXT,5,'0'),

    closed_at::DATE + 3,

    closed_at::DATE + 33,

    'USD',

    amount,

    CASE
        WHEN won_rn % 10 = 0
            THEN 0

        WHEN won_rn % 6 = 0
            THEN ROUND(amount * 0.50, 2)

        ELSE amount
    END,

    CASE
        WHEN won_rn % 10 = 0
            THEN amount

        WHEN won_rn % 6 = 0
            THEN ROUND(amount * 0.50, 2)

        ELSE 0
    END,

    CASE
        WHEN won_rn % 10 = 0
            THEN 'Overdue'

        WHEN won_rn % 6 = 0
            THEN 'Partially Paid'

        ELSE 'Paid'
    END,

    closed_at + INTERVAL '3 days',

    NOW()

FROM invoice_source

ON CONFLICT (invoice_id)
DO UPDATE SET

    account_id =
        EXCLUDED.account_id,

    deal_id =
        EXCLUDED.deal_id,

    invoice_number =
        EXCLUDED.invoice_number,

    invoice_date =
        EXCLUDED.invoice_date,

    due_date =
        EXCLUDED.due_date,

    currency =
        EXCLUDED.currency,

    invoice_amount =
        EXCLUDED.invoice_amount,

    paid_amount =
        EXCLUDED.paid_amount,

    outstanding_amount =
        EXCLUDED.outstanding_amount,

    invoice_status =
        EXCLUDED.invoice_status,

    source_updated_at =
        NOW();


-- ============================================================
-- 2. PAYMENTS
--
-- Paid invoices receive full payment.
-- Partially paid invoices receive one partial payment.
-- Overdue invoices intentionally receive no successful payment.
-- ============================================================

INSERT INTO raw_billing.payments (
    payment_id,
    invoice_id,
    account_id,
    deal_id,

    payment_date,

    currency,
    payment_amount,

    payment_method,
    payment_status,

    source_created_at,
    source_updated_at
)

SELECT

    'PAY-' || invoice_id,

    invoice_id,

    account_id,

    deal_id,

    invoice_date::TIMESTAMPTZ
        + INTERVAL '5 days',

    currency,

    paid_amount,

    CASE
        WHEN RIGHT(invoice_id, 1)::INTEGER % 3 = 0
            THEN 'Bank Transfer'

        WHEN RIGHT(invoice_id, 1)::INTEGER % 3 = 1
            THEN 'Card'

        ELSE 'ACH'
    END,

    'Succeeded',

    invoice_date::TIMESTAMPTZ
        + INTERVAL '5 days',

    NOW()

FROM raw_billing.invoices

WHERE paid_amount > 0

ON CONFLICT (payment_id)
DO UPDATE SET

    invoice_id =
        EXCLUDED.invoice_id,

    account_id =
        EXCLUDED.account_id,

    deal_id =
        EXCLUDED.deal_id,

    payment_date =
        EXCLUDED.payment_date,

    payment_amount =
        EXCLUDED.payment_amount,

    payment_method =
        EXCLUDED.payment_method,

    payment_status =
        EXCLUDED.payment_status,

    source_updated_at =
        NOW();
