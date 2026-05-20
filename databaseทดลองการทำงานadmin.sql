--
-- PostgreSQL database dump
--

\restrict gC32OTgET16mCUe7yxcJDcJb20AHEyiIJzfhpDl30qelPpOKZZE3npmyMqHwOYT

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-05-20 11:07:08

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 228 (class 1259 OID 16869)
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
-- TOC entry 227 (class 1259 OID 16868)
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
-- TOC entry 5088 (class 0 OID 0)
-- Dependencies: 227
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
-- TOC entry 225 (class 1259 OID 16733)
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
    notes text
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
-- TOC entry 226 (class 1259 OID 16758)
-- Name: datatype_raw_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.datatype_raw_mapping (
    id integer DEFAULT nextval('public.datatype_raw_mapping_id_seq'::regclass) NOT NULL,
    db_id integer NOT NULL,
    raw_type text NOT NULL,
    logical_type text NOT NULL,
    source_type character varying(50),
    standard_id integer,
    is_default boolean DEFAULT false
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
-- TOC entry 224 (class 1259 OID 16721)
-- Name: datatype_standard; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.datatype_standard (
    id integer DEFAULT nextval('public.datatype_standard_id_seq'::regclass) NOT NULL,
    standard_type character varying(100) NOT NULL,
    category character varying(50),
    description text
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
-- TOC entry 223 (class 1259 OID 16713)
-- Name: db_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.db_type (
    id integer DEFAULT nextval('public.db_type_id_seq'::regclass) NOT NULL,
    db_name character varying(50) NOT NULL
);


ALTER TABLE public.db_type OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16896)
-- Name: mapping_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mapping_rules (
    id integer NOT NULL,
    src_db character varying(50),
    source_type character varying(128),
    raw_type character varying(100),
    logical_type character varying(100),
    master_type character varying(100),
    dest_db character varying(50),
    final_type character varying(100),
    confidence integer,
    status character varying(20),
    updated date
);


ALTER TABLE public.mapping_rules OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16895)
-- Name: mapping_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mapping_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mapping_rules_id_seq OWNER TO postgres;

--
-- TOC entry 5089 (class 0 OID 0)
-- Dependencies: 230
-- Name: mapping_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mapping_rules_id_seq OWNED BY public.mapping_rules.id;


--
-- TOC entry 229 (class 1259 OID 16883)
-- Name: session_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.session_records (
    id character varying(64) NOT NULL,
    "user" character varying(128) NOT NULL,
    role character varying(32) NOT NULL,
    db character varying(64) NOT NULL,
    tables integer NOT NULL,
    ttl_minutes integer NOT NULL,
    created character varying(32) NOT NULL
);


ALTER TABLE public.session_records OWNER TO postgres;

--
-- TOC entry 4893 (class 2604 OID 16872)
-- Name: database_records id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.database_records ALTER COLUMN id SET DEFAULT nextval('public.database_records_id_seq'::regclass);


--
-- TOC entry 4894 (class 2604 OID 16899)
-- Name: mapping_rules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_rules ALTER COLUMN id SET DEFAULT nextval('public.mapping_rules_id_seq'::regclass);


--
-- TOC entry 5079 (class 0 OID 16869)
-- Dependencies: 228
-- Data for Name: database_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.database_records (id, key, name, version, status, enabled) FROM stdin;
1	sqlserver	SQL Server	2019	active	t
2	postgresql	PostgreSQL	15.x	active	t
3	mysql	MySQL	8.x	active	t
4	oracle	Oracle	19c	active	t
7	mongoDB	mongoDB	7.x	active	t
8	mariaDB	mariaDB	19c	active	t
\.


--
-- TOC entry 5076 (class 0 OID 16733)
-- Dependencies: 225
-- Data for Name: datatype_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datatype_mapping (id, db_id, standard_id, final_type, has_length, has_precision, has_scale, notes) FROM stdin;
1	1	1	int	f	f	f	\N
2	1	2	bigint	f	f	f	\N
3	1	3	decimal	f	t	t	\N
4	1	4	real	f	f	f	\N
5	1	5	float	f	f	f	\N
6	1	6	bit	f	f	f	\N
7	1	7	char	t	f	f	\N
8	1	8	varchar	t	f	f	\N
9	1	9	text	f	f	f	\N
10	1	10	date	f	f	f	\N
11	1	11	time	f	t	f	\N
12	1	13	varbinary	t	f	f	\N
13	1	14	uniqueidentifier	f	f	f	\N
14	1	16	xml	f	f	f	\N
15	1	17	tinyint	f	f	f	\N
16	1	18	smallint	f	f	f	\N
17	1	19	nvarchar	t	f	f	\N
18	1	20	nchar	t	f	f	\N
19	1	21	ntext	f	f	f	\N
20	1	22	datetime	f	f	f	\N
21	1	23	datetime2	f	t	f	\N
22	1	24	smalldatetime	f	f	f	\N
23	1	25	datetimeoffset	f	t	f	\N
24	2	1	integer	f	f	f	\N
25	2	2	bigint	f	f	f	\N
26	2	3	numeric	f	t	t	\N
27	2	4	real	f	f	f	\N
28	2	5	double precision	f	f	f	\N
29	2	6	boolean	f	f	f	\N
30	2	7	char	t	f	f	\N
31	2	8	varchar	t	f	f	\N
32	2	9	text	f	f	f	\N
33	2	10	date	f	f	f	\N
34	2	11	time	f	t	f	\N
35	2	12	timestamp	f	t	f	\N
36	2	13	bytea	f	f	f	\N
37	2	14	uuid	f	f	f	\N
38	2	15	jsonb	f	f	f	\N
39	2	16	xml	f	f	f	\N
40	3	1	int	f	f	f	\N
41	3	2	bigint	f	f	f	\N
42	3	3	decimal	f	t	t	\N
43	3	4	float	f	f	f	\N
44	3	5	double	f	f	f	\N
45	3	6	tinyint(1)	f	f	f	\N
46	3	7	char	t	f	f	\N
47	3	8	varchar	t	f	f	\N
48	3	9	text	f	f	f	\N
49	3	10	date	f	f	f	\N
50	3	11	time	f	t	f	\N
51	3	12	timestamp	f	t	f	\N
52	3	13	blob	f	f	f	\N
53	3	15	json	f	f	f	\N
54	4	1	number(10)	f	t	f	\N
55	4	2	number(19)	f	t	f	\N
56	4	3	number	f	t	t	\N
57	4	4	binary_float	f	f	f	\N
58	4	5	binary_double	f	f	f	\N
59	4	6	number(1)	f	f	f	\N
60	4	7	char	t	f	f	\N
61	4	8	varchar2	t	f	f	\N
62	4	9	clob	f	f	f	\N
63	4	12	timestamp	f	t	f	\N
64	4	13	blob	f	f	f	\N
65	4	16	xmltype	f	f	f	\N
66	1	12	datetime2	f	t	f	\N
67	1	15	nvarchar(max)	f	f	f	\N
68	2	22	timestamp	f	t	f	\N
69	3	14	char(36)	f	f	f	\N
70	3	16	text	f	f	f	\N
71	3	22	datetime	f	f	f	\N
72	4	14	varchar2(36)	f	f	f	\N
73	4	15	clob	f	f	f	\N
74	4	22	timestamp	f	t	f	\N
77	2	17	smallint	f	f	f	\N
78	2	18	smallint	f	f	f	\N
79	2	19	varchar	t	f	f	\N
80	2	20	char	t	f	f	\N
81	2	21	text	f	f	f	\N
83	2	23	timestamp	f	t	f	\N
84	2	24	timestamp	f	f	f	\N
85	2	25	timestamptz	f	f	f	\N
88	3	17	tinyint	f	f	f	\N
89	3	18	smallint	f	f	f	\N
90	3	19	varchar	t	f	f	\N
91	3	20	char	t	f	f	\N
92	3	21	text	f	f	f	\N
94	3	23	datetime	f	f	f	\N
95	3	24	datetime	f	f	f	\N
97	4	10	date	f	f	f	\N
98	4	11	timestamp	f	t	f	\N
101	4	17	number(3)	f	f	f	\N
102	4	18	number(5)	f	f	f	\N
103	4	19	nvarchar2	t	f	f	\N
104	4	20	nchar	t	f	f	\N
105	4	21	nclob	f	f	f	\N
107	4	23	timestamp	f	t	f	\N
108	4	24	date	f	f	f	\N
109	4	25	timestamp with time zone	f	f	f	\N
145	1	26	geometry	f	f	f	\N
146	2	26	geometry	f	f	f	\N
147	3	26	geometry	f	f	f	\N
148	4	26	sdo_geometry	f	f	f	\N
96	3	25	datetime	f	f	f	\N
149	1	27	varchar	t	f	f	\N
150	2	27	interval	f	f	f	\N
151	3	27	varchar	t	f	f	\N
152	4	27	interval day to second	f	t	f	\N
153	1	28	varchar	t	f	f	\N
154	2	28	inet	f	f	f	\N
155	3	28	varchar	t	f	f	\N
156	4	28	varchar2	t	f	f	\N
157	1	29	varchar	t	f	f	\N
158	2	29	varchar	t	f	f	\N
159	3	29	enum	f	f	f	\N
160	4	29	varchar2	t	f	f	\N
\.


