---------------------------------------------------------------------------------------------------------
-- Drop existing output tables
---------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS :TNX_SCHEMA.n3c_patient;
DROP TABLE IF EXISTS :TNX_SCHEMA.n3c_encounter;
DROP TABLE IF EXISTS :TNX_SCHEMA.n3c_diagnosis;
DROP TABLE IF EXISTS :TNX_SCHEMA.n3c_procedure;
DROP TABLE IF EXISTS :TNX_SCHEMA.n3c_medication;
DROP TABLE IF EXISTS :TNX_SCHEMA.n3c_lab_result;
DROP TABLE IF EXISTS :TNX_SCHEMA.n3c_vital_signs;
DROP TABLE IF EXISTS :TNX_SCHEMA.n3c_data_counts;
DROP TABLE IF EXISTS :TNX_SCHEMA.n3c_manifest;

---------------------------------------------------------------------------------------------------------
-- PATIENTS
-- OUTPUT_FILE: PATIENT.csv
---------------------------------------------------------------------------------------------------------
CREATE TABLE :TNX_SCHEMA.n3c_patient AS
SELECT
	n3c.patient_id	AS PATIENT_ID
	, LEFT(pt.birth_date::varchar,7)	AS BIRTH_DATE	--only pull YYYY-MM
	, pt.vital_status	AS VITAL_STATUS
	, pt.death_date::datetime	AS DEATH_DATE
	, LEFT(pt.postal_code,5)	AS POSTAL_CODE
	, pt.gender		AS SEX
	, pt.race		AS RACE
	, pt.ethnicity	AS ETHNICITY
	, pt.language	AS LANGUAGE
	, pt.marital_status	AS MARITAL_STATUS
	, pt.smoking_status	AS SMOKING_STATUS
	, map_sx.mt_code	AS MAPPED_SEX
	, map_rc.mt_code	AS MAPPED_RACE
	, map_et.mt_code	AS MAPPED_ETHNICITY
	, map_ms.mt_code	AS MAPPED_MARITAL_STATUS
FROM :TNX_SCHEMA.n3c_cohort n3c
	JOIN :TNX_SCHEMA.patient pt ON pt.patient_id = n3c.patient_id
	LEFT JOIN :TNX_SCHEMA.mapping map_sx ON map_sx.provider_code = ('DEM|GENDER:' || pt.gender)
	LEFT JOIN :TNX_SCHEMA.mapping map_rc ON map_rc.provider_code = ('DEM|RACE:' || pt.race)
	LEFT JOIN :TNX_SCHEMA.mapping map_et ON map_et.provider_code = ('DEM|ETHNICITY:' || pt.ethnicity)
	LEFT JOIN :TNX_SCHEMA.mapping map_ms ON map_ms.provider_code = ('DEM|MARITAL:' || pt.marital_status)
;

---------------------------------------------------------------------------------------------------------
-- ENCOUNTERS
-- OUTPUT FILE: ENCOUNTER.csv
---------------------------------------------------------------------------------------------------------
CREATE TABLE :TNX_SCHEMA.n3c_encounter AS
SELECT
	n3c.patient_id	AS PATIENT_ID
	, enc.encounter_id	AS ENCOUNTER_ID
	, enc.type	AS ENCOUNTER_TYPE
	, enc.start_date	AS START_DATE
	, enc.end_date		AS END_DATE
	, enc.length_of_stay	AS LENGTH_OF_STAY
	, enc.orphan	AS ORPHAN_FLAG
	, map_et.mt_code	AS MAPPED_ENCOUNTER_TYPE
FROM :TNX_SCHEMA.n3c_cohort n3c
	JOIN :TNX_SCHEMA.encounter enc ON enc.patient_id = n3c.patient_id AND enc.start_date >= '2018-01-01'
	LEFT JOIN :TNX_SCHEMA.mapping map_et ON map_et.provider_code = ('TNX:ENCOUNTER_TYPE:' || enc.type)
;

