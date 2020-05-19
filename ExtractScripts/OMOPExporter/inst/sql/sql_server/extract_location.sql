
--LOCATION
--OUTPUT_FILE: LOCATION.csv
SELECT
   l.LOCATION_ID,
   null as ADDRESS_1, -- to avoid identifying information
   null as ADDRESS_2, -- to avoid identifying information
   CITY,
   STATE,
   ZIP,
   COUNTY,
   LOCATION_SOURCE_VALUE
FROM @cdmDatabaseSchema.LOCATION l
JOIN (
        SELECT DISTINCT cs.LOCATION_ID
        FROM @cdmDatabaseSchema.VISIT_OCCURRENCE vo
        JOIN @cohortDatabaseSchema.N3C_COHORT n
          ON vo.person_id = n.person_id
        JOIN @cdmDatabaseSchema.CARE_SITE cs
          ON vo.care_site_id = cs.care_site_id
        UNION
        SELECT DISTINCT p.LOCATION_ID
        FROM @cdmDatabaseSchema.PERSON p
        JOIN @cohortDatabaseSchema.N3C_COHORT n
          ON p.person_id = n.person_id
      ) a
  ON l.location_id = a.location_id
;
