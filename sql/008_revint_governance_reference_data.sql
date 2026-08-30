--
-- PostgreSQL database dump
--

\restrict s2gq6EjHjOmDfq2QfPg0sArIkR1eiuwa55q7EPIb3rdtsLVdUL80vghEFI0O9E0

-- Dumped from database version 16.15
-- Dumped by pg_dump version 16.15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: metric_catalogue; Type: TABLE DATA; Schema: control; Owner: -
--

INSERT INTO control.metric_catalogue (metric_id, metric_key, metric_name, description, business_definition, query_key, allowed_dimensions, allowed_filters, default_date_field, default_date_range, default_visualization, maximum_date_range, maximum_rows, requires_comparison, is_active, version, created_at, updated_at) VALUES ('REV001', 'closed_won_revenue', 'Closed Won Revenue', 'Total revenue from deals successfully closed as won within the requested reporting period.', 'Sum of deal amount for deals whose outcome is Closed Won within the approved reporting date range.', 'QRY_CLOSED_WON_REVENUE', '["sales_rep", "lead_source", "industry", "account"]', '["sales_rep", "lead_source", "industry", "account"]', 'closed_at', 'this_month', 'kpi', 'this_year', 500, false, true, '1.0', '2026-08-23 18:31:18.088353+00', '2026-08-23 18:31:18.088353+00');
INSERT INTO control.metric_catalogue (metric_id, metric_key, metric_name, description, business_definition, query_key, allowed_dimensions, allowed_filters, default_date_field, default_date_range, default_visualization, maximum_date_range, maximum_rows, requires_comparison, is_active, version, created_at, updated_at) VALUES ('REV002', 'open_pipeline', 'Open Pipeline', 'Total value of currently open sales opportunities expected to close within the requested reporting period.', 'Sum of deal amount for deals that are still open and whose expected close date falls within the approved reporting date range.', 'QRY_OPEN_PIPELINE', '["sales_rep", "lead_source", "industry", "account", "stage"]', '["sales_rep", "lead_source", "industry", "account", "stage"]', 'expected_close_date', 'this_quarter', 'kpi', 'this_year', 500, false, true, '1.0', '2026-08-23 19:16:06.98249+00', '2026-08-23 19:16:06.98249+00');
INSERT INTO control.metric_catalogue (metric_id, metric_key, metric_name, description, business_definition, query_key, allowed_dimensions, allowed_filters, default_date_field, default_date_range, default_visualization, maximum_date_range, maximum_rows, requires_comparison, is_active, version, created_at, updated_at) VALUES ('REV003', 'win_rate', 'Win Rate', 'Percentage of closed sales opportunities that were won within the requested reporting period.', 'Closed Won Deals divided by the total of Closed Won Deals plus Closed Lost Deals, multiplied by 100.', 'QRY_WIN_RATE', '["sales_rep", "lead_source", "industry", "account"]', '["sales_rep", "lead_source", "industry", "account"]', 'closed_at', 'this_quarter', 'kpi', 'this_year', 500, false, true, '1.0', '2026-08-23 19:20:00.09738+00', '2026-08-23 19:20:00.09738+00');
INSERT INTO control.metric_catalogue (metric_id, metric_key, metric_name, description, business_definition, query_key, allowed_dimensions, allowed_filters, default_date_field, default_date_range, default_visualization, maximum_date_range, maximum_rows, requires_comparison, is_active, version, created_at, updated_at) VALUES ('REV004', 'average_deal_size', 'Average Deal Size', 'Average monetary value of successfully closed won deals within the requested reporting period.', 'Closed Won Revenue divided by the number of Closed Won Deals within the approved reporting date range.', 'QRY_AVERAGE_DEAL_SIZE', '["sales_rep", "lead_source", "industry", "account"]', '["sales_rep", "lead_source", "industry", "account"]', 'closed_at', 'this_quarter', 'kpi', 'this_year', 500, false, true, '1.0', '2026-08-23 19:22:58.89597+00', '2026-08-23 19:22:58.89597+00');
INSERT INTO control.metric_catalogue (metric_id, metric_key, metric_name, description, business_definition, query_key, allowed_dimensions, allowed_filters, default_date_field, default_date_range, default_visualization, maximum_date_range, maximum_rows, requires_comparison, is_active, version, created_at, updated_at) VALUES ('REV005', 'sla_compliance', 'SLA Compliance', 'Percentage of eligible reporting records that received their first response within the required SLA deadline.', 'Number of eligible records where first_response_at is on or before sla_due_at divided by the total number of eligible records whose SLA deadline falls within the approved reporting date range, multiplied by 100.', 'QRY_SLA_COMPLIANCE', '["sales_rep", "lead_source", "industry", "account"]', '["sales_rep", "lead_source", "industry", "account"]', 'sla_due_at', 'this_month', 'kpi', 'this_year', 500, false, true, '1.0', '2026-08-23 19:27:00.907074+00', '2026-08-23 19:27:00.907074+00');
INSERT INTO control.metric_catalogue (metric_id, metric_key, metric_name, description, business_definition, query_key, allowed_dimensions, allowed_filters, default_date_field, default_date_range, default_visualization, maximum_date_range, maximum_rows, requires_comparison, is_active, version, created_at, updated_at) VALUES ('REV006', 'stale_deals', 'Stale Deals', 'Count of currently open sales opportunities that have had no recorded activity for at least 14 days.', 'Count of open deals where COALESCE(last_activity_at, created_at) is at least 14 days earlier than the reporting as-of timestamp.', 'QRY_STALE_DEALS', '["sales_rep", "lead_source", "industry", "account", "stage"]', '["sales_rep", "lead_source", "industry", "account", "stage"]', NULL, 'today', 'kpi', 'today', 500, false, true, '1.0', '2026-08-23 19:30:17.931468+00', '2026-08-23 19:30:17.931468+00');
INSERT INTO control.metric_catalogue (metric_id, metric_key, metric_name, description, business_definition, query_key, allowed_dimensions, allowed_filters, default_date_field, default_date_range, default_visualization, maximum_date_range, maximum_rows, requires_comparison, is_active, version, created_at, updated_at) VALUES ('REV007', 'average_sales_cycle', 'Average Sales Cycle', 'Average number of days required to move successfully won opportunities from opportunity creation to closed won.', 'Average elapsed calendar days between opportunity_at and closed_at for Closed Won deals where both timestamps are available and closed_at falls within the approved reporting date range.', 'QRY_AVERAGE_SALES_CYCLE', '["sales_rep", "lead_source", "industry", "account"]', '["sales_rep", "lead_source", "industry", "account"]', 'closed_at', 'this_quarter', 'kpi', 'this_year', 500, false, true, '1.0', '2026-08-23 19:32:22.594598+00', '2026-08-23 19:32:22.594598+00');
INSERT INTO control.metric_catalogue (metric_id, metric_key, metric_name, description, business_definition, query_key, allowed_dimensions, allowed_filters, default_date_field, default_date_range, default_visualization, maximum_date_range, maximum_rows, requires_comparison, is_active, version, created_at, updated_at) VALUES ('REV008', 'pipeline_by_sales_rep', 'Pipeline by Sales Rep', 'Open sales pipeline value grouped by the sales representative responsible for each opportunity.', 'Sum of deal amount for open deals grouped by sales_rep where expected_close_date falls within the approved reporting date range.', 'QRY_PIPELINE_BY_SALES_REP', '["sales_rep"]', '["sales_rep", "lead_source", "industry", "account", "stage"]', 'expected_close_date', 'this_quarter', 'bar_chart', 'this_year', 500, false, true, '1.0', '2026-08-23 19:35:44.159257+00', '2026-08-23 19:35:44.159257+00');
INSERT INTO control.metric_catalogue (metric_id, metric_key, metric_name, description, business_definition, query_key, allowed_dimensions, allowed_filters, default_date_field, default_date_range, default_visualization, maximum_date_range, maximum_rows, requires_comparison, is_active, version, created_at, updated_at) VALUES ('REV009', 'revenue_by_lead_source', 'Revenue by Lead Source', 'Closed won revenue grouped by the lead source associated with each successfully won opportunity.', 'Sum of deal amount for Closed Won deals grouped by lead_source where closed_at falls within the approved reporting date range.', 'QRY_REVENUE_BY_LEAD_SOURCE', '["lead_source"]', '["sales_rep", "lead_source", "industry", "account"]', 'closed_at', 'this_quarter', 'bar_chart', 'this_year', 500, false, true, '1.0', '2026-08-23 19:41:18.497692+00', '2026-08-23 19:41:18.497692+00');
INSERT INTO control.metric_catalogue (metric_id, metric_key, metric_name, description, business_definition, query_key, allowed_dimensions, allowed_filters, default_date_field, default_date_range, default_visualization, maximum_date_range, maximum_rows, requires_comparison, is_active, version, created_at, updated_at) VALUES ('REV010', 'revenue_by_industry', 'Revenue by Industry', 'Closed won revenue grouped by the industry associated with each customer account.', 'Sum of deal amount for Closed Won deals grouped by industry where closed_at falls within the approved reporting date range.', 'QRY_REVENUE_BY_INDUSTRY', '["industry"]', '["sales_rep", "lead_source", "industry", "account"]', 'closed_at', 'this_quarter', 'bar_chart', 'this_year', 500, false, true, '1.0', '2026-08-23 19:44:08.384613+00', '2026-08-23 19:44:08.384613+00');
INSERT INTO control.metric_catalogue (metric_id, metric_key, metric_name, description, business_definition, query_key, allowed_dimensions, allowed_filters, default_date_field, default_date_range, default_visualization, maximum_date_range, maximum_rows, requires_comparison, is_active, version, created_at, updated_at) VALUES ('REV011', 'weighted_pipeline', 'Weighted Pipeline', 'Probability-adjusted value of currently open sales opportunities expected to close within the requested reporting period.', 'Sum of deal amount multiplied by probability divided by 100 for open deals with a valid probability between 0 and 100 whose expected_close_date falls within the approved reporting date range.', 'QRY_WEIGHTED_PIPELINE', '["sales_rep", "lead_source", "industry", "account", "stage"]', '["sales_rep", "lead_source", "industry", "account", "stage"]', 'expected_close_date', 'this_quarter', 'kpi', 'this_year', 500, false, true, '1.0', '2026-08-23 19:49:48.460686+00', '2026-08-23 19:49:48.460686+00');
INSERT INTO control.metric_catalogue (metric_id, metric_key, metric_name, description, business_definition, query_key, allowed_dimensions, allowed_filters, default_date_field, default_date_range, default_visualization, maximum_date_range, maximum_rows, requires_comparison, is_active, version, created_at, updated_at) VALUES ('REV012', 'crm_data_quality', 'CRM Data Quality', 'Percentage of deal records that satisfy the required CRM completeness and validity rules.', 'Number of deal records passing all required data-quality checks divided by total deal records, multiplied by 100. Required checks include populated deal name, account, sales rep, lead source and stage, a non-negative amount, valid probability and expected close date for open deals, and a closed timestamp with a recognized closed outcome for closed deals.', 'QRY_CRM_DATA_QUALITY', '["sales_rep", "lead_source", "industry", "account", "stage"]', '["sales_rep", "lead_source", "industry", "account", "stage"]', NULL, 'today', 'kpi', 'today', 500, false, true, '1.0', '2026-08-23 19:52:41.692054+00', '2026-08-23 19:52:41.692054+00');


