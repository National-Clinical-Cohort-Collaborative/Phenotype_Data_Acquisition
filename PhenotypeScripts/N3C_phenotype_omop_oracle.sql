/**
CHANGE LOG:
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
Script changes between 10-29 & 11-05: simplified script to human-written SQL (versus ATLAS generated) to enable debugging by individual OMOP sites.

HOW TO RUN:
You will need to find and replace @cdmDatabaseSchema, @cdmDatabaseSchema with your local OMOP schema details. This is the only modification you should make to this script.

USER NOTES: 
In OHDSI conventions, we do not usually write tables to the main database schema. 
OHDSI uses @resultsDatabaseSchema as a results schema build cohort tables for specific analysis. 
We built the N3C_COHORT table in this results schema as we know many OMOP analyst do not have write access to their @cdmDatabaseSchema.
To follow the logic used in this code, visit: https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/wiki/Latest-Phenotype

SCRIPT RELEASE DATE: 11-05-2020

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
-- Here we need to know when you ran the phenotype, what version you're using and what vocabulary version you've built your OMOP concepts on
CREATE TABLE @resultsDatabaseSchema.phenotype_execution (
	run_datetime TIMESTAMP NOT NULL,
	phenotype_version varchar(50) NOT NULL,
	vocabulary_version varchar(50) NULL
);


INSERT INTO @resultsDatabaseSchema.n3c_cohort
SELECT DISTINCT person_id
FROM (SELECT DISTINCT person_id
FROM @cdmDatabaseSchema.MEASUREMENT
    WHERE measurement_concept_id IN (SELECT concept_id
		FROM @cdmDatabaseSchema.CONCEPT
		-- here we look for the concepts that are the LOINC codes we're looking for in the phenotype
		    WHERE concept_id IN (
				586515
				,586522
				,706179
				,586521
				,723459
				,706181
				,706177
				,706176
				,706180
				,706178
				,706167
				,706157
				,706155
				,757678
				,706161
				,586520
				,706175
				,706156
				,706154
				,706168
				,715262
				,586526
				,757677
				,706163
				,715260
				,715261
				,706170
				,706158
				,706169
				,706160
				,706173
				,586519
				,586516
				,757680
				,757679
				,586517
				,757686
				,756055
				)
		
		   UNION
		
		SELECT c.concept_id
		FROM @cdmDatabaseSchema.CONCEPT c
		JOIN @cdmDatabaseSchema.CONCEPT_ANCESTOR ca ON c.concept_id = ca.descendant_concept_id
		-- Most of the LOINC codes do not have descendants but there is one OMOP Extension code (765055) in use that has descendants which we want to pull
		-- This statement pulls the descendants of that specific code
			AND ca.ancestor_concept_id IN (756055)
			AND c.invalid_reason IS NULL
		 )
	-- Here we add a date restriction: after January 1, 2020
	AND measurement_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
	AND (
	-- The value_as_concept field is where we store standardized qualitative results
	-- The concept ids here represent LOINC or SNOMED codes for standard ways to code a lab that is positive
		value_as_concept_id IN (
			45878583
			,37079494
			,1177295
			,36307756
			,36309158
			,36308436
			,9189
			)
	-- To be exhaustive, we also look for Positive strings in the value_source_value field
		OR value_source_value IN (
			'Positive'
			,'Present'
			,'Detected'
			)
		)

   UNION

-- Phenotype Entry Criteria: ONE or more of the â€œStrong Positiveâ€? diagnosis codes from the ICD-10 or SNOMED tables
-- This section constructs entry logic prior to the CDC guidance issued on April 1, 2020
SELECT DISTINCT person_id
FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
  WHERE condition_concept_id IN (SELECT concept_id
		FROM @vocabulary_database_schema.CONCEPT
		-- The list of ICD-10 codes in the Phenotype Wiki
		-- This is the list of standard concepts that represent those terms
		  WHERE concept_id IN (
			756023,
			756044,
			756061,
			756031,
			37311061,
			756081,
			37310285,
			756039,
			320651,
			37311060
			)
		 )
	-- This logic imposes the restriction: these codes were only valid as Strong Positive codes between January 1, 2020 and March 31, 2020
	AND condition_start_date BETWEEN TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
		AND TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(03,'00')||'-'||TO_CHAR(31,'00'), 'YYYY-MM-DD')

   UNION

-- The CDC issued guidance on April 1, 2020 that changed COVID coding conventions
SELECT DISTINCT person_id
FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
  WHERE condition_concept_id IN (SELECT concept_id
		FROM @vocabulary_database_schema.CONCEPT
		-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
		-- This is the list of standard concepts that represent those terms
		    WHERE concept_id IN (
				37311061,
				37311060,
				756023,
				756031,
				756039,
				756044,
				756061,
				756081,
				37310285
				)
		
		   UNION
		
		SELECT c.concept_id
		FROM @vocabulary_database_schema.CONCEPT c
		JOIN @vocabulary_database_schema.CONCEPT_ANCESTOR ca ON c.concept_id = ca.descendant_concept_id
		-- Here we pull the descendants (aka terms that are more specific than the concepts selected above)
			AND ca.ancestor_concept_id IN (
				756044,
				37310285,
				37310283,
				756061,
				756081,
				37310287,
				756023,
				756031,
				37310286,
				37311061,
				37310284,
				756039,
				37311060,
				37310254
				)
			AND c.invalid_reason IS NULL
		 )
	
	AND condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')

   UNION

-- 3) TWO or more of the â€œWeak Positiveâ€? diagnosis codes from the ICD-10 or SNOMED tables (below) during the same encounter or on the same date
-- Here we start looking in the CONDITION_OCCCURRENCE table for visits on the same date
-- BEFORE 04-01-2020 "WEAK POSITIVE" LOGIC:
SELECT DISTINCT person_id
FROM (SELECT person_id
	FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
	  WHERE condition_concept_id IN (SELECT concept_id
			FROM @vocabulary_database_schema.CONCEPT
		-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
		-- It also includes the OMOP only codes that are on the Phenotype Wiki
		-- This is the list of standard concepts that represent those terms
			  WHERE concept_id IN (
					260125,
					260139,
					46271075,
					4307774,
					4195694,
					257011,
					442555,
					4059022,
					4059021,
					256451,
					4059003,
					4168213,
					434490,
					439676,
					254761,
					4048098,
					37311061,
					4100065,
					320136,
					4038519,
					312437,
					4060052,
					4263848,
					37311059,
					37016200,
					4011766,
					437663,
					4141062,
					4164645,
					4047610,
					4260205,
					4185711,
					4289517,
					4140453,
					4090569,
					4109381,
					4330445,
					255848,
					4102774,
					436235,
					261326,
					436145,
					40482061,
					439857,
					254677,
					40479642,
					256722,
					4133224,
					4310964,
					4051332,
					4112521,
					4110484,
					4112015,
					4110023,
					4112359,
					4110483,
					4110485,
					254058,
					40482069,
					4256228,
					37016114,
					46273719,
					312940,
					36716978,
					37395564,
					4140438,
					46271074,
					319049,
					314971
					)
			 )
		-- This code list is only valid for CDC guidance before 04-01-2020
		AND condition_start_date BETWEEN TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
			AND TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(03,'00')||'-'||TO_CHAR(31,'00'), 'YYYY-MM-DD')
	-- Now we group by person_id and visit_occurrence_id to find people who have 2 or more
	GROUP BY person_id
		,visit_occurrence_id
	HAVING count(*) >= 2
	 ) dx_same_encounter

  UNION

-- Now we apply logic to look for same visit AND same date
SELECT DISTINCT person_id
FROM (SELECT person_id
	FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
	  WHERE condition_concept_id IN (SELECT concept_id
			FROM @vocabulary_database_schema.CONCEPT
		-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
		-- It also includes the OMOP only codes that are on the Phenotype Wiki
		-- This is the list of standard concepts that represent those terms	
			  WHERE concept_id IN (
					260125,
					260139,
					46271075,
					4307774,
					4195694,
					257011,
					442555,
					4059022,
					4059021,
					256451,
					4059003,
					4168213,
					434490,
					439676,
					254761,
					4048098,
					37311061,
					4100065,
					320136,
					4038519,
					312437,
					4060052,
					4263848,
					37311059,
					37016200,
					4011766,
					437663,
					4141062,
					4164645,
					4047610,
					4260205,
					4185711,
					4289517,
					4140453,
					4090569,
					4109381,
					4330445,
					255848,
					4102774,
					436235,
					261326,
					436145,
					40482061,
					439857,
					254677,
					40479642,
					256722,
					4133224,
					4310964,
					4051332,
					4112521,
					4110484,
					4112015,
					4110023,
					4112359,
					4110483,
					4110485,
					254058,
					40482069,
					4256228,
					37016114,
					46273719,
					312940,
					36716978,
					37395564,
					4140438,
					46271074,
					319049,
					314971
					)
			 )
		-- This code list is only valid for CDC guidance before 04-01-2020
		AND condition_start_date BETWEEN TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
			AND TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(03,'00')||'-'||TO_CHAR(31,'00'), 'YYYY-MM-DD')
	GROUP BY person_id
		,condition_start_date
	HAVING count(*) >= 2
	 ) dx_same_date

  UNION

-- AFTER 04-01-2020 "WEAK POSITIVE" LOGIC:
-- Here we start looking in the CONDITION_OCCCURRENCE table for visits on the same visit

SELECT DISTINCT person_id
FROM (SELECT person_id
	FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
	  WHERE condition_concept_id IN (SELECT concept_id
			FROM @vocabulary_database_schema.CONCEPT
		-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
		-- It also includes the OMOP only codes that are on the Phenotype Wiki
		-- This is the list of standard concepts that represent those terms	
			  WHERE concept_id IN (
					260125,
					260139,
					46271075,
					4307774,
					4195694,
					257011,
					442555,
					4059022,
					4059021,
					256451,
					4059003,
					4168213,
					434490,
					439676,
					254761,
					4048098,
					37311061,
					4100065,
					320136,
					4038519,
					312437,
					4060052,
					4263848,
					37311059,
					37016200,
					4011766,
					437663,
					4141062,
					4164645,
					4047610,
					4260205,
					4185711,
					4289517,
					4140453,
					4090569,
					4109381,
					4330445,
					255848,
					4102774,
					436235,
					261326,
					436145,
					40482061,
					439857,
					254677,
					40479642,
					256722,
					4133224,
					4310964,
					4051332,
					4112521,
					4110484,
					4112015,
					4110023,
					4112359,
					4110483,
					4110485,
					254058,
					40482069,
					4256228,
					37016114,
					46273719,
					312940,
					36716978,
					37395564,
					4140438,
					46271074,
					319049,
					314971,
					320651
					)
			 )
	-- This code list is only valid for CDC guidance before 04-01-2020
		AND condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
	-- Now we group by person_id and visit_occurrence_id to find people who have 2 or more
		GROUP BY person_id
		,visit_occurrence_id
	HAVING count(*) >= 2
	 ) dx_same_encounter

  UNION

-- Now we apply logic to look for same visit AND same date
SELECT DISTINCT person_id
FROM (SELECT person_id
	FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
	  WHERE condition_concept_id IN (SELECT concept_id
			FROM @vocabulary_database_schema.CONCEPT
		-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
		-- It also includes the OMOP only codes that are on the Phenotype Wiki
		-- This is the list of standard concepts that represent those term
			  WHERE concept_id IN (
					260125
					,260139
					,46271075
					,4307774
					,4195694
					,257011
					,442555
					,4059022
					,4059021
					,256451
					,4059003
					,4168213
					,434490
					,439676
					,254761
					,4048098
					,37311061
					,4100065
					,320136
					,4038519
					,312437
					,4060052
					,4263848
					,37311059
					,37016200
					,4011766
					,437663
					,4141062
					,4164645
					,4047610
					,4260205
					,4185711
					,4289517
					,4140453
					,4090569
					,4109381
					,4330445
					,255848
					,4102774
					,436235
					,261326
					,320651
					)
			 )
		-- This code list is based on CDC Guidance for code use AFTER 04-01-2020
		AND condition_start_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
-- Now we group by person_id and visit_occurrence_id to find people who have 2 or more
		GROUP BY person_id
		,condition_start_date
	HAVING count(*) >= 2
	 ) dx_same_date

  UNION

-- 4) ONE or more of the lab tests in the Labs table, regardless of result (unless negative and accompanied by a Z11.59)
-- Patient was assigned code Z11.59 (viral screening code; used per CDC guidance to indicate asymptomatic covid screening) on or after 4/1/2020, 
-- and does NOT also have a record of a positive covid test or a â€œstrong positiveâ€? diagnosis code.

-- We begin by looking for ANY COVID measurement
SELECT DISTINCT person_id
FROM @cdmDatabaseSchema.MEASUREMENT
WHERE measurement_concept_id IN (SELECT concept_id
		FROM @cdmDatabaseSchema.CONCEPT
		-- here we look for the concepts that are the LOINC codes we're looking for in the phenotype
		    WHERE concept_id IN (
				586515
				,586522
				,706179
				,586521
				,723459
				,706181
				,706177
				,706176
				,706180
				,706178
				,706167
				,706157
				,706155
				,757678
				,706161
				,586520
				,706175
				,706156
				,706154
				,706168
				,715262
				,586526
				,757677
				,706163
				,715260
				,715261
				,706170
				,706158
				,706169
				,706160
				,706173
				,586519
				,586516
				,757680
				,757679
				,586517
				,757686
				,756055
				)
		
		   UNION
		
		SELECT c.concept_id
		FROM @cdmDatabaseSchema.CONCEPT c
		JOIN @cdmDatabaseSchema.CONCEPT_ANCESTOR ca ON c.concept_id = ca.descendant_concept_id
		-- Most of the LOINC codes do not have descendants but there is one OMOP Extension code (765055) in use that has descendants which we want to pull
		-- This statement pulls the descendants of that specific code
			AND ca.ancestor_concept_id IN (756055)
			AND c.invalid_reason IS NULL
		 )
	AND measurement_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
	-- existence of Z11.59
	-- Z11.59 here is being pulled from the source_concept_id
	-- we want to make extra sure that we're ONLY looking at Z11.59 not the more general SNOMED code that would be in the standard concept id column for this
	AND person_id NOT IN (SELECT person_id
		FROM @cdmDatabaseSchema.OBSERVATION
		  WHERE observation_source_concept_id = 45595484
			AND observation_date >= TO_DATE(TO_CHAR(2020,'0000')||'-'||TO_CHAR(04,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
		 )
		
		
 ) 
 ;



INSERT INTO @resultsDatabaseSchema.phenotype_execution
SELECT SYSDATE as run_datetime
    ,'2.2' as phenotype_version
    , (SELECT vocabulary_version FROM @cdmDatabaseSchema.vocabulary    WHERE vocabulary_id='None'   AND ROWNUM <= 1) AS VOCABULARY_VERSION FROM DUAL;
