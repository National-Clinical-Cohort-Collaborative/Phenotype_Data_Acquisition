/**
N3C OMOP MSSQL
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
SELECT visit_detail_id
      ,v.person_id
      ,visit_detail_concept_id
      ,CAST(visit_detail_start_date as datetime) as VISIT_DETAIL_START_DATE
      ,CAST(visit_detail_start_datetime as datetime) as VISIT_DETAIL_START_DATETIME
      ,CAST(visit_detail_end_date as datetime) as VISIT_DETAIL_END_DATE
      ,CAST(visit_detail_end_datetime as datetime) as VISIT_DETAIL_END_DATETIME
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
  FROM @cdmDatabaseSchema.VISIT_DETAIL v
  JOIN @resultsDatabaseSchema.N3C_COHORT n
  ON v.PERSON_ID = n.PERSON_ID
  WHERE v.VISIT_DETAIL_START_DATE >= DATEFROMPARTS(2018,01,01);

--DATA_COUNTS TABLE
--OUTPUT_FILE: DATA_COUNTS_APPEND.csv
SELECT 'VISIT_DETAIL' as TABLE_NAME
    ,count(*) as ROW_COUNT
  FROM @cdmDatabaseSchema.VISIT_DETAIL v
  JOIN @resultsDatabaseSchema.N3C_COHORT n
  ON v.PERSON_ID = n.PERSON_ID
  WHERE v.VISIT_DETAIL_START_DATE >= DATEFROMPARTS(2018,01,01)
;


