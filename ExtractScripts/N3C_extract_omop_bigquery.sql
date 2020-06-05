--OMOP v5.3.1 extraction code for N3C
--Written by Kristin Kostka, OHDSI
--Code written for MS SQL Server
--This extract purposefully excludes the following OMOP tables: PERSON, OBSERVATION_PERIOD, VISIT_OCCURRENCE, CONDITION_OCCURRENCE, DRUG_EXPOSURE, PROCEDURE_OCCURRENCE, MEASUREMENT, OBSERVATION, LOCATION, CARE_SITE, PROVIDER,
--Currently this script extracts the derived tables for DRUG_ERA, DOSE_ERA, CONDITION_ERA as well (could be modified we run these in Palantir instead)
--Assumptions:
--	1. You have already built the N3C_COHORT table (with that name) prior to running this extract
--	2. You are extracting data with a lookback period to 1-1-2018

-- To run, you will need to find and replace @cdmDatabaseSchema and @resultsDatabaseSchema with your local OMOP schema details

--PERSON
--OUTPUT_FILE: PERSON.csv
select
   p.person_id,
   gender_concept_id,
   year_of_birth,
   month_of_birth,
   race_concept_id,
   ethnicity_concept_id,
   location_id,
   provider_id,
   care_site_id,
   person_source_value,
   gender_source_value,
   race_source_value,
   race_source_concept_id,
   ethnicity_source_value,
   ethnicity_source_concept_id
  from @cdmDatabaseSchema.person p
  join @resultsDatabaseSchema.n3c_cohort n
    on p.person_id = n.person_id;

--OBSERVATION_PERIOD
--OUTPUT_FILE: OBSERVATION_PERIOD.csv
select
   observation_period_id,
   p.person_id,
   cast(observation_period_start_date as date) as observation_period_start_date,
   cast(observation_period_end_date as date) as observation_period_end_date,
   period_type_concept_id
 from @cdmDatabaseSchema.observation_period p
 join @resultsDatabaseSchema.n3c_cohort n
   on p.person_id = n.person_id;

--VISIT_OCCURRENCE
--OUTPUT_FILE: VISIT_OCCURRENCE.csv
select
   visit_occurrence_id,
   n.person_id,
   visit_concept_id,
   cast(visit_start_date as date) as visit_start_date,
   cast(visit_start_datetime as date) as visit_start_datetime,
   cast(visit_end_date as date) as visit_end_date,
   cast(visit_end_datetime as date) as visit_end_datetime,
   visit_type_concept_id,
   provider_id,
   care_site_id,
   visit_source_value,
   visit_source_concept_id,
   admitting_source_concept_id,
   admitting_source_value,
   discharge_to_concept_id,
   discharge_to_source_value,
   preceding_visit_occurrence_id
from @cdmDatabaseSchema.visit_occurrence v
join @resultsDatabaseSchema.n3c_cohort n
  on v.person_id = n.person_id
where v.visit_start_date >= '1/1/2018';

--CONDITION_OCCURRENCE
--OUTPUT_FILE: CONDITION_OCCURRENCE.csv
select
   condition_occurrence_id,
   n.person_id,
   condition_concept_id,
   cast(condition_start_date as date) as condition_start_date,
   cast(condition_start_datetime as date) as condition_start_datetime,
   cast(condition_end_date as date) as condition_end_date,
   cast(condition_end_datetime as date) as condition_end_datetime,
   condition_type_concept_id,
   condition_status_concept_id,
   null as stop_reason,
   visit_occurrence_id,
   null as visit_detail_id,
   condition_source_value,
   condition_source_concept_id,
   null as condition_status_source_value
from @cdmDatabaseSchema.condition_occurrence co
join @resultsDatabaseSchema.n3c_cohort n
  on co.person_id = n.person_id
where co.condition_start_date >= '1/1/2018';