--
-- TOC entry 5077 (class 0 OID 16758)
-- Dependencies: 226
-- Data for Name: datatype_raw_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datatype_raw_mapping (id, db_id, raw_type, logical_type, source_type, standard_id, is_default) FROM stdin;
155	2	int	int	smallint	18	f
156	2	long	timestamp-millis	timestamptz	25	f
17	2	string	json	jsonb	15	f
27	3	string	json	json	15	f
36	4	string	xml	xmltype	16	f
60	2	string	xml	xml	16	f
2	1	long	long	bigint	2	f
3	1	bytes	decimal	decimal	3	f
4	1	float	float	real	4	f
5	1	double	double	float	5	f
6	1	boolean	boolean	bit	6	f
8	1	string	uuid	uniqueidentifier	14	f
9	1	long	timestamp-millis	datetime	22	f
11	2	long	long	bigint	2	f
12	2	bytes	decimal	numeric	3	f
13	2	float	float	real	4	f
14	2	double	double	double precision	5	f
15	2	boolean	boolean	boolean	6	f
18	2	string	uuid	uuid	14	f
21	3	long	long	bigint	2	f
22	3	bytes	decimal	decimal	3	f
23	3	float	float	float	4	f
24	3	double	double	double	5	f
25	3	boolean	boolean	tinyint(1)	6	f
52	1	string	datetime-offset	datetimeoffset	25	f
40	1	int	date	date	10	f
153	4	string	interval	interval day to second	27	f
154	4	string	interval	interval year to month	27	f
57	2	int	date	date	10	f
63	3	int	date	date	10	f
146	3	int	date	year	10	f
41	1	int	time	time	11	f
157	1	string	json	json	15	f
58	2	long	time	time	11	f
64	3	int	time	time	11	f
44	1	string	xml	xml	16	f
30	4	long	long	number(19)	2	f
31	4	bytes	decimal	number	3	f
32	4	float	float	binary_float	4	f
33	4	double	double	binary_double	5	f
34	4	boolean	boolean	number(1)	6	f
38	1	string	string	char	7	f
39	1	string	string	text	9	f
45	1	int	int	tinyint	17	f
46	1	int	int	smallint	18	f
47	1	string	string	nvarchar	19	f
48	1	string	string	nchar	20	f
49	1	string	string	ntext	21	f
50	1	long	timestamp-micros	datetime2	23	f
51	1	long	timestamp-millis	smalldatetime	24	f
53	1	bytes	decimal	money	3	f
54	1	bytes	decimal	smallmoney	3	f
55	2	string	string	char	7	f
56	2	string	string	text	9	f
61	3	string	string	char	7	f
62	3	string	string	text	9	f
67	4	string	string	char	7	f
68	4	string	string	clob	9	f
70	4	long	timestamp-millis	date	22	f
137	1	string	spatial	geometry	26	f
138	1	string	spatial	geography	26	f
140	2	string	interval	interval	27	f
141	2	string	network	inet	28	f
142	2	string	network	cidr	28	f
143	2	string	network	macaddr	28	f
144	2	string	spatial	geometry	26	f
147	3	string	enum	enum	29	f
148	3	string	enum	set	29	f
151	4	string	string	long	9	f
7	1	string	string	varchar	8	t
16	2	string	string	varchar	8	t
26	3	string	string	varchar	8	t
35	4	string	string	varchar2	8	t
139	1	string	string	hierarchyid	8	t
1	1	int	int	int	1	t
10	2	int	int	integer	1	t
20	3	int	int	int	1	t
29	4	int	int	number(10)	1	t
145	3	int	int	mediumint	1	t
19	2	long	timestamp-micros	timestamp	12	t
28	3	long	timestamp-millis	timestamp	12	t
37	4	long	timestamp-micros	timestamp	12	t
158	2	string	enum	enum	29	f
160	3	long	timestamp-micros	datetime(6)	12	f
161	3	int	int	tinyint	17	f
162	3	int	int	smallint	18	f
163	3	string	string	nvarchar	19	f
164	3	string	uuid	char(36)	14	f
152	4	bytes	bytes	bfile	13	t
42	1	bytes	bytes	binary	13	t
165	4	string	json	json	15	f
166	4	string	spatial	sdo_geometry	26	f
167	4	string	uuid	raw(16)	14	f
168	4	int	int	smallint	18	f
169	1	bytes	bytes	timestamp	12	f
43	1	bytes	bytes	varbinary	13	t
59	2	bytes	bytes	bytea	13	t
65	3	bytes	bytes	binary	13	t
66	3	bytes	bytes	blob	13	t
183	3	long	timestamp-millis	datetime	22	f
186	3	string	datetime-offset	varchar(35)	25	f
187	3	string	spatial	geometry	26	f
69	4	bytes	bytes	blob	13	t
149	4	bytes	bytes	raw	13	t
190	4	int	date	date	10	f
150	4	bytes	bytes	long raw	13	t
194	4	int	int	number(3)	17	f
195	4	string	string	nvarchar2	19	f
196	4	string	string	nchar	20	f
197	4	string	string	nclob	21	f
200	4	string	datetime-offset	timestamp with time zone	25	f
\.


