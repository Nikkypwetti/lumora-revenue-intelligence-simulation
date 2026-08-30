-- ============================================================
-- Lumora Cloud
-- Stage 4D: Runtime Database Security Roles
--
-- No passwords are stored in this file.
-- Passwords are generated separately and stored outside Git.
-- ============================================================


-- ============================================================
-- 1. CREATE LOGIN ROLES IF THEY DO NOT EXIST
-- ============================================================

DO $role$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = 'lumora_reporting_ro'
    ) THEN

        CREATE ROLE lumora_reporting_ro
            LOGIN
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE
            NOREPLICATION
            NOBYPASSRLS;

    END IF;


    IF NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = 'lumora_control_rw'
    ) THEN

        CREATE ROLE lumora_control_rw
            LOGIN
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE
            NOREPLICATION
            NOBYPASSRLS;

    END IF;

END
$role$;


-- ============================================================
-- 2. ENFORCE SAFE ROLE ATTRIBUTES
-- ============================================================

ALTER ROLE lumora_reporting_ro
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION
    NOBYPASSRLS;

ALTER ROLE lumora_control_rw
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION
    NOBYPASSRLS;


-- ============================================================
-- 3. DATABASE ACCESS
-- ============================================================

REVOKE ALL PRIVILEGES
ON DATABASE lumora_revenue_simulation
FROM lumora_reporting_ro;

REVOKE ALL PRIVILEGES
ON DATABASE lumora_revenue_simulation
FROM lumora_control_rw;

GRANT CONNECT
ON DATABASE lumora_revenue_simulation
TO lumora_reporting_ro;

GRANT CONNECT
ON DATABASE lumora_revenue_simulation
TO lumora_control_rw;


-- Prevent ordinary users from creating objects in public.
REVOKE CREATE
ON SCHEMA public
FROM PUBLIC;


-- ============================================================
-- 4. REPORTING READ-ONLY ROLE
-- ============================================================

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA reporting
FROM lumora_reporting_ro;

GRANT USAGE
ON SCHEMA reporting
TO lumora_reporting_ro;

GRANT SELECT
ON ALL TABLES IN SCHEMA reporting
TO lumora_reporting_ro;


-- Explicitly remove access to every non-reporting layer.

REVOKE ALL
ON SCHEMA control, audit, quality,
          raw_crm, raw_marketing,
          raw_billing, raw_planning
FROM lumora_reporting_ro;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA control
FROM lumora_reporting_ro;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA audit
FROM lumora_reporting_ro;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA quality
FROM lumora_reporting_ro;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA raw_crm
FROM lumora_reporting_ro;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA raw_marketing
FROM lumora_reporting_ro;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA raw_billing
FROM lumora_reporting_ro;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA raw_planning
FROM lumora_reporting_ro;


-- Future reporting tables created by revint_admin
-- automatically remain readable by this role.

ALTER DEFAULT PRIVILEGES
FOR ROLE revint_admin
IN SCHEMA reporting
GRANT SELECT ON TABLES
TO lumora_reporting_ro;


-- Additional database safety boundary.

ALTER ROLE lumora_reporting_ro
IN DATABASE lumora_revenue_simulation
SET default_transaction_read_only = ON;

ALTER ROLE lumora_reporting_ro
IN DATABASE lumora_revenue_simulation
SET statement_timeout = '5s';

ALTER ROLE lumora_reporting_ro
IN DATABASE lumora_revenue_simulation
SET search_path = reporting, public;


-- ============================================================
-- 5. CONTROL / AUDIT ROLE
-- ============================================================

-- Start from zero privileges.

REVOKE ALL
ON SCHEMA reporting, quality,
          raw_crm, raw_marketing,
          raw_billing, raw_planning
FROM lumora_control_rw;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA reporting
FROM lumora_control_rw;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA quality
FROM lumora_control_rw;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA raw_crm
FROM lumora_control_rw;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA raw_marketing
FROM lumora_control_rw;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA raw_billing
FROM lumora_control_rw;

REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA raw_planning
FROM lumora_control_rw;


GRANT USAGE
ON SCHEMA control, audit
TO lumora_control_rw;


-- Governance definitions are lookup-only.

GRANT SELECT
ON control.metric_catalogue
TO lumora_control_rw;

GRANT SELECT
ON control.query_templates
TO lumora_control_rw;


-- Request lifecycle can be registered and updated.

GRANT SELECT, INSERT, UPDATE
ON control.report_requests
TO lumora_control_rw;


-- Audit event tables remain append-only to the runtime role.

GRANT SELECT, INSERT
ON audit.report_events
TO lumora_control_rw;

GRANT SELECT, INSERT
ON audit.error_events
TO lumora_control_rw;


-- Dead-letter records need lifecycle/status updates.

GRANT SELECT, INSERT, UPDATE
ON audit.dead_letter
TO lumora_control_rw;


-- BIGSERIAL / identity sequences required for inserts.

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA audit
TO lumora_control_rw;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA control
TO lumora_control_rw;


ALTER ROLE lumora_control_rw
IN DATABASE lumora_revenue_simulation
SET statement_timeout = '5s';

ALTER ROLE lumora_control_rw
IN DATABASE lumora_revenue_simulation
SET search_path = control, audit, public;