--DRUG_EXPOSURE
--OUTPUT_FILE: DRUG_EXPOSURE.csv
select
   drug_exposure_id,
   n.person_id,
   drug_concept_id,
   cast(drug_exposure_start_date as date) as drug_exposure_start_date,
   cast(drug_exposure_start_datetime as date) as drug_exposure_start_datetime,
   cast(drug_exposure_end_date as date) as drug_exposure_end_date,
   cast(drug_exposure_end_datetime as date) as drug_exposure_end_datetime,
   drug_type_concept_id,
   null as stop_reason,
   refills,
   quantity,
   days_supply,
   null as sig,
   route_concept_id,
   lot_number,
   provider_id,
   visit_occurrence_id,
   null as visit_detail_id,
   drug_source_value,
   drug_source_concept_id,
   route_source_value,
   dose_unit_source_value
from @cdmDatabaseSchema.drug_exposure de
join @resultsDatabaseSchema.n3c_cohort n
  on de.person_id = n.person_id
where de.drug_exposure_start_date >= '1/1/2018';

--PROCEDURE_OCCURRENCE
--OUTPUT_FILE: PROCEDURE_OCCURRENCE.csv
select
   procedure_occurrence_id,
   n.person_id,
   procedure_concept_id,
   cast(procedure_date as date) as procedure_date,
   cast(procedure_datetime as date) as procedure_datetime,
   procedure_type_concept_id,
   modifier_concept_id,
   quantity,
   provider_id,
   visit_occurrence_id,
   null as visit_detail_id,
   procedure_source_value,
   procedure_source_concept_id,
   null as modifier_source_value
from @cdmDatabaseSchema.procedure_occurrence po
join @resultsDatabaseSchema.n3c_cohort n
  on po.person_id = n.person_id
where po.procedure_date >= '1/1/2018';

--MEASUREMENT
--OUTPUT_FILE: MEASUREMENT.csv
select
   measurement_id,
   n.person_id,
   measurement_concept_id,
   cast(measurement_date as date) as measurement_date,
   cast(measurement_datetime as date) as measurement_datetime,
   null as measurement_time,
   measurement_type_concept_id,
   operator_concept_id,
   value_as_number,
   value_as_concept_id,
   unit_concept_id,
   range_low,
   range_high,
   provider_id,
   visit_occurrence_id,
   null as visit_detail_id,
   measurement_source_value,
   measurement_source_concept_id,
   null as unit_source_value,
   null as value_source_value
from @cdmDatabaseSchema.measurement m
join @resultsDatabaseSchema.n3c_cohort n
  on m.person_id = n.person_id
where m.measurement_date >= '1/1/2018';

--OBSERVATION
--OUTPUT_FILE: OBSERVATION.csv
select
   observation_id,
   n.person_id,
   observation_concept_id,
   cast(observation_date as date) as observation_date,
   cast(observation_datetime as date) as observation_datetime,
   observation_type_concept_id,
   value_as_number,
   value_as_string,
   value_as_concept_id,
   qualifier_concept_id,
   unit_concept_id,
   provider_id,
   visit_occurrence_id,
   null as visit_detail_id,
   observation_source_value,
   observation_source_concept_id,
   null as unit_source_value,
   null as qualifier_source_value
from @cdmDatabaseSchema.observation o
join @resultsDatabaseSchema.n3c_cohort n
  on o.person_id = n.person_id
where o.observation_date >= '1/1/2018';

--LOCATION
--OUTPUT_FILE: LOCATION.csv
select
   l.location_id,
   null as address_1, -- to avoid identifying information
   null as address_2, -- to avoid identifying information
   city,
   state,
   zip,
   county,
   null as location_source_value
from @cdmDatabaseSchema.location l
join (
        select distinct cs.location_id
        from @cdmDatabaseSchema.visit_occurrence vo
        join @resultsDatabaseSchema.n3c_cohort n
          on vo.person_id = n.person_id
        join @cdmDatabaseSchema.care_site cs
          on vo.care_site_id = cs.care_site_id
        union distinct select distinct p.location_id
        from @cdmDatabaseSchema.person p
        join @resultsDatabaseSchema.n3c_cohort n
          on p.person_id = n.person_id
      ) a
  on l.location_id = a.location_id
;