--
-- TOC entry 5075 (class 0 OID 16721)
-- Dependencies: 224
-- Data for Name: datatype_standard; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datatype_standard (id, standard_type, category, description) FROM stdin;
1	INTEGER	numeric	\N
2	BIGINT	numeric	\N
3	DECIMAL	numeric	\N
4	FLOAT	numeric	\N
5	DOUBLE PRECISION	numeric	\N
6	BOOLEAN	boolean	\N
7	CHAR	string	\N
8	VARCHAR	string	\N
9	TEXT	string	\N
10	DATE	datetime	\N
11	TIME	datetime	\N
12	TIMESTAMP	datetime	\N
13	BINARY	binary	\N
14	UUID	other	\N
15	JSON	other	\N
16	XML	other	\N
17	TINYINT	numeric	\N
18	SMALLINT	numeric	\N
19	NVARCHAR	string	\N
20	NCHAR	string	\N
21	NTEXT	string	\N
22	DATETIME	datetime	\N
23	DATETIME2	datetime	\N
24	SMALLDATETIME	datetime	\N
25	DATETIMEOFFSET	datetime	\N
26	GEOMETRY	spatial	Spatial and geometry data (e.g., points, polygons)
27	INTERVAL	datetime	Time span or interval
28	NETWORK	other	IP addresses and network types (e.g., INET, CIDR)
29	ENUM	other	Enumerated list of values or sets
\.


--
-- TOC entry 5074 (class 0 OID 16713)
-- Dependencies: 223
-- Data for Name: db_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.db_type (id, db_name) FROM stdin;
1	sqlserver
2	postgresql
3	mysql
4	oracle
\.


