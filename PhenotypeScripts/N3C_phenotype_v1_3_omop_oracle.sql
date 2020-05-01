# Change log:
# Version 1 - initial commit
# Version 2 - updated possible positive cases (typo in name of concept set name) and added additional NIH VSAC codeset_id
# NOTE: as of V2, OMOP vocabularies have released an update to include new LOINC codes but the load of these concept_ids into atlas-covid19 has not been completed, when this is done we will include these into the concept_set generated


# Instructions:
# Cohorts were assembled using OHDSI Atlas (atlas-covid19.ohdsi.org)
# This Oracle SQL script contains 4 cohorts: 
# 1- “Lab-confirmed positive cases” (http://atlas-covid19.ohdsi.org/#/cohortdefinition/655)
# 2- "Lab-confirmed negative cases" (http://atlas-covid19.ohdsi.org/#/cohortdefinition/656)
# 3- "Suspected positive cases"	(http://atlas-covid19.ohdsi.org/#/cohortdefinition/657)
# 4- "Possible positive cases" (http://atlas-covid19.ohdsi.org/#/cohortdefinition/658)
# To run, you will need to find and replace @cdm_database_schema, @vocabulary_database_schema with your local OMOP schema details
# This code is currently designed to create 4 seperate cohorts. In version 3, we can consolidate this to 1 cohort definition.


# Cohort 1: Lab-confirmed positive cases

CREATE TABLE @temp_database_schema.d7rh3r1uCodesets (
  codeset_id int NOT NULL,
  concept_id NUMBER(19) NOT NULL
)
;

INSERT INTO @temp_database_schema.d7rh3r1uCodesets (codeset_id, concept_id)
SELECT 0 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @vocabulary_database_schema.CONCEPT     WHERE concept_id in (706156,706154,706170,706171,706157,706155,706172,706173,706174,706175,706163,706165,706177,706178,706181,706180,706166,706167,706168,706159,706161,706160)
   UNION  select c.concept_id
  FROM @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (706156,706154,706170,706171,706157,706155,706172,706173,706174,706175,706163,706165,706177,706178,706181,706180,706166,706167,706168,706159,706161,706160)
  and c.invalid_reason is null

 ) I
 ) C ;


CREATE TABLE @temp_database_schema.d7rh3r1uqualified_events

AS
WITH primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id)  AS (SELECT P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
FROM (SELECT E.person_id, E.start_date, E.end_date,
         row_number() OVER (PARTITION BY E.person_id ORDER BY E.sort_date ASC) ordinal,
         OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
  FROM (SELECT C.person_id, C.measurement_id as event_id, C.measurement_date as start_date, (C.measurement_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.measurement_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.measurement_date as sort_date
FROM (SELECT m.* 
  FROM @cdm_database_schema.MEASUREMENT m
JOIN @temp_database_schema.d7rh3r1uCodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
 ) C

  WHERE C.measurement_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
AND C.value_as_concept_id in (45884084,9191)
-- End Measurement Criteria

   ) E
	JOIN @cdm_database_schema.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
    WHERE (OP.OBSERVATION_PERIOD_START_DATE + NUMTODSINTERVAL(0, 'day')) <= E.START_DATE AND (E.START_DATE + NUMTODSINTERVAL(0, 'day')) <= OP.OBSERVATION_PERIOD_END_DATE
 ) P
  WHERE P.ordinal = 1
-- End Primary Events

 )
 SELECT
event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id

FROM
(SELECT pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
  FROM primary_events pe
  
 ) QE

 ;

--- Inclusion Rule Inserts

create table @temp_database_schema.d7rh3r1uinclusion_events (inclusion_rule_id NUMBER(19),
	person_id NUMBER(19),
	event_id NUMBER(19)
);

CREATE TABLE @temp_database_schema.d7rh3r1uincluded_events

AS
WITH cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal)  AS (SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  FROM (SELECT Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as NUMBER(19)), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    FROM @temp_database_schema.d7rh3r1uqualified_events Q
    LEFT JOIN @temp_database_schema.d7rh3r1uinclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
   ) MG -- matching groups

 )
 SELECT
event_id, person_id, start_date, end_date, op_start_date, op_end_date

FROM
cteIncludedEvents Results
  WHERE Results.ordinal = 1
 ;



-- generate cohort periods into #final_cohort
CREATE TABLE @temp_database_schema.d7rh3r1ucohort_rows

AS
WITH cohort_ends (event_id, person_id, end_date)  AS (SELECT event_id, person_id, op_end_date as end_date FROM @temp_database_schema.d7rh3r1uincluded_events
 ),
