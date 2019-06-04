CREATE DATABASE ilmo_template encoding 'UTF8' template template0;

\c ilmo_template

BEGIN;

CREATE AGGREGATE array_accum(anyelement) (
    SFUNC = array_append,
    STYPE = anyarray,
    INITCOND = '{}'
);

CREATE AGGREGATE array_accum_cat(anyarray) (
    SFUNC = array_cat,
    STYPE = anyarray,
    INITCOND = '{}'
);

CREATE TABLE ack (
    seed text NOT NULL,
    email text NOT NULL,
    acktime timestamp without time zone,
    adminacktime timestamp without time zone
);

CREATE TABLE allergies (
    id integer NOT NULL,
    allergy text
);

CREATE TABLE participants (
    name text NOT NULL,
    email text,
    privacy integer DEFAULT 3 NOT NULL,
    grill integer,
    submitted timestamp without time zone DEFAULT now(),
    nick text,
    id integer NOT NULL,
    passwd text,
    cookie text,
    notcoming integer,
    car integer,
    limitgroup integer DEFAULT 0
);

CREATE SEQUENCE participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE ONLY participants ALTER COLUMN id SET DEFAULT nextval('participants_id_seq'::regclass);

ALTER TABLE ONLY ack
    ADD CONSTRAINT ack_pkey PRIMARY KEY (seed);

ALTER TABLE ONLY participants
    ADD CONSTRAINT participants_pkey PRIMARY KEY (id);

COMMIT;
