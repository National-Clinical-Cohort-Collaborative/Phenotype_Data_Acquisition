---------------------------------------------------------------------------------------------------------
-- Drop existing output tables
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Starting extract...' as log_entry;
DROP TABLE IF EXISTS n3c_patient;
DROP TABLE IF EXISTS n3c_encounter;
DROP TABLE IF EXISTS n3c_diagnosis;
DROP TABLE IF EXISTS n3c_procedure;
DROP TABLE IF EXISTS n3c_medication;
DROP TABLE IF EXISTS n3c_lab_result;
DROP TABLE IF EXISTS n3c_vital_signs;
DROP TABLE IF EXISTS n3c_data_counts;
DROP TABLE IF EXISTS n3c_manifest;

---------------------------------------------------------------------------------------------------------
-- PATIENTS
-- OUTPUT_FILE: PATIENT.csv
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Extracting patient' as log_entry;
CREATE TABLE n3c_patient AS
SELECT
    n3c.patient_id                              AS PATIENT_ID
    , LEFT(pt.birth_date::varchar,7)            AS BIRTH_DATE    --only pull YYYY-MM
    , REPLACE(pt.vital_status,'|',' ')          AS VITAL_STATUS
    , pt.death_date::datetime                   AS DEATH_DATE
    , LEFT(pt.postal_code,5)                    AS POSTAL_CODE
    , REPLACE(pt.gender,'|',' ')                AS SEX
    , REPLACE(pt.race,'|',' ')                  AS RACE
    , REPLACE(pt.ethnicity,'|',' ')             AS ETHNICITY
    , REPLACE(pt.language,'|',' ')              AS LANGUAGE
    , REPLACE(pt.marital_status,'|',' ')        AS MARITAL_STATUS
    , REPLACE(pt.smoking_status,'|',' ')        AS SMOKING_STATUS
    , map_sx.mt_code                            AS MAPPED_SEX
    , map_rc.mt_code                            AS MAPPED_RACE
    , map_et.mt_code                            AS MAPPED_ETHNICITY
    , map_ms.mt_code                            AS MAPPED_MARITAL_STATUS
FROM n3c_cohort n3c
    JOIN patient pt ON pt.patient_id = n3c.patient_id
    JOIN (
        SELECT source_id, patient_id, RANK() OVER(PARTITION BY patient_id ORDER BY batch_id DESC) AS rnk FROM patient
    ) ptDedupFilter ON ptDedupFilter.patient_id = pt.patient_id AND ptDedupFilter.source_id = pt.source_id AND ptDedupFilter.rnk = 1
    LEFT JOIN mapping map_sx ON map_sx.provider_code = ('DEM|GENDER:' || pt.gender)
    LEFT JOIN mapping map_rc ON map_rc.provider_code = ('DEM|RACE:' || pt.race)
    LEFT JOIN mapping map_et ON map_et.provider_code = ('DEM|ETHNICITY:' || pt.ethnicity)
    LEFT JOIN mapping map_ms ON map_ms.provider_code = ('DEM|MARITAL:' || pt.marital_status)
WHERE pt.source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'patient' AND code_system = 'source_id')
;

---------------------------------------------------------------------------------------------------------
-- ENCOUNTERS
-- OUTPUT FILE: ENCOUNTER.csv
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Extracting encounter' as log_entry;
CREATE TABLE n3c_encounter AS
WITH dedup_encounter AS (
    SELECT 
        ROW_NUMBER() OVER (PARTITION BY enc.encounter_id ORDER BY enc.batch_id DESC) as row_num
        , enc.*
    FROM encounter enc
    JOIN n3c_cohort n3c on n3c.patient_id = enc.patient_id
    WHERE enc.start_date >= '2018-01-01'
        AND enc.source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'encounter' AND code_system = 'source_id')
)
SELECT
    enc.patient_id                  AS PATIENT_ID
    , HASH(COALESCE((select code from data_a.n3c_initiative where initiative = 'Source ID Replacement' and table_name = 'encounter' and code_system = enc.source_id), enc.source_id)) || enc.encounter_id    AS ENCOUNTER_ID
    , REPLACE(enc.type,'|',' ')     AS ENCOUNTER_TYPE
    , enc.start_date                AS START_DATE
    , enc.end_date                  AS END_DATE
    , enc.length_of_stay            AS LENGTH_OF_STAY
    , enc.orphan                    AS ORPHAN_FLAG
    , map_et.mt_code                AS MAPPED_ENCOUNTER_TYPE
    , CASE 
        WHEN long_loc.code IS NOT NULL THEN TRUE
          ELSE FALSE
      END                           AS IS_LONG_COVID