first_ends (person_id, start_date, end_date) as
(SELECT F.person_id, F.start_date, F.end_date
	FROM (SELECT I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal 
	  FROM @temp_database_schema.d7rh3r1uincluded_events I
	  join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
	 ) F
	  WHERE F.ordinal = 1
 )
 SELECT
person_id, start_date, end_date

FROM
first_ends ;

CREATE TABLE @temp_database_schema.d7rh3r1ufinal_cohort

AS
WITH cteEndDates (person_id, end_date)  AS (SELECT person_id
		, (event_date + NUMTODSINTERVAL(-1 * 0, 'day'))  as end_date
	FROM (SELECT person_id
			, event_date
			, event_type
			, MAX(start_ordinal) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal 
			, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_date, event_type) AS overall_ord
		FROM (SELECT person_id
				, start_date AS event_date
				, -1 AS event_type
				, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date) AS start_ordinal
			FROM @temp_database_schema.d7rh3r1ucohort_rows
		
			  UNION ALL
		

			SELECT
				person_id
				, (end_date + NUMTODSINTERVAL(0, 'day'))  end_date
				, 1 AS event_type
				, NULL
			FROM @temp_database_schema.d7rh3r1ucohort_rows
		 ) RAWDATA
	 ) e
	  WHERE (2 * e.start_ordinal) - e.overall_ord = 0
 ),
cteEnds (person_id, start_date, end_date) AS
(SELECT c.person_id
		, c.start_date
		, MIN(e.end_date) AS end_date
	FROM @temp_database_schema.d7rh3r1ucohort_rows c
	JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
 )
 SELECT
person_id, min(start_date) as start_date, end_date

FROM
cteEnds
group by person_id, end_date
 ;

DELETE FROM @target_database_schema.@target_cohort_table where cohort_definition_id = @target_cohort_id;
INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
SELECT @target_cohort_id as cohort_definition_id, person_id, start_date, end_date 
FROM @temp_database_schema.d7rh3r1ufinal_cohort CO
 ;





TRUNCATE TABLE @temp_database_schema.d7rh3r1ucohort_rows;
DROP TABLE @temp_database_schema.d7rh3r1ucohort_rows;

TRUNCATE TABLE @temp_database_schema.d7rh3r1ufinal_cohort;
DROP TABLE @temp_database_schema.d7rh3r1ufinal_cohort;

TRUNCATE TABLE @temp_database_schema.d7rh3r1uinclusion_events;
DROP TABLE @temp_database_schema.d7rh3r1uinclusion_events;

TRUNCATE TABLE @temp_database_schema.d7rh3r1uqualified_events;
DROP TABLE @temp_database_schema.d7rh3r1uqualified_events;

TRUNCATE TABLE @temp_database_schema.d7rh3r1uincluded_events;
DROP TABLE @temp_database_schema.d7rh3r1uincluded_events;

TRUNCATE TABLE @temp_database_schema.d7rh3r1uCodesets;
DROP TABLE @temp_database_schema.d7rh3r1uCodesets;

# Cohort 2: Lab-confirmed negative cases

CREATE TABLE @temp_database_schema.gw7cigm0Codesets (
  codeset_id int NOT NULL,
  concept_id NUMBER(19) NOT NULL
)
;

INSERT INTO @temp_database_schema.gw7cigm0Codesets (codeset_id, concept_id)
SELECT 0 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @vocabulary_database_schema.CONCEPT     WHERE concept_id in (706156,706154,706170,706171,706157,706155,706172,706173,706174,706175,706163,706165,706177,706178,706181,706180,706166,706167,706168,706159,706161,706160)
   UNION  select c.concept_id
  FROM @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (706156,706154,706170,706171,706157,706155,706172,706173,706174,706175,706163,706165,706177,706178,706181,706180,706166,706167,706168,706159,706161,706160)
  and c.invalid_reason is null

 ) I
 ) C ;


CREATE TABLE @temp_database_schema.gw7cigm0qualified_events

