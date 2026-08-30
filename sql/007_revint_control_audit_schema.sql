--
-- PostgreSQL database dump
--

\restrict S60ujLwY7YxxoOexBiw0bFbmGIIUEiSsjKg5Lyb0VaQyP1qra98adAAFTecoscs

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
-- Name: audit; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA audit;


--
-- Name: control; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA control;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: dead_letter; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.dead_letter (
    dead_letter_id bigint NOT NULL,
    incident_id character varying(150) NOT NULL,
    source_error_event_id bigint NOT NULL,
    request_id character varying(150),
    correlation_id character varying(150),
    workflow_name character varying(200) NOT NULL,
    workflow_id character varying(100),
    execution_id character varying(100),
    node_name character varying(200),
    source_channel character varying(50),
    environment character varying(50) NOT NULL,
    error_type character varying(100) NOT NULL,
    error_message text NOT NULL,
    http_status integer,
    severity character varying(20) NOT NULL,
    retryable boolean DEFAULT false NOT NULL,
    attempt integer NOT NULL,
    recovery_strategy character varying(100) NOT NULL,
    escalation_reason character varying(100) NOT NULL,
    alert_channel character varying(50),
    alert_status character varying(50) DEFAULT 'not_attempted'::character varying NOT NULL,
    alert_reference jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload_reference jsonb DEFAULT '{}'::jsonb NOT NULL,
    dead_letter_status character varying(50) DEFAULT 'open'::character varying NOT NULL,
    dead_lettered_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone,
    resolution_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_dead_letter_alert_reference CHECK ((jsonb_typeof(alert_reference) = 'object'::text)),
    CONSTRAINT chk_dead_letter_alert_status CHECK (((alert_status)::text = ANY ((ARRAY['not_attempted'::character varying, 'sent'::character varying, 'failed'::character varying])::text[]))),
    CONSTRAINT chk_dead_letter_attempt CHECK ((attempt >= 1)),
    CONSTRAINT chk_dead_letter_environment CHECK (((environment)::text = ANY ((ARRAY['development'::character varying, 'staging'::character varying, 'production'::character varying])::text[]))),
    CONSTRAINT chk_dead_letter_payload_reference CHECK ((jsonb_typeof(payload_reference) = 'object'::text)),
    CONSTRAINT chk_dead_letter_severity CHECK (((severity)::text = ANY ((ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'critical'::character varying])::text[]))),
    CONSTRAINT chk_dead_letter_status CHECK (((dead_letter_status)::text = ANY ((ARRAY['open'::character varying, 'investigating'::character varying, 'resolved'::character varying, 'replayed'::character varying])::text[])))
);


--
-- Name: dead_letter_dead_letter_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.dead_letter_dead_letter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dead_letter_dead_letter_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.dead_letter_dead_letter_id_seq OWNED BY audit.dead_letter.dead_letter_id;


