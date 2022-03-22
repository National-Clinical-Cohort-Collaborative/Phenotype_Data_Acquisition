--N3C NLP extract script - OMOP Redshift
--Use this extra extract file if your site is participating in the NLP portion of N3C.

--NOTE
--OUTPUT_FILE: NOTE.csv
SELECT
   nt.NOTE_ID,
   nt.PERSON_ID,
   CAST(NOTE_DATE as TIMESTAMP) as NOTE_DATE,
   CAST(NOTE_DATETIME as TIMESTAMP) as NOTE_DATETIME,
   NOTE_TYPE_CONCEPT_ID,
   NOTE_CLASS_CONCEPT_ID,
   NULL as NOTE_TITLE,
   NULL as NOTE_TEXT,
   ENCODING_CONCEPT_ID,
   LANGUAGE_CONCEPT_ID,
   PROVIDER_ID,
   NULL as VISIT_OCCURRENCE_ID,
   NULL as VISIT_DETAIL_ID,
   NULL as NOTE_SOURCE_VALUE
FROM @cdmDatabaseSchema.NOTE nt
JOIN @resultsDatabaseSchema.N3C_COHORT n
  ON nt.person_id = n.person_id
WHERE nt.NOTE_DATE >= TO_DATE(TO_CHAR(2018,'0000FM')||'-'||TO_CHAR(01,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD');

--NOTE_NLP
--OUTPUT_FILE: NOTE_NLP.csv
SELECT
   NOTE_NLP_ID,
   ntnlp.NOTE_ID,
   SECTION_CONCEPT_ID,
   NULL as SNIPPET,
   OFFSET,
   NULL as LEXICAL_VARIANT,
   NOTE_NLP_CONCEPT_ID,
   NOTE_NLP_SOURCE_CONCEPT_ID,
   NLP_SYSTEM,
   CAST(NLP_DATE as TIMESTAMP) as NLP_DATE,
   CAST(NLP_DATETIME as TIMESTAMP) as NLP_DATETIME,
   TERM_EXISTS,
   TERM_TEMPORAL,
   TERM_MODIFIERS
FROM @cdmDatabaseSchema.NOTE_NLP ntnlp
	JOIN @cdmDatabaseSchema.NOTE nt ON ntnlp.NOTE_ID = nt.NOTE_ID
	JOIN @resultsDatabaseSchema.N3C_COHORT n ON nt.person_id = n.person_id
WHERE nt.NOTE_DATE >= TO_DATE(TO_CHAR(2018,'0000FM')||'-'||TO_CHAR(01,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD');

--NOTE ROW COUNT
--OUTPUT_FILE: DATA_COUNTS_APPEND.csv
SELECT 'NOTE' as TABLE_NAME
    ,count(*) as ROW_COUNT
 FROM @cdmDatabaseSchema.NOTE nt
 JOIN @resultsDatabaseSchema.N3C_COHORT n ON nt.person_id = n.person_id
WHERE nt.NOTE_DATE >= TO_DATE(TO_CHAR(2018,'0000FM')||'-'||TO_CHAR(01,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD');

--NOTE_NLP ROW COUNT
--OUTPUT_FILE: DATA_COUNTS_APPEND.csv
SELECT 'NOTE_NLP' as TABLE_NAME
    ,count(*) as ROW_COUNT
FROM @cdmDatabaseSchema.NOTE_NLP ntnlp
  JOIN @cdmDatabaseSchema.NOTE nt ON ntnlp.NOTE_ID = nt.NOTE_ID
  JOIN @resultsDatabaseSchema.N3C_COHORT n ON nt.person_id = n.person_id
WHERE nt.NOTE_DATE >= TO_DATE(TO_CHAR(2018,'0000FM')||'-'||TO_CHAR(01,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD');