---------------------------------------------------------------------------------------------------------
-- DIAGNOSES
-- OUTPUT_FILE: DIAGNOSIS.csv
---------------------------------------------------------------------------------------------------------
-- NOTES:
--		-Orphan = record with no associated patient/encounter
---------------------------------------------------------------------------------------------------------
CREATE TABLE :TNX_SCHEMA.n3c_diagnosis AS
SELECT
	n3c.patient_id	AS PATIENT_ID
	, dx.encounter_id	AS ENCOUNTER_ID
	, dx.code_system	AS DX_CODE_SYSTEM
	, dx.code	AS DX_CODE
	, dx.date	AS DATE
	, dx.description	AS DX_DESCRIPTION
	, dx.principal_indicator	AS PRINCIPAL_INDICATOR
	, dx.source	AS DX_SOURCE
	, dx.orphan	AS ORPHAN_FLAG
	, dx.orphan_reason	AS ORPHAN_REASON
	, SPLIT_PART(map_dx.mt_code,':',2)	AS MAPPED_CODE_SYSTEM
	, SPLIT_PART(map_dx.mt_code,':',3)	AS MAPPED_CODE
FROM :TNX_SCHEMA.n3c_cohort n3c
	JOIN :TNX_SCHEMA.diagnosis dx ON dx.patient_id = n3c.patient_id AND dx.date >= '2018-01-01'
	LEFT JOIN :TNX_SCHEMA.mapping map_dx ON map_dx.provider_code = (dx.code_system || ':' || dx.code)
;

---------------------------------------------------------------------------------------------------------
-- PROCEDURES
-- OUTPUT_FILE: PROCEDURE.csv
---------------------------------------------------------------------------------------------------------
-- NOTES:
--	 	-Orphan = record with no associated patient/encounter
---------------------------------------------------------------------------------------------------------
CREATE TABLE :TNX_SCHEMA.n3c_procedure AS
SELECT
	n3c.patient_id	AS PATIENT_ID
	, px.encounter_id	AS ENCOUNTER_ID
	, px.code_system	AS PX_CODE_SYSTEM
	, px.code	AS PX_CODE
	, px.description	AS PX_DESCRIPTION
	, px.date	AS DATE
	, px.orphan	AS ORPHAN_FLAG
	, px.orphan_reason	AS ORPHAN_REASON
	, CASE
		WHEN REGEXP_COUNT(map_px.mt_code,':') = 2 THEN SPLIT_PART(map_px.mt_code,':',2)
		WHEN REGEXP_COUNT(map_px.mt_code,':') = 1 THEN SPLIT_PART(map_px.mt_code,':',1)
		ELSE ''
		END	AS MAPPED_CODE_SYSTEM
	, CASE
		WHEN REGEXP_COUNT(map_px.mt_code,':') = 2 THEN SPLIT_PART(map_px.mt_code,':',3)
		WHEN REGEXP_COUNT(map_px.mt_code,':') = 1 THEN SPLIT_PART(map_px.mt_code,':',2)
		ELSE map_px.mt_code
		END	AS MAPPED_CODE
FROM :TNX_SCHEMA.n3c_cohort n3c
	JOIN :TNX_SCHEMA.procedure px ON px.patient_id = n3c.patient_id AND px.date >= '2018-01-01'
	LEFT JOIN :TNX_SCHEMA.mapping map_px ON map_px.provider_code = (px.code_system || ':' || px.code)
;

