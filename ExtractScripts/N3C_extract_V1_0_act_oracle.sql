--ACT/i2b2 extraction code for N3C
--ACT Ontology Version 2.0.1 and optionally ACT_COVID V3
--Written by Michele Morris, UPitt
--Code written for Oracle
--This extract includes only i2b2 fact relevant tables and the concept dimension tabble for mapping concept codes
--Assumptions: 
--	1. You have already built the N3C_COHORT table (with that name) prior to running this extract
--	2. You are extracting data with a lookback period of 2 years (Not Yet)
--  3. This currently only works for the traditional i2b2 single fact table

--select concept_dimension table to allow the harmonization team to harmonize local coding

--CONCEPT_DIMENSION TABLE
--OUTPUT_FILE: CONCEPT_DIMENSION.CSV
SELECT
    concept_path,
    concept_cd,
    name_char,
    update_date,
    download_date,
    import_date,
    sourcesystem_cd,
    upload_id
FROM
    concept_dimension;

--select all facts - concept_cd determines domain/value    
--OBSERVATION_FACT TABLE
--OUTPUT_FILE: OBSERVATION_FACT.CSV
SELECT
    encounter_num,
    observation_fact.patient_num,
    concept_cd,
    provider_id,
    start_date,
    end_date,
    modifier_cd,
    instance_num,
    valtype_cd,
    location_cd,
    tval_char,
    nval_num,
    valueflag_cd,
    units_cd,
    update_date,
    download_date,
    import_date,
    sourcesystem_cd,
    upload_id
FROM
    observation_fact join n3c_cohort on observation_fact.patient_num = n3c_cohort.patient_num 
WHERE
    start_date >= '01-JAN-18';
    
    
--select patient dimension the demographic facts including ethnicity are included in observation_fact table as well
--PATIENT_DIMENSION TABLE
--OUTPUT_FILE: PATIENT_DIMENSION.csv
SELECT
    patient_dimension.patient_num,
    to_char(BIRTH_DATE, 'MM/YYYY') as birth_date,
    death_date,
    race_cd,
    sex_cd,
    vital_status_cd,
    age_in_years_num,
    language_cd,
    marital_status_cd,
    religion_cd,
    zip_cd,
    statecityzip_path,
    income_cd,
    update_date,
    download_date,
    import_date,
    sourcesystem_cd,
    upload_id
FROM
     patient_dimension join n3c_cohort on patient_dimension.patient_num = n3c_cohort.patient_num ;

    
    
--select visit_dimensions (encounter/visit) vary by site  
--VISIT_DIMENSION TABLE
--OUTPUT_FILE: VISIT_DIMENSION.csv
SELECT
    visit_dimension.patient_num,
    encounter_num,
    active_status_cd,
    start_date,
    end_date,
    inout_cd,
    location_cd,
    location_path,
    length_of_stay,
    update_date,
    download_date,
    import_date,
    sourcesystem_cd,
    upload_id
FROM
    visit_dimension join n3c_cohort on visit_dimension.patient_num = n3c_cohort.patient_num
WHERE
    start_date  >= '01-JAN-18';
    
--DATA_COUNTS TABLE
--OUTPUT_FILE: DATA_COUNTS.csv
select * from 
(select 
   'OBSERVATION_FACT' as TABLE_NAME, 
   (select count(*) from OBSERVATION_FACT join n3c_cohort on observation_fact.patient_num = n3c_cohort.patient_num 
WHERE
    start_date >= '01-JAN-18') as ROW_COUNT
from DUAL

UNION
   
select 
   'VISIT_DIMENSION' as TABLE_NAME,
   (select count(*) from VISIT_DIMENSION join n3c_cohort on visit_dimension.patient_num = n3c_cohort.patient_num
WHERE
    start_date  >= '01-JAN-18') as ROW_COUNT
from DUAL

UNION
   
select 
   'PATIENT_DIMENSION' as TABLE_NAME,
   (select count(*) from PATIENT_DIMENSION join n3c_cohort on patient_dimension.patient_num = n3c_cohort.patient_num) as ROW_COUNT
from DUAL

UNION
   
select 
   'CONCEPT_DIMENSION' as TABLE_NAME,
   (select count(*) from CONCEPT_DIMENSION) as ROW_COUNT
from DUAL);

--MANIFEST TABLE: CHANGE PER YOUR SITE'S SPECS
--OUTPUT_FILE: MANIFEST.csv
select
   'UNC' as SITE_ABBREV,
   'University of North Carolina at Chapel Hill' as SITE_NAME,
   'Jane Doe' as CONTACT_NAME,
   'jane_doe@unc.edu' as CONTACT_EMAIL,
   'ACT' as CDM_NAME,
   '2.0.1' as CDM_VERSION,
   null as VOCABULARY_VERSION, --leave null as this only applies to OMOP
   'Y' as N3C_PHENOTYPE_YN,
   '1.3' as N3C_PHENOTYPE_VERSION,
   TO_CHAR(sysdate, 'YYYY-MM-DD HH24:MI:SS') as RUN_DATE,
   TO_CHAR(sysdate -2, 'YYYY-MM-DD HH24:MI:SS') as UPDATE_DATE,		--change integer based on your site's data latency
   TO_CHAR(sysdate +3, 'YYYY-MM-DD HH24:MI:SS') as NEXT_SUBMISSION_DATE					--change integer based on your site's load frequency
from dual;
    
