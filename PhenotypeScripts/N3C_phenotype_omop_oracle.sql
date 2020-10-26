/**
Change log:
V1.1 - initial commit
V1.2 - updated possible positive cases (typo in name of concept set name) and added additional NIH VSAC codeset_id
V1.3 - consolidated to single cohort definition and added N3C COHORT table + labeling statements
V1.4 - reconfiguration using SQLRender
V1.5 - updating LOINC concept sets, subset of Weak Positive and Strong Positive concept sets into before and after April 1 and new logic to include this distinction
V1.6 - OMOP vocabulary updates to include new LOINCs
V2.0 - dropping weak diagnosis after May 1, adding asymptomatic test code (Z11.59) to condition concepts,
changing logic related to inclusion of qualitative test results
V2.1 - removed HCPCS/CPT4 concept set and PROCEDURE_OCCURRENCE criteria, removed censoring and fixed inclusion entry event instead
NOTE: LOINC codes from LOINC release V2.68 remain unsupported in the OHDSI vocabulary as of Phenotype V2.1 release. Issue is raised with OHDSI Vocab team and will be updated in concept sets as soon as CONCEPT table includes this and is pushed to community.
V2.2 - added back OMOP Extension code (765055), removal of generic LOINC codes and recent modification of faulty use of value_as_concept logic

To run, you will need to find and replace @cdmDatabaseSchema, @cdmDatabaseSchema with your local OMOP schema details

Harmonization note:
In OHDSI conventions, we do not usually write tables to the main database schema.
NOTE: OHDSI uses @resultsDatabaseSchema as a results schema build cohort tables for specific analysis. We built the N3C_COHORT table in this results schema as we know many OMOP analyst do not have write access to their @cdmDatabaseSchema.


Begin building cohort following OHDSI standard cohort definition process


**/

/** Creating the N3C Cohort table **/
--DROP TABLE IF EXISTS @resultsDatabaseSchema.n3c_cohort; -- RUN THIS LINE AFTER FIRST BUILD
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE @resultsDatabaseSchema.n3c_cohort';
  EXECUTE IMMEDIATE 'DROP TABLE @resultsDatabaseSchema.n3c_cohort';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;

-- Create dest table
CREATE TABLE @resultsDatabaseSchema.n3c_cohort (
	person_id			int  NOT NULL
);

--DROP TABLE IF EXISTS @resultsDatabaseSchema.phenotype_execution; -- RUN THIS LINE AFTER FIRST BUILD
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE @resultsDatabaseSchema.phenotype_execution';
  EXECUTE IMMEDIATE 'DROP TABLE @resultsDatabaseSchema.phenotype_execution';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;

-- Create dest table
CREATE TABLE @resultsDatabaseSchema.phenotype_execution (
	run_datetime TIMESTAMP NOT NULL,
	phenotype_version varchar(50) NOT NULL,
	vocabulary_version varchar(50) NULL
);


-- OHDSI ATLAS generated cohort logic
/** This block of code generates concept sets to be used in this phenotype**/
CREATE TABLE cxk18wbkCodesets (
  codeset_id int NOT NULL,
  concept_id NUMBER(19) NOT NULL
)
;

/**This code creates the [CD2H Lab Concepts] concept set - which pulls LOINC codes for inclusion.
In phenotype 2.2 - we readded 756055 per the request of a site using this OMOP extension code.**/
INSERT INTO cxk18wbkCodesets (codeset_id, concept_id)
SELECT 0 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @cdmDatabaseSchema.CONCEPT     WHERE concept_id in (586515,586522,706179,586521,723459,706181,706177,706176,706180,706178,706167,706157,706155,757678,706161,586520,706175,706156,706154,706168,715262,586526,757677,706163,715260,715261,706170,706158,706169,706160,706173,586519,586516,757680,757679,586517,757686,756055)
   UNION  select c.concept_id
  FROM @cdmDatabaseSchema.CONCEPT c
  join @cdmDatabaseSchema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (756055)
  and c.invalid_reason is null

 ) I
 ) C ;