AS
WITH primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id)  AS (SELECT P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
FROM (SELECT E.person_id, E.start_date, E.end_date,
         row_number() OVER (PARTITION BY E.person_id ORDER BY E.sort_date ASC) ordinal,
         OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
  FROM (SELECT C.person_id, C.measurement_id as event_id, C.measurement_date as start_date, (C.measurement_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.measurement_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.measurement_date as sort_date
FROM (SELECT m.* 
  FROM @cdm_database_schema.MEASUREMENT m
JOIN @temp_database_schema.gw7cigm0Codesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
 ) C

  WHERE C.measurement_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
AND C.value_as_concept_id in (9189,45877738,36309158,1177295,45876332,37079494,45878583)
-- End Measurement Criteria

   ) E
	JOIN @cdm_database_schema.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
    WHERE (OP.OBSERVATION_PERIOD_START_DATE + NUMTODSINTERVAL(0, 'day')) <= E.START_DATE AND (E.START_DATE + NUMTODSINTERVAL(0, 'day')) <= OP.OBSERVATION_PERIOD_END_DATE
 ) P
  WHERE P.ordinal = 1
-- End Primary Events

 )
 SELECT
event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id

FROM
(SELECT pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
  FROM primary_events pe
  
 ) QE

 ;

--- Inclusion Rule Inserts

create table @temp_database_schema.gw7cigm0inclusion_events (inclusion_rule_id NUMBER(19),
	person_id NUMBER(19),
	event_id NUMBER(19)
);

CREATE TABLE @temp_database_schema.gw7cigm0included_events

AS
WITH cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal)  AS (SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  FROM (SELECT Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as NUMBER(19)), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    FROM @temp_database_schema.gw7cigm0qualified_events Q
    LEFT JOIN @temp_database_schema.gw7cigm0inclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
   ) MG -- matching groups

 )
 SELECT
event_id, person_id, start_date, end_date, op_start_date, op_end_date

FROM
cteIncludedEvents Results
  WHERE Results.ordinal = 1
 ;



-- generate cohort periods into #final_cohort
CREATE TABLE @temp_database_schema.gw7cigm0cohort_rows

AS
WITH cohort_ends (event_id, person_id, end_date)  AS (SELECT event_id, person_id, op_end_date as end_date FROM @temp_database_schema.gw7cigm0included_events
 ),
first_ends (person_id, start_date, end_date) as
(SELECT F.person_id, F.start_date, F.end_date
	FROM (SELECT I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal 
	  FROM @temp_database_schema.gw7cigm0included_events I
	  join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
	 ) F
	  WHERE F.ordinal = 1
 )
 SELECT
person_id, start_date, end_date

FROM
first_ends ;

CREATE TABLE @temp_database_schema.gw7cigm0final_cohort

AS
WITH cteEndDates (person_id, end_date)  AS (SELECT person_id
		, (event_date + NUMTODSINTERVAL(-1 * 0, 'day'))  as end_date
	FROM (SELECT person_id
			, event_date
			, event_type
			, MAX(start_ordinal) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal 
			, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_date, event_type) AS overall_ord
		FROM (SELECT person_id
				, start_date AS event_date
				, -1 AS event_type
				, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date) AS start_ordinal
			FROM @temp_database_schema.gw7cigm0cohort_rows
		
			  UNION ALL
		

			SELECT
				person_id
				, (end_date + NUMTODSINTERVAL(0, 'day'))  end_date
				, 1 AS event_type
				, NULL
			FROM @temp_database_schema.gw7cigm0cohort_rows
		 ) RAWDATA
	 ) e
	  WHERE (2 * e.start_ordinal) - e.overall_ord = 0
 ),
cteEnds (person_id, start_date, end_date) AS
(SELECT c.person_id
		, c.start_date
		, MIN(e.end_date) AS end_date
	FROM @temp_database_schema.gw7cigm0cohort_rows c
	JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
 )
 SELECT
person_id, min(start_date) as start_date, end_date

FROM
cteEnds
group by person_id, end_date
 ;

DELETE FROM @target_database_schema.@target_cohort_table where cohort_definition_id = @target_cohort_id;
INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
SELECT @target_cohort_id as cohort_definition_id, person_id, start_date, end_date 
FROM @temp_database_schema.gw7cigm0final_cohort CO
 ;





TRUNCATE TABLE @temp_database_schema.gw7cigm0cohort_rows;
DROP TABLE @temp_database_schema.gw7cigm0cohort_rows;

TRUNCATE TABLE @temp_database_schema.gw7cigm0final_cohort;
DROP TABLE @temp_database_schema.gw7cigm0final_cohort;

TRUNCATE TABLE @temp_database_schema.gw7cigm0inclusion_events;
DROP TABLE @temp_database_schema.gw7cigm0inclusion_events;

TRUNCATE TABLE @temp_database_schema.gw7cigm0qualified_events;
DROP TABLE @temp_database_schema.gw7cigm0qualified_events;