--
-- Name: error_events; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.error_events (
    error_event_id bigint NOT NULL,
    incident_id character varying(150) NOT NULL,
    idempotency_key character varying(300) NOT NULL,
    request_id character varying(150),
    correlation_id character varying(150),
    event_type character varying(100) DEFAULT 'workflow_error'::character varying NOT NULL,
    event_status character varying(50) DEFAULT 'recorded'::character varying NOT NULL,
    workflow_stage character varying(100) DEFAULT 'error_logged'::character varying NOT NULL,
    workflow_name character varying(200) NOT NULL,
    workflow_id character varying(100),
    execution_id character varying(100),
    retry_of_execution_id character varying(100),
    node_name character varying(200),
    operation character varying(100),
    channel character varying(50),
    environment character varying(50) NOT NULL,
    error_type character varying(100) NOT NULL,
    error_name character varying(150),
    error_code character varying(150),
    error_message text NOT NULL,
    http_status integer,
    attempt integer DEFAULT 1 NOT NULL,
    severity character varying(20) NOT NULL,
    retryable boolean DEFAULT false NOT NULL,
    recovery_strategy character varying(100) NOT NULL,
    incident_status character varying(50) DEFAULT 'opened'::character varying NOT NULL,
    classification_reason text,
    error_context jsonb DEFAULT '{}'::jsonb NOT NULL,
    classification_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload_reference jsonb DEFAULT '{}'::jsonb NOT NULL,
    event_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    event_version character varying(20) DEFAULT '1.0'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_error_events_attempt CHECK ((attempt >= 1)),
    CONSTRAINT chk_error_events_classification_data CHECK ((jsonb_typeof(classification_data) = 'object'::text)),
    CONSTRAINT chk_error_events_environment CHECK (((environment)::text = ANY ((ARRAY['development'::character varying, 'staging'::character varying, 'production'::character varying])::text[]))),
    CONSTRAINT chk_error_events_error_context CHECK ((jsonb_typeof(error_context) = 'object'::text)),
    CONSTRAINT chk_error_events_http_status CHECK (((http_status IS NULL) OR ((http_status >= 100) AND (http_status <= 599)))),
    CONSTRAINT chk_error_events_payload_reference CHECK ((jsonb_typeof(payload_reference) = 'object'::text)),
    CONSTRAINT chk_error_events_severity CHECK (((severity)::text = ANY ((ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'critical'::character varying])::text[])))
);


--
-- Name: error_events_error_event_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.error_events_error_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: error_events_error_event_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.error_events_error_event_id_seq OWNED BY audit.error_events.error_event_id;


--
-- Name: report_events; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.report_events (
    event_id bigint NOT NULL,
    request_id character varying(150) NOT NULL,
    correlation_id character varying(150) NOT NULL,
    event_type character varying(100) NOT NULL,
    event_status character varying(50) DEFAULT 'recorded'::character varying NOT NULL,
    workflow_stage character varying(100),
    workflow_name character varying(200),
    workflow_id character varying(100),
    execution_id character varying(100),
    node_name character varying(200),
    channel character varying(50),
    environment character varying(50) NOT NULL,
    actor_type character varying(50) DEFAULT 'system'::character varying NOT NULL,
    actor_id character varying(150),
    event_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    event_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    event_version character varying(20) DEFAULT '1.0'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_report_events_environment CHECK (((environment)::text = ANY ((ARRAY['development'::character varying, 'staging'::character varying, 'production'::character varying])::text[]))),
    CONSTRAINT chk_report_events_event_data CHECK ((jsonb_typeof(event_data) = 'object'::text))
);


--
-- Name: report_events_event_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.report_events_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_events_event_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.report_events_event_id_seq OWNED BY audit.report_events.event_id;


--
-- Name: metric_catalogue; Type: TABLE; Schema: control; Owner: -
--

CREATE TABLE control.metric_catalogue (
    metric_id character varying(20) NOT NULL,
    metric_key character varying(100) NOT NULL,
    metric_name character varying(150) NOT NULL,
    description text,
    business_definition text NOT NULL,
    query_key character varying(100) NOT NULL,
    allowed_dimensions jsonb DEFAULT '[]'::jsonb NOT NULL,
    allowed_filters jsonb DEFAULT '[]'::jsonb NOT NULL,
    default_date_field character varying(100),
    default_date_range character varying(50),
    default_visualization character varying(50) DEFAULT 'kpi'::character varying NOT NULL,
    maximum_date_range character varying(50),
    maximum_rows integer DEFAULT 500 NOT NULL,
    requires_comparison boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    version character varying(20) DEFAULT '1.0'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_metric_catalogue_dimensions CHECK ((jsonb_typeof(allowed_dimensions) = 'array'::text)),
    CONSTRAINT chk_metric_catalogue_filters CHECK ((jsonb_typeof(allowed_filters) = 'array'::text)),
    CONSTRAINT chk_metric_catalogue_maximum_rows CHECK (((maximum_rows > 0) AND (maximum_rows <= 10000))),
    CONSTRAINT chk_metric_catalogue_visualization CHECK (((default_visualization)::text = ANY ((ARRAY['kpi'::character varying, 'table'::character varying, 'bar_chart'::character varying, 'line_chart'::character varying, 'pie_chart'::character varying, 'none'::character varying])::text[])))
);