/**This code creates the [CD2H Weak Positive After to 04-01-2020] concept set- which pulls the updated list of SNOMED codes that ICD10 codes map to.
In the phenotype, we have 04-01-2020 as a cut point related to changes in CDC coding guidance.
We have removed the descendant concepts from this after concept set because the coding stringency has changed.**/
INSERT INTO cxk18wbkCodesets (codeset_id, concept_id)
SELECT 2 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @cdmDatabaseSchema.CONCEPT   WHERE concept_id in (260125,260139,46271075,4307774,4195694,257011,442555,4059022,4059021,256451,4059003,4168213,434490,439676,254761,4048098,37311061,4100065,320136,4038519,312437,4060052,4263848,37311059,37016200,4011766,437663,4141062,4164645,4047610,4260205,4185711,4289517,4140453,4090569,4109381,4330445,255848,4102774,436235,261326,320651)

 ) I
 ) C ;
INSERT INTO cxk18wbkCodesets (codeset_id, concept_id)
/**This code creates the [CD2H Strong Positive Prior to 04-01-2020] concept set-which pulls the prior list of SNOMED codes that ICD10 codes map to.
In the phenotype, we have 04-01-2020 as a cut point related to changes in CDC coding guidance.
We have left the descendant concepts in the earlier concept set because there was less specificity in coding at that point in time. **/
SELECT 3 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @cdmDatabaseSchema.CONCEPT     WHERE concept_id in (756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,320651,4100065)
   UNION  select c.concept_id
  FROM @cdmDatabaseSchema.CONCEPT c
  join @cdmDatabaseSchema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,320651,4100065)
  and c.invalid_reason is null

 ) I
 ) C ;
/**This code creates the [CD2H Strong Positive After 04-01-2020] concept set-which pulls the prior list of SNOMED codes that ICD10 codes map to.
In the phenotype, we have 04-01-2020 as a cut point related to changes in CDC coding guidance.
We have removed the descendant concepts from this after concept set because the coding stringency has changed.**/
INSERT INTO cxk18wbkCodesets (codeset_id, concept_id)
/
SELECT 4 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @cdmDatabaseSchema.CONCEPT     WHERE concept_id in (756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,756023,756044,756061,756031,37311061,756081,37310285,756039,37311060)
   UNION  select c.concept_id
  FROM @cdmDatabaseSchema.CONCEPT c
  join @cdmDatabaseSchema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,756023,756044,756061,756031,37311061,756081,37310285,756039,37311060)
  and c.invalid_reason is null

 ) I
 ) C ;
/**This code creates the [CD2H Weak Positive Prior to 04-01-2020] concept set-which pulls the prior list of SNOMED codes that ICD10 codes map to.
In the phenotype, we have 04-01-2020 as a cut point related to changes in CDC coding guidance.
We have left the descendant concepts in the earlier concept set because there was less specificity in coding at that point in time. **/
INSERT INTO cxk18wbkCodesets (codeset_id, concept_id)
SELECT 5 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @cdmDatabaseSchema.CONCEPT   WHERE concept_id in (260125,260139,46271075,4307774,4195694,257011,442555,4059022,4059021,256451,4059003,4168213,434490,439676,254761,4048098,37311061,4100065,320136,4038519,312437,4060052,4263848,37311059,37016200,4011766,437663,4141062,4164645,4047610,4260205,4185711,4289517,4140453,4090569,4109381,4330445,255848,4102774,436235,261326)

 ) I
 ) C ;
/**This code creates the [CD2H Asymptomatic] concept set. This is an unusual concept set because we're using a non-standard code. 
The rationale here is that the standard concept that Z11.59 maps to is "too generic" than the source concept. In this case, we are allowing a non-standard code to be used.
You will see logic in the use of this concept set to indicate to the CDM where to pull this from. If you do not do this, you run the risk of ATLAS not pulling from the right column as Standard concepts and Source concepts live in different columns in the domain.**/
INSERT INTO cxk18wbkCodesets (codeset_id, concept_id)
SELECT 6 as codeset_id, c.concept_id FROM (SELECT distinct I.concept_id FROM (SELECT concept_id FROM @cdmDatabaseSchema.CONCEPT   WHERE concept_id in (45595484)

 ) I
 ) C ;

/** This block of code is beginning to ascribe the "Index" event to how someone qualifies for the phenotype.
It will begin to assemble a cohort based off of any rules related to observation_period (aka the time someone is continuously followed in the data).
In the case of N3C, we don't impart any rules here.**/
CREATE TABLE cxk18wbkqualified_events

