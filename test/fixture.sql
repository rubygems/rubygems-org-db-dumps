-- A tiny rubygems.org database for testing bin/export. The CREATE TABLE
-- statements are copied from the public dump of 2026-10-19; the rows are made up
-- to cover the cases the format has to get right.
CREATE EXTENSION IF NOT EXISTS hstore;

CREATE TABLE public.attestations (
    id bigint NOT NULL,
    version_id bigint NOT NULL,
    body jsonb,
    media_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE public.deletions (
    id integer NOT NULL,
    user_id integer,
    rubygem character varying,
    number character varying,
    platform character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    version_id bigint,
    ruby_abi character varying
);

CREATE TABLE public.dependencies (
    id integer NOT NULL,
    requirements character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    rubygem_id integer,
    version_id integer,
    scope character varying(255),
    unresolved_name character varying(255)
);

CREATE TABLE public.gem_downloads (
    id integer NOT NULL,
    rubygem_id integer NOT NULL,
    version_id integer NOT NULL,
    count bigint
);

CREATE TABLE public.linksets (
    id integer NOT NULL,
    rubygem_id integer,
    home character varying(255),
    wiki character varying(255),
    docs character varying(255),
    mail character varying(255),
    code character varying(255),
    bugs character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);

CREATE TABLE public.rubygems (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    indexed boolean DEFAULT false NOT NULL,
    organization_id bigint
);

CREATE TABLE public.versions (
    id integer NOT NULL,
    authors text,
    description text,
    number character varying(255),
    rubygem_id integer,
    built_at timestamp without time zone,
    updated_at timestamp without time zone,
    summary text,
    platform character varying(255),
    created_at timestamp without time zone,
    indexed boolean DEFAULT true,
    prerelease boolean,
    "position" integer,
    latest boolean,
    full_name character varying(255),
    licenses character varying(255),
    size integer,
    requirements text,
    required_ruby_version character varying(255),
    sha256 character varying(255),
    metadata public.hstore DEFAULT ''::public.hstore NOT NULL,
    required_rubygems_version character varying(255),
    yanked_at timestamp without time zone,
    pusher_id bigint,
    canonical_number character varying,
    cert_chain text,
    pusher_api_key_id bigint,
    gem_platform character varying,
    gem_full_name character varying,
    spec_sha256 character varying(44),
    info_checksum_v2 character varying,
    yanked_info_checksum_v2 character varying,
    ruby_abi character varying,
    content_address character varying
);

-- Rows are inserted out of id order, so the export has to sort them.
INSERT INTO public.attestations VALUES
  (2500, 10, '{"mediaType": "application/vnd.dev.sigstore.bundle.v0.3+json", "note": "comma, \"quote\""}', 'application/vnd.dev.sigstore.bundle.v0.3+json', '2024-11-14 21:15:00.123456', '2024-11-14 21:15:00.5'),
  (1, 10, '{"b": 1, "a": [true, null, "é ☃"]}', '', '2024-11-14 21:15:00', '2024-11-14 21:15:00'),
  (2499, 11, NULL, NULL, '2024-11-14 21:15:00.000001', '2024-11-14 21:15:00.1');

INSERT INTO public.deletions VALUES
  (100000, NULL, 'gone', '1.0.0', 'ruby', '2015-04-20 21:24:09.010243', '2023-12-03 00:02:10.2', NULL, ''),
  (99999, 51305, 'a,b', '0.0.1', 'x86_64-linux', '2015-04-20 21:24:46', '2015-04-20 21:24:46', 12, 'ruby3.3');

INSERT INTO public.dependencies VALUES
  (1, '>= 1.9.2', '2009-07-25 17:46:22', '2009-07-25 17:46:22', 1, 10, 'runtime', NULL),
  (250000, '>= 0', NULL, NULL, NULL, NULL, 'development', 'missing_gem'),
  (750001, '~> 1.0, >= 1.0.2', '2026-10-19 21:00:00.999999', '2026-10-19 21:00:01', 2, 11, 'runtime', '');

INSERT INTO public.gem_downloads VALUES
  (2, 0, 0, 271693712619),
  (1, 1, 10, 0),
  (1000000, 2, 11, NULL);

INSERT INTO public.linksets VALUES
  (14646, 1, 'http://example.org/zyps/', '', '', '', 'https://example.org/"code"', NULL, '2009-07-25 17:46:22', '2009-10-15 11:25:22.863545');

INSERT INTO public.rubygems VALUES
  (2, 'json', '2009-07-25 17:46:23', '2026-10-13 08:04:58.044763', false, 7),
  (1, 'zyps', '2009-07-25 17:46:22', '2024-05-31 20:33:01.579413', true, NULL),
  (100000, '\.', NULL, NULL, true, NULL);

INSERT INTO public.versions (id, authors, description, number, rubygem_id, built_at, updated_at, summary, platform, created_at, indexed, prerelease, "position", latest, full_name, licenses, size, requirements, required_ruby_version, sha256, metadata, cert_chain) VALUES
  (49999, 'Jay McGavren', '', '0.7.6', 1, '2008-02-29 07:00:00', '2024-05-31 20:33:01.443057', 'A game library for Ruby', 'ruby', '2009-07-25 17:46:22', true, false, 0, true, 'zyps-0.7.6', NULL, 50688, NULL, '> 0.0.0', 'ST7zLnibsC3eFYbQrdNck9MnyyVw5iUo3YWzNY5x', '', NULL),
  (50000, 'A, B and "C"', E'Line one\nLine two\r\nLine three', '2.0.0.pre', 2, NULL, '2026-10-19 21:00:00', E'Tab\there', 'java', '2026-10-19 21:00:00', false, true, 1, false, 'json-2.0.0.pre-java', '["MIT", "Ruby"]', 2147483647, 'git', '>= 2.7', NULL, 'source_code_uri=>"https://example.org/a,b", "quote\"key"=>NULL', E'-----BEGIN CERTIFICATE-----\nAAA\n-----END CERTIFICATE-----\n'),
  (150001, '', NULL, '1.0', 2, NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL, NULL, '', NULL, '', NULL, NULL, '', NULL);
