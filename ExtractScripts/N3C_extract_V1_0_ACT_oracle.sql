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
    observation_fact
WHERE
    patient_num in (select patient_num from n3c_cohort) and start_date < '01-JAN-18';
    
    
--select patient dimension the demographic facts including ethnicity are included in observation_fact table as well
SELECT
    patient_num,
    birth_date,
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
    patient_dimension
WHERE
    patient_num in (select patient_num from n3c_cohort) ;
    
    
--select visit_dimensions (encounter/visit) vary by site    
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
    visit_dimension
WHERE
    patient_num in (select patient_num from n3c_cohort) and start_date < '01-JAN-18';
    