AS
WITH primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id)  AS (SELECT P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
FROM (SELECT E.person_id, E.start_date, E.end_date,
         row_number() OVER (PARTITION BY E.person_id ORDER BY E.sort_date ASC) ordinal,
         OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
  FROM (SELECT C.person_id, C.measurement_id as event_id, C.measurement_date as start_date, (C.measurement_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.measurement_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.measurement_date as sort_date
FROM (SELECT m.* 
  FROM @cdmDatabaseSchema.MEASUREMENT m
JOIN cxk18wbkCodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
 ) C

    WHERE C.measurement_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
/** THIS LOGIC WAS INADVERTENTLY PLACED IN THE WRONG EVENT AREA IN V2.1/2.2. IT IS NOW COMMENTED OUT FOR TRANSPARENCY AND WILL BE REMOVED IN SIMPLIFICATION.
 AND ( C.value_as_concept_id in (4126681,45877985,45884084,9191)
 OR
 C.value_source_value in ('Positive', 'Present', 'Detected')
 ) **/
 -- End Measurement Criteria

   UNION ALL
/**Now, we're looking for people who meet eligibility if they meet one of the two CONDITION_OCCURRENCE criteria.**/

-- Begin Condition Occurrence Criteria
SELECT C.person_id, C.condition_occurrence_id  event_id, C.condition_start_date  start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
 ) C

   WHERE (C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD') and C.condition_start_date <= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(03,'00')||'-'||TO_CHAR(31,'00'), 'YYYY-MM-DD'))
-- End Condition Occurrence Criteria

   UNION ALL

/**The next code is saying to look for a strong positive on or after 04-01-2020**/
-- Begin Condition Occurrence Criteria
SELECT C.person_id, C.condition_occurrence_id  event_id, C.condition_start_date  start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
 ) C

   WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria

   UNION ALL
/**The next code is saying to look for a Weak Positive before 04-01-2020**/
SELECT PE.person_id, PE.event_id, PE.start_date, PE.end_date, PE.target_concept_id, PE.visit_occurrence_id, PE.sort_date FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
 ) C

  WHERE (C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD') and C.condition_start_date <= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(03,'00')||'-'||TO_CHAR(31,'00'), 'YYYY-MM-DD'))
-- End Condition Occurrence Criteria

 ) PE
/**The next code is making sure you have TWO distinct occurrences of the Weak Positive before 04-01-2020 on the same day.
It looks really complicated because it's a nested thought: "Find me someone who has a CONDITION_OCCURRENCE of the allowable Weak Positive concepts before 04-01-2020
AND THEN look at that person's records and find me someone who has TWO DISTINCT CONDITION_OCCURRENCE of the allowable Weak Positive concepts before 04-01-2020 on the same day.
It'll be coalescing dates to understand "what is the same day" and it will use the concept set (=5) multiple times to look up this list of allowable concepts.**/
JOIN (SELECT 0 as index_id, person_id, event_id
FROM (SELECT E.person_id, E.event_id 
  FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
 ) C
/* This code tells it what dates: before 04-01-2020**/
  WHERE (C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD') and C.condition_start_date <= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(03,'00')||'-'||TO_CHAR(31,'00'), 'YYYY-MM-DD'))
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdmDatabaseSchema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) E
  INNER JOIN
  (SELECT 0 as index_id, p.person_id, p.event_id
FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
 ) C
/** This code tells it what dates: before 04-01-2020**/
  WHERE (C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD') and C.condition_start_date <= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(03,'00')||'-'||TO_CHAR(31,'00'), 'YYYY-MM-DD'))
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdmDatabaseSchema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) P
INNER JOIN
(SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
 ) C


-- End Condition Occurrence Criteria
/**The next code is making sure you have TWO distinct occurrences of the Weak Positive before 04-01-2020**/
 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= (P.START_DATE + NUMTODSINTERVAL(0, 'day')) AND A.START_DATE <= (P.START_DATE + NUMTODSINTERVAL(0, 'day'))
GROUP BY p.person_id, p.event_id
HAVING COUNT(DISTINCT A.TARGET_CONCEPT_ID) >= 2
-- End Correlated Criteria
/**The next code is making sure you have it on the same day**/
   ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) = 1
 ) G
-- End Criteria Group
 ) AC on AC.person_id = pe.person_id and AC.event_id = pe.event_id