--
-- Name: query_templates; Type: TABLE; Schema: control; Owner: -
--

CREATE TABLE control.query_templates (
    query_key text NOT NULL,
    query_name text NOT NULL,
    description text NOT NULL,
    sql_template text NOT NULL,
    allowed_parameters jsonb DEFAULT '[]'::jsonb NOT NULL,
    result_type text NOT NULL,
    maximum_rows integer DEFAULT 500 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    version text DEFAULT '1.0'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT query_templates_maximum_rows_check CHECK (((maximum_rows >= 1) AND (maximum_rows <= 10000))),
    CONSTRAINT query_templates_parameters_array CHECK ((jsonb_typeof(allowed_parameters) = 'array'::text)),
    CONSTRAINT query_templates_result_type CHECK ((result_type = ANY (ARRAY['scalar'::text, 'breakdown'::text, 'trend'::text, 'comparison'::text, 'data_quality'::text])))
);


--
-- Name: report_requests; Type: TABLE; Schema: control; Owner: -
--

CREATE TABLE control.report_requests (
    request_id character varying(150) NOT NULL,
    correlation_id character varying(150) NOT NULL,
    channel character varying(50) NOT NULL,
    requester_id character varying(100),
    requester_name character varying(150),
    question text,
    source character varying(100),
    received_at timestamp with time zone NOT NULL,
    environment character varying(50) NOT NULL,
    request_status character varying(50) DEFAULT 'received'::character varying NOT NULL,
    validation_status character varying(20),
    validation_errors jsonb DEFAULT '[]'::jsonb NOT NULL,
    validation_warnings jsonb DEFAULT '[]'::jsonb NOT NULL,
    workflow_stage character varying(100) NOT NULL,
    processing_started_at timestamp with time zone NOT NULL,
    retry_count integer DEFAULT 0 NOT NULL,
    schema_version character varying(20) DEFAULT '1.0'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_report_requests_environment CHECK (((environment)::text = ANY ((ARRAY['development'::character varying, 'staging'::character varying, 'production'::character varying])::text[]))),
    CONSTRAINT chk_report_requests_retry_count CHECK ((retry_count >= 0)),
    CONSTRAINT chk_report_requests_status CHECK (((request_status)::text = ANY ((ARRAY['received'::character varying, 'validated'::character varying, 'processing'::character varying, 'clarification_required'::character varying, 'rejected'::character varying, 'completed'::character varying, 'failed'::character varying])::text[]))),
    CONSTRAINT chk_report_requests_validation_errors CHECK ((jsonb_typeof(validation_errors) = 'array'::text)),
    CONSTRAINT chk_report_requests_validation_status CHECK (((validation_status IS NULL) OR ((validation_status)::text = ANY ((ARRAY['valid'::character varying, 'rejected'::character varying])::text[])))),
    CONSTRAINT chk_report_requests_validation_warnings CHECK ((jsonb_typeof(validation_warnings) = 'array'::text))
);


--
-- Name: dead_letter dead_letter_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.dead_letter ALTER COLUMN dead_letter_id SET DEFAULT nextval('audit.dead_letter_dead_letter_id_seq'::regclass);


--
-- Name: error_events error_event_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.error_events ALTER COLUMN error_event_id SET DEFAULT nextval('audit.error_events_error_event_id_seq'::regclass);


--
-- Name: report_events event_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.report_events ALTER COLUMN event_id SET DEFAULT nextval('audit.report_events_event_id_seq'::regclass);


--
-- Name: dead_letter dead_letter_incident_id_key; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.dead_letter
    ADD CONSTRAINT dead_letter_incident_id_key UNIQUE (incident_id);


--
-- Name: dead_letter dead_letter_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.dead_letter
    ADD CONSTRAINT dead_letter_pkey PRIMARY KEY (dead_letter_id);