--
-- TOC entry 5082 (class 0 OID 16896)
-- Dependencies: 231
-- Data for Name: mapping_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mapping_rules (id, src_db, source_type, raw_type, logical_type, master_type, dest_db, final_type, confidence, status, updated) FROM stdin;
1	postgresql	smallint	int	int	SMALLINT	sqlserver	smallint	100	active	2026-05-19
2	postgresql	smallint	int	int	SMALLINT	mysql	smallint	100	active	2026-05-19
3	postgresql	smallint	int	int	SMALLINT	oracle	number(5)	100	active	2026-05-19
4	postgresql	timestamptz	long	timestamp-millis	DATETIMEOFFSET	sqlserver	datetimeoffset	100	active	2026-05-19
5	postgresql	timestamptz	long	timestamp-millis	DATETIMEOFFSET	mysql	datetime	100	active	2026-05-19
6	postgresql	timestamptz	long	timestamp-millis	DATETIMEOFFSET	oracle	timestamp with time zone	100	active	2026-05-19
7	postgresql	jsonb	string	json	JSON	sqlserver	nvarchar(max)	100	active	2026-05-19
8	postgresql	jsonb	string	json	JSON	mysql	json	100	active	2026-05-19
9	postgresql	jsonb	string	json	JSON	oracle	clob	100	active	2026-05-19
10	mysql	json	string	json	JSON	sqlserver	nvarchar(max)	100	active	2026-05-19
11	mysql	json	string	json	JSON	postgresql	jsonb	100	active	2026-05-19
12	mysql	json	string	json	JSON	oracle	clob	100	active	2026-05-19
13	oracle	xmltype	string	xml	XML	sqlserver	xml	100	active	2026-05-19
14	oracle	xmltype	string	xml	XML	postgresql	xml	100	active	2026-05-19
15	oracle	xmltype	string	xml	XML	mysql	text	100	active	2026-05-19
16	postgresql	xml	string	xml	XML	sqlserver	xml	100	active	2026-05-19
17	postgresql	xml	string	xml	XML	mysql	text	100	active	2026-05-19
18	postgresql	xml	string	xml	XML	oracle	xmltype	100	active	2026-05-19
19	sqlserver	bigint	long	long	BIGINT	postgresql	bigint	100	active	2026-05-19
20	sqlserver	bigint	long	long	BIGINT	mysql	bigint	100	active	2026-05-19
21	sqlserver	bigint	long	long	BIGINT	oracle	number(19)	100	active	2026-05-19
22	sqlserver	decimal	bytes	decimal	DECIMAL	postgresql	numeric	100	active	2026-05-19
23	sqlserver	decimal	bytes	decimal	DECIMAL	mysql	decimal	100	active	2026-05-19
24	sqlserver	decimal	bytes	decimal	DECIMAL	oracle	number	100	active	2026-05-19
25	sqlserver	real	float	float	FLOAT	postgresql	real	100	active	2026-05-19
26	sqlserver	real	float	float	FLOAT	mysql	float	100	active	2026-05-19
27	sqlserver	real	float	float	FLOAT	oracle	binary_float	100	active	2026-05-19
28	sqlserver	float	double	double	DOUBLE PRECISION	postgresql	double precision	100	active	2026-05-19
29	sqlserver	float	double	double	DOUBLE PRECISION	mysql	double	100	active	2026-05-19
30	sqlserver	float	double	double	DOUBLE PRECISION	oracle	binary_double	100	active	2026-05-19
31	sqlserver	bit	boolean	boolean	BOOLEAN	postgresql	boolean	100	active	2026-05-19
32	sqlserver	bit	boolean	boolean	BOOLEAN	mysql	tinyint(1)	100	active	2026-05-19
33	sqlserver	bit	boolean	boolean	BOOLEAN	oracle	number(1)	100	active	2026-05-19
34	sqlserver	uniqueidentifier	string	uuid	UUID	postgresql	uuid	100	active	2026-05-19
35	sqlserver	uniqueidentifier	string	uuid	UUID	mysql	char(36)	100	active	2026-05-19
36	sqlserver	uniqueidentifier	string	uuid	UUID	oracle	varchar2(36)	100	active	2026-05-19
37	sqlserver	datetime	long	timestamp-millis	DATETIME	postgresql	timestamp	100	active	2026-05-19
38	sqlserver	datetime	long	timestamp-millis	DATETIME	mysql	datetime	100	active	2026-05-19
39	sqlserver	datetime	long	timestamp-millis	DATETIME	oracle	timestamp	100	active	2026-05-19
40	postgresql	bigint	long	long	BIGINT	sqlserver	bigint	100	active	2026-05-19
41	postgresql	bigint	long	long	BIGINT	mysql	bigint	100	active	2026-05-19
42	postgresql	bigint	long	long	BIGINT	oracle	number(19)	100	active	2026-05-19
43	postgresql	integer	int	int	INTEGER	sqlserver	int	100	active	2026-05-19
44	postgresql	integer	int	int	INTEGER	mysql	int	100	active	2026-05-19
45	postgresql	integer	int	int	INTEGER	oracle	number(10)	100	active	2026-05-19
46	mysql	int	int	int	INTEGER	sqlserver	int	100	active	2026-05-19
47	mysql	int	int	int	INTEGER	postgresql	integer	100	active	2026-05-19
48	mysql	int	int	int	INTEGER	oracle	number(10)	100	active	2026-05-19
49	oracle	number(10)	int	int	INTEGER	sqlserver	int	100	active	2026-05-19
50	oracle	number(10)	int	int	INTEGER	postgresql	integer	100	active	2026-05-19
51	oracle	number(10)	int	int	INTEGER	mysql	int	100	active	2026-05-19
52	mysql	timestamp	long	timestamp-millis	TIMESTAMP	sqlserver	datetime2	100	active	2026-05-19
53	mysql	timestamp	long	timestamp-millis	TIMESTAMP	postgresql	timestamp	100	active	2026-05-19
54	mysql	timestamp	long	timestamp-millis	TIMESTAMP	oracle	timestamp	100	active	2026-05-19
55	mysql	decimal	bytes	decimal	DECIMAL	sqlserver	decimal	100	active	2026-05-19
56	mysql	decimal	bytes	decimal	DECIMAL	postgresql	numeric	100	active	2026-05-19
57	mysql	decimal	bytes	decimal	DECIMAL	oracle	number	100	active	2026-05-19
58	mysql	float	float	float	FLOAT	sqlserver	real	100	active	2026-05-19
59	mysql	float	float	float	FLOAT	postgresql	real	100	active	2026-05-19
60	mysql	float	float	float	FLOAT	oracle	binary_float	100	active	2026-05-19
61	mysql	double	double	double	DOUBLE PRECISION	sqlserver	float	100	active	2026-05-19
62	mysql	double	double	double	DOUBLE PRECISION	postgresql	double precision	100	active	2026-05-19
63	mysql	double	double	double	DOUBLE PRECISION	oracle	binary_double	100	active	2026-05-19
64	mysql	tinyint(1)	boolean	boolean	BOOLEAN	sqlserver	bit	100	active	2026-05-19
65	mysql	tinyint(1)	boolean	boolean	BOOLEAN	postgresql	boolean	100	active	2026-05-19
66	mysql	tinyint(1)	boolean	boolean	BOOLEAN	oracle	number(1)	100	active	2026-05-19
67	sqlserver	datetimeoffset	string	datetime-offset	DATETIMEOFFSET	postgresql	timestamptz	100	active	2026-05-19
68	sqlserver	datetimeoffset	string	datetime-offset	DATETIMEOFFSET	mysql	datetime	100	active	2026-05-19
69	sqlserver	datetimeoffset	string	datetime-offset	DATETIMEOFFSET	oracle	timestamp with time zone	100	active	2026-05-19
70	sqlserver	date	int	date	DATE	postgresql	date	100	active	2026-05-19
71	sqlserver	date	int	date	DATE	mysql	date	100	active	2026-05-19
72	sqlserver	date	int	date	DATE	oracle	date	100	active	2026-05-19
73	oracle	interval day to second	string	interval	INTERVAL	sqlserver	varchar	100	active	2026-05-19
74	oracle	interval day to second	string	interval	INTERVAL	postgresql	interval	100	active	2026-05-19
75	oracle	interval day to second	string	interval	INTERVAL	mysql	varchar	100	active	2026-05-19
76	oracle	interval year to month	string	interval	INTERVAL	sqlserver	varchar	100	active	2026-05-19
77	oracle	interval year to month	string	interval	INTERVAL	postgresql	interval	100	active	2026-05-19
78	oracle	interval year to month	string	interval	INTERVAL	mysql	varchar	100	active	2026-05-19
79	postgresql	date	int	date	DATE	sqlserver	date	100	active	2026-05-19
80	postgresql	date	int	date	DATE	mysql	date	100	active	2026-05-19
81	postgresql	date	int	date	DATE	oracle	date	100	active	2026-05-19
82	mysql	date	int	date	DATE	sqlserver	date	100	active	2026-05-19
83	mysql	date	int	date	DATE	postgresql	date	100	active	2026-05-19
84	mysql	date	int	date	DATE	oracle	date	100	active	2026-05-19
85	mysql	year	int	date	DATE	sqlserver	date	100	active	2026-05-19
86	mysql	year	int	date	DATE	postgresql	date	100	active	2026-05-19
87	mysql	year	int	date	DATE	oracle	date	100	active	2026-05-19
88	sqlserver	time	int	time	TIME	postgresql	time	100	active	2026-05-19
89	sqlserver	time	int	time	TIME	mysql	time	100	active	2026-05-19
90	sqlserver	time	int	time	TIME	oracle	timestamp	100	active	2026-05-19
91	sqlserver	json	string	json	JSON	postgresql	jsonb	100	active	2026-05-19
92	sqlserver	json	string	json	JSON	mysql	json	100	active	2026-05-19
93	sqlserver	json	string	json	JSON	oracle	clob	100	active	2026-05-19
94	postgresql	time	long	time	TIME	sqlserver	time	100	active	2026-05-19
95	postgresql	time	long	time	TIME	mysql	time	100	active	2026-05-19
96	postgresql	time	long	time	TIME	oracle	timestamp	100	active	2026-05-19
97	mysql	time	int	time	TIME	sqlserver	time	100	active	2026-05-19
98	mysql	time	int	time	TIME	postgresql	time	100	active	2026-05-19
99	mysql	time	int	time	TIME	oracle	timestamp	100	active	2026-05-19
100	sqlserver	xml	string	xml	XML	postgresql	xml	100	active	2026-05-19
101	sqlserver	xml	string	xml	XML	mysql	text	100	active	2026-05-19
102	sqlserver	xml	string	xml	XML	oracle	xmltype	100	active	2026-05-19
103	oracle	number(19)	long	long	BIGINT	sqlserver	bigint	100	active	2026-05-19
104	oracle	number(19)	long	long	BIGINT	postgresql	bigint	100	active	2026-05-19
105	oracle	number(19)	long	long	BIGINT	mysql	bigint	100	active	2026-05-19
106	oracle	number	bytes	decimal	DECIMAL	sqlserver	decimal	100	active	2026-05-19
107	oracle	number	bytes	decimal	DECIMAL	postgresql	numeric	100	active	2026-05-19
108	oracle	number	bytes	decimal	DECIMAL	mysql	decimal	100	active	2026-05-19
109	oracle	binary_float	float	float	FLOAT	sqlserver	real	100	active	2026-05-19
110	oracle	binary_float	float	float	FLOAT	postgresql	real	100	active	2026-05-19
111	oracle	binary_float	float	float	FLOAT	mysql	float	100	active	2026-05-19
112	oracle	binary_double	double	double	DOUBLE PRECISION	sqlserver	float	100	active	2026-05-19
113	oracle	binary_double	double	double	DOUBLE PRECISION	postgresql	double precision	100	active	2026-05-19
114	oracle	binary_double	double	double	DOUBLE PRECISION	mysql	double	100	active	2026-05-19
115	oracle	number(1)	boolean	boolean	BOOLEAN	sqlserver	bit	100	active	2026-05-19
116	oracle	number(1)	boolean	boolean	BOOLEAN	postgresql	boolean	100	active	2026-05-19
117	oracle	number(1)	boolean	boolean	BOOLEAN	mysql	tinyint(1)	100	active	2026-05-19
118	sqlserver	char	string	string	CHAR	postgresql	char	100	active	2026-05-19
119	sqlserver	char	string	string	CHAR	mysql	char	100	active	2026-05-19
120	sqlserver	char	string	string	CHAR	oracle	char	100	active	2026-05-19
121	sqlserver	text	string	string	TEXT	postgresql	text	100	active	2026-05-19
122	sqlserver	text	string	string	TEXT	mysql	text	100	active	2026-05-19
123	sqlserver	text	string	string	TEXT	oracle	clob	100	active	2026-05-19
124	sqlserver	tinyint	int	int	TINYINT	postgresql	smallint	100	active	2026-05-19
125	sqlserver	tinyint	int	int	TINYINT	mysql	tinyint	100	active	2026-05-19
126	sqlserver	tinyint	int	int	TINYINT	oracle	number(3)	100	active	2026-05-19
127	sqlserver	smallint	int	int	SMALLINT	postgresql	smallint	100	active	2026-05-19
128	sqlserver	smallint	int	int	SMALLINT	mysql	smallint	100	active	2026-05-19
129	sqlserver	smallint	int	int	SMALLINT	oracle	number(5)	100	active	2026-05-19
130	sqlserver	nvarchar	string	string	NVARCHAR	postgresql	varchar	100	active	2026-05-19
131	sqlserver	nvarchar	string	string	NVARCHAR	mysql	varchar	100	active	2026-05-19
132	sqlserver	nvarchar	string	string	NVARCHAR	oracle	nvarchar2	100	active	2026-05-19
133	sqlserver	nchar	string	string	NCHAR	postgresql	char	100	active	2026-05-19
134	sqlserver	nchar	string	string	NCHAR	mysql	char	100	active	2026-05-19
135	sqlserver	nchar	string	string	NCHAR	oracle	nchar	100	active	2026-05-19
136	sqlserver	ntext	string	string	NTEXT	postgresql	text	100	active	2026-05-19
137	sqlserver	ntext	string	string	NTEXT	mysql	text	100	active	2026-05-19
138	sqlserver	ntext	string	string	NTEXT	oracle	nclob	100	active	2026-05-19
139	sqlserver	datetime2	long	timestamp-micros	DATETIME2	postgresql	timestamp	100	active	2026-05-19
140	sqlserver	datetime2	long	timestamp-micros	DATETIME2	mysql	datetime	100	active	2026-05-19
141	sqlserver	datetime2	long	timestamp-micros	DATETIME2	oracle	timestamp	100	active	2026-05-19
142	sqlserver	smalldatetime	long	timestamp-millis	SMALLDATETIME	postgresql	timestamp	100	active	2026-05-19
143	sqlserver	smalldatetime	long	timestamp-millis	SMALLDATETIME	mysql	datetime	100	active	2026-05-19
144	sqlserver	smalldatetime	long	timestamp-millis	SMALLDATETIME	oracle	date	100	active	2026-05-19
145	sqlserver	money	bytes	decimal	DECIMAL	postgresql	numeric	100	active	2026-05-19
146	sqlserver	money	bytes	decimal	DECIMAL	mysql	decimal	100	active	2026-05-19
147	sqlserver	money	bytes	decimal	DECIMAL	oracle	number	100	active	2026-05-19
148	sqlserver	smallmoney	bytes	decimal	DECIMAL	postgresql	numeric	100	active	2026-05-19
149	sqlserver	smallmoney	bytes	decimal	DECIMAL	mysql	decimal	100	active	2026-05-19
150	sqlserver	smallmoney	bytes	decimal	DECIMAL	oracle	number	100	active	2026-05-19
151	postgresql	char	string	string	CHAR	sqlserver	char	100	active	2026-05-19
152	postgresql	char	string	string	CHAR	mysql	char	100	active	2026-05-19
153	postgresql	char	string	string	CHAR	oracle	char	100	active	2026-05-19
154	postgresql	text	string	string	TEXT	sqlserver	text	100	active	2026-05-19
155	postgresql	text	string	string	TEXT	mysql	text	100	active	2026-05-19
156	postgresql	text	string	string	TEXT	oracle	clob	100	active	2026-05-19
157	mysql	char	string	string	CHAR	sqlserver	char	100	active	2026-05-19
158	mysql	char	string	string	CHAR	postgresql	char	100	active	2026-05-19
159	mysql	char	string	string	CHAR	oracle	char	100	active	2026-05-19
160	mysql	text	string	string	TEXT	sqlserver	text	100	active	2026-05-19
161	mysql	text	string	string	TEXT	postgresql	text	100	active	2026-05-19
162	mysql	text	string	string	TEXT	oracle	clob	100	active	2026-05-19
163	oracle	char	string	string	CHAR	sqlserver	char	100	active	2026-05-19
164	oracle	char	string	string	CHAR	postgresql	char	100	active	2026-05-19
165	oracle	char	string	string	CHAR	mysql	char	100	active	2026-05-19
166	oracle	clob	string	string	TEXT	sqlserver	text	100	active	2026-05-19
167	oracle	clob	string	string	TEXT	postgresql	text	100	active	2026-05-19
168	oracle	clob	string	string	TEXT	mysql	text	100	active	2026-05-19
169	oracle	date	long	timestamp-millis	DATETIME	sqlserver	datetime	100	active	2026-05-19
170	oracle	date	long	timestamp-millis	DATETIME	postgresql	timestamp	100	active	2026-05-19
171	oracle	date	long	timestamp-millis	DATETIME	mysql	datetime	100	active	2026-05-19
172	sqlserver	geometry	string	spatial	GEOMETRY	postgresql	geometry	100	active	2026-05-19
173	sqlserver	geometry	string	spatial	GEOMETRY	mysql	geometry	100	active	2026-05-19
174	sqlserver	geometry	string	spatial	GEOMETRY	oracle	sdo_geometry	100	active	2026-05-19
175	sqlserver	geography	string	spatial	GEOMETRY	postgresql	geometry	100	active	2026-05-19
176	sqlserver	geography	string	spatial	GEOMETRY	mysql	geometry	100	active	2026-05-19
177	sqlserver	geography	string	spatial	GEOMETRY	oracle	sdo_geometry	100	active	2026-05-19
178	postgresql	interval	string	interval	INTERVAL	sqlserver	varchar	100	active	2026-05-19
179	postgresql	interval	string	interval	INTERVAL	mysql	varchar	100	active	2026-05-19
180	postgresql	interval	string	interval	INTERVAL	oracle	interval day to second	100	active	2026-05-19
181	postgresql	inet	string	network	NETWORK	sqlserver	varchar	100	active	2026-05-19
182	postgresql	inet	string	network	NETWORK	mysql	varchar	100	active	2026-05-19
183	postgresql	inet	string	network	NETWORK	oracle	varchar2	100	active	2026-05-19
184	postgresql	cidr	string	network	NETWORK	sqlserver	varchar	100	active	2026-05-19
185	postgresql	cidr	string	network	NETWORK	mysql	varchar	100	active	2026-05-19
186	postgresql	cidr	string	network	NETWORK	oracle	varchar2	100	active	2026-05-19
187	postgresql	macaddr	string	network	NETWORK	sqlserver	varchar	100	active	2026-05-19
188	postgresql	macaddr	string	network	NETWORK	mysql	varchar	100	active	2026-05-19
189	postgresql	macaddr	string	network	NETWORK	oracle	varchar2	100	active	2026-05-19
190	postgresql	geometry	string	spatial	GEOMETRY	sqlserver	geometry	100	active	2026-05-19
191	postgresql	geometry	string	spatial	GEOMETRY	mysql	geometry	100	active	2026-05-19
192	postgresql	geometry	string	spatial	GEOMETRY	oracle	sdo_geometry	100	active	2026-05-19
193	mysql	enum	string	enum	ENUM	sqlserver	varchar	100	active	2026-05-19
194	mysql	enum	string	enum	ENUM	postgresql	varchar	100	active	2026-05-19
195	mysql	enum	string	enum	ENUM	oracle	varchar2	100	active	2026-05-19
196	mysql	set	string	enum	ENUM	sqlserver	varchar	100	active	2026-05-19
197	mysql	set	string	enum	ENUM	postgresql	varchar	100	active	2026-05-19
198	mysql	set	string	enum	ENUM	oracle	varchar2	100	active	2026-05-19
199	oracle	long	string	string	TEXT	sqlserver	text	100	active	2026-05-19
200	oracle	long	string	string	TEXT	postgresql	text	100	active	2026-05-19
201	oracle	long	string	string	TEXT	mysql	text	100	active	2026-05-19
202	sqlserver	varchar	string	string	VARCHAR	postgresql	varchar	100	active	2026-05-19
203	sqlserver	varchar	string	string	VARCHAR	mysql	varchar	100	active	2026-05-19
204	sqlserver	varchar	string	string	VARCHAR	oracle	varchar2	100	active	2026-05-19
205	postgresql	varchar	string	string	VARCHAR	sqlserver	varchar	100	active	2026-05-19
206	postgresql	varchar	string	string	VARCHAR	mysql	varchar	100	active	2026-05-19
207	postgresql	varchar	string	string	VARCHAR	oracle	varchar2	100	active	2026-05-19
208	mysql	varchar	string	string	VARCHAR	sqlserver	varchar	100	active	2026-05-19
209	mysql	varchar	string	string	VARCHAR	postgresql	varchar	100	active	2026-05-19
210	mysql	varchar	string	string	VARCHAR	oracle	varchar2	100	active	2026-05-19
211	oracle	varchar2	string	string	VARCHAR	sqlserver	varchar	100	active	2026-05-19
212	oracle	varchar2	string	string	VARCHAR	postgresql	varchar	100	active	2026-05-19
213	oracle	varchar2	string	string	VARCHAR	mysql	varchar	100	active	2026-05-19
214	sqlserver	hierarchyid	string	string	VARCHAR	postgresql	varchar	100	active	2026-05-19
215	sqlserver	hierarchyid	string	string	VARCHAR	mysql	varchar	100	active	2026-05-19
216	sqlserver	hierarchyid	string	string	VARCHAR	oracle	varchar2	100	active	2026-05-19
217	sqlserver	int	int	int	INTEGER	postgresql	integer	100	active	2026-05-19
218	sqlserver	int	int	int	INTEGER	mysql	int	100	active	2026-05-19
219	sqlserver	int	int	int	INTEGER	oracle	number(10)	100	active	2026-05-19
220	mysql	mediumint	int	int	INTEGER	sqlserver	int	100	active	2026-05-19
221	mysql	mediumint	int	int	INTEGER	postgresql	integer	100	active	2026-05-19
222	mysql	mediumint	int	int	INTEGER	oracle	number(10)	100	active	2026-05-19
223	postgresql	timestamp	long	timestamp-micros	TIMESTAMP	sqlserver	datetime2	100	active	2026-05-19
224	postgresql	timestamp	long	timestamp-micros	TIMESTAMP	mysql	timestamp	100	active	2026-05-19
225	postgresql	timestamp	long	timestamp-micros	TIMESTAMP	oracle	timestamp	100	active	2026-05-19
226	oracle	timestamp	long	timestamp-micros	TIMESTAMP	sqlserver	datetime2	100	active	2026-05-19
227	oracle	timestamp	long	timestamp-micros	TIMESTAMP	postgresql	timestamp	100	active	2026-05-19
228	oracle	timestamp	long	timestamp-micros	TIMESTAMP	mysql	timestamp	100	active	2026-05-19
229	postgresql	enum	string	enum	ENUM	sqlserver	varchar	100	active	2026-05-19
230	postgresql	enum	string	enum	ENUM	mysql	enum	100	active	2026-05-19
231	postgresql	enum	string	enum	ENUM	oracle	varchar2	100	active	2026-05-19
232	mysql	datetime(6)	long	timestamp-micros	TIMESTAMP	sqlserver	datetime2	100	active	2026-05-19
233	mysql	datetime(6)	long	timestamp-micros	TIMESTAMP	postgresql	timestamp	100	active	2026-05-19
234	mysql	datetime(6)	long	timestamp-micros	TIMESTAMP	oracle	timestamp	100	active	2026-05-19
235	mysql	tinyint	int	int	TINYINT	sqlserver	tinyint	100	active	2026-05-19
236	mysql	tinyint	int	int	TINYINT	postgresql	smallint	100	active	2026-05-19
237	mysql	tinyint	int	int	TINYINT	oracle	number(3)	100	active	2026-05-19
238	mysql	smallint	int	int	SMALLINT	sqlserver	smallint	100	active	2026-05-19
239	mysql	smallint	int	int	SMALLINT	postgresql	smallint	100	active	2026-05-19
240	mysql	smallint	int	int	SMALLINT	oracle	number(5)	100	active	2026-05-19
241	mysql	nvarchar	string	string	NVARCHAR	sqlserver	nvarchar	100	active	2026-05-19
242	mysql	nvarchar	string	string	NVARCHAR	postgresql	varchar	100	active	2026-05-19
243	mysql	nvarchar	string	string	NVARCHAR	oracle	nvarchar2	100	active	2026-05-19
244	mysql	char(36)	string	uuid	UUID	sqlserver	uniqueidentifier	100	active	2026-05-19
245	mysql	char(36)	string	uuid	UUID	postgresql	uuid	100	active	2026-05-19
246	mysql	char(36)	string	uuid	UUID	oracle	varchar2(36)	100	active	2026-05-19
247	oracle	bfile	bytes	bytes	BINARY	sqlserver	varbinary	100	active	2026-05-19
248	oracle	bfile	bytes	bytes	BINARY	postgresql	bytea	100	active	2026-05-19
249	oracle	bfile	bytes	bytes	BINARY	mysql	blob	100	active	2026-05-19
250	sqlserver	binary	bytes	bytes	BINARY	postgresql	bytea	100	active	2026-05-19
251	sqlserver	binary	bytes	bytes	BINARY	mysql	blob	100	active	2026-05-19
252	sqlserver	binary	bytes	bytes	BINARY	oracle	blob	100	active	2026-05-19
253	oracle	json	string	json	JSON	sqlserver	nvarchar(max)	100	active	2026-05-19
254	oracle	json	string	json	JSON	postgresql	jsonb	100	active	2026-05-19
255	oracle	json	string	json	JSON	mysql	json	100	active	2026-05-19
256	oracle	sdo_geometry	string	spatial	GEOMETRY	sqlserver	geometry	100	active	2026-05-19
257	oracle	sdo_geometry	string	spatial	GEOMETRY	postgresql	geometry	100	active	2026-05-19
258	oracle	sdo_geometry	string	spatial	GEOMETRY	mysql	geometry	100	active	2026-05-19
259	oracle	raw(16)	string	uuid	UUID	sqlserver	uniqueidentifier	100	active	2026-05-19
260	oracle	raw(16)	string	uuid	UUID	postgresql	uuid	100	active	2026-05-19
261	oracle	raw(16)	string	uuid	UUID	mysql	char(36)	100	active	2026-05-19
262	oracle	smallint	int	int	SMALLINT	sqlserver	smallint	100	active	2026-05-19
263	oracle	smallint	int	int	SMALLINT	postgresql	smallint	100	active	2026-05-19
264	oracle	smallint	int	int	SMALLINT	mysql	smallint	100	active	2026-05-19
265	sqlserver	timestamp	bytes	bytes	TIMESTAMP	postgresql	timestamp	100	active	2026-05-19
266	sqlserver	timestamp	bytes	bytes	TIMESTAMP	mysql	timestamp	100	active	2026-05-19
267	sqlserver	timestamp	bytes	bytes	TIMESTAMP	oracle	timestamp	100	active	2026-05-19
268	sqlserver	varbinary	bytes	bytes	BINARY	postgresql	bytea	100	active	2026-05-19
269	sqlserver	varbinary	bytes	bytes	BINARY	mysql	blob	100	active	2026-05-19
270	sqlserver	varbinary	bytes	bytes	BINARY	oracle	blob	100	active	2026-05-19
271	postgresql	bytea	bytes	bytes	BINARY	sqlserver	varbinary	100	active	2026-05-19
272	postgresql	bytea	bytes	bytes	BINARY	mysql	blob	100	active	2026-05-19
273	postgresql	bytea	bytes	bytes	BINARY	oracle	blob	100	active	2026-05-19
274	mysql	binary	bytes	bytes	BINARY	sqlserver	varbinary	100	active	2026-05-19
275	mysql	binary	bytes	bytes	BINARY	postgresql	bytea	100	active	2026-05-19
276	mysql	binary	bytes	bytes	BINARY	oracle	blob	100	active	2026-05-19
277	mysql	blob	bytes	bytes	BINARY	sqlserver	varbinary	100	active	2026-05-19
278	mysql	blob	bytes	bytes	BINARY	postgresql	bytea	100	active	2026-05-19
279	mysql	blob	bytes	bytes	BINARY	oracle	blob	100	active	2026-05-19
280	oracle	blob	bytes	bytes	BINARY	sqlserver	varbinary	100	active	2026-05-19
281	oracle	blob	bytes	bytes	BINARY	postgresql	bytea	100	active	2026-05-19
282	oracle	blob	bytes	bytes	BINARY	mysql	blob	100	active	2026-05-19
283	oracle	raw	bytes	bytes	BINARY	sqlserver	varbinary	100	active	2026-05-19
284	oracle	raw	bytes	bytes	BINARY	postgresql	bytea	100	active	2026-05-19
285	oracle	raw	bytes	bytes	BINARY	mysql	blob	100	active	2026-05-19
286	mysql	datetime	long	timestamp-millis	DATETIME	sqlserver	datetime	100	active	2026-05-19
287	mysql	datetime	long	timestamp-millis	DATETIME	postgresql	timestamp	100	active	2026-05-19
288	mysql	datetime	long	timestamp-millis	DATETIME	oracle	timestamp	100	active	2026-05-19
289	mysql	varchar(35)	string	datetime-offset	DATETIMEOFFSET	sqlserver	datetimeoffset	100	active	2026-05-19
290	mysql	varchar(35)	string	datetime-offset	DATETIMEOFFSET	postgresql	timestamptz	100	active	2026-05-19
291	mysql	varchar(35)	string	datetime-offset	DATETIMEOFFSET	oracle	timestamp with time zone	100	active	2026-05-19
292	mysql	geometry	string	spatial	GEOMETRY	sqlserver	geometry	100	active	2026-05-19
293	mysql	geometry	string	spatial	GEOMETRY	postgresql	geometry	100	active	2026-05-19
294	mysql	geometry	string	spatial	GEOMETRY	oracle	sdo_geometry	100	active	2026-05-19
295	oracle	long raw	bytes	bytes	BINARY	sqlserver	varbinary	100	active	2026-05-19
296	oracle	long raw	bytes	bytes	BINARY	postgresql	bytea	100	active	2026-05-19
297	oracle	long raw	bytes	bytes	BINARY	mysql	blob	100	active	2026-05-19
298	oracle	date	int	date	DATE	sqlserver	date	100	active	2026-05-19
299	oracle	date	int	date	DATE	postgresql	date	100	active	2026-05-19
300	oracle	date	int	date	DATE	mysql	date	100	active	2026-05-19
301	oracle	number(3)	int	int	TINYINT	sqlserver	tinyint	100	active	2026-05-19
302	oracle	number(3)	int	int	TINYINT	postgresql	smallint	100	active	2026-05-19
303	oracle	number(3)	int	int	TINYINT	mysql	tinyint	100	active	2026-05-19
304	oracle	nvarchar2	string	string	NVARCHAR	sqlserver	nvarchar	100	active	2026-05-19
305	oracle	nvarchar2	string	string	NVARCHAR	postgresql	varchar	100	active	2026-05-19
306	oracle	nvarchar2	string	string	NVARCHAR	mysql	varchar	100	active	2026-05-19
307	oracle	nchar	string	string	NCHAR	sqlserver	nchar	100	active	2026-05-19
308	oracle	nchar	string	string	NCHAR	postgresql	char	100	active	2026-05-19
309	oracle	nchar	string	string	NCHAR	mysql	char	100	active	2026-05-19
310	oracle	nclob	string	string	NTEXT	sqlserver	ntext	100	active	2026-05-19
311	oracle	nclob	string	string	NTEXT	postgresql	text	100	active	2026-05-19
312	oracle	nclob	string	string	NTEXT	mysql	text	100	active	2026-05-19
313	oracle	timestamp with time zone	string	datetime-offset	DATETIMEOFFSET	sqlserver	datetimeoffset	100	active	2026-05-19
314	oracle	timestamp with time zone	string	datetime-offset	DATETIMEOFFSET	postgresql	timestamptz	100	active	2026-05-19
315	oracle	timestamp with time zone	string	datetime-offset	DATETIMEOFFSET	mysql	datetime	100	active	2026-05-19
\.


