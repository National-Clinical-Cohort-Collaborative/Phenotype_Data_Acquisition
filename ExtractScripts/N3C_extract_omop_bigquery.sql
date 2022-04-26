/**
OMOP v5.3.1 extraction code for N3C
Author: Kristin Kostka (OHDSI), Robert Miller (Tufts)

HOW TO RUN:
If you are not using the R or Python exporters, you will need to find and replace @cdmDatabaseSchema and @resultsDatabaseSchema with your local OMOP schema details


USER NOTES:
This extract pulls the following OMOP tables: PERSON, OBSERVATION_PERIOD, VISIT_OCCURRENCE, CONDITION_OCCURRENCE, DRUG_EXPOSURE, PROCEDURE_OCCURRENCE, MEASUREMENT, OBSERVATION, LOCATION, CARE_SITE, PROVIDER, DEATH, DRUG_ERA, CONDITION_ERA
As an OMOP site, you are expected to be populating derived tables (OBSERVATION_PERIOD, DRUG_ERA, CONDITION_ERA)
Please refer to the OMOP site instructions for assistance on how to generate these tables.


SCRIPT ASSUMPTIONS:
1. You have already built the N3C_COHORT table (with that name) prior to running this extract
2. You are extracting data with a lookback period to 1-1-2018
3. You have existing tables for each of these extracted tables. If you do not, at a minimum, you MUST create a shell table so it can extract an empty table. Failure to create shells for missing table will result in ingestion problems.

RELEASE DATE: 2-10-2020
**/

--MANIFEST TABLE: CHANGE PER YOUR SITE'S SPECS
--OUTPUT_FILE: MANIFEST.csv
select
   '@siteAbbrev' as site_abbrev,
   '@siteName'    as site_name,
   '@contactName' as contact_name,
   '@contactEmail' as contact_email,
   '@cdmName' as cdm_name,
   '@cdmVersion' as cdm_version,
   (SELECT  vocabulary_version from @resultsDatabaseSchema.n3c_pre_cohort LIMIT 1) as vocabulary_version,
   'Y' as n3c_phenotype_yn,
   (SELECT  phenotype_version from @resultsDatabaseSchema.n3c_pre_cohort LIMIT 1) as n3c_phenotype_version,
   '@shiftDateYN' as shift_date_yn,
   '@maxNumShiftDays' as max_num_shift_days,
   cast(CURRENT_DATE() as datetime) as run_date,
   cast( DATE_ADD(IF(SAFE_CAST(CURRENT_DATE()  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(CURRENT_DATE()  AS STRING)),SAFE_CAST(CURRENT_DATE()  AS DATE)), interval -@dataLatencyNumDays DAY) as datetime) as update_date,	--change integer based on your site's data latency
   cast( DATE_ADD(IF(SAFE_CAST(CURRENT_DATE()  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(CURRENT_DATE()  AS STRING)),SAFE_CAST(CURRENT_DATE()  AS DATE)), interval @daysBetweenSubmissions DAY) as datetime) as next_submission_date;

--VALIDATION_SCRIPT
--OUTPUT_FILE: EXTRACT_VALIDATION.csv
  select 'PERSON' table_name
	,count(*) dup_count
  from @cdmDatabaseSchema.person x
inner join @resultsDatabaseSchema.n3c_cohort n3c
on x.person_id = n3c.person_id
  group by  x.person_id
 having count(*) > 1

union distinct select 'OBSERVATION_PERIOD' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.observation_period x
inner join @resultsDatabaseSchema.n3c_cohort n3c
on x.person_id = n3c.person_id
and x.observation_period_start_date > DATE(2018, 01, 01)
  group by  x.observation_period_id
 having count(*) > 1

union distinct select 'VISIT_OCCURRENCE' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.visit_occurrence x
inner join @resultsDatabaseSchema.n3c_cohort n3c
on x.person_id = n3c.person_id
and x.visit_start_date > DATE(2018, 01, 01)
  group by  x.visit_occurrence_id
 having count(*) > 1

union distinct select 'CONDITION_OCCURRENCE' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.condition_occurrence x
inner join @resultsDatabaseSchema.n3c_cohort n3c
on x.person_id = n3c.person_id
and x.condition_start_date > DATE(2018, 01, 01)
  group by  x.condition_occurrence_id
 having count(*) > 1

union distinct select 'DRUG_EXPOSURE' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.drug_exposure x
inner join @resultsDatabaseSchema.n3c_cohort n3c
on x.person_id = n3c.person_id
and x.drug_exposure_start_date > DATE(2018, 01, 01)
  group by  x.drug_exposure_id
 having count(*) > 1

 union distinct select 'DEVICE_EXPOSURE' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.device_exposure x