/**That's the end of the Weak Positive before 04-01-2020. But we're not done, we have to apply similar logic for Weak Positive between 04-01-2020 and 05-01-2020**/

  UNION ALL
/**The next code is making sure you have TWO distinct occurrences of the Weak Positive between 04-01-2020 and 05-01-2020**/
/**First we establish that someone has a condition occurrence of Weak Positive between 04-01-2020 and 05-01-2020**//
SELECT PE.person_id, PE.event_id, PE.start_date, PE.end_date, PE.target_concept_id, PE.visit_occurrence_id, PE.sort_date FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
 ) C
/** This code tells it what dates: between 04-01-2020 and 05-01-2020**/
  WHERE (C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD') and C.condition_start_date <= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(05,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD'))
-- End Condition Occurrence Criteria

 ) PE
JOIN (SELECT 0 as index_id, person_id, event_id
FROM (SELECT E.person_id, E.event_id 
  FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
 ) C
/** This code tells it what dates: between 04-01-2020 and 05-01-2020**/
  WHERE (C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD') and C.condition_start_date <= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(05,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD'))
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdmDatabaseSchema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) E
  INNER JOIN
  (SELECT 0 as index_id, p.person_id, p.event_id
FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
 ) C
/** This code tells it what dates: between 04-01-2020 and 05-01-2020**/
  WHERE (C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD') and C.condition_start_date <= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(05,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD'))
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdmDatabaseSchema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) P
INNER JOIN
/**OCCURRENCE 2**/
(SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
 ) C


-- End Condition Occurrence Criteria
/**The next code is making extra sure it's TWO distinct occurrences of the Weak Positive between 04-01-2020 and 05-01-2020**/
 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= (P.START_DATE + NUMTODSINTERVAL(0, 'day')) AND A.START_DATE <= (P.START_DATE + NUMTODSINTERVAL(0, 'day'))
GROUP BY p.person_id, p.event_id
HAVING COUNT(DISTINCT A.TARGET_CONCEPT_ID) >= 2
-- End Correlated Criteria
/**The next code is making sure you have it on the same day**/
   ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) = 1
 ) G
-- End Criteria Group
 ) AC on AC.person_id = pe.person_id and AC.event_id = pe.event_id
/**That's the end of the Weak Positive logic inclusive of through 05-01-2020**/

  UNION ALL
/**We have to now apply logic to look for Asymptomatic patients.
This one is going to get extra confusing because we're using a non-standard concept for Z11.59 so we have to do some extra gymnastics.
Z11.59 is a condition code in ICD-10 vocabulary but in OMOP, you will find it in the OBSERVATION domain because the absence of a condition is not an active condition.
It's an observation about the patient. Thus, it lives in the DOMAIN_ID = OBSERVATION.
So we start by building a piece of logic to look at the OBSERVATION domain.**/
select PE.person_id, PE.event_id, PE.start_date, PE.end_date, PE.target_concept_id, PE.visit_occurrence_id, PE.sort_date FROM (SELECT C.person_id, C.observation_id as event_id, C.observation_date as start_date, (C.observation_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.observation_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.observation_date as sort_date
FROM (SELECT o.* 
  FROM @cdmDatabaseSchema.OBSERVATION o
JOIN cxk18wbkCodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
 ) C
/**And we say, well we want this on or after 04-01-2020, when the CDC guidance started.**/
  WHERE C.observation_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Observation Criteria

 ) PE
JOIN (SELECT 0 as index_id, person_id, event_id
FROM (SELECT E.person_id, E.event_id 
  FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.observation_id as event_id, C.observation_date as start_date, (C.observation_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.observation_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.observation_date as sort_date
FROM (SELECT o.* 
  FROM @cdmDatabaseSchema.OBSERVATION o
JOIN cxk18wbkCodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
 ) C

  WHERE C.observation_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Observation Criteria
 ) Q
JOIN @cdmDatabaseSchema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) E
  INNER JOIN
  (SELECT 0 as index_id, p.person_id, p.event_id
FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.observation_id as event_id, C.observation_date as start_date, (C.observation_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.observation_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.observation_date as sort_date
FROM (SELECT o.* 
  FROM @cdmDatabaseSchema.OBSERVATION o
JOIN cxk18wbkCodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
 ) C

  WHERE C.observation_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Observation Criteria
 ) Q
JOIN @cdmDatabaseSchema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) P
INNER JOIN
/*Now we're going to specify logic to get to at least 1 Strong Positive On or After 04-01-2020... and soon we will filter: but not people who have a lab-confirmed negative**/
(SELECT PE.person_id, PE.event_id, PE.start_date, PE.end_date, PE.target_concept_id, PE.visit_occurrence_id, PE.sort_date FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
 ) C
/**This is where we impart the date rule: on or after 04-01-2020**/
  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria

 ) PE
JOIN (SELECT 0 as index_id, person_id, event_id
FROM (SELECT E.person_id, E.event_id 
  FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
 ) C
/**We add the date criteria: on or after 04-01-2020**/
  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria
 ) Q
/** Now we want to take the Strong Positive On or After 04-01-2020 cohort and filter it further.
We're going to create a Criteria grouping here to look at the people who meet Strong Positive On or After 04-01-2020 and then filter out people who have negative results.
We start by respecify the CONDITION_OCCURRENCE criteria.**/
JOIN @cdmDatabaseSchema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) E
  LEFT JOIN
  (SELECT 0 as index_id, p.person_id, p.event_id
FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
 ) C

  WHERE C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdmDatabaseSchema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) P