TRUNCATE TABLE @temp_database_schema.gw7cigm0included_events;
DROP TABLE @temp_database_schema.gw7cigm0included_events;

TRUNCATE TABLE @temp_database_schema.gw7cigm0Codesets;
DROP TABLE @temp_database_schema.gw7cigm0Codesets;

# Cohort 3: Suspected positive cases

CREATE TABLE @temp_database_schema.eaydvg5gCodesets (
  codeset_id int NOT NULL,
  concept_id NUMBER(19) NOT NULL
)
;

INSERT INTO @temp_database_schema.eaydvg5gCodesets (codeset_id, concept_id)
SELECT 0 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @vocabulary_database_schema.CONCEPT     WHERE concept_id in (706156,706154,706170,706171,706157,706155,706172,706173,706174,706175,706163,706165,706177,706178,706181,706180,706166,706167,706168,706159,706161,706160)
   UNION  select c.concept_id
  FROM @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (706156,706154,706170,706171,706157,706155,706172,706173,706174,706175,706163,706165,706177,706178,706181,706180,706166,706167,706168,706159,706161,706160)
  and c.invalid_reason is null

 ) I
 ) C ;
INSERT INTO @temp_database_schema.eaydvg5gCodesets (codeset_id, concept_id)
SELECT 1 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @vocabulary_database_schema.CONCEPT   WHERE concept_id in (37311061,37311060,756023,756031,756039,756044,756061,756081,37310285)

 ) I
 ) C ;
INSERT INTO @temp_database_schema.eaydvg5gCodesets (codeset_id, concept_id)
SELECT 2 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @vocabulary_database_schema.CONCEPT     WHERE concept_id in (40218805,40218804,700360,2212793)
   UNION  select c.concept_id
  FROM @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (40218805,40218804,700360,2212793)
  and c.invalid_reason is null

 ) I
 ) C ;


CREATE TABLE @temp_database_schema.eaydvg5gqualified_events

AS
WITH primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id)  AS (SELECT P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
FROM (SELECT E.person_id, E.start_date, E.end_date,
         row_number() OVER (PARTITION BY E.person_id ORDER BY E.sort_date ASC) ordinal,
         OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
  FROM (SELECT PE.person_id, PE.event_id, PE.start_date, PE.end_date, PE.target_concept_id, PE.visit_occurrence_id, PE.sort_date FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  
 ) C

  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria

 ) PE
JOIN (SELECT 0 as index_id, person_id, event_id
FROM (SELECT E.person_id, E.event_id 
  FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  
 ) C

  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdm_database_schema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) E
  INNER JOIN
  (SELECT 0 as index_id, p.person_id, p.event_id
FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  
 ) C

  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdm_database_schema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) P
INNER JOIN
(SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  JOIN @temp_database_schema.eaydvg5gCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 1))
 ) C

  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

  UNION ALL
-- Begin Correlated Criteria
SELECT 1  index_id, p.person_id, p.event_id
FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  
 ) C

  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdm_database_schema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) P
INNER JOIN
(SELECT C.person_id, C.measurement_id as event_id, C.measurement_date as start_date, (C.measurement_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.measurement_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.measurement_date as sort_date
FROM (SELECT m.* 
  FROM @cdm_database_schema.MEASUREMENT m
JOIN @temp_database_schema.eaydvg5gCodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
 ) C

  WHERE C.measurement_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
AND C.value_as_concept_id in (45880847,45880480,45885232,45885242,45876576,45882283,45878545)
-- End Measurement Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

  UNION ALL
-- Begin Correlated Criteria
SELECT 2  index_id, p.person_id, p.event_id
FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  
 ) C

  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdm_database_schema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) P
INNER JOIN
(SELECT C.person_id, C.procedure_occurrence_id as event_id, C.procedure_date as start_date, (C.procedure_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.procedure_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.procedure_date as sort_date
FROM (SELECT po.* 
  FROM @cdm_database_schema.PROCEDURE_OCCURRENCE po
JOIN @temp_database_schema.eaydvg5gCodesets codesets on ((po.procedure_concept_id = codesets.concept_id and codesets.codeset_id = 2))
 ) C

  WHERE C.procedure_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Procedure Occurrence Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

   ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) > 0
 ) G
