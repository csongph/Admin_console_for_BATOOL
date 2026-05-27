--
-- PostgreSQL database dump
--

\restrict UN6EyRn5Oh1Ez2JwZ7oRlAmw96ZqaMCQanOetO9igQKVfcNhWI3OMfhSvrwfFa8

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-05-26 14:03:45

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
-- TOC entry 236 (class 1255 OID 16933)
-- Name: update_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 235 (class 1259 OID 17067)
-- Name: admin_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_users (
    id integer NOT NULL,
    username character varying(128) NOT NULL,
    hashed_pw character varying(256) NOT NULL,
    role character varying(32) DEFAULT 'viewer'::character varying NOT NULL,
    display_name character varying(128) DEFAULT ''::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_login timestamp with time zone
);


ALTER TABLE public.admin_users OWNER TO postgres;

--
-- TOC entry 5141 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE admin_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.admin_users IS 'ผู้ใช้งาน Admin Console — จัดการโดย admin';


--
-- TOC entry 5142 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN admin_users.hashed_pw; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.admin_users.hashed_pw IS 'bcrypt hashed password';


--
-- TOC entry 5143 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN admin_users.role; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.admin_users.role IS 'admin | editor | viewer';


--
-- TOC entry 234 (class 1259 OID 17066)
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_users_id_seq OWNER TO postgres;

--
-- TOC entry 5144 (class 0 OID 0)
-- Dependencies: 234
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;


--
-- TOC entry 227 (class 1259 OID 16869)
-- Name: database_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.database_records (
    id integer NOT NULL,
    key character varying(64) NOT NULL,
    name character varying(128) NOT NULL,
    version character varying(32) NOT NULL,
    status character varying(32) NOT NULL,
    enabled boolean NOT NULL
);


ALTER TABLE public.database_records OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16868)
-- Name: database_records_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.database_records_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.database_records_id_seq OWNER TO postgres;

--
-- TOC entry 5145 (class 0 OID 0)
-- Dependencies: 226
-- Name: database_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.database_records_id_seq OWNED BY public.database_records.id;


--
-- TOC entry 221 (class 1259 OID 16711)
-- Name: datatype_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.datatype_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.datatype_mapping_id_seq OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16733)
-- Name: datatype_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.datatype_mapping (
    id integer DEFAULT nextval('public.datatype_mapping_id_seq'::regclass) NOT NULL,
    db_id integer NOT NULL,
    standard_id integer NOT NULL,
    final_type character varying(100) NOT NULL,
    has_length boolean DEFAULT false,
    has_precision boolean DEFAULT false,
    has_scale boolean DEFAULT false,
    notes text,
    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    max_length integer,
    numeric_precision integer,
    numeric_scale integer
);


ALTER TABLE public.datatype_mapping OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16712)
-- Name: datatype_raw_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.datatype_raw_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.datatype_raw_mapping_id_seq OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16758)
-- Name: datatype_raw_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.datatype_raw_mapping (
    id integer DEFAULT nextval('public.datatype_raw_mapping_id_seq'::regclass) NOT NULL,
    db_id integer NOT NULL,
    raw_type text NOT NULL,
    logical_type text NOT NULL,
    source_type character varying(50),
    standard_id integer,
    is_default boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    max_length integer,
    numeric_precision integer,
    numeric_scale integer
);


ALTER TABLE public.datatype_raw_mapping OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16710)
-- Name: datatype_standard_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.datatype_standard_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.datatype_standard_id_seq OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16721)
-- Name: datatype_standard; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.datatype_standard (
    id integer DEFAULT nextval('public.datatype_standard_id_seq'::regclass) NOT NULL,
    standard_type character varying(100) NOT NULL,
    category character varying(50),
    description text,
    data_category character varying(50),
    has_length_parameter boolean DEFAULT false,
    is_alias_of integer
);


ALTER TABLE public.datatype_standard OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16709)
-- Name: db_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.db_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.db_type_id_seq OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16964)
-- Name: mapping_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mapping_rules (
    id bigint NOT NULL,
    src_db character varying(50) NOT NULL,
    source_type character varying(255) NOT NULL,
    raw_type character varying(255),
    logical_type character varying(255),
    master_type character varying(255),
    dest_db character varying(50) NOT NULL,
    final_type character varying(255) NOT NULL,
    confidence integer DEFAULT 100,
    status character varying(50) DEFAULT 'active'::character varying,
    updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    error_message character varying(256) DEFAULT NULL::character varying,
    synced_at timestamp with time zone,
    retry_count integer DEFAULT 0
);


ALTER TABLE public.mapping_rules OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16963)
-- Name: mapping_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mapping_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mapping_rules_id_seq OWNER TO postgres;

--
-- TOC entry 5146 (class 0 OID 0)
-- Dependencies: 230
-- Name: mapping_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mapping_rules_id_seq OWNED BY public.mapping_rules.id;


--
-- TOC entry 228 (class 1259 OID 16883)
-- Name: session_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.session_records (
    id character varying(64) NOT NULL,
    "user" character varying(128) NOT NULL,
    role character varying(32) NOT NULL,
    db character varying(64) NOT NULL,
    tables integer NOT NULL,
    ttl_minutes integer NOT NULL,
    created character varying(32) NOT NULL,
    status_cache character varying(16) DEFAULT 'active'::character varying
);


ALTER TABLE public.session_records OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16905)
-- Name: system_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_settings (
    key character varying(64) NOT NULL,
    value character varying(256) NOT NULL
);


ALTER TABLE public.system_settings OWNER TO postgres;

--
-- TOC entry 5147 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE system_settings; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.system_settings IS 'Key-value store สำหรับ system configuration';