/**We restrict the Strong Positive On or After 04-01-2020 cohort that's specified to now look for who has measurement data**/
INNER JOIN
(SELECT C.person_id, C.measurement_id as event_id, C.measurement_date as start_date, (C.measurement_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.measurement_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.measurement_date as sort_date
FROM (SELECT m.* 
  FROM @cdmDatabaseSchema.MEASUREMENT m
JOIN cxk18wbkCodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
 ) C
/**This statement below says: "If there is a lab, find me the ones who are NEGATIVE." 
In OMOP, value_as_concept_id is the standard representation of the qualitative results.**/
  WHERE C.value_as_concept_id in (45878583,37079494,1177295,36307756,36309158,36308436,9189)
-- End Measurement Criteria
/**Counting people who have a Z11.59 + a lab-confirmed negative.**/
 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

   ) 
  /**Restricting to people who DO NOT have a lab-confirmed negative test.**/
  CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) <= 0
 ) G
-- End Criteria Group
 ) AC on AC.person_id = pe.person_id and AC.event_id = pe.event_id
/**Keeping people who have a Z11.59 + a Strong Positive On or After 04-01-2020.**/
 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

  UNION ALL
-- Begin Correlated Criteria

/**Now we've got to move on in our logic... we want to find people who have a Z11.59 + a Strong Positive Before 04-01-2020.**/
/**Here's the OBSERVATION logic again where we're looking for Z11.59 after 04-01-2020**/
SELECT 1  index_id, p.person_id, p.event_id
FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.observation_id as event_id, C.observation_date as start_date, (C.observation_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.observation_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.observation_date as sort_date
FROM (SELECT o.* 
  FROM @cdmDatabaseSchema.OBSERVATION o
JOIN cxk18wbkCodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
 ) C

  WHERE C.observation_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Observation Criteria
 ) Q
JOIN @cdmDatabaseSchema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) P
INNER 
/** Now we want to take the Strong Positive Before 04-01-2020 cohort and filter it further.
We're going to create a Criteria grouping here to look at the people who meet Strong Positive On or After 04-01-2020 and then filter out people who have negative results.
We start by respecify the CONDITION_OCCURRENCE criteria.**/
(SELECT PE.person_id, PE.event_id, PE.start_date, PE.end_date, PE.target_concept_id, PE.visit_occurrence_id, PE.sort_date FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
 ) C
/**Restricting to after 01-01-2020 and before 04-01-2020**/
  WHERE (C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD') and C.condition_start_date <= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(03,'00')||'-'||TO_CHAR(31,'00'), 'YYYY-MM-DD'))
-- End Condition Occurrence Criteria

 ) PE