-- End Criteria Group
 ) AC on AC.person_id = pe.person_id and AC.event_id = pe.event_id

   ) E
	JOIN @cdm_database_schema.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
    WHERE (OP.OBSERVATION_PERIOD_START_DATE + NUMTODSINTERVAL(0, 'day')) <= E.START_DATE AND (E.START_DATE + NUMTODSINTERVAL(0, 'day')) <= OP.OBSERVATION_PERIOD_END_DATE
 ) P
  WHERE P.ordinal = 1
-- End Primary Events

 )
 SELECT
event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id

FROM
(SELECT pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
  FROM primary_events pe
  
JOIN (SELECT 0 as index_id, person_id, event_id
FROM (SELECT E.person_id, E.event_id 
  FROM primary_events E
  LEFT JOIN
  (SELECT 0 as index_id, p.person_id, p.event_id
FROM primary_events P
INNER JOIN
(SELECT C.person_id, C.measurement_id as event_id, C.measurement_date as start_date, (C.measurement_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.measurement_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.measurement_date as sort_date
FROM (SELECT m.* 
  FROM @cdm_database_schema.MEASUREMENT m
JOIN @temp_database_schema.eaydvg5gCodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
 ) C

  WHERE C.measurement_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
AND C.value_as_concept_id in (9189,36309158,45877738,1177295,37079494,45876332,45878583,45876469)
-- End Measurement Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

  UNION ALL
-- Begin Correlated Criteria
SELECT 1  index_id, p.person_id, p.event_id
FROM primary_events P
INNER JOIN
(SELECT C.person_id, C.measurement_id as event_id, C.measurement_date as start_date, (C.measurement_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.measurement_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.measurement_date as sort_date
FROM (SELECT m.* 
  FROM @cdm_database_schema.MEASUREMENT m
JOIN @temp_database_schema.eaydvg5gCodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
 ) C

  WHERE C.measurement_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
AND C.value_as_concept_id in (45884084,9191)
-- End Measurement Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

   ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) <= 0
 ) G
-- End Criteria Group
 ) AC on AC.person_id = pe.person_id and AC.event_id = pe.event_id

 ) QE
  WHERE QE.ordinal = 1
 ;

--- Inclusion Rule Inserts

create table @temp_database_schema.eaydvg5ginclusion_events (inclusion_rule_id NUMBER(19),
	person_id NUMBER(19),
	event_id NUMBER(19)
);

CREATE TABLE @temp_database_schema.eaydvg5gincluded_events

AS
WITH cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal)  AS (SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  FROM (SELECT Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as NUMBER(19)), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    FROM @temp_database_schema.eaydvg5gqualified_events Q
    LEFT JOIN @temp_database_schema.eaydvg5ginclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
   ) MG -- matching groups

 )
 SELECT
event_id, person_id, start_date, end_date, op_start_date, op_end_date

FROM
cteIncludedEvents Results
  WHERE Results.ordinal = 1
 ;



-- generate cohort periods into #final_cohort
CREATE TABLE @temp_database_schema.eaydvg5gcohort_rows

AS
WITH cohort_ends (event_id, person_id, end_date)  AS (SELECT event_id, person_id, op_end_date as end_date FROM @temp_database_schema.eaydvg5gincluded_events
 ),
first_ends (person_id, start_date, end_date) as
(SELECT F.person_id, F.start_date, F.end_date
	FROM (SELECT I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal 
	  FROM @temp_database_schema.eaydvg5gincluded_events I
	  join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
	 ) F
	  WHERE F.ordinal = 1
 )
 SELECT
person_id, start_date, end_date

FROM
first_ends ;

CREATE TABLE @temp_database_schema.eaydvg5gfinal_cohort

AS
WITH cteEndDates (person_id, end_date)  AS (SELECT person_id
		, (event_date + NUMTODSINTERVAL(-1 * 0, 'day'))  as end_date
	FROM (SELECT person_id
			, event_date
			, event_type
			, MAX(start_ordinal) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal 
			, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_date, event_type) AS overall_ord
		FROM (SELECT person_id
				, start_date AS event_date
				, -1 AS event_type
				, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date) AS start_ordinal
			FROM @temp_database_schema.eaydvg5gcohort_rows
		
			  UNION ALL
		

			SELECT
				person_id
				, (end_date + NUMTODSINTERVAL(0, 'day'))  end_date
				, 1 AS event_type
				, NULL
			FROM @temp_database_schema.eaydvg5gcohort_rows
		 ) RAWDATA
	 ) e
	  WHERE (2 * e.start_ordinal) - e.overall_ord = 0
 ),
cteEnds (person_id, start_date, end_date) AS
(SELECT c.person_id
		, c.start_date
		, MIN(e.end_date) AS end_date
	FROM @temp_database_schema.eaydvg5gcohort_rows c
	JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
 )
 SELECT