inner join @resultsDatabaseSchema.n3c_cohort n3c
on x.person_id = n3c.person_id
and x.device_exposure_start_date > DATE(2018, 01, 01)
  group by  x.device_exposure_id
 having count(*) > 1

union distinct select 'PROCEDURE_OCCURRENCE' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.procedure_occurrence x
inner join @resultsDatabaseSchema.n3c_cohort n3c
on x.person_id = n3c.person_id
and x.procedure_date > DATE(2018, 01, 01)
  group by  x.procedure_occurrence_id
 having count(*) > 1

union distinct select 'MEASUREMENT' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.measurement x
inner join @resultsDatabaseSchema.n3c_cohort n3c
on x.person_id = n3c.person_id
and x.measurement_date > DATE(2018, 01, 01)
  group by  x.measurement_id
 having count(*) > 1

union distinct select 'OBSERVATION' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.observation x
inner join @resultsDatabaseSchema.n3c_cohort n3c
on x.person_id = n3c.person_id
and x.observation_date > DATE(2018, 01, 01)
  group by  x.observation_id
 having count(*) > 1

union distinct select 'LOCATION' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.location x
  group by  x.location_id
 having count(*) > 1

union distinct select 'CARE_SITE' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.care_site x
  group by  x.care_site_id
 having count(*) > 1

union distinct select 'PROVIDER' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.provider x
  group by  x.provider_id
 having count(*) > 1

union distinct select 'DRUG_ERA' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.drug_era x
inner join @resultsDatabaseSchema.n3c_cohort n3c
on x.person_id = n3c.person_id
and x.drug_era_start_date > DATE(2018, 01, 01)
  group by  x.drug_era_id
 having count(*) > 1

union distinct select 'CONDITION_ERA' table_name
	, count(*) dup_count
  from @cdmDatabaseSchema.condition_era x
inner join @resultsDatabaseSchema.n3c_cohort n3c
on x.person_id = n3c.person_id
and x.condition_era_start_date > DATE(2018, 01, 01)
  group by  x.condition_era_id
 having count(*) > 1             ;

--PERSON
--OUTPUT_FILE: PERSON.csv
select
   p.person_id,
   gender_concept_id,
   IFNULL(year_of_birth,extract(year from birth_datetime)) as year_of_birth,
   IFNULL(month_of_birth,extract(month from birth_datetime)) as month_of_birth,
   race_concept_id,
   ethnicity_concept_id,
   location_id,
   provider_id,
   care_site_id,
   null as person_source_value,
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
   cast(observation_period_start_date as datetime) as observation_period_start_date,
   cast(observation_period_end_date as datetime) as observation_period_end_date,
   period_type_concept_id
 from @cdmDatabaseSchema.observation_period p
 join @resultsDatabaseSchema.n3c_cohort n
   on p.person_id = n.person_id
   and (p.observation_period_start_date >= DATE(2018,01,01) OR p.observation_period_end_date >= DATE(2018,01,01));

--VISIT_OCCURRENCE
--OUTPUT_FILE: VISIT_OCCURRENCE.csv
select
   visit_occurrence_id,
   n.person_id,
   visit_concept_id,
   cast(visit_start_date as datetime) as visit_start_date,
   cast(visit_start_datetime as datetime) as visit_start_datetime,
   cast(visit_end_date as datetime) as visit_end_date,
   cast(visit_end_datetime as datetime) as visit_end_datetime,
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
where v.visit_start_date >= DATE(2018, 01, 01);

--CONDITION_OCCURRENCE
--OUTPUT_FILE: CONDITION_OCCURRENCE.csv
select
   condition_occurrence_id,
   n.person_id,
   condition_concept_id,
   cast(condition_start_date as datetime) as condition_start_date,
   cast(condition_start_datetime as datetime) as condition_start_datetime,
   cast(condition_end_date as datetime) as condition_end_date,
   cast(condition_end_datetime as datetime) as condition_end_datetime,
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
where co.condition_start_date >= DATE(2018, 01, 01);

--DRUG_EXPOSURE
--OUTPUT_FILE: DRUG_EXPOSURE.csv
select
   drug_exposure_id,
   n.person_id,
   drug_concept_id,
   cast(drug_exposure_start_date as datetime) as drug_exposure_start_date,
   cast(drug_exposure_start_datetime as datetime) as drug_exposure_start_datetime,
   cast(drug_exposure_end_date as datetime) as drug_exposure_end_date,
   cast(drug_exposure_end_datetime as datetime) as drug_exposure_end_datetime,
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
where de.drug_exposure_start_date >= DATE(2018, 01, 01);

