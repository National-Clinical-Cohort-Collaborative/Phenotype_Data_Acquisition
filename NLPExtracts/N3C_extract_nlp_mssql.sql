--NLP extract script
--Use this extra extract file if your site is participating in the NLP portion of N3C.

--NOTE
--OUTPUT_FILE: NOTE.csv
SELECT
   NOTE_ID,
   PERSON_ID,
   CAST(NOTE_DATE as datetime) as NOTE_DATE,
   CASE(NOTE_DATETIME as datetime) as NOTE_DATETIME,
   NOTE_TYPE_CONCEPT_ID,
   NOTE_CLASS_CONCEPT_ID,
   NULL as NOTE_TITLE,
   NULL as NOTE_TEXT,
   ENCODING_CONCEPT_ID,
   LANGUAGE_CONCEPT_ID,
   PROVIDER_ID,
   NULL as VISIT_OCCURRENCE_ID,
   NULL as VISIT_DETAIL_ID,
   NULL as NOTE_SOURCE VALUE
FROM @cdmDatabaseSchema.NOTE nt
JOIN @resultsDatabaseSchema.N3C_COHORT n
  ON nt.person_id = n.person_id
WHERE nt.NOTE_DATE >= DATEFROMPARTS(2018,01,01);

--NOTE_NLP
--OUTPUT_FILE: NOTE_NLP.csv
SELECT
   NOTE_NLP_ID,
   NOTE_ID,
   SECTION_CONCEPT_ID,
   NULL as SNIPPET,
   OFFSET,
   NULL as LEXICAL_VARIANT,
   NOTE_NLP_CONCEPT_ID,
   NOTE_NLP_SOURCE_CONCEPT_ID,
   NLP_SYSTEM,
   CAST(NLP_DATE as datetime) as NLP_DATE,
   CAST(NLP_DATETIME as datetime) as NLP_DATETIME,
   TERM_EXISTS,
   TERM_TEMPORAL,
   TERM_MODIFIERS
FROM @cdmDatabaseSchema.NOTE_NLP ntnlp
	JOIN @cdmDatabaseSchema.NOTE nt ON ntnlp.NOTE_ID = nt.NOTE_ID
	JOIN @resultsDatabaseSchema.N3C_COHORT n ON nt.person_id = n.person_id
WHERE nt.NOTE_DATE >= DATEFROMPARTS(2018,01,01);