---------------------------------------------------------------------------------------------------------
-- MEDICATIONS
-- OUTPUT_FILE: MEDICATION.csv
---------------------------------------------------------------------------------------------------------
-- NOTES:
--	 	-Orphan = record with no associated patient/encounter
---------------------------------------------------------------------------------------------------------
CREATE TABLE :TNX_SCHEMA.n3c_medication AS
SELECT
	n3c.patient_id	AS PATIENT_ID
	, rx.encounter_id	AS ENCOUNTER_ID
	, rx.code_system	AS RX_CODE_SYSTEM
	, rx.code	AS RX_CODE
	, rx.name	AS RX_DESCRIPTION
	, rx.alt_drug_code_sys	AS ALT_DRUG_CODE_SYS
	, rx.alt_drug_code	AS ALT_DRUG_CODE
	, rx.start_date::datetime	AS START_DATE
	, rx.route_of_administration	AS ROUTE_OF_ADMINISTRATION
	, rx.units_per_administration	AS UNITS_PER_ADMINISTRATION
	, rx.frequency	AS FREQUENCY
	, rx.strength	AS STRENGTH
	, rx.form	AS FORM
	, rx.duration	AS DURATION
	, rx.refills	AS REFILLS
	, rx.source	AS RX_SOURCE
	, rx.indication_code_system	AS INDICATION_CODE_SYSTEM
	, rx.indication_code	AS INDICATION_CODE
	, rx.indication_desc	AS INDICATION_DESC
	, rx.alt_drug_name	AS ALT_DRUG_NAME
	, rx.clinical_drug	AS CLINICAL_DRUG
	, rx.end_date::datetime	AS END_DATE
	, rx.quantity_dispensed	AS QTY_DISPENSED
	, rx.dose_amount	AS DOSE_AMOUNT
	, rx.dose_unit	AS DOSE_UNIT
	, rx.brand	AS BRAND
	, rx.orphan	AS ORPHAN_FLAG
	, rx.orphan_reason	AS ORPHAN_REASON
	, CASE
		WHEN REGEXP_COUNT(map_rx.mt_code,':') = 2 THEN SPLIT_PART(map_rx.mt_code,':',2)
		WHEN REGEXP_COUNT(map_rx.mt_code,':') = 1 THEN SPLIT_PART(map_rx.mt_code,':',1)
		ELSE ''
		END	AS MAPPED_CODE_SYSTEM
	, CASE
		WHEN REGEXP_COUNT(map_rx.mt_code,':') = 2 THEN SPLIT_PART(map_rx.mt_code,':',3)
		WHEN REGEXP_COUNT(map_rx.mt_code,':') = 1 THEN SPLIT_PART(map_rx.mt_code,':',2)
		ELSE map_rx.mt_code
		END	AS MAPPED_CODE
FROM :TNX_SCHEMA.n3c_cohort n3c
	JOIN :TNX_SCHEMA.medication rx ON rx.patient_id = n3c.patient_id AND rx.start_date >= '2018-01-01'
	LEFT JOIN :TNX_SCHEMA.mapping map_rx ON map_rx.provider_code = (rx.code_system || ':' || rx.code)
;

---------------------------------------------------------------------------------------------------------
-- LAB RESULTS
-- OUTPUT_FILE: LAB_RESULT.csv
---------------------------------------------------------------------------------------------------------
-- NOTES:
--	 	-Orphan = record with no associated patient/encounter
---------------------------------------------------------------------------------------------------------
CREATE TABLE :TNX_SCHEMA.n3c_lab_result AS
SELECT
	n3c.patient_id	AS PATIENT_ID
	, lab.encounter_id	AS ENCOUNTER_ID
	, lab.observation_code_system	AS LAB_CODE_SYSTEM
	, lab.observation_code	AS LAB_CODE
	, lab.observation_desc	AS LAB_DESCRIPTION
	, lab.battery_code_system	AS BATTERY_CODE_SYSTEM
	, lab.battery_code	AS BATTERY_CODE
	, lab.battery_desc	AS BATTERY_DESC
	, lab.section	AS SECTION
	, lab.normal_range	AS NORMAL_RANGE
	, lab.test_date	AS TEST_DATE
	, lab.result_type	AS RESULT_TYPE
	, lab.lab_result_num_val	AS NUMERIC_RESULT_VAL
	, lab.lab_result_text_val	AS TEXT_RESULT_VAL
	, lab.units_of_measure	AS UNITS_OF_MEASURE
	, lab.orphan	AS ORPHAN_FLAG
	, lab.orphan_reason	AS ORPHAN_REASON
	, SPLIT_PART(map_lab.mt_code,':',2)	AS MAPPED_CODE_SYSTEM
	, SPLIT_PART(map_lab.mt_code,':',3)	AS MAPPED_CODE
FROM :TNX_SCHEMA.n3c_cohort n3c
	JOIN :TNX_SCHEMA.lab_result lab ON lab.patient_id = n3c.patient_id AND lab.test_date >= '2018-01-01'
	LEFT JOIN :TNX_SCHEMA.mapping map_lab ON map_lab.provider_code = (lab.observation_code_system || ':' || lab.observation_code)
;