--CARE_SITE
--OUTPUT_FILE: CARE_SITE.csv
select
   cs.care_site_id,
   care_site_name,
   place_of_service_concept_id,
   location_id,
   null as care_site_source_value,
   null as place_of_service_source_value
from @cdmDatabaseSchema.care_site cs
join (
        select distinct care_site_id
        from @cdmDatabaseSchema.visit_occurrence vo
        join @resultsDatabaseSchema.n3c_cohort n
          on vo.person_id = n.person_id
      ) a
  on cs.care_site_id = a.care_site_id
;

--PROVIDER
--OUTPUT_FILE: PROVIDER.csv
select
   pr.provider_id,
   null as provider_name, -- to avoid accidentally identifying sites
   null as npi, -- to avoid accidentally identifying sites
   null as dea, -- to avoid accidentally identifying sites
   specialty_concept_id,
   care_site_id,
   null as year_of_birth,
   gender_concept_id,
   null as provider_source_value, -- to avoid accidentally identifying sites
   specialty_source_value,
   specialty_source_concept_id,
   gender_source_value,
   gender_source_concept_id
from @cdmDatabaseSchema.provider pr
join (
       select distinct provider_id
       from @cdmDatabaseSchema.visit_occurrence vo
       join @resultsDatabaseSchema.n3c_cohort n
          on vo.person_id = n.person_id
       union distinct select distinct provider_id
       from @cdmDatabaseSchema.drug_exposure de
       join @resultsDatabaseSchema.n3c_cohort n
          on de.person_id = n.person_id
       union distinct select distinct provider_id
       from @cdmDatabaseSchema.measurement m
       join @resultsDatabaseSchema.n3c_cohort n
          on m.person_id = n.person_id
       union distinct select distinct provider_id
       from @cdmDatabaseSchema.procedure_occurrence po
       join @resultsDatabaseSchema.n3c_cohort n
          on po.person_id = n.person_id
       union distinct select distinct provider_id
       from @cdmDatabaseSchema.observation o
       join @resultsDatabaseSchema.n3c_cohort n
          on o.person_id = n.person_id
     ) a
 on pr.provider_id = a.provider_id
;

--Note: it has yet to be decided if Era tables will be constructured downstream in Palantir platform.
-- If it is decided that eras will be reconstructed, these three tables will be omitted.

--DRUG_ERA
--OUTPUT_FILE: DRUG_ERA.csv
select
   drug_era_id,
   n.person_id,
   drug_concept_id,
   cast(drug_era_start_date as date) as drug_era_start_date,
   cast(drug_era_end_date as date) as drug_era_end_date,
   drug_exposure_count,
   gap_days
from @cdmDatabaseSchema.drug_era dre
join @resultsDatabaseSchema.n3c_cohort n
  on dre.person_id = n.person_id
where drug_era_start_date >= '1/1/2018';

--DOSE_ERA
--OUTPUT_FILE: DOSE_ERA.csv

select
   dose_era_id,
   n.person_id,
   drug_concept_id,
   unit_concept_id,
   dose_value,
   cast(dose_era_start_date as date) as dose_era_start_date,
   cast(dose_era_end_date as date) as dose_era_end_date
from @cdmDatabaseSchema.dose_era y join @resultsDatabaseSchema.n3c_cohort n on y.person_id = n.person_id
where y.dose_era_start_date >= '1/1/2018';


--CONDITION_ERA
--OUTPUT_FILE: CONDITION_ERA.csv
select
   condition_era_id,
   n.person_id,
   condition_concept_id,
   cast(condition_era_start_date as date) as condition_era_start_date,
   cast(condition_era_end_date as date) as condition_era_end_date,
   condition_occurrence_count
from @cdmDatabaseSchema.condition_era ce join @resultsDatabaseSchema.n3c_cohort n on ce.person_id = n.person_id
where condition_era_start_date >= '1/1/2018';