person_id, min(start_date) as start_date, end_date

FROM
cteEnds
group by person_id, end_date
 ;

DELETE FROM @target_database_schema.@target_cohort_table where cohort_definition_id = @target_cohort_id;
INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
SELECT @target_cohort_id as cohort_definition_id, person_id, start_date, end_date 
FROM @temp_database_schema.eaydvg5gfinal_cohort CO
 ;





TRUNCATE TABLE @temp_database_schema.eaydvg5gcohort_rows;
DROP TABLE @temp_database_schema.eaydvg5gcohort_rows;

TRUNCATE TABLE @temp_database_schema.eaydvg5gfinal_cohort;
DROP TABLE @temp_database_schema.eaydvg5gfinal_cohort;

TRUNCATE TABLE @temp_database_schema.eaydvg5ginclusion_events;
DROP TABLE @temp_database_schema.eaydvg5ginclusion_events;

TRUNCATE TABLE @temp_database_schema.eaydvg5gqualified_events;
DROP TABLE @temp_database_schema.eaydvg5gqualified_events;

TRUNCATE TABLE @temp_database_schema.eaydvg5gincluded_events;
DROP TABLE @temp_database_schema.eaydvg5gincluded_events;

TRUNCATE TABLE @temp_database_schema.eaydvg5gCodesets;
DROP TABLE @temp_database_schema.eaydvg5gCodesets;

# Cohort 4: Possible positive cases 
# Note: PCORNet values were translated via OMOP vocabulary schema from condition_source_concept_id to condition_concept_id (aka the OMOP standards)

CREATE TABLE @temp_database_schema.khxmbhhpCodesets (
  codeset_id int NOT NULL,
  concept_id NUMBER(19) NOT NULL
)
;

INSERT INTO @temp_database_schema.khxmbhhpCodesets (codeset_id, concept_id)
SELECT 0 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @vocabulary_database_schema.CONCEPT     WHERE concept_id in (706156,706154,706170,706171,706157,706155,706172,706173,706174,706175,706163,706165,706177,706178,706181,706180,706166,706167,706168,706159,706161,706160)
   UNION  select c.concept_id
  FROM @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (706156,706154,706170,706171,706157,706155,706172,706173,706174,706175,706163,706165,706177,706178,706181,706180,706166,706167,706168,706159,706161,706160)
  and c.invalid_reason is null

 ) I
 ) C ;
INSERT INTO @temp_database_schema.khxmbhhpCodesets (codeset_id, concept_id)
SELECT 1 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @vocabulary_database_schema.CONCEPT   WHERE concept_id in (37311061,37311060,756023,756031,756039,756044,756061,756081,37310285)

 ) I
 ) C ;
INSERT INTO @temp_database_schema.khxmbhhpCodesets (codeset_id, concept_id)
SELECT 2 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @vocabulary_database_schema.CONCEPT     WHERE concept_id in (40218805,40218804,700360,2212793)
   UNION  select c.concept_id
  FROM @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (40218805,40218804,700360,2212793)
  and c.invalid_reason is null

 ) I
 ) C ;
INSERT INTO @temp_database_schema.khxmbhhpCodesets (codeset_id, concept_id)
SELECT 3 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @vocabulary_database_schema.CONCEPT     WHERE concept_id in (4100065,37311061,37016200,439676,437663,254761,312437,261326,255848,260139,256451,260125,46271075,4307774,257011,320136,4195694,4185711,436235)
   UNION  select c.concept_id
  FROM @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (4100065,37311061,37016200,439676,437663,254761,312437,261326,255848,260139,256451,260125,46271075,4307774,257011,320136,4195694,4185711,436235)
  and c.invalid_reason is null

 ) I
 ) C ;


CREATE TABLE @temp_database_schema.khxmbhhpqualified_events

AS
WITH primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id)  AS (SELECT P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
FROM (SELECT E.person_id, E.start_date, E.end_date,
         row_number() OVER (PARTITION BY E.person_id ORDER BY E.sort_date ASC) ordinal,
         OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
  FROM (SELECT PE.person_id, PE.event_id, PE.start_date, PE.end_date, PE.target_concept_id, PE.visit_occurrence_id, PE.sort_date FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  JOIN @temp_database_schema.khxmbhhpCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
 ) C

  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria

 ) PE
JOIN (SELECT 0 as index_id, person_id, event_id
FROM (SELECT E.person_id, E.event_id 
  FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  JOIN @temp_database_schema.khxmbhhpCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
 ) C

  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdm_database_schema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) E
  INNER JOIN
  (SELECT 0 as index_id, p.person_id, p.event_id
FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  JOIN @temp_database_schema.khxmbhhpCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
 ) C

  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdm_database_schema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) P
