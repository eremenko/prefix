---
--- prefix opclass installation
---
BEGIN;

CREATE OR REPLACE FUNCTION prefix_contains(text, text)
RETURNS bool
AS '$libdir/prefix'
LANGUAGE 'C' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION prefix_contained_by(text, text)
RETURNS bool
AS '$libdir/prefix'
LANGUAGE 'C' IMMUTABLE STRICT;

DROP OPERATOR IF EXISTS @>(text, text) CASCADE;
CREATE OPERATOR @> (
	LEFTARG = text,
	RIGHTARG = text,
	PROCEDURE = prefix_contains,
	COMMUTATOR = '<@'
);
COMMENT ON OPERATOR @>(text, text) IS 'prefix contains query';

DROP OPERATOR IF EXISTS <@(text, text) CASCADE;
CREATE OPERATOR <@ (
	LEFTARG = text,
	RIGHTARG = text,
	PROCEDURE = prefix_contained_by,
	COMMUTATOR = '@>'
);
COMMENT ON OPERATOR <@(text, text) IS 'query is contained by prefix';

--
-- greatest prefix aggregate
--
CREATE OR REPLACE FUNCTION greater_prefix(text, text)
RETURNS text
AS '$libdir/prefix'
LANGUAGE 'C' IMMUTABLE STRICT;

DROP AGGREGATE IF EXISTS greater_prefix(text);
CREATE AGGREGATE greater_prefix(text) (
       SFUNC = greater_prefix,
       STYPE = text
);
COMMENT ON AGGREGATE greater_prefix(text) IS 'greater prefix aggregate';

--
-- define the GiST support methods
--

CREATE OR REPLACE FUNCTION gprefix_consistent(internal, text, text)
RETURNS bool
AS '$libdir/prefix'
LANGUAGE 'C';

CREATE OR REPLACE FUNCTION gprefix_compress(internal)
RETURNS internal 
AS '$libdir/prefix'
LANGUAGE 'C';

CREATE OR REPLACE FUNCTION gprefix_decompress(internal)
RETURNS internal 
AS '$libdir/prefix'
LANGUAGE 'C';

CREATE OR REPLACE FUNCTION gprefix_penalty(internal, internal, internal)
RETURNS internal
AS '$libdir/prefix'
LANGUAGE 'C' STRICT;

CREATE OR REPLACE FUNCTION gprefix_picksplit(internal, internal)
RETURNS internal
AS '$libdir/prefix'
LANGUAGE 'C';

CREATE OR REPLACE FUNCTION gprefix_union(internal, internal)
RETURNS text
AS '$libdir/prefix'
LANGUAGE 'C';

CREATE OR REPLACE FUNCTION gprefix_same(text, text, internal)
RETURNS internal 
AS '$libdir/prefix'
LANGUAGE 'C';

CREATE OPERATOR CLASS gist_prefix_ops
FOR TYPE text USING gist 
AS
	OPERATOR	1	@>,
	FUNCTION	1	gprefix_consistent (internal, text, text),
	FUNCTION	2	gprefix_union (internal, internal),
	FUNCTION	3	gprefix_compress (internal),
	FUNCTION	4	gprefix_decompress (internal),
	FUNCTION	5	gprefix_penalty (internal, internal, internal),
	FUNCTION	6	gprefix_picksplit (internal, internal),
	FUNCTION	7	gprefix_same (text, text, internal);

COMMIT;