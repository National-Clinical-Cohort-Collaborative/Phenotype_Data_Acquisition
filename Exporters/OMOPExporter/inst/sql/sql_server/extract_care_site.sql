
--CARE_SITE
--OUTPUT_FILE: CARE_SITE.csv
SELECT
   cs.CARE_SITE_ID,
   CARE_SITE_NAME,
   PLACE_OF_SERVICE_CONCEPT_ID,
   LOCATION_ID,
   CARE_SITE_SOURCE_VALUE,
   PLACE_OF_SERVICE_SOURCE_VALUE
FROM @cdmDatabaseSchema.CARE_SITE cs
JOIN (
        SELECT DISTINCT CARE_SITE_ID
        FROM @cdmDatabaseSchema.VISIT_OCCURRENCE vo
        JOIN @cohortDatabaseSchema.N3C_COHORT n
          ON vo.person_id = n.person_id
      ) a
  ON cs.CARE_SITE_ID = a.CARE_SITE_ID
;
