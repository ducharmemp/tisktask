-- Dumped by pg_dump version 17.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: oban_job_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.oban_job_state AS ENUM (
    'available',
    'scheduled',
    'executing',
    'retryable',
    'completed',
    'discarded',
    'cancelled'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: github_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.github_triggers (
    id bigint NOT NULL,
    type character varying(255) NOT NULL,
    action character varying(255),
    payload jsonb NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    source_control_repository_id bigint NOT NULL
);


--
-- Name: github_triggers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.github_triggers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: github_triggers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.github_triggers_id_seq OWNED BY public.github_triggers.id;


--
-- Name: oban_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oban_jobs (
    id bigint NOT NULL,
    state public.oban_job_state DEFAULT 'available'::public.oban_job_state NOT NULL,
    queue text DEFAULT 'default'::text NOT NULL,
    worker text NOT NULL,
    args jsonb DEFAULT '{}'::jsonb NOT NULL,
    errors jsonb[] DEFAULT ARRAY[]::jsonb[] NOT NULL,
    attempt integer DEFAULT 0 NOT NULL,
    max_attempts integer DEFAULT 20 NOT NULL,
    inserted_at timestamp without time zone DEFAULT timezone('UTC'::text, now()) NOT NULL,
    scheduled_at timestamp without time zone DEFAULT timezone('UTC'::text, now()) NOT NULL,
    attempted_at timestamp without time zone,
    completed_at timestamp without time zone,
    attempted_by text[],
    discarded_at timestamp without time zone,
    priority integer DEFAULT 0 NOT NULL,
    tags text[] DEFAULT ARRAY[]::text[],
    meta jsonb DEFAULT '{}'::jsonb,
    cancelled_at timestamp without time zone,
    CONSTRAINT attempt_range CHECK (((attempt >= 0) AND (attempt <= max_attempts))),
    CONSTRAINT positive_max_attempts CHECK ((max_attempts > 0)),
    CONSTRAINT queue_length CHECK (((char_length(queue) > 0) AND (char_length(queue) < 128))),
    CONSTRAINT worker_length CHECK (((char_length(worker) > 0) AND (char_length(worker) < 128)))
);


--
-- Name: TABLE oban_jobs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.oban_jobs IS '12';


--
-- Name: oban_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oban_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oban_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oban_jobs_id_seq OWNED BY public.oban_jobs.id;


--
-- Name: oban_peers; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE public.oban_peers (
    name text NOT NULL,
    node text NOT NULL,
    started_at timestamp without time zone NOT NULL,
    expires_at timestamp without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: task_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_events (
    id bigint NOT NULL,
    type character varying(255),
    payload jsonb,
    originator character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    head_sha character varying(255),
    head_ref character varying(255),
    repo_id bigint NOT NULL
);


--
-- Name: source_control_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.source_control_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: source_control_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.source_control_events_id_seq OWNED BY public.task_events.id;


--
-- Name: source_control_repositories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.source_control_repositories (
    id bigint NOT NULL,
    name text,
    url text,
    api_token text,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    external_repository_id bigint,
    raw_attributes jsonb
);


--
-- Name: source_control_repositories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.source_control_repositories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: source_control_repositories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.source_control_repositories_id_seq OWNED BY public.source_control_repositories.id;


--
-- Name: task_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_jobs (
    id bigint NOT NULL,
    program_path character varying(255),
    exit_status integer,
    task_run_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    log_file character varying(255) NOT NULL
);


--
-- Name: task_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.task_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: task_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.task_jobs_id_seq OWNED BY public.task_jobs.id;


--
-- Name: task_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_runs (
    id bigint NOT NULL,
    status text,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    log_file character varying(255) NOT NULL,
    github_trigger_id bigint
);


--
-- Name: task_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.task_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: task_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.task_runs_id_seq OWNED BY public.task_runs.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email public.citext NOT NULL,
    hashed_password character varying(255),
    confirmed_at timestamp(0) without time zone,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token bytea NOT NULL,
    context character varying(255) NOT NULL,
    sent_to character varying(255),
    authenticated_at timestamp(0) without time zone,
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: users_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_tokens_id_seq OWNED BY public.users_tokens.id;


--
-- Name: github_triggers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.github_triggers ALTER COLUMN id SET DEFAULT nextval('public.github_triggers_id_seq'::regclass);


--
-- Name: oban_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_jobs ALTER COLUMN id SET DEFAULT nextval('public.oban_jobs_id_seq'::regclass);


--
-- Name: source_control_repositories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_control_repositories ALTER COLUMN id SET DEFAULT nextval('public.source_control_repositories_id_seq'::regclass);


--
-- Name: task_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_events ALTER COLUMN id SET DEFAULT nextval('public.source_control_events_id_seq'::regclass);


--
-- Name: task_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_jobs ALTER COLUMN id SET DEFAULT nextval('public.task_jobs_id_seq'::regclass);


--
-- Name: task_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_runs ALTER COLUMN id SET DEFAULT nextval('public.task_runs_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: users_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens ALTER COLUMN id SET DEFAULT nextval('public.users_tokens_id_seq'::regclass);


--
-- Name: github_triggers github_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.github_triggers
    ADD CONSTRAINT github_triggers_pkey PRIMARY KEY (id);


--
-- Name: oban_jobs non_negative_priority; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.oban_jobs
    ADD CONSTRAINT non_negative_priority CHECK ((priority >= 0)) NOT VALID;


--
-- Name: oban_jobs oban_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_jobs
    ADD CONSTRAINT oban_jobs_pkey PRIMARY KEY (id);


--
-- Name: oban_peers oban_peers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_peers
    ADD CONSTRAINT oban_peers_pkey PRIMARY KEY (name);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: task_events source_control_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_events
    ADD CONSTRAINT source_control_events_pkey PRIMARY KEY (id);


--
-- Name: source_control_repositories source_control_repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_control_repositories
    ADD CONSTRAINT source_control_repositories_pkey PRIMARY KEY (id);


--
-- Name: task_jobs task_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_jobs
    ADD CONSTRAINT task_jobs_pkey PRIMARY KEY (id);


--
-- Name: task_runs task_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_runs
    ADD CONSTRAINT task_runs_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_tokens users_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_pkey PRIMARY KEY (id);


--
-- Name: oban_jobs_args_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_args_index ON public.oban_jobs USING gin (args);


--
-- Name: oban_jobs_meta_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_meta_index ON public.oban_jobs USING gin (meta);


--
-- Name: oban_jobs_state_queue_priority_scheduled_at_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_state_queue_priority_scheduled_at_id_index ON public.oban_jobs USING btree (state, queue, priority, scheduled_at, id);


--
-- Name: source_control_events_head_ref_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX source_control_events_head_ref_index ON public.task_events USING btree (head_ref);


--
-- Name: source_control_events_head_sha_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX source_control_events_head_sha_index ON public.task_events USING btree (head_sha);


--
-- Name: source_control_events_repo_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX source_control_events_repo_id_index ON public.task_events USING btree (repo_id);


--
-- Name: task_jobs_log_file_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX task_jobs_log_file_index ON public.task_jobs USING btree (log_file);


--
-- Name: task_runs_log_file_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX task_runs_log_file_index ON public.task_runs USING btree (log_file);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: users_tokens_context_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_tokens_context_token_index ON public.users_tokens USING btree (context, token);


--
-- Name: users_tokens_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_tokens_user_id_index ON public.users_tokens USING btree (user_id);


--
-- Name: github_triggers github_triggers_source_control_repository_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.github_triggers
    ADD CONSTRAINT github_triggers_source_control_repository_id_fkey FOREIGN KEY (source_control_repository_id) REFERENCES public.source_control_repositories(id) ON DELETE CASCADE;


--
-- Name: task_events source_control_events_repo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_events
    ADD CONSTRAINT source_control_events_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES public.source_control_repositories(id) ON DELETE CASCADE;


--
-- Name: task_jobs task_jobs_task_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_jobs
    ADD CONSTRAINT task_jobs_task_run_id_fkey FOREIGN KEY (task_run_id) REFERENCES public.task_runs(id) ON DELETE CASCADE;


--
-- Name: task_runs task_runs_github_trigger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_runs
    ADD CONSTRAINT task_runs_github_trigger_id_fkey FOREIGN KEY (github_trigger_id) REFERENCES public.github_triggers(id) ON DELETE CASCADE;


--
-- Name: users_tokens users_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--


INSERT INTO public."schema_migrations" (version) VALUES (20250405151924);
INSERT INTO public."schema_migrations" (version) VALUES (20250407150527);
INSERT INTO public."schema_migrations" (version) VALUES (20250407150836);
INSERT INTO public."schema_migrations" (version) VALUES (20250407162008);
INSERT INTO public."schema_migrations" (version) VALUES (20250407162018);
INSERT INTO public."schema_migrations" (version) VALUES (20250407164025);
INSERT INTO public."schema_migrations" (version) VALUES (20250407234126);
INSERT INTO public."schema_migrations" (version) VALUES (20250409020341);
INSERT INTO public."schema_migrations" (version) VALUES (20250413145217);
INSERT INTO public."schema_migrations" (version) VALUES (20250413150544);
INSERT INTO public."schema_migrations" (version) VALUES (20250425000946);
INSERT INTO public."schema_migrations" (version) VALUES (20250426162325);
INSERT INTO public."schema_migrations" (version) VALUES (20250426202532);
INSERT INTO public."schema_migrations" (version) VALUES (20250427190533);
INSERT INTO public."schema_migrations" (version) VALUES (20250430015644);
INSERT INTO public."schema_migrations" (version) VALUES (20250501013829);
INSERT INTO public."schema_migrations" (version) VALUES (20250502131829);
INSERT INTO public."schema_migrations" (version) VALUES (20250503153253);
INSERT INTO public."schema_migrations" (version) VALUES (20250504165032);
INSERT INTO public."schema_migrations" (version) VALUES (20250504211119);
INSERT INTO public."schema_migrations" (version) VALUES (20250505003347);
INSERT INTO public."schema_migrations" (version) VALUES (20250528005410);
INSERT INTO public."schema_migrations" (version) VALUES (20250528005704);
INSERT INTO public."schema_migrations" (version) VALUES (20260112023849);