FROM dedup_encounter enc
    LEFT JOIN mapping map_et ON map_et.provider_code = ('TNX:ENCOUNTER_TYPE:' || enc.type)
    LEFT JOIN data_a.n3c_initiative long_loc ON long_loc.code = enc.location_id AND upper(long_loc.initiative) = 'LONG COVID' AND long_loc.table_name = 'encounter' AND long_loc.code_system = 'location_id'
WHERE enc.row_num = 1
;

---------------------------------------------------------------------------------------------------------
-- DIAGNOSES
-- OUTPUT_FILE: DIAGNOSIS.csv
---------------------------------------------------------------------------------------------------------
-- NOTES:
--        -Orphan = record with no associated patient/encounter
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Extracting diagnosis' as log_entry;
CREATE TABLE n3c_diagnosis AS
SELECT
    dx.patient_id                           AS PATIENT_ID
    , HASH(COALESCE((select code from data_a.n3c_initiative where initiative = 'Source ID Replacement' and table_name = 'diagnosis' and code_system = dx.source_id), dx.source_id)) || dx.encounter_id        AS ENCOUNTER_ID
    , REPLACE(dx.code_system,'|',' ')       AS DX_CODE_SYSTEM
    , REPLACE(dx.code,'|',' ')              AS DX_CODE
    , dx.date                               AS DATE
    , REPLACE(dx.description,'|',' ')       AS DX_DESCRIPTION
    , dx.principal_indicator                AS PRINCIPAL_INDICATOR
    , dx.source                             AS DX_SOURCE
    , dx.orphan                             AS ORPHAN_FLAG
    , dx.orphan_reason                      AS ORPHAN_REASON
    , SPLIT_PART(map_dx.mt_code,':',2)      AS MAPPED_CODE_SYSTEM
    , SPLIT_PART(map_dx.mt_code,':',3)      AS MAPPED_CODE
FROM diagnosis dx
    JOIN n3c_cohort n3c on n3c.patient_id = dx.patient_id
    LEFT JOIN mapping map_dx ON map_dx.provider_code = (dx.code_system || ':' || dx.code)
WHERE dx.date >= '2018-01-01'
    AND dx.source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'diagnosis' AND code_system = 'source_id')
    AND (dx.code_system || ':' || dx.code) NOT IN (SELECT code_system || ':' || code FROM data_a.n3c_filter WHERE table_name = 'diagnosis')
;

---------------------------------------------------------------------------------------------------------
-- PROCEDURES
-- OUTPUT_FILE: PROCEDURE.csv
---------------------------------------------------------------------------------------------------------
-- NOTES:
--         -Orphan = record with no associated patient/encounter
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Extracting procedure' as log_entry;
CREATE TABLE n3c_procedure AS
SELECT
    px.patient_id                           AS PATIENT_ID
    , HASH(COALESCE((select code from data_a.n3c_initiative where initiative = 'Source ID Replacement' and table_name = 'procedure' and code_system = px.source_id), px.source_id)) || px.encounter_id    AS ENCOUNTER_ID
    , REPLACE(px.code_system,'|',' ')       AS PX_CODE_SYSTEM
    , REPLACE(px.code,'|',' ')              AS PX_CODE
    , REPLACE(px.description,'|',' ')       AS PX_DESCRIPTION
    , px.date                               AS DATE
    , px.orphan                             AS ORPHAN_FLAG
    , px.orphan_reason                      AS ORPHAN_REASON
    , CASE
        WHEN REGEXP_COUNT(map_px.mt_code,':') = 2 THEN SPLIT_PART(map_px.mt_code,':',2)
        WHEN REGEXP_COUNT(map_px.mt_code,':') = 1 THEN SPLIT_PART(map_px.mt_code,':',1)
        ELSE ''
        END                                 AS MAPPED_CODE_SYSTEM
    , CASE
        WHEN REGEXP_COUNT(map_px.mt_code,':') = 2 THEN SPLIT_PART(map_px.mt_code,':',3)
        WHEN REGEXP_COUNT(map_px.mt_code,':') = 1 THEN SPLIT_PART(map_px.mt_code,':',2)
        ELSE map_px.mt_code
        END                                 AS MAPPED_CODE
FROM procedure px
    JOIN n3c_cohort n3c on n3c.patient_id = px.patient_id
    LEFT JOIN mapping map_px ON map_px.provider_code = (px.code_system || ':' || px.code)