JOIN (SELECT 0 as index_id, person_id, event_id
FROM (SELECT E.person_id, E.event_id 
  FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
 ) C

  WHERE (C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD') and C.condition_start_date <= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(03,'00')||'-'||TO_CHAR(31,'00'), 'YYYY-MM-DD'))
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdmDatabaseSchema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) E
  LEFT JOIN
  (SELECT 0 as index_id, p.person_id, p.event_id
FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + NUMTODSINTERVAL(1, 'day'))) as end_date,
       C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.condition_start_date as sort_date
FROM (SELECT co.* 
  FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
  JOIN cxk18wbkCodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
 ) C

  WHERE (C.condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD') and C.condition_start_date <= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(03,'00')||'-'||TO_CHAR(31,'00'), 'YYYY-MM-DD'))
-- End Condition Occurrence Criteria
 ) Q
JOIN @cdmDatabaseSchema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) P
INNER JOIN
/*Now we specifiy the logic to look for a lab-confirmed negative.*/
(SELECT C.person_id, C.measurement_id as event_id, C.measurement_date as start_date, (C.measurement_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.measurement_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.measurement_date as sort_date
FROM (SELECT m.* 
  FROM @cdmDatabaseSchema.MEASUREMENT m
JOIN cxk18wbkCodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
 ) C
/*Looking specifically for people who are lab-confirmed negative using the value_as_concept_id field where we standardize qualitative results.*/
  WHERE C.value_as_concept_id in (45878583,37079494,1177295,36307756,36309158,36308436,9189)
-- End Measurement Criteria

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria
/**Filtering to keep Z11.59 AND Strong Positive before 04-01-2020 but only those who are NOT lab-confirmed negative.**/
   ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) <= 0
 ) G
-- End Criteria Group
 ) AC on AC.person_id = pe.person_id and AC.event_id = pe.event_id

 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
GROUP BY p.person_id, p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1
-- End Correlated Criteria

  UNION ALL
/**One last OR criteria here... if we don't have you as Z11.59 with a Strong Positive... we want you if you're Z11.59 with a lab-confirmed positive.**/
/**We begin this by stating the Z11.59 criteria from the beginning -- looking at the observation table for that specific code.**/
-- Begin Correlated Criteria
SELECT 2  index_id, p.person_id, p.event_id
FROM (SELECT Q.person_id, Q.event_id, Q.start_date, Q.end_date, Q.visit_occurrence_id, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
FROM (SELECT C.person_id, C.observation_id as event_id, C.observation_date as start_date, (C.observation_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.observation_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.observation_date as sort_date
FROM (SELECT o.* 
  FROM @cdmDatabaseSchema.OBSERVATION o
JOIN cxk18wbkCodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
 ) C
/**Restricting to after 04-01-2020**/
  WHERE C.observation_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- End Observation Criteria
 ) Q
JOIN @cdmDatabaseSchema.OBSERVATION_PERIOD OP on Q.person_id = OP.person_id 
  and OP.observation_period_start_date <= Q.start_date and OP.observation_period_end_date >= Q.start_date
 ) P
INNER JOIN
/**Looking in the Measurement table for lab-confirmed positive**/
(SELECT C.person_id, C.measurement_id as event_id, C.measurement_date as start_date, (C.measurement_date + NUMTODSINTERVAL(1, 'day')) as END_DATE,
       C.measurement_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id,
       C.measurement_date as sort_date
FROM (SELECT m.* 
  FROM @cdmDatabaseSchema.MEASUREMENT m
JOIN cxk18wbkCodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
 ) C
/**Specifying the value_as_concept_ids for positive and allowing a string search for where people have not coded these lab-confirmed qualitative results.\
This is where the logic from MS SQL Line 159-163 should have gone.**/
  WHERE AND ( C.value_as_concept_id in (4126681,45877985,45884084,9191)
OR
C.value_source_value in ('Positive', 'Present', 'Detected')
	)


-- End Measurement Criteria
/**Now bringing this logic together to look for people who are Z11.59 and Lab-confirmed positive**/
 ) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE
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
	JOIN @cdmDatabaseSchema.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
    WHERE (OP.OBSERVATION_PERIOD_START_DATE + NUMTODSINTERVAL(0, 'day')) <= E.START_DATE AND (E.START_DATE + NUMTODSINTERVAL(0, 'day')) <= OP.OBSERVATION_PERIOD_END_DATE
 ) P
  WHERE P.ordinal = 1
