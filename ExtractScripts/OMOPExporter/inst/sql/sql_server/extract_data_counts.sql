
--DATA_COUNTS TABLE
--OUTPUT_FILE: DATA_COUNTS.csv
SELECT * from
(select
   'PERSON' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.PERSON p JOIN @cohortDatabaseSchema.N3C_COHORT n ON p.PERSON_ID = n.PERSON_ID) as ROW_COUNT

UNION

select
   'OBSERVATION_PERIOD' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.OBSERVATION_PERIOD op JOIN @cohortDatabaseSchema.N3C_COHORT n ON op.PERSON_ID = n.PERSON_ID AND OBSERVATION_PERIOD_START_DATE >= '1/1/2018') as ROW_COUNT

UNION

select
   'VISIT_OCCURRENCE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.VISIT_OCCURRENCE vo JOIN @cohortDatabaseSchema.N3C_COHORT n ON vo.PERSON_ID = n.PERSON_ID AND VISIT_START_DATE >= '1/1/2018') as ROW_COUNT

UNION

select
   'CONDITION_OCCURRENCE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.CONDITION_OCCURRENCE co JOIN @cohortDatabaseSchema.N3C_COHORT n ON co.PERSON_ID = n.PERSON_ID AND CONDITION_START_DATE >= '1/1/2018') as ROW_COUNT

UNION

select
   'DRUG_EXPOSURE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.DRUG_EXPOSURE de JOIN @cohortDatabaseSchema.N3C_COHORT n ON de.PERSON_ID = n.PERSON_ID AND DRUG_EXPOSURE_START_DATE >= '1/1/2018') as ROW_COUNT

UNION

select
   'PROCEDURE_OCCURRENCE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.PROCEDURE_OCCURRENCE po JOIN @cohortDatabaseSchema.N3C_COHORT n ON po.PERSON_ID = n.PERSON_ID AND PROCEDURE_DATE >= '1/1/2018') as ROW_COUNT

UNION

select
   'MEASUREMENT' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.MEASUREMENT m JOIN @cohortDatabaseSchema.N3C_COHORT n ON m.PERSON_ID = n.PERSON_ID AND MEASUREMENT_DATE >= '1/1/2018') as ROW_COUNT

UNION

select
   'OBSERVATION' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.OBSERVATION o JOIN @cohortDatabaseSchema.N3C_COHORT n ON o.PERSON_ID = n.PERSON_ID AND OBSERVATION_DATE >= '1/1/2018') as ROW_COUNT

UNION

--OMOP does not have PERSON_ID for Location, Care Site and Provider tables so we need to determine the applicability of this check
--We could re-engineer the cohort table to include the JOIN variables
select
   'LOCATION' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.LOCATION) as ROW_COUNT

UNION

select
   'CARE_SITE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.CARE_SITE) as ROW_COUNT

UNION

 select
   'PROVIDER' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.PROVIDER) as ROW_COUNT

UNION

select
   'DRUG_ERA' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.DRUG_ERA de JOIN @cohortDatabaseSchema.N3C_COHORT n ON de.PERSON_ID = n.PERSON_ID AND DRUG_ERA_START_DATE >= '1/1/2018') as ROW_COUNT
   /**
UNION

select
   'DOSE_ERA' as TABLE_NAME,
   (select count(*) from DOSE_ERA ds JOIN @cohortDatabaseSchema.N3C_COHORT n ON ds.PERSON_ID = n.PERSON_ID AND DOSE_ERA_START_DATE >= '1/1/2018') as ROW_COUNT
   **/
UNION

select
   'CONDITION_ERA' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.CONDITION_ERA JOIN @cohortDatabaseSchema.N3C_COHORT ON CONDITION_ERA.PERSON_ID = N3C_COHORT.PERSON_ID AND CONDITION_ERA_START_DATE >= '1/1/2018') as ROW_COUNT
) s;