--
-- TOC entry 5080 (class 0 OID 16883)
-- Dependencies: 229
-- Data for Name: session_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.session_records (id, "user", role, db, tables, ttl_minutes, created) FROM stdin;
\.


--
-- TOC entry 5090 (class 0 OID 0)
-- Dependencies: 227
-- Name: database_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.database_records_id_seq', 8, true);


--
-- TOC entry 5091 (class 0 OID 0)
-- Dependencies: 221
-- Name: datatype_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.datatype_mapping_id_seq', 161, true);


--
-- TOC entry 5092 (class 0 OID 0)
-- Dependencies: 222
-- Name: datatype_raw_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.datatype_raw_mapping_id_seq', 202, true);


--
-- TOC entry 5093 (class 0 OID 0)
-- Dependencies: 220
-- Name: datatype_standard_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.datatype_standard_id_seq', 29, true);


--
-- TOC entry 5094 (class 0 OID 0)
-- Dependencies: 219
-- Name: db_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.db_type_id_seq', 4, true);


--
-- TOC entry 5095 (class 0 OID 0)
-- Dependencies: 230
-- Name: mapping_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mapping_rules_id_seq', 315, true);


--
-- TOC entry 4912 (class 2606 OID 16882)
-- Name: database_records database_records_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.database_records
    ADD CONSTRAINT database_records_key_key UNIQUE (key);