WHERE px.date >= '2018-01-01'
    AND px.source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'procedure' AND code_system = 'source_id')
    AND (px.code_system || ':' || px.code) NOT IN (SELECT code_system || ':' || code FROM data_a.n3c_filter WHERE table_name = 'procedure')
;

---------------------------------------------------------------------------------------------------------
-- MEDICATIONS
-- OUTPUT_FILE: MEDICATION.csv
---------------------------------------------------------------------------------------------------------
-- NOTES:
--         -Orphan = record with no associated patient/encounter
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Extracting medication' as log_entry;
CREATE TABLE n3c_medication AS
SELECT
    rx.patient_id                                       AS PATIENT_ID
    , HASH(COALESCE((select code from data_a.n3c_initiative where initiative = 'Source ID Replacement' and table_name = 'medication' and code_system = rx.source_id), rx.source_id)) || rx.encounter_id            AS ENCOUNTER_ID
    , REPLACE(rx.code_system,'|',' ')                   AS RX_CODE_SYSTEM
    , REPLACE(rx.code,'|',' ')                          AS RX_CODE
    , REPLACE(rx.name,'|',' ')                          AS RX_DESCRIPTION
    , REPLACE(rx.alt_drug_code_sys,'|',' ')             AS ALT_DRUG_CODE_SYS
    , rx.alt_drug_code                                  AS ALT_DRUG_CODE
    , rx.start_date::datetime                           AS START_DATE
    , REPLACE(rx.route_of_administration,'|',' ')       AS ROUTE_OF_ADMINISTRATION
    , rx.units_per_administration                       AS UNITS_PER_ADMINISTRATION
    , REPLACE(rx.frequency,'|',' ')                     AS FREQUENCY
    , REPLACE(rx.strength,'|',' ')                      AS STRENGTH
    , REPLACE(rx.form,'|',' ')                          AS FORM
    , rx.duration                                       AS DURATION
    , rx.refills                                        AS REFILLS
    , rx.source                                         AS RX_SOURCE
    , REPLACE(rx.indication_code_system,'|',' ')        AS INDICATION_CODE_SYSTEM
    , rx.indication_code                                AS INDICATION_CODE
    , REPLACE(rx.indication_desc,'|',' ')               AS INDICATION_DESC
    , REPLACE(rx.alt_drug_name,'|',' ')                 AS ALT_DRUG_NAME
    , rx.clinical_drug                                  AS CLINICAL_DRUG
    , rx.end_date::datetime                             AS END_DATE
    , rx.quantity_dispensed                             AS QTY_DISPENSED
    , rx.dose_amount                                    AS DOSE_AMOUNT
    , rx.dose_unit                                      AS DOSE_UNIT
    , REPLACE(rx.brand,'|',' ')                         AS BRAND
    , rx.orphan                                         AS ORPHAN_FLAG
    , rx.orphan_reason                                  AS ORPHAN_REASON
    , CASE
        WHEN REGEXP_COUNT(map_rx.mt_code,':') = 2 THEN SPLIT_PART(map_rx.mt_code,':',2)
        WHEN REGEXP_COUNT(map_rx.mt_code,':') = 1 THEN SPLIT_PART(map_rx.mt_code,':',1)
        ELSE ''
        END                                             AS MAPPED_CODE_SYSTEM
    , CASE
        WHEN REGEXP_COUNT(map_rx.mt_code,':') = 2 THEN SPLIT_PART(map_rx.mt_code,':',3)
        WHEN REGEXP_COUNT(map_rx.mt_code,':') = 1 THEN SPLIT_PART(map_rx.mt_code,':',2)
        ELSE map_rx.mt_code
        END                                             AS MAPPED_CODE
FROM medication rx
    JOIN n3c_cohort n3c on n3c.patient_id = rx.patient_id
    LEFT JOIN mapping map_rx ON map_rx.provider_code = (rx.code_system || ':' || rx.code)
WHERE rx.start_date >= '2018-01-01'
    AND rx.source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'medication' AND code_system = 'source_id')
    AND (rx.code_system || ':' || rx.code) NOT IN (SELECT code_system || ':' || code FROM data_a.n3c_filter WHERE table_name = 'medication')
;

