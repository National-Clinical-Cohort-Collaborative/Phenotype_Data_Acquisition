
--PROVIDER
--OUTPUT_FILE: PROVIDER.csv
SELECT
   pr.PROVIDER_ID,
   null as PROVIDER_NAME, -- to avoid accidentally identifying sites
   null as NPI, -- to avoid accidentally identifying sites
   null as DEA, -- to avoid accidentally identifying sites
   SPECIALTY_CONCEPT_ID,
   CARE_SITE_ID,
   null as YEAR_OF_BIRTH,
   GENDER_CONCEPT_ID,
   null as PROVIDER_SOURCE_VALUE, -- to avoid accidentally identifying sites
   SPECIALTY_SOURCE_VALUE,
   SPECIALTY_SOURCE_CONCEPT_ID,
   GENDER_SOURCE_VALUE,
   GENDER_SOURCE_CONCEPT_ID
FROM @cdmDatabaseSchema.PROVIDER pr
JOIN (
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.VISIT_OCCURRENCE vo
       JOIN @cohortDatabaseSchema.N3C_COHORT n
          ON vo.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.DRUG_EXPOSURE de
       JOIN @cohortDatabaseSchema.N3C_COHORT n
          ON de.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.MEASUREMENT m
       JOIN @cohortDatabaseSchema.N3C_COHORT n
          ON m.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.PROCEDURE_OCCURRENCE po
       JOIN @cohortDatabaseSchema.N3C_COHORT n
          ON po.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.OBSERVATION o
       JOIN @cohortDatabaseSchema.N3C_COHORT n
          ON o.PERSON_ID = n.PERSON_ID
     ) a
 ON pr.PROVIDER_ID = a.PROVIDER_ID
;