--
-- TOC entry 233 (class 1259 OID 17048)
-- Name: update_activities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.update_activities (
    id integer NOT NULL,
    username character varying(128) NOT NULL,
    action character varying(32) NOT NULL,
    target_type character varying(64) NOT NULL,
    target_id character varying(64),
    summary character varying(256) NOT NULL,
    detail text,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.update_activities OWNER TO postgres;

--
-- TOC entry 5148 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE update_activities; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.update_activities IS 'บันทึกทุกการเปลี่ยนแปลงข้อมูลของผู้ใช้งาน';


--
-- TOC entry 5149 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN update_activities.action; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.update_activities.action IS 'create | update | delete | bulk_import';


--
-- TOC entry 5150 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN update_activities.detail; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.update_activities.detail IS 'JSON {before, after, changes} snapshot';


--
-- TOC entry 232 (class 1259 OID 17047)
-- Name: update_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.update_activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.update_activities_id_seq OWNER TO postgres;

--
-- TOC entry 5151 (class 0 OID 0)
-- Dependencies: 232
-- Name: update_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.update_activities_id_seq OWNED BY public.update_activities.id;


--
-- TOC entry 4917 (class 2604 OID 17070)
-- Name: admin_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users ALTER COLUMN id SET DEFAULT nextval('public.admin_users_id_seq'::regclass);


--
-- TOC entry 4908 (class 2604 OID 16872)
-- Name: database_records id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.database_records ALTER COLUMN id SET DEFAULT nextval('public.database_records_id_seq'::regclass);


--
-- TOC entry 4910 (class 2604 OID 16967)
-- Name: mapping_rules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_rules ALTER COLUMN id SET DEFAULT nextval('public.mapping_rules_id_seq'::regclass);


--
-- TOC entry 4916 (class 2604 OID 17051)
-- Name: update_activities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.update_activities ALTER COLUMN id SET DEFAULT nextval('public.update_activities_id_seq'::regclass);


--
-- TOC entry 5135 (class 0 OID 17067)
-- Dependencies: 235
-- Data for Name: admin_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_users (id, username, hashed_pw, role, display_name, is_active, created_at, last_login) FROM stdin;
1	admin	$2b$12$kIhik.v1akqcrhhvo.Q8wO6k3YW86jY5TQxx/5VF4EXq4gcuurcYy	admin	Superadmin	t	2026-05-25 13:43:43.581998+07	2026-05-26 13:31:31.24437+07
5	perm	$2b$12$GDF7k7QpCqJe/7D.GtYi8ewgMsOWyBtHJKxssYAOKIzMXMI/WOIde	editor	พี่เปรม	t	2026-05-25 13:52:09.483071+07	2026-05-26 13:39:22.197438+07
\.


--
-- TOC entry 5127 (class 0 OID 16869)
-- Dependencies: 227
-- Data for Name: database_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.database_records (id, key, name, version, status, enabled) FROM stdin;
1	sqlserver	SQL Server	2019	active	t
2	postgresql	PostgreSQL	15	active	t
3	mysql	MySQL	8.x	active	t
4	oracle	Oracle	19c	active	t
6	mariadb	mariaDB	7.x	active	t
\.


--
-- TOC entry 5124 (class 0 OID 16733)
-- Dependencies: 224
-- Data for Name: datatype_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datatype_mapping (id, db_id, standard_id, final_type, has_length, has_precision, has_scale, notes, updated_at, created_at, max_length, numeric_precision, numeric_scale) FROM stdin;
727	6	1	int	f	f	f	\N	2026-05-25 13:32:33.607608	2026-05-25 13:32:33.607608+07	\N	\N	\N
1	1	1	int	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
2	1	2	bigint	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
3	1	3	decimal	f	t	t	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
4	1	4	real	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
5	1	5	float	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
6	1	6	bit	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
7	1	7	char	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
8	1	8	varchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
9	1	9	text	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
10	1	10	date	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
11	1	11	time	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
12	1	13	varbinary	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
13	1	14	uniqueidentifier	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
14	1	16	xml	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
15	1	17	tinyint	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
16	1	18	smallint	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
17	1	19	nvarchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
18	1	20	nchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
19	1	21	ntext	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
20	1	22	datetime	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
21	1	23	datetime2	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
22	1	24	smalldatetime	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
23	1	25	datetimeoffset	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
24	2	1	integer	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
25	2	2	bigint	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
26	2	3	numeric	f	t	t	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
27	2	4	real	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
28	2	5	double precision	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
29	2	6	boolean	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
30	2	7	char	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
31	2	8	varchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
32	2	9	text	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
33	2	10	date	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
34	2	11	time	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
35	2	12	timestamp	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
36	2	13	bytea	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
37	2	14	uuid	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
38	2	15	jsonb	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
39	2	16	xml	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
40	3	1	int	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
41	3	2	bigint	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
42	3	3	decimal	f	t	t	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
43	3	4	float	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
44	3	5	double	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
45	3	6	tinyint(1)	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
46	3	7	char	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
47	3	8	varchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
48	3	9	text	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
49	3	10	date	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
50	3	11	time	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
51	3	12	timestamp	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
52	3	13	blob	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
53	3	15	json	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
54	4	1	number(10)	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
55	4	2	number(19)	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
56	4	3	number	f	t	t	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
57	4	4	binary_float	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
58	4	5	binary_double	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
59	4	6	number(1)	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
60	4	7	char	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
61	4	8	varchar2	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
62	4	9	clob	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
63	4	12	timestamp	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
64	4	13	blob	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
65	4	16	xmltype	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
66	1	12	datetime2	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
67	1	15	nvarchar(max)	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
68	2	22	timestamp	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
69	3	14	char(36)	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
70	3	16	text	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
71	3	22	datetime	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
72	4	14	varchar2(36)	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
73	4	15	clob	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
74	4	22	timestamp	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
77	2	17	smallint	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
78	2	18	smallint	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
79	2	19	varchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
80	2	20	char	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
81	2	21	text	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
83	2	23	timestamp	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
84	2	24	timestamp	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
85	2	25	timestamptz	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
88	3	17	tinyint	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
89	3	18	smallint	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
90	3	19	varchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
91	3	20	char	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
92	3	21	text	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
94	3	23	datetime	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
95	3	24	datetime	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
97	4	10	date	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
98	4	11	timestamp	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
101	4	17	number(3)	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
102	4	18	number(5)	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
103	4	19	nvarchar2	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
104	4	20	nchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
105	4	21	nclob	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
107	4	23	timestamp	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
108	4	24	date	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
109	4	25	timestamp with time zone	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
145	1	26	geometry	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
146	2	26	geometry	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
147	3	26	geometry	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
148	4	26	sdo_geometry	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
96	3	25	datetime	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
149	1	27	varchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
150	2	27	interval	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
151	3	27	varchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
152	4	27	interval day to second	f	t	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
153	1	28	varchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
154	2	28	inet	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
155	3	28	varchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
156	4	28	varchar2	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
157	1	29	varchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
158	2	29	varchar	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
159	3	29	enum	f	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
160	4	29	varchar2	t	f	f	\N	2026-05-26 09:02:50.430374	2026-05-26 09:02:50.430374+07	\N	\N	\N
\.


--
-- TOC entry 5125 (class 0 OID 16758)
-- Dependencies: 225
-- Data for Name: datatype_raw_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datatype_raw_mapping (id, db_id, raw_type, logical_type, source_type, standard_id, is_default, updated_at, created_at, max_length, numeric_precision, numeric_scale) FROM stdin;
779	6	int	int	int	1	f	2026-05-25 13:32:33.607608	2026-05-25 13:32:33.607608+07	\N	\N	\N
155	2	int	int	smallint	18	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
156	2	long	timestamp-millis	timestamptz	25	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
17	2	string	json	jsonb	15	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
27	3	string	json	json	15	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
36	4	string	xml	xmltype	16	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
60	2	string	xml	xml	16	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
2	1	long	long	bigint	2	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
3	1	bytes	decimal	decimal	3	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
4	1	float	float	real	4	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
5	1	double	double	float	5	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
6	1	boolean	boolean	bit	6	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
8	1	string	uuid	uniqueidentifier	14	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
9	1	long	timestamp-millis	datetime	22	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
11	2	long	long	bigint	2	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
12	2	bytes	decimal	numeric	3	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
13	2	float	float	real	4	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
14	2	double	double	double precision	5	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
15	2	boolean	boolean	boolean	6	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
18	2	string	uuid	uuid	14	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
21	3	long	long	bigint	2	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
22	3	bytes	decimal	decimal	3	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
23	3	float	float	float	4	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
24	3	double	double	double	5	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
25	3	boolean	boolean	tinyint(1)	6	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
52	1	string	datetime-offset	datetimeoffset	25	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
40	1	int	date	date	10	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
153	4	string	interval	interval day to second	27	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
154	4	string	interval	interval year to month	27	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
57	2	int	date	date	10	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
63	3	int	date	date	10	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
146	3	int	date	year	10	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
41	1	int	time	time	11	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
157	1	string	json	json	15	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
58	2	long	time	time	11	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
64	3	int	time	time	11	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
44	1	string	xml	xml	16	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
30	4	long	long	number(19)	2	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
31	4	bytes	decimal	number	3	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
32	4	float	float	binary_float	4	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
33	4	double	double	binary_double	5	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
34	4	boolean	boolean	number(1)	6	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
38	1	string	string	char	7	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
39	1	string	string	text	9	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
45	1	int	int	tinyint	17	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
46	1	int	int	smallint	18	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
47	1	string	string	nvarchar	19	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
48	1	string	string	nchar	20	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
49	1	string	string	ntext	21	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
50	1	long	timestamp-micros	datetime2	23	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
51	1	long	timestamp-millis	smalldatetime	24	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
53	1	bytes	decimal	money	3	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
54	1	bytes	decimal	smallmoney	3	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
55	2	string	string	char	7	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
56	2	string	string	text	9	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
61	3	string	string	char	7	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
62	3	string	string	text	9	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
67	4	string	string	char	7	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
68	4	string	string	clob	9	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
70	4	long	timestamp-millis	date	22	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
137	1	string	spatial	geometry	26	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
138	1	string	spatial	geography	26	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
140	2	string	interval	interval	27	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
141	2	string	network	inet	28	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
142	2	string	network	cidr	28	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
143	2	string	network	macaddr	28	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
144	2	string	spatial	geometry	26	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
147	3	string	enum	enum	29	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
148	3	string	enum	set	29	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
151	4	string	string	long	9	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
7	1	string	string	varchar	8	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
16	2	string	string	varchar	8	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
26	3	string	string	varchar	8	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
35	4	string	string	varchar2	8	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
139	1	string	string	hierarchyid	8	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
1	1	int	int	int	1	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
10	2	int	int	integer	1	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
20	3	int	int	int	1	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
29	4	int	int	number(10)	1	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
145	3	int	int	mediumint	1	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
19	2	long	timestamp-micros	timestamp	12	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
28	3	long	timestamp-millis	timestamp	12	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
37	4	long	timestamp-micros	timestamp	12	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
158	2	string	enum	enum	29	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
160	3	long	timestamp-micros	datetime(6)	12	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
161	3	int	int	tinyint	17	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
162	3	int	int	smallint	18	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
163	3	string	string	nvarchar	19	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
164	3	string	uuid	char(36)	14	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
152	4	bytes	bytes	bfile	13	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
42	1	bytes	bytes	binary	13	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
165	4	string	json	json	15	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
166	4	string	spatial	sdo_geometry	26	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
167	4	string	uuid	raw(16)	14	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
168	4	int	int	smallint	18	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
169	1	bytes	bytes	timestamp	12	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
43	1	bytes	bytes	varbinary	13	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
59	2	bytes	bytes	bytea	13	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
65	3	bytes	bytes	binary	13	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
66	3	bytes	bytes	blob	13	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
183	3	long	timestamp-millis	datetime	22	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
186	3	string	datetime-offset	varchar(35)	25	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
187	3	string	spatial	geometry	26	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
69	4	bytes	bytes	blob	13	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
149	4	bytes	bytes	raw	13	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
190	4	int	date	date	10	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
150	4	bytes	bytes	long raw	13	t	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
194	4	int	int	number(3)	17	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
195	4	string	string	nvarchar2	19	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
196	4	string	string	nchar	20	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
197	4	string	string	nclob	21	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
200	4	string	datetime-offset	timestamp with time zone	25	f	2026-05-26 09:06:54.613575	2026-05-26 09:06:54.613575+07	\N	\N	\N
\.


--
-- TOC entry 5123 (class 0 OID 16721)
-- Dependencies: 223
-- Data for Name: datatype_standard; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datatype_standard (id, standard_type, category, description, data_category, has_length_parameter, is_alias_of) FROM stdin;
1	INTEGER	numeric	\N	\N	f	\N
2	BIGINT	numeric	\N	\N	f	\N
5	DOUBLE PRECISION	numeric	\N	\N	f	\N
6	BOOLEAN	boolean	\N	\N	f	\N
9	TEXT	string	\N	\N	f	\N
10	DATE	datetime	\N	\N	f	\N
11	TIME	datetime	\N	\N	f	\N
12	TIMESTAMP	datetime	\N	\N	f	\N
14	UUID	other	\N	\N	f	\N
15	JSON	other	\N	\N	f	\N
16	XML	other	\N	\N	f	\N
17	TINYINT	numeric	\N	\N	f	\N
18	SMALLINT	numeric	\N	\N	f	\N
21	NTEXT	string	\N	\N	f	\N
24	SMALLDATETIME	datetime	\N	\N	f	\N
26	GEOMETRY	spatial	Spatial and geometry data (e.g., points, polygons)	\N	f	\N
27	INTERVAL	datetime	Time span or interval	\N	f	\N
28	NETWORK	other	IP addresses and network types (e.g., INET, CIDR)	\N	f	\N
29	ENUM	other	Enumerated list of values or sets	\N	f	\N
31	MONEY	numeric	Currency/monetary value, used in SQL Server (MONEY, SMALLMONEY) and PostgreSQL	\N	f	\N
33	BLOB	binary	Binary Large Object, used in Oracle, MySQL, MariaDB (BLOB, TINYBLOB, MEDIUMBLOB, LONGBLOB)	\N	f	\N
35	YEAR	datetime	4-digit or 2-digit year value, used in MySQL and MariaDB (YEAR)	\N	f	\N
36	TIMESTAMP WITH TIME ZONE	datetime	Timestamp with timezone offset, used in PostgreSQL (TIMESTAMPTZ) and Oracle	\N	f	\N
38	ARRAY	other	Array/list of values, used in PostgreSQL, BigQuery, Snowflake, Spark	\N	f	\N
39	GEOGRAPHY	spatial	Geographic spatial data (ellipsoidal), used in SQL Server and PostGIS	\N	f	\N
40	VARIANT	other	Semi-structured data container, used in Snowflake (VARIANT, OBJECT, ARRAY)	\N	f	\N
41	STRUCT	other	Nested record/struct type, used in BigQuery (STRUCT/RECORD) and Spark	\N	f	\N
42	MAP	other	Key-value map type, used in BigQuery, Spark, Cassandra, Hive	\N	f	\N
43	HSTORE	other	Key-value store within a single PostgreSQL value (hstore)	\N	f	\N
44	HIERARCHYID	other	Represents position in a hierarchy tree, used in SQL Server	\N	f	\N
45	ROWID	other	Physical row address/identifier, used in Oracle (ROWID, UROWID)	\N	f	\N
50	CIDR	other	Network address types in PostgreSQL (CIDR, MACADDR, MACADDR8)	\N	f	\N
51	TIME WITH TIME ZONE	datetime	Time with timezone offset, used in PostgreSQL (TIMETZ) and Oracle	\N	f	\N
52	SMALLMONEY	numeric	Small monetary value in SQL Server (SMALLMONEY)	\N	f	\N
53	CURSOR	other	Cursor/reference type, used in SQL Server and PostgreSQL (REFCURSOR)	\N	f	\N
3	DECIMAL	numeric	\N	\N	t	\N
4	FLOAT	numeric	\N	\N	t	\N
7	CHAR	string	\N	\N	t	\N
8	VARCHAR	string	\N	\N	t	\N
13	BINARY	binary	\N	\N	t	\N
19	NVARCHAR	string	\N	\N	t	\N
20	NCHAR	string	\N	\N	t	\N
30	REAL	numeric	Single-precision floating-point, used in PostgreSQL, SQL Server, Oracle (BINARY_FLOAT)	\N	t	\N
46	RAW	binary	Fixed-length raw binary data in Oracle (RAW, LONG RAW, BFILE)	\N	t	\N
49	BIT VARYING	binary	Variable-length bit string in PostgreSQL (BIT VARYING(n))	\N	t	\N
48	VARCHAR2	string	Variable-length character string in Oracle (VARCHAR2, NVARCHAR2)	\N	t	8
37	JSONB	other	Binary JSON with indexing support, used in PostgreSQL (jsonb)	\N	f	15
34	BYTEA	binary	Binary data type in PostgreSQL (bytea)	\N	f	33
32	CLOB	string	Character Large Object for large text, used in Oracle (CLOB, NCLOB, LONG) and DB2	\N	f	9
47	NUMBER	numeric	Flexible precision numeric type in Oracle (NUMBER(p,s))	\N	t	3
22	DATETIME	datetime	\N	\N	f	12
23	DATETIME2	datetime	\N	\N	f	12
25	DATETIMEOFFSET	datetime	\N	\N	f	36
\.


--
-- TOC entry 5131 (class 0 OID 16964)
-- Dependencies: 231
-- Data for Name: mapping_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mapping_rules (id, src_db, source_type, raw_type, logical_type, master_type, dest_db, final_type, confidence, status, updated, error_message, synced_at, retry_count) FROM stdin;
2	postgresql	smallint	int	int	SMALLINT	postgresql	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.523718+07	0
3	postgresql	smallint	int	int	SMALLINT	mysql	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.536104+07	0
5	postgresql	timestamptz	long	timestamp-millis	DATETIMEOFFSET	sqlserver	datetimeoffset	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.559884+07	0
6	postgresql	timestamptz	long	timestamp-millis	DATETIMEOFFSET	postgresql	timestamptz	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.571573+07	0
7	postgresql	timestamptz	long	timestamp-millis	DATETIMEOFFSET	mysql	datetime	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.582407+07	0
9	postgresql	jsonb	string	json	JSON	sqlserver	nvarchar(max)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.603175+07	0
10	postgresql	jsonb	string	json	JSON	postgresql	jsonb	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.616255+07	0
11	postgresql	jsonb	string	json	JSON	mysql	json	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.62756+07	0
12	postgresql	jsonb	string	json	JSON	oracle	clob	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.638586+07	0
13	postgresql	xml	string	xml	XML	sqlserver	xml	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.650826+07	0
14	postgresql	xml	string	xml	XML	postgresql	xml	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.661014+07	0
15	postgresql	xml	string	xml	XML	mysql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.671387+07	0
17	sqlserver	bigint	long	long	BIGINT	sqlserver	bigint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.692484+07	0
18	sqlserver	bigint	long	long	BIGINT	postgresql	bigint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.701753+07	0
19	sqlserver	bigint	long	long	BIGINT	mysql	bigint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.712801+07	0
21	sqlserver	decimal	bytes	decimal	DECIMAL	sqlserver	decimal	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.734939+07	0
22	sqlserver	decimal	bytes	decimal	DECIMAL	postgresql	numeric	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.745205+07	0
23	sqlserver	decimal	bytes	decimal	DECIMAL	mysql	decimal	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.756448+07	0
24	sqlserver	decimal	bytes	decimal	DECIMAL	oracle	number	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.768144+07	0
26	sqlserver	real	float	float	FLOAT	postgresql	real	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.792115+07	0
27	sqlserver	real	float	float	FLOAT	mysql	float	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.803486+07	0
28	sqlserver	real	float	float	FLOAT	oracle	binary_float	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.813798+07	0
30	sqlserver	float	double	double	DOUBLE PRECISION	postgresql	double precision	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.83464+07	0
31	sqlserver	float	double	double	DOUBLE PRECISION	mysql	double	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.84513+07	0
32	sqlserver	float	double	double	DOUBLE PRECISION	oracle	binary_double	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.855752+07	0
33	sqlserver	bit	boolean	boolean	BOOLEAN	sqlserver	bit	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.866828+07	0
34	sqlserver	bit	boolean	boolean	BOOLEAN	postgresql	boolean	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.877136+07	0
36	sqlserver	bit	boolean	boolean	BOOLEAN	oracle	number(1)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.89908+07	0
37	sqlserver	uniqueidentifier	string	uuid	UUID	sqlserver	uniqueidentifier	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.910102+07	0
38	sqlserver	uniqueidentifier	string	uuid	UUID	postgresql	uuid	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.920088+07	0
39	sqlserver	uniqueidentifier	string	uuid	UUID	mysql	char(36)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.930919+07	0
41	sqlserver	datetime	long	timestamp-millis	DATETIME	sqlserver	datetime	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.95279+07	0
42	sqlserver	datetime	long	timestamp-millis	DATETIME	postgresql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.963418+07	0
43	sqlserver	datetime	long	timestamp-millis	DATETIME	mysql	datetime	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.974338+07	0
44	sqlserver	datetime	long	timestamp-millis	DATETIME	oracle	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.983988+07	0
46	postgresql	bigint	long	long	BIGINT	postgresql	bigint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.006147+07	0
47	postgresql	bigint	long	long	BIGINT	mysql	bigint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.016746+07	0
48	postgresql	bigint	long	long	BIGINT	oracle	number(19)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.027361+07	0
49	postgresql	numeric	bytes	decimal	DECIMAL	sqlserver	decimal	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.038192+07	0
51	postgresql	numeric	bytes	decimal	DECIMAL	mysql	decimal	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.058197+07	0
52	postgresql	numeric	bytes	decimal	DECIMAL	oracle	number	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.069207+07	0
53	postgresql	real	float	float	FLOAT	sqlserver	real	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.079263+07	0
54	postgresql	real	float	float	FLOAT	postgresql	real	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.089798+07	0
56	postgresql	real	float	float	FLOAT	oracle	binary_float	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.109937+07	0
57	postgresql	double precision	double	double	DOUBLE PRECISION	sqlserver	float	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.120694+07	0
59	postgresql	double precision	double	double	DOUBLE PRECISION	mysql	double	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.143104+07	0
60	postgresql	double precision	double	double	DOUBLE PRECISION	oracle	binary_double	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.154704+07	0
61	postgresql	boolean	boolean	boolean	BOOLEAN	sqlserver	bit	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.166536+07	0
62	postgresql	boolean	boolean	boolean	BOOLEAN	postgresql	boolean	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.176241+07	0
63	postgresql	boolean	boolean	boolean	BOOLEAN	mysql	tinyint(1)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.18643+07	0
64	postgresql	boolean	boolean	boolean	BOOLEAN	oracle	number(1)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.197214+07	0
66	postgresql	uuid	string	uuid	UUID	postgresql	uuid	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.21755+07	0
67	postgresql	uuid	string	uuid	UUID	mysql	char(36)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.228311+07	0
68	postgresql	uuid	string	uuid	UUID	oracle	varchar2(36)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.238515+07	0
69	mysql	bigint	long	long	BIGINT	sqlserver	bigint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.248532+07	0
72	mysql	bigint	long	long	BIGINT	oracle	number(19)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.28127+07	0
73	mysql	decimal	bytes	decimal	DECIMAL	sqlserver	decimal	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.291777+07	0
74	mysql	decimal	bytes	decimal	DECIMAL	postgresql	numeric	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.301355+07	0
76	mysql	decimal	bytes	decimal	DECIMAL	oracle	number	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.322311+07	0
77	mysql	float	float	float	FLOAT	sqlserver	real	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.332974+07	0
78	mysql	float	float	float	FLOAT	postgresql	real	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.343879+07	0
79	mysql	float	float	float	FLOAT	mysql	float	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.356847+07	0
81	mysql	double	double	double	DOUBLE PRECISION	sqlserver	float	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.38059+07	0
82	mysql	double	double	double	DOUBLE PRECISION	postgresql	double precision	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.391947+07	0
83	mysql	double	double	double	DOUBLE PRECISION	mysql	double	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.403016+07	0
85	mysql	tinyint(1)	boolean	boolean	BOOLEAN	sqlserver	bit	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.424303+07	0
86	mysql	tinyint(1)	boolean	boolean	BOOLEAN	postgresql	boolean	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.43496+07	0
87	mysql	tinyint(1)	boolean	boolean	BOOLEAN	mysql	tinyint(1)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.446175+07	0
88	mysql	tinyint(1)	boolean	boolean	BOOLEAN	oracle	number(1)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.456091+07	0
90	sqlserver	datetimeoffset	string	datetime-offset	DATETIMEOFFSET	postgresql	timestamptz	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.476975+07	0
91	sqlserver	datetimeoffset	string	datetime-offset	DATETIMEOFFSET	mysql	datetime	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.486356+07	0
92	sqlserver	datetimeoffset	string	datetime-offset	DATETIMEOFFSET	oracle	timestamp with time zone	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.498363+07	0
93	sqlserver	date	int	date	DATE	sqlserver	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.510192+07	0
94	sqlserver	date	int	date	DATE	postgresql	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.520943+07	0
95	sqlserver	date	int	date	DATE	mysql	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.531194+07	0
97	oracle	interval day to second	string	interval	INTERVAL	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.55169+07	0
98	oracle	interval day to second	string	interval	INTERVAL	postgresql	interval	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.561586+07	0
99	oracle	interval day to second	string	interval	INTERVAL	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.571833+07	0
101	oracle	interval year to month	string	interval	INTERVAL	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.618211+07	0
102	oracle	interval year to month	string	interval	INTERVAL	postgresql	interval	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.633714+07	0
103	oracle	interval year to month	string	interval	INTERVAL	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.665256+07	0
104	oracle	interval year to month	string	interval	INTERVAL	oracle	interval day to second	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.677531+07	0
105	postgresql	date	int	date	DATE	sqlserver	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.690093+07	0
106	postgresql	date	int	date	DATE	postgresql	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.702867+07	0
108	postgresql	date	int	date	DATE	oracle	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.728562+07	0
109	mysql	date	int	date	DATE	sqlserver	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.740382+07	0
110	mysql	date	int	date	DATE	postgresql	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.752893+07	0
111	mysql	date	int	date	DATE	mysql	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.763733+07	0
113	mysql	year	int	date	DATE	sqlserver	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.787604+07	0
114	mysql	year	int	date	DATE	postgresql	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.79913+07	0
115	mysql	year	int	date	DATE	mysql	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.8099+07	0
117	sqlserver	time	int	time	TIME	sqlserver	time	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.835628+07	0
118	sqlserver	time	int	time	TIME	postgresql	time	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.84877+07	0
119	sqlserver	time	int	time	TIME	mysql	time	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.86076+07	0
121	sqlserver	json	string	json	JSON	sqlserver	nvarchar(max)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.886953+07	0
122	sqlserver	json	string	json	JSON	postgresql	jsonb	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.898995+07	0
123	sqlserver	json	string	json	JSON	mysql	json	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.911814+07	0
124	sqlserver	json	string	json	JSON	oracle	clob	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.92383+07	0
126	postgresql	time	long	time	TIME	postgresql	time	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.94681+07	0
127	postgresql	time	long	time	TIME	mysql	time	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.959338+07	0
128	postgresql	time	long	time	TIME	oracle	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.97053+07	0
129	mysql	time	int	time	TIME	sqlserver	time	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.982594+07	0
131	mysql	time	int	time	TIME	mysql	time	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.008668+07	0
132	mysql	time	int	time	TIME	oracle	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.020901+07	0
133	sqlserver	xml	string	xml	XML	sqlserver	xml	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.032271+07	0
135	sqlserver	xml	string	xml	XML	mysql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.055733+07	0
136	sqlserver	xml	string	xml	XML	oracle	xmltype	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.066977+07	0
137	oracle	number(19)	long	long	BIGINT	sqlserver	bigint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.078182+07	0
139	oracle	number(19)	long	long	BIGINT	mysql	bigint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.102771+07	0
140	oracle	number(19)	long	long	BIGINT	oracle	number(19)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.115157+07	0
141	oracle	number	bytes	decimal	DECIMAL	sqlserver	decimal	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.125855+07	0
142	oracle	number	bytes	decimal	DECIMAL	postgresql	numeric	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.137128+07	0
144	oracle	number	bytes	decimal	DECIMAL	oracle	number	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.160877+07	0
146	oracle	binary_float	float	float	FLOAT	postgresql	real	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.184967+07	0
147	oracle	binary_float	float	float	FLOAT	mysql	float	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.19687+07	0
148	oracle	binary_float	float	float	FLOAT	oracle	binary_float	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.207555+07	0
150	oracle	binary_double	double	double	DOUBLE PRECISION	postgresql	double precision	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.229808+07	0
151	oracle	binary_double	double	double	DOUBLE PRECISION	mysql	double	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.242054+07	0
152	oracle	binary_double	double	double	DOUBLE PRECISION	oracle	binary_double	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.253321+07	0
153	oracle	number(1)	boolean	boolean	BOOLEAN	sqlserver	bit	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.264905+07	0
154	oracle	number(1)	boolean	boolean	BOOLEAN	postgresql	boolean	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.277+07	0
156	oracle	number(1)	boolean	boolean	BOOLEAN	oracle	number(1)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.29968+07	0
157	sqlserver	char	string	string	CHAR	sqlserver	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.311514+07	0
158	sqlserver	char	string	string	CHAR	postgresql	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.323063+07	0
159	sqlserver	char	string	string	CHAR	mysql	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.334982+07	0
161	sqlserver	text	string	string	TEXT	sqlserver	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.357388+07	0
162	sqlserver	text	string	string	TEXT	postgresql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.368675+07	0
163	sqlserver	text	string	string	TEXT	mysql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.3809+07	0
164	sqlserver	text	string	string	TEXT	oracle	clob	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.392353+07	0
166	sqlserver	tinyint	int	int	TINYINT	postgresql	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.41603+07	0
167	sqlserver	tinyint	int	int	TINYINT	mysql	tinyint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.426224+07	0
168	sqlserver	tinyint	int	int	TINYINT	oracle	number(3)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.437658+07	0
170	sqlserver	smallint	int	int	SMALLINT	postgresql	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.460934+07	0
171	sqlserver	smallint	int	int	SMALLINT	mysql	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.472049+07	0
172	sqlserver	smallint	int	int	SMALLINT	oracle	number(5)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.484892+07	0
173	sqlserver	nvarchar	string	string	NVARCHAR	sqlserver	nvarchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.497664+07	0
175	sqlserver	nvarchar	string	string	NVARCHAR	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.523375+07	0
176	sqlserver	nvarchar	string	string	NVARCHAR	oracle	nvarchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.5349+07	0
177	sqlserver	nchar	string	string	NCHAR	sqlserver	nchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.545076+07	0
178	sqlserver	nchar	string	string	NCHAR	postgresql	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.556826+07	0
179	sqlserver	nchar	string	string	NCHAR	mysql	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.570072+07	0
181	sqlserver	ntext	string	string	NTEXT	sqlserver	ntext	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.593677+07	0
182	sqlserver	ntext	string	string	NTEXT	postgresql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.605076+07	0
183	sqlserver	ntext	string	string	NTEXT	mysql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.617441+07	0
185	sqlserver	datetime2	long	timestamp-micros	DATETIME2	sqlserver	datetime2	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.639837+07	0
186	sqlserver	datetime2	long	timestamp-micros	DATETIME2	postgresql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.650891+07	0
187	sqlserver	datetime2	long	timestamp-micros	DATETIME2	mysql	datetime	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.661497+07	0
189	sqlserver	smalldatetime	long	timestamp-millis	SMALLDATETIME	sqlserver	smalldatetime	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.682511+07	0
190	sqlserver	smalldatetime	long	timestamp-millis	SMALLDATETIME	postgresql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.694874+07	0
191	sqlserver	smalldatetime	long	timestamp-millis	SMALLDATETIME	mysql	datetime	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.705276+07	0
192	sqlserver	smalldatetime	long	timestamp-millis	SMALLDATETIME	oracle	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.715444+07	0
193	sqlserver	money	bytes	decimal	DECIMAL	sqlserver	decimal	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.726273+07	0
195	sqlserver	money	bytes	decimal	DECIMAL	mysql	decimal	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.746718+07	0
196	sqlserver	money	bytes	decimal	DECIMAL	oracle	number	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.75777+07	0
197	sqlserver	smallmoney	bytes	decimal	DECIMAL	sqlserver	decimal	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.769038+07	0
198	sqlserver	smallmoney	bytes	decimal	DECIMAL	postgresql	numeric	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.779238+07	0
200	sqlserver	smallmoney	bytes	decimal	DECIMAL	oracle	number	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.800224+07	0
201	postgresql	char	string	string	CHAR	sqlserver	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.79405+07	0
202	postgresql	char	string	string	CHAR	postgresql	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.812773+07	0
203	postgresql	char	string	string	CHAR	mysql	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.827013+07	0
204	postgresql	char	string	string	CHAR	oracle	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.840237+07	0
206	postgresql	text	string	string	TEXT	postgresql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.865471+07	0
207	postgresql	text	string	string	TEXT	mysql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.878447+07	0
208	postgresql	text	string	string	TEXT	oracle	clob	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.892258+07	0
210	mysql	char	string	string	CHAR	postgresql	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.91727+07	0
211	mysql	char	string	string	CHAR	mysql	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.928846+07	0
212	mysql	char	string	string	CHAR	oracle	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.94127+07	0
213	mysql	text	string	string	TEXT	sqlserver	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.955198+07	0
215	mysql	text	string	string	TEXT	mysql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.979081+07	0
216	mysql	text	string	string	TEXT	oracle	clob	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.989673+07	0
217	oracle	char	string	string	CHAR	sqlserver	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.001808+07	0
218	oracle	char	string	string	CHAR	postgresql	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.014915+07	0
220	oracle	char	string	string	CHAR	oracle	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.03954+07	0
221	oracle	clob	string	string	TEXT	sqlserver	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.051741+07	0
222	oracle	clob	string	string	TEXT	postgresql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.064869+07	0
224	oracle	clob	string	string	TEXT	oracle	clob	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.088387+07	0
225	oracle	date	long	timestamp-millis	DATETIME	sqlserver	datetime	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.099767+07	0
226	oracle	date	long	timestamp-millis	DATETIME	postgresql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.112832+07	0
228	oracle	date	long	timestamp-millis	DATETIME	oracle	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.137903+07	0
229	sqlserver	geometry	string	spatial	GEOMETRY	sqlserver	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.149007+07	0
230	sqlserver	geometry	string	spatial	GEOMETRY	postgresql	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.161243+07	0
231	sqlserver	geometry	string	spatial	GEOMETRY	mysql	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.174587+07	0
233	sqlserver	geography	string	spatial	GEOMETRY	sqlserver	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.201099+07	0
234	sqlserver	geography	string	spatial	GEOMETRY	postgresql	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.215026+07	0
235	sqlserver	geography	string	spatial	GEOMETRY	mysql	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.227159+07	0
236	sqlserver	geography	string	spatial	GEOMETRY	oracle	sdo_geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.241102+07	0
238	postgresql	interval	string	interval	INTERVAL	postgresql	interval	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.266011+07	0
239	postgresql	interval	string	interval	INTERVAL	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.277898+07	0
240	postgresql	interval	string	interval	INTERVAL	oracle	interval day to second	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.28887+07	0
241	postgresql	inet	string	network	NETWORK	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.301374+07	0
242	postgresql	inet	string	network	NETWORK	postgresql	inet	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.313828+07	0
244	postgresql	inet	string	network	NETWORK	oracle	varchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.338088+07	0
245	postgresql	cidr	string	network	NETWORK	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.350024+07	0
246	postgresql	cidr	string	network	NETWORK	postgresql	inet	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.362018+07	0
247	postgresql	cidr	string	network	NETWORK	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.373883+07	0
249	postgresql	macaddr	string	network	NETWORK	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.397653+07	0
250	postgresql	macaddr	string	network	NETWORK	postgresql	inet	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.410342+07	0
251	postgresql	macaddr	string	network	NETWORK	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.421866+07	0
252	postgresql	macaddr	string	network	NETWORK	oracle	varchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.433611+07	0
254	postgresql	geometry	string	spatial	GEOMETRY	postgresql	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.457374+07	0
255	postgresql	geometry	string	spatial	GEOMETRY	mysql	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.470932+07	0
256	postgresql	geometry	string	spatial	GEOMETRY	oracle	sdo_geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.484344+07	0
257	mysql	enum	string	enum	ENUM	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.497149+07	0
259	mysql	enum	string	enum	ENUM	mysql	enum	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.520525+07	0
260	mysql	enum	string	enum	ENUM	oracle	varchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.533243+07	0
261	mysql	set	string	enum	ENUM	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.545889+07	0
262	mysql	set	string	enum	ENUM	postgresql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.557899+07	0
264	mysql	set	string	enum	ENUM	oracle	varchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.582242+07	0
265	oracle	long	string	string	TEXT	sqlserver	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.594778+07	0
266	oracle	long	string	string	TEXT	postgresql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.606563+07	0
267	oracle	long	string	string	TEXT	mysql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.618823+07	0
269	sqlserver	varchar	string	string	VARCHAR	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.642225+07	0
270	sqlserver	varchar	string	string	VARCHAR	postgresql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.654427+07	0
271	sqlserver	varchar	string	string	VARCHAR	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.666469+07	0
273	postgresql	varchar	string	string	VARCHAR	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.690756+07	0
274	postgresql	varchar	string	string	VARCHAR	postgresql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.704737+07	0
275	postgresql	varchar	string	string	VARCHAR	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.71839+07	0
276	postgresql	varchar	string	string	VARCHAR	oracle	varchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.732139+07	0
278	mysql	varchar	string	string	VARCHAR	postgresql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.795206+07	0
279	mysql	varchar	string	string	VARCHAR	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.806597+07	0
280	mysql	varchar	string	string	VARCHAR	oracle	varchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.819664+07	0
281	oracle	varchar2	string	string	VARCHAR	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.831363+07	0
283	oracle	varchar2	string	string	VARCHAR	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.854299+07	0
284	oracle	varchar2	string	string	VARCHAR	oracle	varchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.865396+07	0
286	sqlserver	hierarchyid	string	string	VARCHAR	postgresql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.887914+07	0
287	sqlserver	hierarchyid	string	string	VARCHAR	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.900156+07	0
289	sqlserver	int	int	int	INTEGER	sqlserver	int	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.93699+07	0
290	sqlserver	int	int	int	INTEGER	postgresql	integer	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.948705+07	0
291	sqlserver	int	int	int	INTEGER	mysql	int	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.95996+07	0
292	sqlserver	int	int	int	INTEGER	oracle	number(10)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.971631+07	0
294	postgresql	integer	int	int	INTEGER	postgresql	integer	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.995604+07	0
295	postgresql	integer	int	int	INTEGER	mysql	int	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:21.008505+07	0
296	postgresql	integer	int	int	INTEGER	oracle	number(10)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:21.021161+07	0
297	mysql	int	int	int	INTEGER	sqlserver	int	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:21.032463+07	0
299	mysql	int	int	int	INTEGER	mysql	int	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:21.056116+07	0
300	mysql	int	int	int	INTEGER	oracle	number(10)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:21.068416+07	0
301	oracle	number(10)	int	int	INTEGER	sqlserver	int	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.388449+07	0
303	oracle	number(10)	int	int	INTEGER	mysql	int	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.419446+07	0
304	oracle	number(10)	int	int	INTEGER	oracle	number(10)	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.431762+07	0
305	mysql	mediumint	int	int	INTEGER	sqlserver	int	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.450451+07	0
306	mysql	mediumint	int	int	INTEGER	postgresql	integer	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.461656+07	0
307	mysql	mediumint	int	int	INTEGER	mysql	int	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.473486+07	0
309	postgresql	timestamp	long	timestamp-micros	TIMESTAMP	sqlserver	datetime2	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.496501+07	0
310	postgresql	timestamp	long	timestamp-micros	TIMESTAMP	postgresql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.507335+07	0
312	postgresql	timestamp	long	timestamp-micros	TIMESTAMP	oracle	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.534882+07	0
313	mysql	timestamp	long	timestamp-millis	TIMESTAMP	sqlserver	datetime2	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.546858+07	0
314	mysql	timestamp	long	timestamp-millis	TIMESTAMP	postgresql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.558996+07	0
315	mysql	timestamp	long	timestamp-millis	TIMESTAMP	mysql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.571364+07	0
316	mysql	timestamp	long	timestamp-millis	TIMESTAMP	oracle	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.583196+07	0
318	oracle	timestamp	long	timestamp-micros	TIMESTAMP	postgresql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.606938+07	0
319	oracle	timestamp	long	timestamp-micros	TIMESTAMP	mysql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.61889+07	0
320	oracle	timestamp	long	timestamp-micros	TIMESTAMP	oracle	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.630426+07	0
321	postgresql	enum	string	enum	ENUM	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.642326+07	0
322	postgresql	enum	string	enum	ENUM	postgresql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.653026+07	0
324	postgresql	enum	string	enum	ENUM	oracle	varchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.674823+07	0
325	mysql	datetime(6)	long	timestamp-micros	TIMESTAMP	sqlserver	datetime2	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.68857+07	0
326	mysql	datetime(6)	long	timestamp-micros	TIMESTAMP	postgresql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.699377+07	0
328	mysql	datetime(6)	long	timestamp-micros	TIMESTAMP	oracle	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.723614+07	0
329	mysql	tinyint	int	int	TINYINT	sqlserver	tinyint	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.735121+07	0
330	mysql	tinyint	int	int	TINYINT	postgresql	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.745788+07	0
331	mysql	tinyint	int	int	TINYINT	mysql	tinyint	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.757308+07	0
332	mysql	tinyint	int	int	TINYINT	oracle	number(3)	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.768218+07	0
334	mysql	smallint	int	int	SMALLINT	postgresql	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.789965+07	0
335	mysql	smallint	int	int	SMALLINT	mysql	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.802141+07	0
336	mysql	smallint	int	int	SMALLINT	oracle	number(5)	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.81368+07	0
338	mysql	nvarchar	string	string	NVARCHAR	postgresql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.836021+07	0
339	mysql	nvarchar	string	string	NVARCHAR	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.847707+07	0
340	mysql	nvarchar	string	string	NVARCHAR	oracle	nvarchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.859934+07	0
341	mysql	char(36)	string	uuid	UUID	sqlserver	uniqueidentifier	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.870894+07	0
342	mysql	char(36)	string	uuid	UUID	postgresql	uuid	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.882203+07	0
344	mysql	char(36)	string	uuid	UUID	oracle	varchar2(36)	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.904541+07	0
345	oracle	bfile	bytes	bytes	BINARY	sqlserver	varbinary	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.91639+07	0
346	oracle	bfile	bytes	bytes	BINARY	postgresql	bytea	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.927348+07	0
347	oracle	bfile	bytes	bytes	BINARY	mysql	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.938249+07	0
349	sqlserver	binary	bytes	bytes	BINARY	sqlserver	varbinary	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.960293+07	0
350	sqlserver	binary	bytes	bytes	BINARY	postgresql	bytea	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.972397+07	0
351	sqlserver	binary	bytes	bytes	BINARY	mysql	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.985484+07	0
353	oracle	json	string	json	JSON	sqlserver	nvarchar(max)	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.009919+07	0
354	oracle	json	string	json	JSON	postgresql	jsonb	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.024425+07	0
355	oracle	json	string	json	JSON	mysql	json	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.036816+07	0
356	oracle	json	string	json	JSON	oracle	clob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.050879+07	0
358	oracle	sdo_geometry	string	spatial	GEOMETRY	postgresql	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.075635+07	0
359	oracle	sdo_geometry	string	spatial	GEOMETRY	mysql	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.087488+07	0
361	oracle	raw(16)	string	uuid	UUID	sqlserver	uniqueidentifier	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.112233+07	0
362	oracle	raw(16)	string	uuid	UUID	postgresql	uuid	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.123824+07	0
363	oracle	raw(16)	string	uuid	UUID	mysql	char(36)	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.135317+07	0
364	oracle	raw(16)	string	uuid	UUID	oracle	varchar2(36)	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.146943+07	0
365	oracle	smallint	int	int	SMALLINT	sqlserver	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.158623+07	0
367	oracle	smallint	int	int	SMALLINT	mysql	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.184856+07	0
368	oracle	smallint	int	int	SMALLINT	oracle	number(5)	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.198412+07	0
369	sqlserver	timestamp	bytes	bytes	TIMESTAMP	sqlserver	datetime2	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.21048+07	0
371	sqlserver	timestamp	bytes	bytes	TIMESTAMP	mysql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.233147+07	0
372	sqlserver	timestamp	bytes	bytes	TIMESTAMP	oracle	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.245438+07	0
373	sqlserver	varbinary	bytes	bytes	BINARY	sqlserver	varbinary	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.257143+07	0
374	sqlserver	varbinary	bytes	bytes	BINARY	postgresql	bytea	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.268651+07	0
375	sqlserver	varbinary	bytes	bytes	BINARY	mysql	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.280331+07	0
377	postgresql	bytea	bytes	bytes	BINARY	sqlserver	varbinary	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.305366+07	0
378	postgresql	bytea	bytes	bytes	BINARY	postgresql	bytea	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.317601+07	0
379	postgresql	bytea	bytes	bytes	BINARY	mysql	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.329016+07	0
380	postgresql	bytea	bytes	bytes	BINARY	oracle	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.339625+07	0
382	mysql	binary	bytes	bytes	BINARY	postgresql	bytea	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.361821+07	0
383	mysql	binary	bytes	bytes	BINARY	mysql	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.372993+07	0
384	mysql	binary	bytes	bytes	BINARY	oracle	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.383563+07	0
385	mysql	blob	bytes	bytes	BINARY	sqlserver	varbinary	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.39408+07	0
387	mysql	blob	bytes	bytes	BINARY	mysql	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.41554+07	0
388	mysql	blob	bytes	bytes	BINARY	oracle	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.42666+07	0
389	mysql	datetime	long	timestamp-millis	DATETIME	sqlserver	datetime	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.438437+07	0
391	mysql	datetime	long	timestamp-millis	DATETIME	mysql	datetime	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.46097+07	0
392	mysql	datetime	long	timestamp-millis	DATETIME	oracle	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.472359+07	0
393	mysql	varchar(35)	string	datetime-offset	DATETIMEOFFSET	sqlserver	datetimeoffset	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.484368+07	0
394	mysql	varchar(35)	string	datetime-offset	DATETIMEOFFSET	postgresql	timestamptz	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.49472+07	0
396	mysql	varchar(35)	string	datetime-offset	DATETIMEOFFSET	oracle	timestamp with time zone	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.51766+07	0
397	mysql	geometry	string	spatial	GEOMETRY	sqlserver	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.52756+07	0
398	mysql	geometry	string	spatial	GEOMETRY	postgresql	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.537429+07	0
399	mysql	geometry	string	spatial	GEOMETRY	mysql	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.548239+07	0
400	mysql	geometry	string	spatial	GEOMETRY	oracle	sdo_geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.558896+07	0
402	oracle	blob	bytes	bytes	BINARY	postgresql	bytea	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.469566+07	0
403	oracle	blob	bytes	bytes	BINARY	mysql	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.484855+07	0
404	oracle	blob	bytes	bytes	BINARY	oracle	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.502072+07	0
405	oracle	raw	bytes	bytes	BINARY	sqlserver	varbinary	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.5163+07	0
407	oracle	raw	bytes	bytes	BINARY	mysql	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.545937+07	0
408	oracle	raw	bytes	bytes	BINARY	oracle	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.560343+07	0
409	oracle	date	int	date	DATE	sqlserver	date	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.575351+07	0
410	oracle	date	int	date	DATE	postgresql	date	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.591207+07	0
412	oracle	date	int	date	DATE	oracle	date	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.621425+07	0
413	oracle	long raw	bytes	bytes	BINARY	sqlserver	varbinary	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.635017+07	0
414	oracle	long raw	bytes	bytes	BINARY	postgresql	bytea	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.648492+07	0
416	oracle	long raw	bytes	bytes	BINARY	oracle	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.674812+07	0
417	oracle	number(3)	int	int	TINYINT	sqlserver	tinyint	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.686826+07	0
418	oracle	number(3)	int	int	TINYINT	postgresql	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.701235+07	0
419	oracle	number(3)	int	int	TINYINT	mysql	tinyint	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.715472+07	0
421	oracle	nvarchar2	string	string	NVARCHAR	sqlserver	nvarchar	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.742569+07	0
422	oracle	nvarchar2	string	string	NVARCHAR	postgresql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.756557+07	0
423	oracle	nvarchar2	string	string	NVARCHAR	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.768225+07	0
425	oracle	nchar	string	string	NCHAR	sqlserver	nchar	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.793383+07	0
426	oracle	nchar	string	string	NCHAR	postgresql	char	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.806262+07	0
427	oracle	nchar	string	string	NCHAR	mysql	char	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.819615+07	0
428	oracle	nchar	string	string	NCHAR	oracle	nchar	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.831407+07	0
1	postgresql	smallint	int	int	SMALLINT	sqlserver	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.506481+07	0
4	postgresql	smallint	int	int	SMALLINT	oracle	number(5)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.547505+07	0
8	postgresql	timestamptz	long	timestamp-millis	DATETIMEOFFSET	oracle	timestamp with time zone	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.592318+07	0
16	postgresql	xml	string	xml	XML	oracle	xmltype	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.681721+07	0
20	sqlserver	bigint	long	long	BIGINT	oracle	number(19)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.724203+07	0
25	sqlserver	real	float	float	FLOAT	sqlserver	real	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.78069+07	0
29	sqlserver	float	double	double	DOUBLE PRECISION	sqlserver	float	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.82334+07	0
35	sqlserver	bit	boolean	boolean	BOOLEAN	mysql	tinyint(1)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.887941+07	0
40	sqlserver	uniqueidentifier	string	uuid	UUID	oracle	varchar2(36)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.941751+07	0
45	postgresql	bigint	long	long	BIGINT	sqlserver	bigint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:13.994706+07	0
50	postgresql	numeric	bytes	decimal	DECIMAL	postgresql	numeric	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.047704+07	0
55	postgresql	real	float	float	FLOAT	mysql	float	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.100154+07	0
58	postgresql	double precision	double	double	DOUBLE PRECISION	postgresql	double precision	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.131233+07	0
65	postgresql	uuid	string	uuid	UUID	sqlserver	uniqueidentifier	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.207113+07	0
70	mysql	bigint	long	long	BIGINT	postgresql	bigint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.259811+07	0
71	mysql	bigint	long	long	BIGINT	mysql	bigint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.270591+07	0
75	mysql	decimal	bytes	decimal	DECIMAL	mysql	decimal	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.311742+07	0
80	mysql	float	float	float	FLOAT	oracle	binary_float	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.369223+07	0
84	mysql	double	double	double	DOUBLE PRECISION	oracle	binary_double	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.414047+07	0
89	sqlserver	datetimeoffset	string	datetime-offset	DATETIMEOFFSET	sqlserver	datetimeoffset	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.466402+07	0
96	sqlserver	date	int	date	DATE	oracle	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.541859+07	0
100	oracle	interval day to second	string	interval	INTERVAL	oracle	interval day to second	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:24:14.582065+07	0
107	postgresql	date	int	date	DATE	mysql	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.715562+07	0
112	mysql	date	int	date	DATE	oracle	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.775877+07	0
116	mysql	year	int	date	DATE	oracle	date	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.8228+07	0
120	sqlserver	time	int	time	TIME	oracle	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.873827+07	0
125	postgresql	time	long	time	TIME	sqlserver	time	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.935832+07	0
130	mysql	time	int	time	TIME	postgresql	time	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:14.996312+07	0
134	sqlserver	xml	string	xml	XML	postgresql	xml	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.043605+07	0
138	oracle	number(19)	long	long	BIGINT	postgresql	bigint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.089728+07	0
143	oracle	number	bytes	decimal	DECIMAL	mysql	decimal	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.149389+07	0
145	oracle	binary_float	float	float	FLOAT	sqlserver	real	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.17259+07	0
149	oracle	binary_double	double	double	DOUBLE PRECISION	sqlserver	float	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.219562+07	0
155	oracle	number(1)	boolean	boolean	BOOLEAN	mysql	tinyint(1)	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.288707+07	0
160	sqlserver	char	string	string	CHAR	oracle	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.346427+07	0
165	sqlserver	tinyint	int	int	TINYINT	sqlserver	tinyint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.40393+07	0
169	sqlserver	smallint	int	int	SMALLINT	sqlserver	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.448726+07	0
174	sqlserver	nvarchar	string	string	NVARCHAR	postgresql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.51086+07	0
180	sqlserver	nchar	string	string	NCHAR	oracle	nchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.582362+07	0
184	sqlserver	ntext	string	string	NTEXT	oracle	nclob	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.629276+07	0
188	sqlserver	datetime2	long	timestamp-micros	DATETIME2	oracle	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.671523+07	0
194	sqlserver	money	bytes	decimal	DECIMAL	postgresql	numeric	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.736937+07	0
199	sqlserver	smallmoney	bytes	decimal	DECIMAL	mysql	decimal	100	synced	2026-05-21 00:00:00	\N	2026-05-21 14:29:15.789638+07	0
205	postgresql	text	string	string	TEXT	sqlserver	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.852294+07	0
209	mysql	char	string	string	CHAR	sqlserver	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.90442+07	0
214	mysql	text	string	string	TEXT	postgresql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:19.966606+07	0
219	oracle	char	string	string	CHAR	mysql	char	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.02773+07	0
223	oracle	clob	string	string	TEXT	mysql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.076636+07	0
227	oracle	date	long	timestamp-millis	DATETIME	mysql	datetime	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.125366+07	0
232	sqlserver	geometry	string	spatial	GEOMETRY	oracle	sdo_geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.188354+07	0
237	postgresql	interval	string	interval	INTERVAL	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.254443+07	0
430	oracle	nclob	string	string	NTEXT	postgresql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.857388+07	0
431	oracle	nclob	string	string	NTEXT	mysql	text	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.871167+07	0
433	oracle	timestamp with time zone	string	datetime-offset	DATETIMEOFFSET	sqlserver	datetimeoffset	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.89859+07	0
434	oracle	timestamp with time zone	string	datetime-offset	DATETIMEOFFSET	postgresql	timestamptz	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.911529+07	0
436	oracle	timestamp with time zone	string	datetime-offset	DATETIMEOFFSET	oracle	timestamp with time zone	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.937279+07	0
243	postgresql	inet	string	network	NETWORK	mysql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.326363+07	0
248	postgresql	cidr	string	network	NETWORK	oracle	varchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.385134+07	0
253	postgresql	geometry	string	spatial	GEOMETRY	sqlserver	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.445447+07	0
258	mysql	enum	string	enum	ENUM	postgresql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.508735+07	0
263	mysql	set	string	enum	ENUM	mysql	enum	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.569548+07	0
268	oracle	long	string	string	TEXT	oracle	clob	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.630198+07	0
272	sqlserver	varchar	string	string	VARCHAR	oracle	varchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.678662+07	0
277	mysql	varchar	string	string	VARCHAR	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.746243+07	0
282	oracle	varchar2	string	string	VARCHAR	postgresql	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.843418+07	0
285	sqlserver	hierarchyid	string	string	VARCHAR	sqlserver	varchar	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.87647+07	0
288	sqlserver	hierarchyid	string	string	VARCHAR	oracle	varchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.912305+07	0
293	postgresql	integer	int	int	INTEGER	sqlserver	int	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:20.984569+07	0
298	mysql	int	int	int	INTEGER	postgresql	integer	100	synced	2026-05-21 00:00:00	\N	2026-05-21 15:03:21.044125+07	0
302	oracle	number(10)	int	int	INTEGER	postgresql	integer	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.404799+07	0
308	mysql	mediumint	int	int	INTEGER	oracle	number(10)	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.484298+07	0
311	postgresql	timestamp	long	timestamp-micros	TIMESTAMP	mysql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.518398+07	0
317	oracle	timestamp	long	timestamp-micros	TIMESTAMP	sqlserver	datetime2	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.594004+07	0
323	postgresql	enum	string	enum	ENUM	mysql	enum	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.664471+07	0
327	mysql	datetime(6)	long	timestamp-micros	TIMESTAMP	mysql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.711822+07	0
333	mysql	smallint	int	int	SMALLINT	sqlserver	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.778215+07	0
337	mysql	nvarchar	string	string	NVARCHAR	sqlserver	nvarchar	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.824897+07	0
343	mysql	char(36)	string	uuid	UUID	mysql	char(36)	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.893871+07	0
348	oracle	bfile	bytes	bytes	BINARY	oracle	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.949176+07	0
352	sqlserver	binary	bytes	bytes	BINARY	oracle	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:27.997009+07	0
357	oracle	sdo_geometry	string	spatial	GEOMETRY	sqlserver	geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.063997+07	0
360	oracle	sdo_geometry	string	spatial	GEOMETRY	oracle	sdo_geometry	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.099658+07	0
366	oracle	smallint	int	int	SMALLINT	postgresql	smallint	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.171775+07	0
370	sqlserver	timestamp	bytes	bytes	TIMESTAMP	postgresql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.222593+07	0
376	sqlserver	varbinary	bytes	bytes	BINARY	oracle	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.293445+07	0
381	mysql	binary	bytes	bytes	BINARY	sqlserver	varbinary	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.350776+07	0
386	mysql	blob	bytes	bytes	BINARY	postgresql	bytea	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.404645+07	0
390	mysql	datetime	long	timestamp-millis	DATETIME	postgresql	timestamp	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.448997+07	0
395	mysql	varchar(35)	string	datetime-offset	DATETIMEOFFSET	mysql	datetime	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:28:28.505651+07	0
401	oracle	blob	bytes	bytes	BINARY	sqlserver	varbinary	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.447417+07	0
406	oracle	raw	bytes	bytes	BINARY	postgresql	bytea	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.531198+07	0
411	oracle	date	int	date	DATE	mysql	date	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.605734+07	0
415	oracle	long raw	bytes	bytes	BINARY	mysql	blob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.66026+07	0
420	oracle	number(3)	int	int	TINYINT	oracle	number(3)	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.729292+07	0
424	oracle	nvarchar2	string	string	NVARCHAR	oracle	nvarchar2	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.781127+07	0
429	oracle	nclob	string	string	NTEXT	sqlserver	ntext	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.84568+07	0
432	oracle	nclob	string	string	NTEXT	oracle	nclob	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.88479+07	0
435	oracle	timestamp with time zone	string	datetime-offset	DATETIMEOFFSET	mysql	datetime	100	synced	2026-05-21 00:00:00	\N	2026-05-22 11:31:54.925606+07	0
440	mariadb	int	int	int	INTEGER	mariadb	int	100	synced	2026-05-25 00:00:00	\N	2026-05-25 13:32:33.625811+07	0
441	mariadb	Tinyint	int	int	TINYINT	mariadb	Tinyint	100	error	2026-05-26 00:00:00	DATABASE_ERROR	\N	1
\.


--
-- TOC entry 5128 (class 0 OID 16883)
-- Dependencies: 228
-- Data for Name: session_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.session_records (id, "user", role, db, tables, ttl_minutes, created, status_cache) FROM stdin;
auth-perm	perm	editor	admin-console	0	60	2026-05-26 06:39:22	active
\.


--
-- TOC entry 5129 (class 0 OID 16905)
-- Dependencies: 229
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.system_settings (key, value) FROM stdin;
maintenance_reason	กำลังอัพเดต database เพิ่มเติม
maintenance_mode	false
\.


--
-- TOC entry 5133 (class 0 OID 17048)
-- Dependencies: 233
-- Data for Name: update_activities; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.update_activities (id, username, action, target_type, target_id, summary, detail, created_at) FROM stdin;
1	admin	create	mapping	440	สร้าง mapping: int (mariadb → mariadb)	{"after": {"id": 440, "src_db": "mariadb", "raw_type": "int", "source_type": "int", "logical_type": "int", "master_type": "INTEGER", "dest_db": "mariadb", "final_type": "int", "confidence": 100, "status": "pending", "updated": "2026-05-25T00:00:00", "error_message": null, "synced_at": null, "retry_count": 0}}	2026-05-25 13:29:36.303227+07
2	admin	create	user	2	สร้างผู้ใช้ใหม่: perm (role: editor)	{"after": {"id": 2, "username": "perm", "role": "editor", "display_name": "พี่เปรม", "is_active": true, "created_at": "2026-05-25T06:45:06.132104+00:00", "last_login": null}}	2026-05-25 13:45:06.13511+07
3	admin	delete	user	2	ลบผู้ใช้: perm (role: editor)	{"before": {"id": 2, "username": "perm", "role": "editor", "display_name": "พี่เปรม", "is_active": true, "created_at": "2026-05-25T06:45:06.132104+00:00", "last_login": null}}	2026-05-25 13:46:09.863656+07
4	admin	create	user	3	สร้างผู้ใช้ใหม่: perm (role: editor)	{"after": {"id": 3, "username": "perm", "role": "editor", "display_name": "พี่เปรม", "is_active": true, "created_at": "2026-05-25T06:46:33.310220+00:00", "last_login": null}}	2026-05-25 13:46:33.311933+07
5	admin	delete	user	3	ลบผู้ใช้: perm (role: editor)	{"before": {"id": 3, "username": "perm", "role": "editor", "display_name": "พี่เปรม", "is_active": true, "created_at": "2026-05-25T06:46:33.310220+00:00", "last_login": null}}	2026-05-25 13:48:22.500691+07
6	admin	create	user	4	สร้างผู้ใช้ใหม่: perm (role: viewer)	{"after": {"id": 4, "username": "perm", "role": "viewer", "display_name": "พี่เปรม", "is_active": true, "created_at": "2026-05-25T06:48:46.745536+00:00", "last_login": null}}	2026-05-25 13:48:46.748013+07
7	admin	delete	user	4	ลบผู้ใช้: perm (role: viewer)	{"before": {"id": 4, "username": "perm", "role": "viewer", "display_name": "พี่เปรม", "is_active": true, "created_at": "2026-05-25T06:48:46.745536+00:00", "last_login": null}}	2026-05-25 13:51:50.795484+07
8	admin	create	user	5	สร้างผู้ใช้ใหม่: perm (role: editor)	{"after": {"id": 5, "username": "perm", "role": "editor", "display_name": "พี่เปรม", "is_active": true, "created_at": "2026-05-25T06:52:09.483071+00:00", "last_login": null}}	2026-05-25 13:52:09.486621+07
9	perm	create	mapping	441	สร้าง mapping: int (mariadb → mariadb)	{"after": {"id": 441, "src_db": "mariadb", "raw_type": "int", "source_type": "Tinyint", "logical_type": "int", "master_type": "TINYINT", "dest_db": "mariadb", "final_type": "Tinyint", "confidence": 100, "status": "pending", "updated": "2026-05-26T00:00:00", "error_message": null, "synced_at": null, "retry_count": 0}}	2026-05-26 13:41:42.456742+07
\.


--
-- TOC entry 5152 (class 0 OID 0)
-- Dependencies: 234
-- Name: admin_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_users_id_seq', 5, true);


--
-- TOC entry 5153 (class 0 OID 0)
-- Dependencies: 226
-- Name: database_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.database_records_id_seq', 6, true);


--
-- TOC entry 5154 (class 0 OID 0)
-- Dependencies: 221
-- Name: datatype_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.datatype_mapping_id_seq', 727, true);


--
-- TOC entry 5155 (class 0 OID 0)
-- Dependencies: 222
-- Name: datatype_raw_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.datatype_raw_mapping_id_seq', 779, true);


--
-- TOC entry 5156 (class 0 OID 0)
-- Dependencies: 220
-- Name: datatype_standard_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.datatype_standard_id_seq', 53, true);


--
-- TOC entry 5157 (class 0 OID 0)
-- Dependencies: 219
-- Name: db_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.db_type_id_seq', 4, true);


--
-- TOC entry 5158 (class 0 OID 0)
-- Dependencies: 230
-- Name: mapping_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mapping_rules_id_seq', 441, true);


--
-- TOC entry 5159 (class 0 OID 0)
-- Dependencies: 232
-- Name: update_activities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.update_activities_id_seq', 9, true);


--
-- TOC entry 4961 (class 2606 OID 17085)
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- TOC entry 4963 (class 2606 OID 17087)
-- Name: admin_users admin_users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_username_key UNIQUE (username);


--
-- TOC entry 4942 (class 2606 OID 16882)
-- Name: database_records database_records_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.database_records
    ADD CONSTRAINT database_records_key_key UNIQUE (key);


--
-- TOC entry 4944 (class 2606 OID 16880)
-- Name: database_records database_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.database_records
    ADD CONSTRAINT database_records_pkey PRIMARY KEY (id);


--
-- TOC entry 4927 (class 2606 OID 16747)
-- Name: datatype_mapping datatype_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT datatype_mapping_pkey PRIMARY KEY (id);


--
-- TOC entry 4935 (class 2606 OID 16769)
-- Name: datatype_raw_mapping datatype_raw_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT datatype_raw_mapping_pkey PRIMARY KEY (id);


--
-- TOC entry 4923 (class 2606 OID 16730)
-- Name: datatype_standard datatype_standard_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_standard
    ADD CONSTRAINT datatype_standard_pkey PRIMARY KEY (id);


--
-- TOC entry 4925 (class 2606 OID 16732)
-- Name: datatype_standard datatype_standard_standard_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_standard
    ADD CONSTRAINT datatype_standard_standard_type_key UNIQUE (standard_type);


--
-- TOC entry 4952 (class 2606 OID 16989)
-- Name: mapping_rules mapping_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_rules
    ADD CONSTRAINT mapping_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 4947 (class 2606 OID 16894)
-- Name: session_records session_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.session_records
    ADD CONSTRAINT session_records_pkey PRIMARY KEY (id);


--
-- TOC entry 4949 (class 2606 OID 16911)
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (key);


--
-- TOC entry 4931 (class 2606 OID 16798)
-- Name: datatype_mapping uniq_final_mapping; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT uniq_final_mapping UNIQUE (db_id, standard_id);


--
-- TOC entry 4940 (class 2606 OID 16781)
-- Name: datatype_raw_mapping unique_mapping_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT unique_mapping_idx UNIQUE (db_id, raw_type, logical_type, source_type, standard_id);


--
-- TOC entry 4959 (class 2606 OID 17061)
-- Name: update_activities update_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.update_activities
    ADD CONSTRAINT update_activities_pkey PRIMARY KEY (id);


--
-- TOC entry 4933 (class 2606 OID 16944)
-- Name: datatype_mapping uq_datatype_mapping; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT uq_datatype_mapping UNIQUE (db_id, standard_id);


--
-- TOC entry 4954 (class 2606 OID 16991)
-- Name: mapping_rules uq_mapping_rules; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_rules
    ADD CONSTRAINT uq_mapping_rules UNIQUE (src_db, source_type, raw_type, dest_db, final_type);


--
-- TOC entry 4928 (class 1259 OID 17021)
-- Name: idx_mapping_db_standard; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mapping_db_standard ON public.datatype_mapping USING btree (db_id, standard_id);


--
-- TOC entry 4950 (class 1259 OID 16992)
-- Name: idx_mapping_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mapping_lookup ON public.mapping_rules USING btree (src_db, source_type, dest_db);


--
-- TOC entry 4936 (class 1259 OID 17022)
-- Name: idx_raw_mapping_db; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_raw_mapping_db ON public.datatype_raw_mapping USING btree (db_id);


--
-- TOC entry 4955 (class 1259 OID 17063)
-- Name: ix_activity_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_activity_action ON public.update_activities USING btree (action);


--
-- TOC entry 4956 (class 1259 OID 17064)
-- Name: ix_activity_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_activity_created_at ON public.update_activities USING btree (created_at);


--
-- TOC entry 4957 (class 1259 OID 17062)
-- Name: ix_activity_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_activity_user ON public.update_activities USING btree (username);


--
-- TOC entry 4964 (class 1259 OID 17088)
-- Name: ix_admin_user_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_admin_user_username ON public.admin_users USING btree (username);


--
-- TOC entry 4929 (class 1259 OID 16932)
-- Name: ix_datatype_mapping_db_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_datatype_mapping_db_id ON public.datatype_mapping USING btree (db_id);


--
-- TOC entry 4937 (class 1259 OID 16930)
-- Name: ix_raw_mapping_db_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_raw_mapping_db_id ON public.datatype_raw_mapping USING btree (db_id);


--
-- TOC entry 4938 (class 1259 OID 16931)
-- Name: ix_raw_mapping_standard_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_raw_mapping_standard_id ON public.datatype_raw_mapping USING btree (standard_id);


--
-- TOC entry 4945 (class 1259 OID 16925)
-- Name: uq_db_record_key_lower; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_db_record_key_lower ON public.database_records USING btree (lower((key)::text));


--
-- TOC entry 4970 (class 2620 OID 16935)
-- Name: datatype_mapping trg_datatype_mapping_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_datatype_mapping_updated_at BEFORE UPDATE ON public.datatype_mapping FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4971 (class 2620 OID 16934)
-- Name: datatype_raw_mapping trg_raw_mapping_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_raw_mapping_updated_at BEFORE UPDATE ON public.datatype_raw_mapping FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 4965 (class 2606 OID 17016)
-- Name: datatype_standard datatype_standard_is_alias_of_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_standard
    ADD CONSTRAINT datatype_standard_is_alias_of_fkey FOREIGN KEY (is_alias_of) REFERENCES public.datatype_standard(id);


--
-- TOC entry 4968 (class 2606 OID 17000)
-- Name: datatype_raw_mapping fk_db; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT fk_db FOREIGN KEY (db_id) REFERENCES public.database_records(id) ON UPDATE CASCADE;


--
-- TOC entry 4966 (class 2606 OID 16995)
-- Name: datatype_mapping fk_mapping_db; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT fk_mapping_db FOREIGN KEY (db_id) REFERENCES public.database_records(id) ON UPDATE CASCADE;


--
-- TOC entry 4967 (class 2606 OID 17005)
-- Name: datatype_mapping fk_mapping_standard; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT fk_mapping_standard FOREIGN KEY (standard_id) REFERENCES public.datatype_standard(id) ON UPDATE CASCADE;


--
-- TOC entry 4969 (class 2606 OID 17010)
-- Name: datatype_raw_mapping fk_standard; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT fk_standard FOREIGN KEY (standard_id) REFERENCES public.datatype_standard(id) ON UPDATE CASCADE;


-- Completed on 2026-05-26 14:03:45

--
-- PostgreSQL database dump complete
--

\unrestrict UN6EyRn5Oh1Ez2JwZ7oRlAmw96ZqaMCQanOetO9igQKVfcNhWI3OMfhSvrwfFa8