--DEVICE_EXPOSURE
--OUTPUT_FILE: DEVICE_EXPOSURE.csv
SELECT
   DEVICE_EXPOSURE_ID,
   n.PERSON_ID,
   DEVICE_CONCEPT_ID,
   CAST(DEVICE_EXPOSURE_START_DATE as datetime) as DEVICE_EXPOSURE_START_DATE,
   CAST(DEVICE_EXPOSURE_START_DATETIME as datetime) as DEVICE_EXPOSURE_START_DATETIME,
   CAST(DEVICE_EXPOSURE_END_DATE as datetime) as DEVICE_EXPOSURE_END_DATE,
   CAST(DEVICE_EXPOSURE_END_DATETIME as datetime) as DEVICE_EXPOSURE_END_DATETIME,
   DEVICE_TYPE_CONCEPT_ID,
   NULL as UNIQUE_DEVICE_ID,
   QUANTITY,
   PROVIDER_ID,
   VISIT_OCCURRENCE_ID,
   NULL as VISIT_DETAIL_ID,
   DEVICE_SOURCE_VALUE,
   DEVICE_SOURCE_CONCEPT_ID
FROM @cdmDatabaseSchema.device_exposure de
JOIN @resultsDatabaseSchema.n3c_cohort n
  ON de.PERSON_ID = n.PERSON_ID
WHERE de.DEVICE_EXPOSURE_START_DATE >= DATE(2018, 01, 01);

--PROCEDURE_OCCURRENCE
--OUTPUT_FILE: PROCEDURE_OCCURRENCE.csv
select
   procedure_occurrence_id,
   n.person_id,
   procedure_concept_id,
   cast(procedure_date as datetime) as procedure_date,
   cast(procedure_datetime as datetime) as procedure_datetime,
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
where po.procedure_date >= DATE(2018, 01, 01);

--MEASUREMENT
--OUTPUT_FILE: MEASUREMENT.csv
select
   measurement_id,
   n.person_id,
   measurement_concept_id,
   cast(measurement_date as datetime) as measurement_date,
   cast(measurement_datetime as datetime) as measurement_datetime,
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
where m.measurement_date >= DATE(2018, 01, 01);

--OBSERVATION
--OUTPUT_FILE: OBSERVATION.csv
select
   observation_id,
   n.person_id,
   observation_concept_id,
   cast(observation_date as datetime) as observation_date,
   cast(observation_datetime as datetime) as observation_datetime,
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
where o.observation_date >= DATE(2018, 01, 01);

--DEATH
--OUTPUT_FILE: DEATH.csv
select
   n.person_id,
    cast(death_date as datetime) as death_date,
	cast(death_datetime as datetime) as death_datetime,
	death_type_concept_id,
	cause_concept_id,
	null as cause_source_value,
	cause_source_concept_id
from @cdmDatabaseSchema.death d
join @resultsDatabaseSchema.n3c_cohort n
on d.person_id = n.person_id
where d.death_date >= DATE(2020, 01, 01);

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
        select distinct p.location_id
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
   null as location_id,
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

--DRUG_ERA
--OUTPUT_FILE: DRUG_ERA.csv
select
   drug_era_id,
   n.person_id,
   drug_concept_id,
   cast(drug_era_start_date as datetime) as drug_era_start_date,
   cast(drug_era_end_date as datetime) as drug_era_end_date,
   drug_exposure_count,
   gap_days
from @cdmDatabaseSchema.drug_era dre
join @resultsDatabaseSchema.n3c_cohort n
  on dre.person_id = n.person_id
where drug_era_start_date >= DATE(2018, 01, 01);

--CONDITION_ERA
--OUTPUT_FILE: CONDITION_ERA.csv
select
   condition_era_id,
   n.person_id,
   condition_concept_id,
   cast(condition_era_start_date as datetime) as condition_era_start_date,
   cast(condition_era_end_date as datetime) as condition_era_end_date,
   condition_occurrence_count
from @cdmDatabaseSchema.condition_era ce join @resultsDatabaseSchema.n3c_cohort n on ce.person_id = n.person_id
where condition_era_start_date >= DATE(2018, 01, 01);