--
-- TOC entry 4914 (class 2606 OID 16880)
-- Name: database_records database_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.database_records
    ADD CONSTRAINT database_records_pkey PRIMARY KEY (id);


--
-- TOC entry 4902 (class 2606 OID 16747)
-- Name: datatype_mapping datatype_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT datatype_mapping_pkey PRIMARY KEY (id);


--
-- TOC entry 4906 (class 2606 OID 16769)
-- Name: datatype_raw_mapping datatype_raw_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT datatype_raw_mapping_pkey PRIMARY KEY (id);


--
-- TOC entry 4898 (class 2606 OID 16730)
-- Name: datatype_standard datatype_standard_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_standard
    ADD CONSTRAINT datatype_standard_pkey PRIMARY KEY (id);


--
-- TOC entry 4900 (class 2606 OID 16732)
-- Name: datatype_standard datatype_standard_standard_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_standard
    ADD CONSTRAINT datatype_standard_standard_type_key UNIQUE (standard_type);


--
-- TOC entry 4896 (class 2606 OID 16720)
-- Name: db_type db_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.db_type
    ADD CONSTRAINT db_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4918 (class 2606 OID 16904)
-- Name: mapping_rules mapping_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_rules
    ADD CONSTRAINT mapping_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 4916 (class 2606 OID 16894)