--DATA_COUNTS TABLE
--OUTPUT_FILE: DATA_COUNTS.csv
select * from
(select
   'PERSON' as table_name,
   (select count(*) from @cdmDatabaseSchema.person p join @resultsDatabaseSchema.n3c_cohort n on p.person_id = n.person_id) as row_count

union distinct select
   'OBSERVATION_PERIOD' as table_name,
   (select count(*) from @cdmDatabaseSchema.observation_period op join @resultsDatabaseSchema.n3c_cohort n on op.person_id = n.person_id and observation_period_start_date >= '1/1/2018') as row_count

union distinct select
   'VISIT_OCCURRENCE' as table_name,
   (select count(*) from @cdmDatabaseSchema.visit_occurrence vo join @resultsDatabaseSchema.n3c_cohort n on vo.person_id = n.person_id and visit_start_date >= '1/1/2018') as row_count

union distinct select
   'CONDITION_OCCURRENCE' as table_name,
   (select count(*) from @cdmDatabaseSchema.condition_occurrence co join @resultsDatabaseSchema.n3c_cohort n on co.person_id = n.person_id and condition_start_date >= '1/1/2018') as row_count

union distinct select
   'DRUG_EXPOSURE' as table_name,
   (select count(*) from @cdmDatabaseSchema.drug_exposure de join @resultsDatabaseSchema.n3c_cohort n on de.person_id = n.person_id and drug_exposure_start_date >= '1/1/2018') as row_count

union distinct select
   'PROCEDURE_OCCURRENCE' as table_name,
   (select count(*) from @cdmDatabaseSchema.procedure_occurrence po join @resultsDatabaseSchema.n3c_cohort n on po.person_id = n.person_id and procedure_date >= '1/1/2018') as row_count

union distinct select
   'MEASUREMENT' as table_name,
   (select count(*) from @cdmDatabaseSchema.measurement m join @resultsDatabaseSchema.n3c_cohort n on m.person_id = n.person_id and measurement_date >= '1/1/2018') as row_count

union distinct select
   'OBSERVATION' as table_name,
   (select count(*) from @cdmDatabaseSchema.observation o join @resultsDatabaseSchema.n3c_cohort n on o.person_id = n.person_id and observation_date >= '1/1/2018') as row_count

union distinct select
   'LOCATION' as table_name,
   (select count(*) from @cdmDatabaseSchema.location) as row_count

union distinct select
   'CARE_SITE' as table_name,
   (select count(*) from @cdmDatabaseSchema.care_site) as row_count

union distinct select
   'PROVIDER' as table_name,
   (select count(*) from @cdmDatabaseSchema.provider) as row_count

union distinct select
   'DRUG_ERA' as table_name,
   (select count(*) from @cdmDatabaseSchema.drug_era de join @resultsDatabaseSchema.n3c_cohort n on de.person_id = n.person_id and drug_era_start_date >= '1/1/2018') as row_count
   /**
UNION

select
   'DOSE_ERA' as TABLE_NAME,
   (select count(*) from DOSE_ERA ds JOIN @resultsDatabaseSchema.N3C_COHORT n ON ds.PERSON_ID = n.PERSON_ID AND DOSE_ERA_START_DATE >= '1/1/2018') as ROW_COUNT
   **/
union distinct select
   'CONDITION_ERA' as table_name,
   (select count(*) from @cdmDatabaseSchema.condition_era join @resultsDatabaseSchema.n3c_cohort on condition_era.person_id = n3c_cohort.person_id and condition_era_start_date >= '1/1/2018') as row_count
) s;

--MANIFEST TABLE: CHANGE PER YOUR SITE'S SPECS
--OUTPUT_FILE: MANIFEST.csv
select
   'OHDSI' as site_abbrev,
   ''    as site_name,
   'Jane Doe' as contact_name,
   'jane_doe@OHDSI.edu' as contact_email,
   'OMOP' as cdm_name,
   '5.3.1' as cdm_version,
   ''    as vocabulary_version,
   'Y' as n3c_phenotype_yn,
   '1.3' as n3c_phenotype_version,
   cast(CURRENT_DATE() as date) as run_date,
   cast(CURRENT_DATE() -2 as date) as update_date,		--change integer based on your site's data latency
   cast(CURRENT_DATE() +3 as date) as next_submission_date;
