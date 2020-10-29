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
incremental change on 10-29: simplified script

To run, you will need to find and replace @cdmDatabaseSchema, @cdmDatabaseSchema with your local OMOP schema details

Harmonization note:
In OHDSI conventions, we do not usually write tables to the main database schema.
NOTE: OHDSI uses @resultsDatabaseSchema as a results schema build cohort tables for specific analysis. We built the N3C_COHORT table in this results schema as we know many OMOP analyst do not have write access to their @cdmDatabaseSchema.


Begin building cohort following OHDSI standard cohort definition process


**/

/** Creating the N3C Cohort table **/

--DROP TABLE IF EXISTS @resultsDatabaseSchema.n3c_cohort; -- RUN THIS LINE AFTER FIRST BUILD
IF OBJECT_ID('@resultsDatabaseSchema.n3c_cohort', 'U') IS NOT NULL           -- Drop temp table if it exists
  DROP TABLE @resultsDatabaseSchema.n3c_cohort;

-- Create dest table
CREATE TABLE @resultsDatabaseSchema.n3c_cohort (
	person_id			int  NOT NULL
);

--DROP TABLE IF EXISTS @resultsDatabaseSchema.phenotype_execution; -- RUN THIS LINE AFTER FIRST BUILD
IF OBJECT_ID('@resultsDatabaseSchema.phenotype_execution', 'U') IS NOT NULL           -- Drop temp table if it exists
  DROP TABLE @resultsDatabaseSchema.phenotype_execution;

-- Create dest table
CREATE TABLE @resultsDatabaseSchema.phenotype_execution (
	run_datetime datetime2 NOT NULL,
	phenotype_version varchar(50) NOT NULL,
	vocabulary_version varchar(50) NULL
);


INSERT INTO @resultsDatabaseSchema.n3c_cohort
SELECT DISTINCT person_id
FROM
(

/**

INCLUSION:

1) Postive COVID Measurement
2) Strong positive dx
3) 2x Weak Dx
4) COVID Measurement & No occurrences of Z11.59 


**/

-- 1) Positive COVID Measurement
SELECT DISTINCT person_id
FROM @cdmDatabaseSchema.MEASUREMENT
WHERE measurement_concept_id IN (
		SELECT concept_id
		FROM @cdmDatabaseSchema.CONCEPT
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
			AND ca.ancestor_concept_id IN (756055)
			AND c.invalid_reason IS NULL
		)
	AND measurement_date >= DATEFROMPARTS(2020, 01, 01)
	AND (
		value_as_concept_id IN (
			4126681,
			45877985,
			45884084,
			9191
			)
		OR value_source_value IN (
			'Positive'
			,'Present'
			,'Detected'
			)
		)

UNION

-- 2) Strong positive 
-- prior to 04-01
SELECT DISTINCT person_id
FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
WHERE condition_concept_id IN (
		SELECT concept_id
		FROM @vocabulary_database_schema.CONCEPT
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
	AND condition_start_date BETWEEN DATEFROMPARTS(2020, 01, 01)
		AND DATEFROMPARTS(2020, 03, 31)

UNION

-- after 04-01
SELECT DISTINCT person_id
FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
WHERE condition_concept_id IN (
		SELECT concept_id
		FROM @vocabulary_database_schema.CONCEPT
		WHERE concept_id IN (
				756023
				,756044
				,756061
				,756031
				,37311061
				,756081
				,37310285
				,756039
				,37311060
				,756023
				,756044
				,756061
				,756031
				,37311061
				,756081
				,37310285
				,756039
				,37311060
				)
		
		UNION
		
		SELECT c.concept_id
		FROM @vocabulary_database_schema.CONCEPT c
		JOIN @vocabulary_database_schema.CONCEPT_ANCESTOR ca ON c.concept_id = ca.descendant_concept_id
			AND ca.ancestor_concept_id IN (
				756023
				,756044
				,756061
				,756031
				,37311061
				,756081
				,37310285
				,756039
				,37311060
				,756023
				,756044
				,756061
				,756031
				,37311061
				,756081
				,37310285
				,756039
				,37311060
				)
			AND c.invalid_reason IS NULL
		)
	AND condition_start_date >= DATEFROMPARTS(2020, 04, 01)

UNION

-- 3) 2x Weak diagnosis 
-- prior to 04-01
-- same visit 
SELECT DISTINCT person_id
FROM (
	SELECT person_id
		,visit_occurrence_id
		,count(*)
	FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
	WHERE condition_concept_id IN (
			SELECT concept_id
			FROM @vocabulary_database_schema.CONCEPT
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
					)
			)
		AND condition_start_date BETWEEN DATEFROMPARTS(2020, 01, 01)
			AND DATEFROMPARTS(2020, 03, 31)
	GROUP BY person_id
		,visit_occurrence_id
	HAVING count(*) >= 2
	) dx_same_encounter

UNION

-- same date
SELECT DISTINCT person_id
FROM (
	SELECT person_id
		,condition_start_date
		,count(*)
	FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
	WHERE condition_concept_id IN (
			SELECT concept_id
			FROM @vocabulary_database_schema.CONCEPT
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
					)
			)
		AND condition_start_date BETWEEN DATEFROMPARTS(2020, 01, 01)
			AND DATEFROMPARTS(2020, 03, 31)
	GROUP BY person_id
		,condition_start_date
	HAVING count(*) >= 2
	) dx_same_date

UNION

-- after 04-01
-- same visit 
SELECT DISTINCT person_id
FROM (
	SELECT person_id
		,visit_occurrence_id
		,count(*)
	FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
	WHERE condition_concept_id IN (
			SELECT concept_id
			FROM @vocabulary_database_schema.CONCEPT
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
		AND condition_start_date >= DATEFROMPARTS(2020, 04, 01)
	GROUP BY person_id
		,visit_occurrence_id
	HAVING count(*) >= 2
	) dx_same_encounter

UNION

-- same date
SELECT DISTINCT person_id
FROM (
	SELECT person_id
		,condition_start_date
		,count(*)
	FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
	WHERE condition_concept_id IN (
			SELECT concept_id
			FROM @vocabulary_database_schema.CONCEPT
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
		AND condition_start_date >= DATEFROMPARTS(2020, 04, 01)
	GROUP BY person_id
		,condition_start_date
	HAVING count(*) >= 2
	) dx_same_date

UNION

-- 4) COVID Measurement & No occurrences of Z11.59 
-- COVID lab test of any result
SELECT DISTINCT person_id
FROM @cdmDatabaseSchema.MEASUREMENT
WHERE measurement_concept_id IN (
		SELECT concept_id
		FROM @cdmDatabaseSchema.CONCEPT
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
			AND ca.ancestor_concept_id IN (756055)
			AND c.invalid_reason IS NULL
		)
	AND measurement_date >= DATEFROMPARTS(2020, 01, 01)
	-- existence of Z11.59
	AND person_id NOT IN (
		SELECT person_id
		FROM @cdmDatabaseSchema.OBSERVATION
		WHERE observation_source_concept_id = 45595484
			AND observation_date >= DATEFROMPARTS(2020, 04, 01)
		)
		
		
) 
;



INSERT INTO @resultsDatabaseSchema.phenotype_execution
SELECT
    GETDATE() as run_datetime
    ,'2.2' as phenotype_version
    , (SELECT TOP 1 vocabulary_version FROM @cdmDatabaseSchema.vocabulary WHERE vocabulary_id='None') AS VOCABULARY_VERSION;