---------------------------------------------------------------------------------------------------------
-- Temp table for lab results performance improvement
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Creating temp lab mapping table' as log_entry;
CREATE TABLE tempLabMapping (provider_code varchar(65000), mt_code varchar(65000), row_num int);
INSERT INTO tempLabMapping SELECT provider_code, mt_code, ROW_NUMBER () OVER (PARTITION BY provider_code ORDER BY mt_code) FROM mapping WHERE mt_code LIKE 'UMLS:LNC:%';
INSERT INTO tempLabMapping SELECT provider_code, mt_code, ROW_NUMBER () OVER (PARTITION BY provider_code ORDER BY mt_code) FROM mapping WHERE provider_code LIKE 'TNX:LAB_RESULT:%';

---------------------------------------------------------------------------------------------------------
-- LAB RESULTS
-- OUTPUT_FILE: LAB_RESULT.csv
---------------------------------------------------------------------------------------------------------
-- NOTES:
--         -Orphan = record with no associated patient/encounter
--         -Stripping characters from observation desc due to NLP
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Extracting lab results' as log_entry;
CREATE TABLE n3c_lab_result AS
SELECT
    lab.patient_id                                                  AS PATIENT_ID
    , HASH(COALESCE((select code from data_a.n3c_initiative where initiative = 'Source ID Replacement' and table_name = 'lab_result' and code_system = lab.source_id), lab.source_id)) || lab.encounter_id    AS ENCOUNTER_ID
    , REPLACE(lab.observation_code_system,'|',' ')                  AS LAB_CODE_SYSTEM
    , REPLACE(lab.observation_code,'|',' ')                         AS LAB_CODE
    , REPLACE(REPLACE(lab.observation_desc,'|',' '),'\n',' ')       AS LAB_DESCRIPTION
    , REPLACE(lab.battery_code_system,'|',' ')                      AS BATTERY_CODE_SYSTEM
    , lab.battery_code                                              AS BATTERY_CODE
    , REPLACE(lab.battery_desc,'|',' ')                             AS BATTERY_DESC
    , lab.section                                                   AS SECTION
    , lab.normal_range                                              AS NORMAL_RANGE
    , lab.test_date                                                 AS TEST_DATE
    , lab.result_type                                               AS RESULT_TYPE
    , lab.lab_result_num_val                                        AS NUMERIC_RESULT_VAL
    , REPLACE(REPLACE(REPLACE(lab.lab_result_text_val, '|', ' '),'\\','\\\\'),'\n',' ')    AS TEXT_RESULT_VAL
    , lab.units_of_measure                                          AS UNITS_OF_MEASURE
    , lab.orphan                                                    AS ORPHAN_FLAG
    , lab.orphan_reason                                             AS ORPHAN_REASON
    , SPLIT_PART(map_lab.mt_code,':',2)                             AS MAPPED_CODE_SYSTEM
    , SPLIT_PART(map_lab.mt_code,':',3)                             AS MAPPED_CODE
    , SPLIT_PART(map_result.mt_code,':',3)                          AS MAPPED_TEXT_RESULT_VAL
FROM lab_result lab
    JOIN n3c_cohort n3c on n3c.patient_id = lab.patient_id
    LEFT JOIN tempLabMapping map_lab ON map_lab.provider_code = (lab.observation_code_system || ':' || lab.observation_code)
    LEFT JOIN tempLabMapping map_result ON map_result.provider_code = ('TNX:LAB_RESULT:' || lab.lab_result_text_val) and map_result.row_num = 1
WHERE lab.test_date >= '2018-01-01'
    AND lab.source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'lab_result' AND code_system = 'source_id')
    AND (lab.observation_code_system || ':' || lab.observation_code) NOT IN (SELECT code_system || ':' || code FROM data_a.n3c_filter WHERE table_name = 'lab_result')
;