-- End Primary Events

 ) /*The following code is a vestigal part of Atlas-generated code. If we had additional qualifying logic that restricted cohort entry, we'd see it here. But we don't so it's largely just a shell of code. */
 SELECT
event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id

FROM
(SELECT pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as NUMBER(19)) as visit_occurrence_id
  FROM primary_events pe
  
 ) QE

 ;

/**The following code is a vestigal part of Atlas-generated code. If we had additional inclusion criteria that further filtered cohort entry, we'd see it here. But we don't so it's largely just a shell of code. **/

--- Inclusion Rule Inserts

create table cxk18wbkinclusion_events (inclusion_rule_id NUMBER(19),
	person_id NUMBER(19),
	event_id NUMBER(19)
);

CREATE TABLE cxk18wbkincluded_events

AS
WITH cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal)  AS (SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  FROM (SELECT Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as NUMBER(19)), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    FROM cxk18wbkqualified_events Q
    LEFT JOIN cxk18wbkinclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
   ) MG -- matching groups

 )
 SELECT
event_id, person_id, start_date, end_date, op_start_date, op_end_date

FROM
cteIncludedEvents Results
  WHERE Results.ordinal = 1
 ;


/**The following code looks to see how many times people qualify for the cohort because we DO allow people to qualify more than once.**/
-- generate cohort periods into #final_cohort
CREATE TABLE cxk18wbkcohort_rows

AS
WITH cohort_ends (event_id, person_id, end_date)  AS (SELECT event_id, person_id, op_end_date as end_date FROM cxk18wbkincluded_events
 ),
first_ends (person_id, start_date, end_date) as
(SELECT F.person_id, F.start_date, F.end_date
	FROM (SELECT I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal 
	  FROM cxk18wbkincluded_events I
	  join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
	 ) F
	  WHERE F.ordinal = 1
 )
 SELECT
person_id, start_date, end_date

FROM
first_ends ;

/**More Atlas generated code that largely goes unused.**/
INSERT INTO @resultsDatabaseSchema.n3c_cohort
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
			FROM cxk18wbkcohort_rows
		
			  UNION ALL
		

			SELECT
				person_id
				, (end_date + NUMTODSINTERVAL(0, 'day'))  end_date
				, 1 AS event_type
				, NULL
			FROM cxk18wbkcohort_rows
		 ) RAWDATA
	 ) e
	  WHERE (2 * e.start_ordinal) - e.overall_ord = 0
 ),
cteEnds (person_id, start_date, end_date) AS
(SELECT c.person_id
		, c.start_date
		, MIN(e.end_date) AS end_date
	FROM cxk18wbkcohort_rows c
	JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
 ),
final_cohort (person_id, start_date, end_date) AS
(SELECT person_id, min(start_date) as start_date, end_date
FROM cteEnds
group by person_id, end_date
 )

/**The final collapsing of ALL the logic into the cohort table.**/
--# BEGIN N3C_COHORT table to be retained

--SELECT person_id
 SELECT DISTINCT
    person_id
FROM final_cohort ;

INSERT INTO @resultsDatabaseSchema.phenotype_execution
SELECT SYSDATE as run_datetime
    ,'2.2' as phenotype_version
    , (SELECT vocabulary_version FROM @cdmDatabaseSchema.vocabulary    WHERE vocabulary_id='None'   AND ROWNUM <= 1) AS VOCABULARY_VERSION FROM DUAL;

/**Dropping out all the temp tables.**/

TRUNCATE TABLE cxk18wbkcohort_rows;
DROP TABLE cxk18wbkcohort_rows;

TRUNCATE TABLE cxk18wbkinclusion_events;
DROP TABLE cxk18wbkinclusion_events;

TRUNCATE TABLE cxk18wbkqualified_events;
DROP TABLE cxk18wbkqualified_events;

TRUNCATE TABLE cxk18wbkincluded_events;
DROP TABLE cxk18wbkincluded_events;

TRUNCATE TABLE cxk18wbkCodesets;
DROP TABLE cxk18wbkCodesets;
