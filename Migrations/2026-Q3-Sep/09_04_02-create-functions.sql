--liquibase formatted sql

--changeset nwpd:PD-048-002-safe-numeric splitStatements:false
--comment: Lenient TEXT -> NUMERIC cast. The legacy workbooks (and the app that
--comment: still writes to them) put sentinel strings such as '_', 'Pending' and
--comment: '' into columns that are otherwise numeric, so the stored value has to
--comment: stay TEXT. This function backs the generated numeric shadow columns,
--comment: which give reporting/indexing a real NUMERIC to work with and are NULL
--comment: wherever the text is not a number. IMMUTABLE is required for use in a
--comment: GENERATED ALWAYS ... STORED column.
CREATE OR REPLACE FUNCTION ${schema.name}.safe_numeric(p_value text)
RETURNS numeric
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE
AS $$
BEGIN
    IF p_value IS NULL OR btrim(p_value) = '' THEN
        RETURN NULL;
    END IF;
    RETURN btrim(p_value)::numeric;
EXCEPTION WHEN others THEN
    RETURN NULL;
END;
$$;
--rollback DROP FUNCTION IF EXISTS ${schema.name}.safe_numeric(text);

--changeset nwpd:PD-048-002-safe-timestamp splitStatements:false
--comment: Lenient TEXT -> TIMESTAMP cast for the stage/date-time columns, which
--comment: the app writes as 'YYYY-MM-DD, HH:MM' but which also legitimately hold
--comment: 'Pending' / 'Waiting' / ''. Returns NULL when the text is not a
--comment: timestamp, so the generated shadow columns stay usable for range
--comment: queries and the live dashboard's trend charts.
CREATE OR REPLACE FUNCTION ${schema.name}.safe_timestamp(p_value text)
RETURNS timestamp
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE
AS $$
BEGIN
    IF p_value IS NULL OR btrim(p_value) = '' THEN
        RETURN NULL;
    END IF;
    -- The workbooks use a comma between date and time; strip it so the
    -- standard timestamp input parser can take over.
    RETURN replace(btrim(p_value), ',', '')::timestamp;
EXCEPTION WHEN others THEN
    RETURN NULL;
END;
$$;
--rollback DROP FUNCTION IF EXISTS ${schema.name}.safe_timestamp(text);

--changeset nwpd:PD-048-002-touch-updated-at splitStatements:false
--comment: Keeps updated_at honest without every write site having to remember it.
CREATE OR REPLACE FUNCTION ${schema.name}.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;
--rollback DROP FUNCTION IF EXISTS ${schema.name}.touch_updated_at();