--
-- Name: error_events error_events_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.error_events
    ADD CONSTRAINT error_events_pkey PRIMARY KEY (error_event_id);


--
-- Name: report_events report_events_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.report_events
    ADD CONSTRAINT report_events_pkey PRIMARY KEY (event_id);


--
-- Name: error_events uq_error_events_idempotency; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.error_events
    ADD CONSTRAINT uq_error_events_idempotency UNIQUE (idempotency_key);


--
-- Name: metric_catalogue metric_catalogue_metric_key_key; Type: CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.metric_catalogue
    ADD CONSTRAINT metric_catalogue_metric_key_key UNIQUE (metric_key);


--
-- Name: metric_catalogue metric_catalogue_pkey; Type: CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.metric_catalogue
    ADD CONSTRAINT metric_catalogue_pkey PRIMARY KEY (metric_id);


--
-- Name: query_templates query_templates_pkey; Type: CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.query_templates
    ADD CONSTRAINT query_templates_pkey PRIMARY KEY (query_key);


--
-- Name: report_requests report_requests_pkey; Type: CONSTRAINT; Schema: control; Owner: -
--

ALTER TABLE ONLY control.report_requests
    ADD CONSTRAINT report_requests_pkey PRIMARY KEY (request_id);


--
-- Name: idx_dead_letter_created; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_dead_letter_created ON audit.dead_letter USING btree (dead_lettered_at DESC);


--
-- Name: idx_dead_letter_execution; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_dead_letter_execution ON audit.dead_letter USING btree (execution_id);


--
-- Name: idx_dead_letter_request; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_dead_letter_request ON audit.dead_letter USING btree (request_id);


--
-- Name: idx_dead_letter_status; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_dead_letter_status ON audit.dead_letter USING btree (dead_letter_status);


--
-- Name: idx_error_events_correlation; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_error_events_correlation ON audit.error_events USING btree (correlation_id);


--
-- Name: idx_error_events_execution; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_error_events_execution ON audit.error_events USING btree (execution_id);


--
-- Name: idx_error_events_incident; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_error_events_incident ON audit.error_events USING btree (incident_id);


--
-- Name: idx_error_events_request; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_error_events_request ON audit.error_events USING btree (request_id);


--
-- Name: idx_error_events_retryable; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_error_events_retryable ON audit.error_events USING btree (retryable, severity) WHERE (retryable = true);


--
-- Name: idx_error_events_timestamp; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_error_events_timestamp ON audit.error_events USING btree (event_timestamp DESC);


--
-- Name: idx_error_events_type; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_error_events_type ON audit.error_events USING btree (error_type);


--
-- Name: idx_report_events_correlation_time; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_report_events_correlation_time ON audit.report_events USING btree (correlation_id, event_timestamp, event_id) WHERE (correlation_id IS NOT NULL);


--
-- Name: idx_report_events_identity_anchor; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_report_events_identity_anchor ON audit.report_events USING btree (execution_id, event_id DESC) WHERE ((execution_id IS NOT NULL) AND ((event_type)::text = ANY ((ARRAY['request_received'::character varying, 'request_rejected'::character varying])::text[])));


--
-- Name: idx_report_events_request_time; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX idx_report_events_request_time ON audit.report_events USING btree (request_id, event_timestamp, event_id);


--
-- Name: dead_letter fk_dead_letter_error_event; Type: FK CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.dead_letter
    ADD CONSTRAINT fk_dead_letter_error_event FOREIGN KEY (source_error_event_id) REFERENCES audit.error_events(error_event_id);


--
-- Name: report_events fk_report_events_request; Type: FK CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.report_events
    ADD CONSTRAINT fk_report_events_request FOREIGN KEY (request_id) REFERENCES control.report_requests(request_id);


--
-- PostgreSQL database dump complete
--

\unrestrict S60ujLwY7YxxoOexBiw0bFbmGIIUEiSsjKg5Lyb0VaQyP1qra98adAAFTecoscs

