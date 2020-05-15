--ACT/i2b2 extraction code for N3C
--ACT Ontology Version 2.0.1 and optionally ACT_COVID V3
--Written by Michele Morris, UPitt
--Code written for MS SQL Server
--This extract includes only i2b2 fact relevant tables and the concept dimension table for mapping concept codes
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
    patient_num,
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
    start_date >= '1/1/2018';
    
    
--select patient dimension the demographic facts including ethnicity are included in observation_fact table as well
--PATIENT_DIMENSION TABLE
--OUTPUT_FILE: PATIENT_DIMENSION.csv
SELECT
    patient_num,
    LEFT(CONVERT(VARCHAR(20), BIRTH_DATE, 120),7) as birth_date,
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
    source_id,
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
    upload_id,
    age_at_visit,
    n_hosp_service_cd,
    n_provider_id,
    visit_year,
    n_enc_type_cd,
    n_dept_facility_cd,
    patient_num
FROM
    visit_dimiension join n3c_cohort on visit_dimension.patient_num = n3c_cohort.patient_num
WHERE
    start_date < '1/1/2018'
    
--DATA_COUNTS TABLE
--OUTPUT_FILE: DATA_COUNTS.csv
select * from 
(select 
   'OBSERVATION_FACT' as TABLE_NAME, 
   (select count(*) from OBSERVATION_FACT join n3c_cohort on observation_fact.patient_num = n3c_cohort.patient_num 
WHERE
    start_date >= '1/1/2018') as ROW_COUNT

UNION
   
select 
   'VISIT_DIMENSION' as TABLE_NAME,
   (select count(*) from VISIT_DIMENSION join n3c_cohort on visit_dimension.patient_num = n3c_cohort.patient_num
WHERE
    start_date < '1/1/2018') as ROW_COUNT

UNION
   
select 
   'PATIENT_DIMENSION' as TABLE_NAME,
   (select count(*) from PATIENT_DIMENSION join n3c_cohort on patient_dimension.patient_num = n3c_cohort.patient_num) as ROW_COUNT

UNION
   
select 
   'CONCEPT_DIMENSION' as TABLE_NAME,
   (select count(*) from CONCEPT_DIMENSION) as ROW_COUNT);

--MANIFEST TABLE: CHANGE PER YOUR SITE'S SPECS
--OUTPUT_FILE: MANIFEST.csv
select
   'UNC' as SITE_ABBREV,
   'Jane Doe' as CONTACT_NAME,
   'jane_doe@unc.edu' as CONTACT_EMAIL,
   'ACT' as CDM_NAME,
   '2.0.1' as CDM_VERSION,
   'Y' as N3C_PHENOTYPE_YN,
   '1.3' as N3C_PHENOTYPE_VERSION,
   CONVERT(VARCHAR(20), GETDATE(), 120) as RUN_DATE,
   CONVERT(VARCHAR(20), GETDATE() -2, 120) as UPDATE_DATE,		--change integer based on your site's data latency
   CONVERT(VARCHAR(20), GETDATE() +3, 120) as NEXT_SUBMISSION_DATE;					--change integer based on your site's load frequency