--DATA_COUNTS TABLE
--OUTPUT_FILE: DATA_COUNTS.csv
select * from
(select
   'PERSON' as table_name,
   (select count(*) from @cdmDatabaseSchema.person p join @resultsDatabaseSchema.n3c_cohort n on p.person_id = n.person_id) as row_count

union distinct select
   'OBSERVATION_PERIOD' as table_name,
   (select count(*) from @cdmDatabaseSchema.observation_period op join @resultsDatabaseSchema.n3c_cohort n on op.person_id = n.person_id and (observation_period_start_date >= DATE(2018, 01, 01) or observation_period_end_date >= DATE(2018, 01, 01))) as row_count

union distinct select
   'VISIT_OCCURRENCE' as table_name,
   (select count(*) from @cdmDatabaseSchema.visit_occurrence vo join @resultsDatabaseSchema.n3c_cohort n on vo.person_id = n.person_id and visit_start_date >= DATE(2018, 01, 01)) as row_count

union distinct select
   'CONDITION_OCCURRENCE' as table_name,
   (select count(*) from @cdmDatabaseSchema.condition_occurrence co join @resultsDatabaseSchema.n3c_cohort n on co.person_id = n.person_id and condition_start_date >= DATE(2018, 01, 01)) as row_count

union distinct select
   'DRUG_EXPOSURE' as table_name,
   (select count(*) from @cdmDatabaseSchema.drug_exposure de join @resultsDatabaseSchema.n3c_cohort n on de.person_id = n.person_id and drug_exposure_start_date >= DATE(2018, 01, 01)) as row_count

union distinct select
   'DEVICE_EXPOSURE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.device_exposure de JOIN @resultsDatabaseSchema.n3c_cohort n ON de.PERSON_ID = n.PERSON_ID AND DEVICE_EXPOSURE_START_DATE >= DATE(2018, 01, 01)) as ROW_COUNT

union distinct select
   'PROCEDURE_OCCURRENCE' as table_name,
   (select count(*) from @cdmDatabaseSchema.procedure_occurrence po join @resultsDatabaseSchema.n3c_cohort n on po.person_id = n.person_id and procedure_date >= DATE(2018, 01, 01)) as row_count

union distinct select
   'MEASUREMENT' as table_name,
   (select count(*) from @cdmDatabaseSchema.measurement m join @resultsDatabaseSchema.n3c_cohort n on m.person_id = n.person_id and measurement_date >= DATE(2018, 01, 01)) as row_count

union distinct select
   'OBSERVATION' as table_name,
   (select count(*) from @cdmDatabaseSchema.observation o join @resultsDatabaseSchema.n3c_cohort n on o.person_id = n.person_id and observation_date >= DATE(2018, 01, 01)) as row_count

union distinct select
   'DEATH' as table_name,
  (select count(*) from @cdmDatabaseSchema.death d join @resultsDatabaseSchema.n3c_cohort n on d.person_id = n.person_id and death_date >= DATE(2020, 01, 01)) as row_count

union distinct select
   'LOCATION' as table_name,
   (select count(*) from @cdmDatabaseSchema.location l
   join (
        select distinct p.location_id
        from @cdmDatabaseSchema.person p
        join @resultsDatabaseSchema.n3c_cohort n
          on p.person_id = n.person_id
      ) a
  on l.location_id = a.location_id) as row_count

union distinct select
   'CARE_SITE' as table_name,
   (select count(*) from @cdmDatabaseSchema.care_site cs
	join (
        select distinct care_site_id
        from @cdmDatabaseSchema.visit_occurrence vo
        join @resultsDatabaseSchema.n3c_cohort n
          on vo.person_id = n.person_id
      ) a
  on cs.care_site_id = a.care_site_id) as row_count

union distinct select
   'PROVIDER' as table_name,
   (select count(*) from @cdmDatabaseSchema.provider pr
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
 on pr.provider_id = a.provider_id) as row_count

union distinct select
   'DRUG_ERA' as table_name,
   (select count(*) from @cdmDatabaseSchema.drug_era de join @resultsDatabaseSchema.n3c_cohort n on de.person_id = n.person_id and drug_era_start_date >= DATE(2018, 01, 01)) as row_count

union distinct select
   'CONDITION_ERA' as table_name,
   (select count(*) from @cdmDatabaseSchema.condition_era join @resultsDatabaseSchema.n3c_cohort on condition_era.person_id = n3c_cohort.person_id and condition_era_start_date >= DATE(2018, 01, 01)) as row_count
) s;


--n3c_control_map
--OUTPUT_FILE: N3C_CONTROL_MAP.csv
select *
from @resultsDatabaseSchema.n3c_control_map;