INNER JOIN
(SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  JOIN @temp_database_schema.khxmbhhpCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
 ) C


-- End Condition Occurrence Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= (P.START_DATE + NUMTODSINTERVAL(0, 'day')) AND A.START_DATE <= (P.START_DATE + NUMTODSINTERVAL(0, 'day'))
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

  UNION ALL
-- Begin Correlated Criteria
SELECT 1  index_id, p.person_id, p.event_id
FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  JOIN @temp_database_schema.khxmbhhpCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
 ) C

  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdm_database_schema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) P
INNER JOIN
(SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  JOIN @temp_database_schema.khxmbhhpCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
 ) C


-- End Condition Occurrence Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= (P.START_DATE + NUMTODSINTERVAL(0, 'day')) AND A.START_DATE <= P.OP_END_DATE AND A.visit_occurrence_id = P.visit_occurrence_id
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

   ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) >= 1
 ) G
-- End Criteria Group
 ) AC on AC.person_id = pe.person_id and AC.event_id = pe.event_id

   ) E
	JOIN @cdm_database_schema.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
    WHERE (OP.OBSERVATION_PERIOD_START_DATE + NUMTODSINTERVAL(0, 'day')) <= E.START_DATE AND (E.START_DATE + NUMTODSINTERVAL(0, 'day')) <= OP.OBSERVATION_PERIOD_END_DATE
 ) P
  WHERE P.ordinal = 1
-- End Primary Events

 )
 SELECT
event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id

