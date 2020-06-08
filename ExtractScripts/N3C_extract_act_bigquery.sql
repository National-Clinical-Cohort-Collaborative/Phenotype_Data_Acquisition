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
select
    concept_path,
    concept_cd,
    name_char,
    update_date,
    download_date,
    import_date,
    sourcesystem_cd,
    upload_id
from
    @cdmDatabaseSchema.concept_dimension;

--select all facts - concept_cd determines domain/value    
--OBSERVATION_FACT TABLE
--OUTPUT_FILE: OBSERVATION_FACT.CSV
select
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
from
    @cdmDatabaseSchema.observation_fact join @resultsDatabaseSchema.n3c_cohort on observation_fact.patient_num = n3c_cohort.patient_num 
where
    start_date >= '1/1/2018';
    
    
--select patient dimension the demographic facts including ethnicity are included in observation_fact table as well
--PATIENT_DIMENSION TABLE
--OUTPUT_FILE: PATIENT_DIMENSION.csv
select
    patient_dimension.patient_num,
    SUBSTR(cast(birth_date as STRING),0,7) as birth_date,
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
from
     @cdmDatabaseSchema.patient_dimension join @resultsDatabaseSchema.n3c_cohort on patient_dimension.patient_num = n3c_cohort.patient_num ;

    
    
--select visit_dimensions (encounter/visit) vary by site  
--VISIT_DIMENSION TABLE
--OUTPUT_FILE: VISIT_DIMENSION.csv
select
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
    upload_id,
from
    @cdmDatabaseSchema.visit_dimension join @resultsDatabaseSchema.n3c_cohort on visit_dimension.patient_num = n3c_cohort.patient_num
where    start_date >= '1/1/2018';
    
--DATA_COUNTS TABLE
--OUTPUT_FILE: DATA_COUNTS.csv
select * from 
(select 
   'OBSERVATION_FACT' as table_name, 
   (select count(*) from @cdmDatabaseSchema.observation_fact join @resultsDatabaseSchema.n3c_cohort on observation_fact.patient_num = n3c_cohort.patient_num 
where
    start_date >= '1/1/2018') as row_count

union distinct select 
   'VISIT_DIMENSION' as table_name,
   (select count(*) from @cdmDatabaseSchema.visit_dimension join @resultsDatabaseSchema.n3c_cohort on visit_dimension.patient_num = n3c_cohort.patient_num
where
    start_date >= '1/1/2018') as row_count

union distinct select 
   'PATIENT_DIMENSION' as table_name,
   (select count(*) from @cdmDatabaseSchema.patient_dimension join @resultsDatabaseSchema.n3c_cohort on patient_dimension.patient_num = n3c_cohort.patient_num) as row_count

union distinct select 
   'CONCEPT_DIMENSION' as table_name,
   (select count(*) from @cdmDatabaseSchema.concept_dimension) as row_count);

--MANIFEST TABLE: CHANGE PER YOUR SITE'S SPECS
--OUTPUT_FILE: MANIFEST.csv
select
   'UNC' as site_abbrev,
   'University of North Carolina at Chapel Hill' as site_name,
   'Jane Doe' as contact_name,
   'jane_doe@unc.edu' as contact_email,
   'ACT' as cdm_name,
   '2.0.1' as cdm_version,
   null as vocabulary_version, --leave null as this only applies to OMOP
   'Y' as n3c_phenotype_yn,
   '1.3' as n3c_phenotype_version,
   cast(CURRENT_DATE() as date) as run_date,
   cast( DATE_ADD(cast(CURRENT_DATE() as date), interval -2 DAY) as date) as update_date,	--change integer based on your site's data latency
   cast( DATE_ADD(cast(CURRENT_DATE() as date), interval 3 DAY) as date) as next_submission_date;