---------------------------------------------------------------------------------------------------------
-- VITAL SIGNS
-- OUTPUT_FILE: VITAL_SIGNS.csv
---------------------------------------------------------------------------------------------------------
-- NOTES:
--	 	-Orphan = record with no associated patient/encounter
---------------------------------------------------------------------------------------------------------
CREATE TABLE :TNX_SCHEMA.n3c_vital_signs AS
SELECT
	n3c.patient_id	AS PATIENT_ID
	, vit.encounter_id	AS ENCOUNTER_ID
	, vit.measure_date	AS MEASURE_DATE
	, vit.code_system	AS VITAL_CODE_SYSTEM
	, vit.code	AS VITAL_CODE
	, vit.description	AS VITAL_DESCRIPTION
	, vit.unit_of_measure	AS UNIT_OF_MEASURE
	, vit.result_type	AS RESULT_TYPE
	, vit.numeric_value	AS NUMERIC_RESULT_VAL
	, vit.text_value	AS TEXT_RESULT_VAL
	, vit.orphan	AS ORPHAN_FLAG
	, vit.orphan_reason	AS ORPHAN_REASON
	, SPLIT_PART(map_vit.mt_code,':',2)	AS MAPPED_CODE_SYSTEM
	, SPLIT_PART(map_vit.mt_code,':',3)	AS MAPPED_CODE
FROM :TNX_SCHEMA.n3c_cohort n3c
	JOIN :TNX_SCHEMA.vital_signs vit ON vit.patient_id = n3c.patient_id AND vit.measure_date >= '2018-01-01'
	LEFT JOIN :TNX_SCHEMA.mapping map_vit ON map_vit.provider_code = (vit.code_system || ':' || vit.code)
;

---------------------------------------------------------------------------------------------------------
-- DATA COUNTS
-- OUTPUT_FILE: DATA_COUNTS.csv
---------------------------------------------------------------------------------------------------------
CREATE TABLE :TNX_SCHEMA.n3c_data_counts (
	TABLE_NAME	varchar(200)
	, ROW_COUNT	int
);

INSERT INTO :TNX_SCHEMA.n3c_data_counts SELECT 'PATIENT', count(1) FROM :TNX_SCHEMA.n3c_patient;
INSERT INTO :TNX_SCHEMA.n3c_data_counts SELECT 'ENCOUNTER', count(1) FROM :TNX_SCHEMA.n3c_encounter;
INSERT INTO :TNX_SCHEMA.n3c_data_counts SELECT 'DIAGNOSIS', count(1) FROM :TNX_SCHEMA.n3c_diagnosis;
INSERT INTO :TNX_SCHEMA.n3c_data_counts SELECT 'PROCEDURE', count(1) FROM :TNX_SCHEMA.n3c_procedure;
INSERT INTO :TNX_SCHEMA.n3c_data_counts SELECT 'MEDICATION', count(1) FROM :TNX_SCHEMA.n3c_medication;
INSERT INTO :TNX_SCHEMA.n3c_data_counts SELECT 'LAB_RESULT', count(1) FROM :TNX_SCHEMA.n3c_lab_result;
INSERT INTO :TNX_SCHEMA.n3c_data_counts SELECT 'VITAL_SIGNS', count(1) FROM :TNX_SCHEMA.n3c_vital_signs;
COMMIT;

---------------------------------------------------------------------------------------------------------
-- MANIFEST TABLE (updated per site)
-- OUTPUT_FILE: MANIFEST.csv
---------------------------------------------------------------------------------------------------------
CREATE TABLE :TNX_SCHEMA.n3c_manifest AS
SELECT
	:MNFST_SITE_ABBREV	AS SITE_ABBREV
	, :MNFST_SITE_NAME	AS SITE_NAME
	, :MNFST_CONTACT_NAME	AS CONTACT_NAME
	, :MNFST_CONTACT_EMAIL	AS CONTACT_EMAIL
	, 'TRINETX'	AS CDM_NAME
	, ''	AS CDM_VERSION
	, ''	AS VOCABULARY_VERSION
	, 'Y'	AS N3C_PHENOTYPE_YN
	, :MNFST_PHENO_VERSION	AS N3C_PHENOTYPE_VERSION
	, CURRENT_TIMESTAMP(0)::datetime	AS RUN_DATE
	, MAX(import_date)	AS UPDATE_DATE
	, TIMESTAMPADD(DAY, :MNFST_SUBMISSION_OFFSET, CURRENT_TIMESTAMP(0))::datetime	AS NEXT_SUBMISSION_DATE
FROM :LOG_SCHEMA.audit
;