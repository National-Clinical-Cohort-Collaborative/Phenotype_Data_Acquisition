/**
N3C OMOP BigQuery
VISIT_DETAIL extraction for ADT addition
RELEASE DATE: 03-10-2022
Author: Robert Miller (Tufts)

HOW TO RUN:
  If you are not using the R or Python exporters, you will need to find and replace @cdmDatabaseSchema and @resultsDatabaseSchema with your local OMOP schema details.

USER NOTES:
  This extract pulls the following OMOP tables: VISIT_DETAIL
Please refer to the OMOP site instructions for assistance on how to generate these tables.

SCRIPT ASSUMPTIONS:
1. You have already built the N3C_COHORT table (with that name) prior to running this extract
2. You are extracting data with a lookback period to 1-1-2018
3.You have already executed the main extraction function that generates DATA_COUNTS.csv
**/

--VISIT_DETAIL
--OUTPUT_FILE: VISIT_DETAIL.csv
select visit_detail_id
      ,v.person_id
      ,visit_detail_concept_id
      ,cast(visit_detail_start_date as datetime) as visit_detail_start_date
      ,cast(visit_detail_start_datetime as datetime) as visit_detail_start_datetime
      ,cast(visit_detail_end_date as datetime) as visit_detail_end_date
      ,cast(visit_detail_end_datetime as datetime) as visit_detail_end_datetime
      ,visit_detail_type_concept_id
      ,provider_id
      ,care_site_id
      ,visit_detail_source_value
      ,visit_detail_source_concept_id
      ,admitted_from_concept_id
      ,admitted_from_source_value
      ,discharged_to_source_value
      ,discharged_to_concept_id
      ,preceding_visit_detail_id
      ,parent_visit_detail_id
      ,visit_occurrence_id
  from @cdmDatabaseSchema.visit_detail v
  join @resultsDatabaseSchema.n3c_cohort n
  on v.person_id = n.person_id
  where v.visit_detail_start_date >= DATE(2018, 01, 01);

--DATA_COUNTS TABLE
--OUTPUT_FILE: DATA_COUNTS_APPEND.csv
select 'VISIT_DETAIL' as table_name
    ,count(*) as row_count
  from @cdmDatabaseSchema.VISIT_DETAIL v
  join @resultsDatabaseSchema.N3C_COHORT n
  on v.person_id = n.person_id
  where v.visit_detail_start_date >= DATE(2018, 01, 01);