-- Name: session_records session_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.session_records
    ADD CONSTRAINT session_records_pkey PRIMARY KEY (id);


--
-- TOC entry 4904 (class 2606 OID 16798)
-- Name: datatype_mapping uniq_final_mapping; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT uniq_final_mapping UNIQUE (db_id, standard_id);


--
-- TOC entry 4908 (class 2606 OID 16800)
-- Name: datatype_raw_mapping uniq_raw_mapping; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT uniq_raw_mapping UNIQUE (db_id, raw_type, source_type);


--
-- TOC entry 4910 (class 2606 OID 16781)
-- Name: datatype_raw_mapping unique_mapping_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT unique_mapping_idx UNIQUE (db_id, raw_type, logical_type, source_type, standard_id);


--
-- TOC entry 4921 (class 2606 OID 16770)
-- Name: datatype_raw_mapping fk_db; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT fk_db FOREIGN KEY (db_id) REFERENCES public.db_type(id);


--
-- TOC entry 4919 (class 2606 OID 16748)
-- Name: datatype_mapping fk_mapping_db; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT fk_mapping_db FOREIGN KEY (db_id) REFERENCES public.db_type(id);


--
-- TOC entry 4920 (class 2606 OID 16753)
-- Name: datatype_mapping fk_mapping_standard; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT fk_mapping_standard FOREIGN KEY (standard_id) REFERENCES public.datatype_standard(id);


--
-- TOC entry 4922 (class 2606 OID 16775)
-- Name: datatype_raw_mapping fk_standard; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT fk_standard FOREIGN KEY (standard_id) REFERENCES public.datatype_standard(id);


-- Completed on 2026-05-20 11:07:08

--
-- PostgreSQL database dump complete
--

\unrestrict gC32OTgET16mCUe7yxcJDcJb20AHEyiIJzfhpDl30qelPpOKZZE3npmyMqHwOYT