FROM
(SELECT pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
  FROM primary_events pe
  
JOIN (SELECT 0 as index_id, person_id, event_id
FROM (SELECT E.person_id, E.event_id 
  FROM primary_events E
  LEFT JOIN
  (SELECT 0 as index_id, p.person_id, p.event_id
FROM primary_events P
INNER JOIN
(SELECT C.person_id, C.measurement_id as event_id, C.measurement_date as start_date, (C.measurement_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.measurement_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.measurement_date as sort_date
FROM (SELECT m.* 
  FROM @cdm_database_schema.MEASUREMENT m
JOIN @temp_database_schema.khxmbhhpCodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
 ) C

  WHERE C.measurement_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
AND C.value_as_concept_id in (9189,36309158,45877738,1177295,37079494,45876332,45878583,45876469)
-- End Measurement Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

  UNION ALL
-- Begin Correlated Criteria
SELECT 1  index_id, p.person_id, p.event_id
FROM primary_events P
INNER JOIN
(SELECT C.person_id, C.measurement_id as event_id, C.measurement_date as start_date, (C.measurement_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.measurement_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.measurement_date as sort_date
FROM (SELECT m.* 
  FROM @cdm_database_schema.MEASUREMENT m
JOIN @temp_database_schema.khxmbhhpCodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
 ) C

  WHERE C.measurement_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
AND C.value_as_concept_id in (45884084,9191)
-- End Measurement Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

  UNION ALL
-- Begin Correlated Criteria
SELECT 2  index_id, p.person_id, p.event_id
FROM primary_events P
INNER JOIN
(SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  JOIN @temp_database_schema.khxmbhhpCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 1))
 ) C

  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

  UNION ALL
-- Begin Correlated Criteria
SELECT 3  index_id, p.person_id, p.event_id
FROM primary_events P
INNER JOIN
(SELECT C.person_id, C.measurement_id as event_id, C.measurement_date as start_date, (C.measurement_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.measurement_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.measurement_date as sort_date
FROM (SELECT m.* 
  FROM @cdm_database_schema.MEASUREMENT m
JOIN @temp_database_schema.khxmbhhpCodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
 ) C

  WHERE C.measurement_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
AND C.value_as_concept_id in (45880847,45880480,45885232,45885242,45876576,45882283,45878545)
-- End Measurement Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

  UNION ALL
-- Begin Correlated Criteria
SELECT 4  index_id, p.person_id, p.event_id
FROM primary_events P
INNER JOIN
(SELECT C.person_id, C.procedure_occurrence_id as event_id, C.procedure_date as start_date, (C.procedure_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.procedure_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.procedure_date as sort_date
FROM (SELECT po.* 
  FROM @cdm_database_schema.PROCEDURE_OCCURRENCE po
JOIN @temp_database_schema.khxmbhhpCodesets codesets on ((po.procedure_concept_id = codesets.concept_id and codesets.codeset_id = 2))
 ) C

  WHERE C.procedure_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Procedure Occurrence Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

   ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) <= 0
 ) G
-- End Criteria Group
 ) AC on AC.person_id = pe.person_id and AC.event_id = pe.event_id

 ) QE
  WHERE QE.ordinal = 1
 ;

--- Inclusion Rule Inserts

create table @temp_database_schema.khxmbhhpinclusion_events (inclusion_rule_id NUMBER(19),
	person_id NUMBER(19),
	event_id NUMBER(19)
);

CREATE TABLE @temp_database_schema.khxmbhhpincluded_events

AS
WITH cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal)  AS (SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  FROM (SELECT Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as NUMBER(19)), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    FROM @temp_database_schema.khxmbhhpqualified_events Q
    LEFT JOIN @temp_database_schema.khxmbhhpinclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
   ) MG -- matching groups

 )
 SELECT
event_id, person_id, start_date, end_date, op_start_date, op_end_date

FROM
cteIncludedEvents Results
  WHERE Results.ordinal = 1
 ;



-- generate cohort periods into #final_cohort
CREATE TABLE @temp_database_schema.khxmbhhpcohort_rows

AS
WITH cohort_ends (event_id, person_id, end_date)  AS (SELECT event_id, person_id, op_end_date as end_date FROM @temp_database_schema.khxmbhhpincluded_events
 ),
first_ends (person_id, start_date, end_date) as
(SELECT F.person_id, F.start_date, F.end_date
	FROM (SELECT I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal 
	  FROM @temp_database_schema.khxmbhhpincluded_events I
	  join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
	 ) F
	  WHERE F.ordinal = 1
 )
 SELECT
person_id, start_date, end_date

FROM
first_ends ;

CREATE TABLE @temp_database_schema.khxmbhhpfinal_cohort

AS
WITH cteEndDates (person_id, end_date)  AS (SELECT person_id
		, (event_date + NUMTODSINTERVAL(-1 * 0, 'day'))  as end_date
	FROM (SELECT person_id
			, event_date
			, event_type
			, MAX(start_ordinal) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal 
			, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_date, event_type) AS overall_ord
		FROM (SELECT person_id
				, start_date AS event_date
				, -1 AS event_type
				, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date) AS start_ordinal
			FROM @temp_database_schema.khxmbhhpcohort_rows
		
			  UNION ALL
		

			SELECT
				person_id
				, (end_date + NUMTODSINTERVAL(0, 'day'))  end_date
				, 1 AS event_type
				, NULL
			FROM @temp_database_schema.khxmbhhpcohort_rows
		 ) RAWDATA
	 ) e
	  WHERE (2 * e.start_ordinal) - e.overall_ord = 0
 ),
cteEnds (person_id, start_date, end_date) AS
(SELECT c.person_id
		, c.start_date
		, MIN(e.end_date) AS end_date
	FROM @temp_database_schema.khxmbhhpcohort_rows c
	JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
 )
 SELECT
person_id, min(start_date) as start_date, end_date

FROM
cteEnds
group by person_id, end_date
 ;

DELETE FROM @target_database_schema.@target_cohort_table where cohort_definition_id = @target_cohort_id;
INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
SELECT @target_cohort_id as cohort_definition_id, person_id, start_date, end_date 
FROM @temp_database_schema.khxmbhhpfinal_cohort CO
 ;





TRUNCATE TABLE @temp_database_schema.khxmbhhpcohort_rows;
DROP TABLE @temp_database_schema.khxmbhhpcohort_rows;

TRUNCATE TABLE @temp_database_schema.khxmbhhpfinal_cohort;
DROP TABLE @temp_database_schema.khxmbhhpfinal_cohort;

TRUNCATE TABLE @temp_database_schema.khxmbhhpinclusion_events;
DROP TABLE @temp_database_schema.khxmbhhpinclusion_events;

TRUNCATE TABLE @temp_database_schema.khxmbhhpqualified_events;
DROP TABLE @temp_database_schema.khxmbhhpqualified_events;

TRUNCATE TABLE @temp_database_schema.khxmbhhpincluded_events;
DROP TABLE @temp_database_schema.khxmbhhpincluded_events;

TRUNCATE TABLE @temp_database_schema.khxmbhhpCodesets;
DROP TABLE @temp_database_schema.khxmbhhpCodesets;