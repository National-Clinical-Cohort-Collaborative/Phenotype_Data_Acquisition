SELECT CURRENT_TIMESTAMP as date_time, 'Starting NLP extract...' as log_entry;

SELECT CURRENT_TIMESTAMP as date_time, 'NLP tables drop and recreate...' as log_entry;

DROP TABLE IF EXISTS n3c_note;
DROP TABLE IF EXISTS n3c_note_nlp;

---------------------------------------------------------------------------------------------------------
-- CREATE TABLES
---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS n3c_note (
    NOTE_ID                     VARCHAR(200)
    , PERSON_ID                 VARCHAR(200)
    , NOTE_DATE                 TIMESTAMP
    , NOTE_DATETIME             TIMESTAMP
    , NOTE_TYPE_CONCEPT_ID      VARCHAR(250)
    , NOTE_CLASS_CONCEPT_ID     VARCHAR(250)
    , NOTE_TITLE                VARCHAR(250)
    , NOTE_TEXT                 VARCHAR(250)
    , ENCODING_CONCEPT_ID       VARCHAR(250)
    , LANGUAGE_CONCEPT_ID       VARCHAR(250)
    , PROVIDER_ID               VARCHAR(250)
    , VISIT_OCCURRENCE_ID       VARCHAR(250)
    , VISIT_DETAIL_ID           VARCHAR(250)
    , NOTE_SOURCE_VALUE         VARCHAR(250)
);

CREATE TABLE IF NOT EXISTS n3c_note_nlp (
    NOTE_NLP_ID                     VARCHAR(200)
    , NOTE_ID                       VARCHAR(200)
    , SECTION_CONCEPT_ID            VARCHAR(50)
    , SNIPPET                       VARCHAR(250)
    , "OFFSET"                      VARCHAR(50)
    , LEXICAL_VARIANT               VARCHAR(250)
    , NOTE_NLP_CONCEPT_ID           VARCHAR(50)
    , NOTE_NLP_SOURCE_CONCEPT_ID    VARCHAR(50)
    , NLP_SYSTEM                    VARCHAR(250)
    , NLP_DATE                      TIMESTAMP
    , NLP_DATETIME                  TIMESTAMP
    , TERM_EXISTS                   VARCHAR(250)
    , TERM_TEMPORAL                 VARCHAR(50)
    , TERM_MODIFIERS                VARCHAR(2000)
);
---------------------------------------------------------------------------------------------------------
-- NLP Documents
-- OUTPUT_FILE: NOTE.csv
--              NOTE_NLP.csv
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Extracting Note data' as log_entry;
INSERT INTO n3c_note 
SELECT
    nlp_meta.document_id                        AS NOTE_ID
    , n3c.patient_id                            AS PERSON_ID
    , nlp_meta.document_date::DATE::TIMESTAMP   AS NOTE_DATE
    , nlp_meta.document_date::TIMESTAMP         AS NOTE_DATETIME
    , NULL                                      AS NOTE_TYPE_CONCEPT_ID
    , NULL                                      AS NOTE_CLASS_CONCEPT_ID
    , NULL                                      AS NOTE_TITLE
    , NULL                                      AS NOTE_TEXT
    , NULL                                      AS ENCODING_CONCEPT_ID
    , NULL                                      AS LANGUAGE_CONCEPT_ID
    , NULL                                      AS PROVIDER_ID
    , NULL                                      AS VISIT_OCCURRENCE_ID
    , NULL                                      AS VISIT_DETAIL_ID
    , nlp_meta.document_type                    AS NOTE_SOURCE_VALUE
FROM n3c_cohort n3c
    JOIN N3C_NLP.METADATA nlp_meta ON nlp_meta.patient_id = n3c.patient_id
;

SELECT CURRENT_TIMESTAMP as date_time, 'Extracting Note NLP data' as log_entry;
INSERT INTO n3c_note_nlp
SELECT DISTINCT
    n3c_note.note_id || LPAD(nlp_res.note_nlp_concept_id::VARCHAR, 15, '0') || LPAD(nlp_res.offset_value::VARCHAR, 15, '0') AS NOTE_NLP_ID
    , n3c_note.note_id                      AS NOTE_ID
    , nlp_res.section_concept_id            AS SECTION_CONCEPT_ID
    , NULL                                  AS SNIPPET
    , nlp_res.offset_value                  AS OFFSET
    , NULL                                  AS LEXICAL_VARIANT		--nlp_res.lexical_variant?
    , nlp_res.note_nlp_concept_id           AS NOTE_NLP_CONCEPT_ID
    , nlp_res.note_nlp_source_concept_id    AS NOTE_NLP_SOURCE_CONCEPT_ID
    , nlp_res.nlp_system                    AS NLP_SYSTEM
    , nlp_res.nlp_date::DATE::TIMESTAMP     AS NLP_DATE
    , nlp_res.nlp_date::TIMESTAMP           AS NLP_DATETIME
    , NULL                                  AS TERM_EXISTS
    , NULL                                  AS TERM_TEMPORAL
    , nlp_res.term_modifiers                AS TERM_MODIFIERS
FROM n3c_note n3c_note
    JOIN N3C_NLP.RESULTS nlp_res ON nlp_res.document_id = n3c_note.note_id
;
COMMIT;

---------------------------------------------------------------------------------------------------------
-- UPDATE DATA COUNTS
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Adding NLP to n3c_data_counts' as log_entry;

INSERT INTO n3c_data_counts SELECT 'Note', count(1) FROM n3c_note;
INSERT INTO n3c_data_counts SELECT 'Note NLP', count(1) FROM n3c_note_nlp;
COMMIT;