---------------------------------------------------------------------------------------------------------
-- VITAL SIGNS
-- OUTPUT_FILE: VITAL_SIGNS.csv
---------------------------------------------------------------------------------------------------------
-- NOTES:
--         -Orphan = record with no associated patient/encounter
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Extracting vital signs' as log_entry;
CREATE TABLE n3c_vital_signs AS
SELECT
    vit.patient_id                              AS PATIENT_ID
    , HASH(COALESCE((select code from data_a.n3c_initiative where initiative = 'Source ID Replacement' and table_name = 'vital_signs' and code_system = vit.source_id), vit.source_id)) || vit.encounter_id    AS ENCOUNTER_ID
    , vit.measure_date                          AS MEASURE_DATE
    , REPLACE(vit.code_system,'|',' ')          AS VITAL_CODE_SYSTEM
    , REPLACE(vit.code,'|',' ')                 AS VITAL_CODE
    , REPLACE(vit.description,'|',' ')          AS VITAL_DESCRIPTION
    , vit.unit_of_measure                       AS UNIT_OF_MEASURE
    , vit.result_type                           AS RESULT_TYPE
    , vit.numeric_value                         AS NUMERIC_RESULT_VAL
    , REPLACE(REPLACE(REPLACE(vit.text_value, '|', ' '),'\\','\\\\'),'\n',' ')    AS TEXT_RESULT_VAL
    , vit.orphan                                AS ORPHAN_FLAG
    , vit.orphan_reason                         AS ORPHAN_REASON
    , SPLIT_PART(map_vit.mt_code,':',2)         AS MAPPED_CODE_SYSTEM
    , SPLIT_PART(map_vit.mt_code,':',3)         AS MAPPED_CODE
    , SPLIT_PART(map_result.mt_code,':',3)      AS MAPPED_TEXT_RESULT_VAL
FROM vital_signs vit
    JOIN n3c_cohort n3c on n3c.patient_id = vit.patient_id
    LEFT JOIN tempLabMapping map_vit ON map_vit.provider_code = (vit.code_system || ':' || vit.code)
    LEFT JOIN tempLabMapping map_result ON map_result.provider_code = ('TNX:LAB_RESULT:' || vit.text_value) and map_result.row_num = 1
WHERE vit.measure_date >= '2018-01-01'
    AND vit.source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'vital_signs' AND code_system = 'source_id')
    AND (vit.code_system || ':' || vit.code) NOT IN (SELECT code_system || ':' || code FROM data_a.n3c_filter WHERE table_name = 'vital_signs')
;

DROP TABLE tempLabMapping;

---------------------------------------------------------------------------------------------------------
-- DATA COUNTS
-- OUTPUT_FILE: DATA_COUNTS.csv
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Creating n3c_data_counts' as log_entry;
CREATE TABLE n3c_data_counts (
    TABLE_NAME    varchar(200)
    , ROW_COUNT    int
);

INSERT INTO n3c_data_counts SELECT 'PATIENT', count(1) FROM n3c_patient;
INSERT INTO n3c_data_counts SELECT 'ENCOUNTER', count(1) FROM n3c_encounter;
INSERT INTO n3c_data_counts SELECT 'DIAGNOSIS', count(1) FROM n3c_diagnosis;
INSERT INTO n3c_data_counts SELECT 'PROCEDURE', count(1) FROM n3c_procedure;
INSERT INTO n3c_data_counts SELECT 'MEDICATION', count(1) FROM n3c_medication;
INSERT INTO n3c_data_counts SELECT 'LAB_RESULT', count(1) FROM n3c_lab_result;
INSERT INTO n3c_data_counts SELECT 'VITAL_SIGNS', count(1) FROM n3c_vital_signs;
COMMIT;

---------------------------------------------------------------------------------------------------------
-- MANIFEST TABLE (updated per site)
-- OUTPUT_FILE: MANIFEST.csv
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Creating n3c_manifest' as log_entry;
SET TABLE_NAME='&LOG_SCHEMA.audit';
CREATE TABLE n3c_manifest AS
SELECT
    '&MNFST_SITE_ABBREV'                    AS SITE_ABBREV
    , '&MNFST_SITE_NAME'                    AS SITE_NAME
    , '&MNFST_CONTACT_NAME'                 AS CONTACT_NAME
    , '&MNFST_CONTACT_EMAIL'                AS CONTACT_EMAIL
    , 'TRINETX'                             AS CDM_NAME
    , ''                                    AS CDM_VERSION
    , ''                                    AS VOCABULARY_VERSION
    , 'Y'                                   AS N3C_PHENOTYPE_YN
    , phenoVers.version                     AS N3C_PHENOTYPE_VERSION
    , '&MNFST_SHIFT_DATE_YN'                AS SHIFT_DATE_YN
    , '&MNFST_MAX_SHIFT_DAYS'               AS MAX_NUM_SHIFT_DAYS
    , CURRENT_TIMESTAMP(0)::datetime        AS RUN_DATE
    , MAX(import_date)                      AS UPDATE_DATE
    , TIMESTAMPADD(DAY, '&MNFST_SUBMISSION_OFFSET', CURRENT_TIMESTAMP(0))::datetime    AS NEXT_SUBMISSION_DATE
FROM IDENTIFIER($TABLE_NAME)
LEFT JOIN n3c_pheno_version phenoVers on 1=1
GROUP BY phenoVers.version
;