--
-- Data for Name: query_templates; Type: TABLE DATA; Schema: control; Owner: -
--

INSERT INTO control.query_templates (query_key, query_name, description, sql_template, allowed_parameters, result_type, maximum_rows, is_active, version, created_at, updated_at) VALUES ('QRY_CLOSED_WON_REVENUE', 'Closed Won Revenue', 'Returns total Closed Won revenue and won deal count for an approved reporting period.', '
SELECT
    COALESCE(SUM(fd.amount), 0)::NUMERIC(14,2) AS closed_won_revenue,
    COUNT(*)::INTEGER AS closed_won_deal_count
FROM reporting.fact_deals fd
WHERE fd.outcome = ''Closed Won''
  AND fd.closed_at >= $1::TIMESTAMPTZ
  AND fd.closed_at <  $2::TIMESTAMPTZ;
', '["start_at", "end_at"]', 'scalar', 1, true, '1.0', '2026-08-23 22:22:39.159599+00', '2026-08-23 22:22:39.159599+00');
INSERT INTO control.query_templates (query_key, query_name, description, sql_template, allowed_parameters, result_type, maximum_rows, is_active, version, created_at, updated_at) VALUES ('QRY_PIPELINE_BY_SALES_REP', 'Pipeline by Sales Rep', 'Returns open pipeline value grouped by sales representative for deals whose expected close date falls within the approved reporting period.', '
SELECT
    COALESCE(dsr.sales_rep_name, ''Unassigned'') AS sales_rep,
    SUM(fd.amount)::NUMERIC(14,2) AS pipeline_value,
    COUNT(*)::INTEGER AS deal_count
FROM reporting.fact_deals fd
LEFT JOIN reporting.dim_sales_rep dsr
    ON dsr.sales_rep_id = fd.sales_rep_id
WHERE fd.outcome IS NULL
  AND fd.expected_close_date >= $1::TIMESTAMPTZ
  AND fd.expected_close_date <  $2::TIMESTAMPTZ
GROUP BY
    COALESCE(dsr.sales_rep_name, ''Unassigned'')
ORDER BY
    pipeline_value DESC;
', '["start_at", "end_at"]', 'breakdown', 500, true, '1.0', '2026-08-25 18:30:38.342515+00', '2026-08-25 18:30:38.342515+00');


--
-- PostgreSQL database dump complete
--

\unrestrict s2gq6EjHjOmDfq2QfPg0sArIkR1eiuwa55q7EPIb3rdtsLVdUL80vghEFI0O9E0

