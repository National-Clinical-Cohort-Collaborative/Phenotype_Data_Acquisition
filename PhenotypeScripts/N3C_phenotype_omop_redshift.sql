/**
N3C Phenotype 3.2 - OMOP Redshift
Author: Robert Miller (Tufts), Emily Pfaff (UNC)

HOW TO RUN:
If you are not using the R or Python exporters, you will need to find and replace @cdmDatabaseSchema and @resultsDatabaseSchema, @cdmDatabaseSchema with your local OMOP schema details. This is the only modification you should make to this script.

USER NOTES:
In OHDSI conventions, we do not usually write tables to the main database schema.
OHDSI uses @resultsDatabaseSchema as a results schema build cohort tables for specific analysis.
Here we will build five tables in this script (N3C_PRE_COHORT, N3C_CASE_COHORT, N3C_CONTROL_COHORT, N3C_CONTROL_MAP, N3C_COHORT).
Each table is assembled in the results schema as we know some OMOP analysts do not have write access to their @cdmDatabaseSchema.
If you have read/write to your cdmDatabaseSchema, you would use the same schema name for both.

To follow the logic used in this code, visit: https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/wiki/Latest-Phenotype

SCRIPT RELEASE DATE: By 14 February 2020

**/


CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.N3C_PRE_COHORT   ( person_id INT NOT NULL
		,inc_dx_strong INT NOT NULL
		,inc_dx_weak INT NOT NULL
		,inc_lab_any INT NOT NULL
		,inc_lab_pos INT NOT NULL
		,phenotype_version VARCHAR(10)
		,pt_age VARCHAR(20)
		,sex VARCHAR(20)
		,hispanic VARCHAR(20)
		,race VARCHAR(20)
		,vocabulary_version VARCHAR(20)
		)
DISTKEY(person_id);




CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.N3C_CASE_COHORT   ( person_id INT NOT NULL
		,pt_age VARCHAR(20)
		,sex VARCHAR(20)
		,hispanic VARCHAR(20)
		,race VARCHAR(20)
		)
DISTKEY(person_id);



CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.N3C_CONTROL_COHORT   ( person_id INT NOT NULL
		,pt_age VARCHAR(20)
		,sex VARCHAR(20)
		,hispanic VARCHAR(20)
		,race VARCHAR(20)
		)
DISTKEY(person_id);

CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.N3C_CONTROL_MAP   (case_person_id INT NOT NULL
		,buddy_num INT NOT NULL
		,control_person_id INT NULL
		)
DISTSTYLE ALL;

CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.n3c_cohort   ( person_id INT NOT NULL)
DISTKEY(person_id);

DROP TABLE IF EXISTS @resultsDatabaseSchema.final_map;

-- before beginning, remove any patients from the last run
-- IMPORTANT: do NOT truncate or drop the control-map table.
TRUNCATE TABLE @resultsDatabaseSchema.N3C_PRE_COHORT;
TRUNCATE TABLE @resultsDatabaseSchema.N3C_CASE_COHORT;
TRUNCATE TABLE @resultsDatabaseSchema.N3C_CONTROL_COHORT;
TRUNCATE TABLE @resultsDatabaseSchema.N3C_COHORT;

-- Phenotype Entry Criteria: A lab confirmed positive test
INSERT INTO @resultsDatabaseSchema.N3C_PRE_COHORT
-- populate the pre-cohort table
 WITH covid_lab_pos
AS (
	SELECT DISTINCT person_id
	FROM @cdmDatabaseSchema.MEASUREMENT
	WHERE measurement_concept_id IN (
			SELECT concept_id
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
					,36659631
					,36661377
					,36661378
					,36661372
					,36661373
					,36661374
					,36661370
					,36661371
					,723479
					,723474
					,757685
					,723476
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
		AND measurement_date >= TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(01,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
		AND (
			-- The value_as_concept field is where we store standardized qualitative results
			-- The concept ids here represent LOINC or SNOMED codes for standard ways to code a lab that is positive
			value_as_concept_id IN (
				4126681 -- Detected
				,45877985 -- Detected
				,45884084 -- Positive
				,9191 --- Positive 
				,4181412 -- Present
				,45879438 -- Present
				,45881802 -- Reactive
				)
			-- To be exhaustive, we also look for Positive strings in the value_source_value field
			OR value_source_value IN (
				'Positive'
				,'Present'
				,'Detected'
				,'Reactive'
				)
			)
	)
	,
	-- UNION
	-- Phenotype Entry Criteria: ONE or more of the Strong Positive diagnosis codes from the ICD-10 or SNOMED tables
	-- This section constructs entry logic prior to the CDC guidance issued on April 1, 2020
dx_strong
AS (
	SELECT DISTINCT person_id
	FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
	WHERE condition_concept_id IN (
			SELECT concept_id
			FROM @cdmDatabaseSchema.CONCEPT
			-- The list of ICD-10 codes in the Phenotype Wiki
			-- This is the list of standard concepts that represent those terms
			WHERE concept_id IN (
					756023
					,756044
					,756061
					,756031
					,37311061
					,756081
					,37310285
					,756039
					,320651
					)
			)
		-- This logic imposes the restriction: these codes were only valid as Strong Positive codes between January 1, 2020 and March 31, 2020
		AND condition_start_date BETWEEN TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(01,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
			AND TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(03,'00FM')||'-'||TO_CHAR(31,'00FM'), 'YYYY-MM-DD')

	UNION
	-- the one condition code that maps to an observation (3731160)
		SELECT DISTINCT person_id
	FROM @cdmDatabaseSchema.OBSERVATION
	WHERE observation_concept_id IN (
			SELECT concept_id
			FROM @cdmDatabaseSchema.CONCEPT
			-- The list of ICD-10 codes in the Phenotype Wiki
			-- This is the list of standard concepts that represent those terms
			WHERE concept_id IN (37311060)
			)
		-- This logic imposes the restriction: these codes were only valid as Strong Positive codes between January 1, 2020 and March 31, 2020
		AND observation_date BETWEEN TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(01,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
			AND TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(03,'00FM')||'-'||TO_CHAR(31,'00FM'), 'YYYY-MM-DD')

	UNION

	-- The CDC issued guidance on April 1, 2020 that changed COVID coding conventions
	SELECT DISTINCT person_id
	FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
	WHERE condition_concept_id IN (
			SELECT concept_id
			FROM @cdmDatabaseSchema.CONCEPT
			-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
			-- This is the list of standard concepts that represent those terms
			WHERE concept_id IN (
					37311061
					,756023
					,756031
					,756039
					,756044
					,756061
					,756081
					,37310285
					)

			UNION

			SELECT c.concept_id
			FROM @cdmDatabaseSchema.CONCEPT c
			JOIN @cdmDatabaseSchema.CONCEPT_ANCESTOR ca ON c.concept_id = ca.descendant_concept_id
				-- Here we pull the descendants (aka terms that are more specific than the concepts selected above)
				AND ca.ancestor_concept_id IN (
					756044
					,37310285
					,37310283
					,756061
					,756081
					,37310287
					,756023
					,756031
					,37310286
					,37311061
					,37310284
					,756039
					,37310254
					)
				AND c.invalid_reason IS NULL
			)

		AND condition_start_date >= TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(04,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
	
	UNION

	-- the one condition code that maps to an observation (3731160)
	SELECT DISTINCT person_id
	FROM @cdmDatabaseSchema.OBSERVATION
	WHERE observation_concept_id IN (
			SELECT concept_id
			FROM @cdmDatabaseSchema.CONCEPT
			-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
			-- This is the list of standard concepts that represent those terms
			WHERE concept_id IN (37311060)

			UNION

			SELECT c.concept_id
			FROM @cdmDatabaseSchema.CONCEPT c
			JOIN @cdmDatabaseSchema.CONCEPT_ANCESTOR ca ON c.concept_id = ca.descendant_concept_id
				-- Here we pull the descendants (aka terms that are more specific than the concepts selected above)
				AND ca.ancestor_concept_id IN (37311060)
				AND c.invalid_reason IS NULL
			)

		AND observation_date >= TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(04,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
	)
	,
	-- UNION
	-- 3) TWO or more of the Weak Positive diagnosis codes from the ICD-10 or SNOMED tables (below) during the same encounter or on the same date
	-- Here we start looking in the CONDITION_OCCCURRENCE table for visits on the same date
	-- BEFORE 04-01-2020 WEAK POSITIVE LOGIC:
dx_weak
AS (
	SELECT DISTINCT person_id
	FROM (
		SELECT person_id
		FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
		WHERE condition_concept_id IN (
				SELECT concept_id
				FROM @cdmDatabaseSchema.CONCEPT
				-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
				-- It also includes the OMOP only codes that are on the Phenotype Wiki
				-- This is the list of standard concepts that represent those terms
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
						,436145
						,40482061
						,439857
						,254677
						,40479642
						,256722
						,4133224
						,4310964
						,4051332
						,4112521
						,4110484
						,4112015
						,4110023
						,4112359
						,4110483
						,4110485
						,254058
						,40482069
						,4256228
						,37016114
						,46273719
						,312940
						,36716978
						,37395564
						,4140438
						,46271074
						,319049
						,314971
						)
				)
			-- This code list is only valid for CDC guidance before 04-01-2020
			AND condition_start_date BETWEEN TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(01,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
				AND TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(03,'00FM')||'-'||TO_CHAR(31,'00FM'), 'YYYY-MM-DD')
		-- Now we group by person_id and visit_occurrence_id to find people who have 2 or more

		GROUP BY person_id
			,visit_occurrence_id
		HAVING count(distinct condition_concept_id) >= 2
		) dx_same_encounter

	UNION

	-- Now we apply logic to look for same visit AND same date
	SELECT DISTINCT person_id
	FROM (
		SELECT person_id
		FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
		WHERE condition_concept_id IN (
				SELECT concept_id
				FROM @cdmDatabaseSchema.CONCEPT
				-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
				-- It also includes the OMOP only codes that are on the Phenotype Wiki
				-- This is the list of standard concepts that represent those terms
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
						,436145
						,40482061
						,439857
						,254677
						,40479642
						,256722
						,4133224
						,4310964
						,4051332
						,4112521
						,4110484
						,4112015
						,4110023
						,4112359
						,4110483
						,4110485
						,254058
						,40482069
						,4256228
						,37016114
						,46273719
						,312940
						,36716978
						,37395564
						,4140438
						,46271074
						,319049
						,314971
						)
				)
			-- This code list is only valid for CDC guidance before 04-01-2020
			AND condition_start_date BETWEEN TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(01,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
				AND TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(03,'00FM')||'-'||TO_CHAR(31,'00FM'), 'YYYY-MM-DD')
		GROUP BY person_id
			,condition_start_date
		HAVING count(distinct condition_concept_id) >= 2
		) dx_same_date

	UNION

	-- AFTER 04-01-2020 WEAK POSITIVE LOGIC:
	-- Here we start looking in the CONDITION_OCCCURRENCE table for visits on the same visit
	SELECT DISTINCT person_id
	FROM (
		SELECT person_id
		FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
		WHERE condition_concept_id IN (
				SELECT concept_id
				FROM @cdmDatabaseSchema.CONCEPT
				-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
				-- It also includes the OMOP only codes that are on the Phenotype Wiki
				-- This is the list of standard concepts that represent those terms
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
						,436145
						,40482061
						,439857
						,254677
						,40479642
						,256722
						,4133224
						,4310964
						,4051332
						,4112521
						,4110484
						,4112015
						,4110023
						,4112359
						,4110483
						,4110485
						,254058
						,40482069
						,4256228
						,37016114
						,46273719
						,312940
						,36716978
						,37395564
						,4140438
						,46271074
						,319049
						,314971
						,320651
						)
				)
			-- This code list is only valid for CDC guidance before 04-01-2020
			AND condition_start_date BETWEEN TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(04,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
				AND TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(05,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
		-- Now we group by person_id and visit_occurrence_id to find people who have 2 or more
		GROUP BY person_id
			,visit_occurrence_id
		HAVING count(distinct condition_concept_id) >= 2
		) dx_same_encounter

	UNION

	-- Now we apply logic to look for same visit AND same date
	SELECT DISTINCT person_id
	FROM (
		SELECT person_id
		FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE
		WHERE condition_concept_id IN (
				SELECT concept_id
				FROM @cdmDatabaseSchema.CONCEPT
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
			AND condition_start_date BETWEEN TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(04,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
				AND TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(05,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
		-- Now we group by person_id and visit_occurrence_id to find people who have 2 or more
		GROUP BY person_id
			,condition_start_date
		HAVING count(distinct condition_concept_id) >= 2
		) dx_same_date
	)
	,
	-- UNION
	-- 4) ONE or more of the lab tests in the Labs table, regardless of result
	-- We begin by looking for ANY COVID measurement
covid_lab
AS (
	SELECT DISTINCT person_id
	FROM @cdmDatabaseSchema.MEASUREMENT
	WHERE measurement_concept_id IN (
			SELECT concept_id
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
					,36659631
					,36661377
					,36661378
					,36661372
					,36661373
					,36661374
					,36661370
					,36661371
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

		AND measurement_date >= TO_DATE(TO_CHAR(2020,'0000FM')||'-'||TO_CHAR(01,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
	)
	,
covid_cohort
AS (
	SELECT DISTINCT person_id
	FROM dx_strong

	UNION

	SELECT DISTINCT person_id
	FROM dx_weak

	UNION

	SELECT DISTINCT person_id
	FROM covid_lab
	)
	,cohort
AS (
	SELECT covid_cohort.person_id
		,CASE
			WHEN dx_strong.person_id IS NOT NULL
				THEN 1
			ELSE 0
			END AS inc_dx_strong
		,CASE
			WHEN dx_weak.person_id IS NOT NULL
				THEN 1
			ELSE 0
			END AS inc_dx_weak
		,CASE
			WHEN covid_lab.person_id IS NOT NULL
				THEN 1
			ELSE 0
			END AS inc_lab_any
		,CASE
			WHEN covid_lab_pos.person_id IS NOT NULL
				THEN 1
			ELSE 0
			END AS inc_lab_pos
	FROM covid_cohort
	LEFT OUTER JOIN dx_strong ON covid_cohort.person_id = dx_strong.person_id
	LEFT OUTER JOIN dx_weak ON covid_cohort.person_id = dx_weak.person_id
	LEFT OUTER JOIN covid_lab ON covid_cohort.person_id = covid_lab.person_id
	LEFT OUTER JOIN covid_lab_pos ON covid_cohort.person_id = covid_lab_pos.person_id
	)
 SELECT DISTINCT c.person_id
	,inc_dx_strong
	,inc_dx_weak
	,inc_lab_any
	,inc_lab_pos
	,'3.2' AS phenotype_version
	,CASE
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 0
				AND 4
			THEN '0-4'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 5
				AND 9
			THEN '5-9'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 10
				AND 14
			THEN '10-14'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 15
				AND 19
			THEN '15-19'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 20
				AND 24
			THEN '20-24'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 25
				AND 29
			THEN '25-29'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 30
				AND 34
			THEN '30-34'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 35
				AND 39
			THEN '35-39'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 40
				AND 44
			THEN '40-44'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 45
				AND 49
			THEN '45-49'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 50
				AND 54
			THEN '50-54'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 55
				AND 59
			THEN '55-59'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 60
				AND 64
			THEN '60-64'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 65
				AND 69
			THEN '65-69'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 70
				AND 74
			THEN '70-74'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 75
				AND 79
			THEN '75-79'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 80
				AND 84
			THEN '80-84'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) BETWEEN 85
				AND 89
			THEN '85-89'
		WHEN datediff(year, d.birth_datetime, CURRENT_DATE) >= 90
			THEN '90+'
		END AS pt_age
	,d.gender_concept_id AS sex
	,d.ethnicity_concept_id AS hispanic
	,d.race_concept_id AS race
	,(
		SELECT TOP 1 vocabulary_version
		FROM @cdmDatabaseSchema.vocabulary
		WHERE vocabulary_id = 'None'
		) AS vocabulary_version
FROM cohort c
JOIN @cdmDatabaseSchema.person d ON c.person_id = d.person_id;

--populate the case table
INSERT INTO @resultsDatabaseSchema.N3C_CASE_COHORT (person_id
									,pt_age
									,sex
									,hispanic
									,race )
SELECT 	person_id
		,pt_age
		,sex
		,hispanic
		,race
FROM @resultsDatabaseSchema.N3C_PRE_COHORT
WHERE inc_dx_strong = 1
	OR inc_lab_pos = 1
	OR inc_dx_weak = 1;

INSERT INTO @resultsDatabaseSchema.N3C_CONTROL_COHORT  (person_id
									,pt_age
									,sex
									,hispanic
									,race )
SELECT npc.person_id
		,pt_age
		,sex
		,hispanic
		,race
FROM @resultsDatabaseSchema.N3C_PRE_COHORT npc
JOIN (
		SELECT person_id
		FROM @cdmDatabaseSchema.visit_occurrence
		WHERE visit_start_date > TO_DATE(TO_CHAR(2018,'0000FM')||'-'||TO_CHAR(01,'00FM')||'-'||TO_CHAR(01,'00FM'), 'YYYY-MM-DD')
		GROUP BY person_id
		HAVING DATEDIFF(day, min(visit_start_date), max(visit_start_date)) >= 10
) e
ON npc.person_id = e.person_id
WHERE inc_dx_strong = 0
	AND inc_lab_pos = 0
	AND inc_dx_weak = 0
	AND inc_lab_any = 1;


-- Now that the pre-cohort and case tables are populated, we start matching cases and controls, and updating the case and control tables as needed.
-- all cases need two control buddies. We select on progressively looser demographic criteria until every case has two control matches, or we run out of patients in the control pool.
-- First handle instances where someone who was in the control group in the prior run is now a case
-- just delete both the case and the control from the mapping table. The case will repopulate automatically with a replaced control.
DELETE
FROM @resultsDatabaseSchema.N3C_CONTROL_MAP
WHERE CONTROL_PERSON_ID IN (
		SELECT person_id
		FROM @resultsDatabaseSchema.N3C_CASE_COHORT
		);

-- Remove cases and controls from the mapping table if those people are no longer in the person table (due to merges or other reasons)
DELETE
FROM @resultsDatabaseSchema.N3C_CONTROL_MAP
WHERE CASE_person_id NOT IN (
		SELECT person_id
		FROM @cdmDatabaseSchema.person
		);

DELETE
FROM @resultsDatabaseSchema.N3C_CONTROL_MAP
WHERE CONTROL_person_id NOT IN (
		SELECT person_id
		FROM @cdmDatabaseSchema.person
		);

-- Remove cases who no longer meet the phenotype definition
DELETE
FROM @resultsDatabaseSchema.N3C_CONTROL_MAP
WHERE CASE_person_id NOT IN (
		SELECT person_id
		FROM @resultsDatabaseSchema.N3C_CASE_COHORT
		WHERE person_id IS NOT NULL
		);


INSERT INTO @resultsDatabaseSchema.N3C_CONTROL_MAP
SELECT
		person_id, 1 as buddy_num, NULL
		FROM @resultsDatabaseSchema.n3c_case_cohort
		WHERE person_id NOT IN (
			SELECT case_person_id
			FROM @resultsDatabaseSchema.N3C_CONTROL_MAP
			WHERE buddy_num = 1
			)

		UNION

		SELECT person_id, 2 as buddy_num, NULL
		FROM @resultsDatabaseSchema.n3c_case_cohort
		WHERE person_id NOT IN (
			SELECT case_person_id
			FROM @resultsDatabaseSchema.N3C_CONTROL_MAP
			WHERE buddy_num = 2
			)
;

-- Match #1 - age, sex, race, ethnicity
UPDATE @resultsDatabaseSchema.N3C_CONTROL_MAP
SET control_person_id = y.control_pid
FROM
(
	SELECT cases.person_id as case_pid, cases.buddy_num bud_num, controls.person_id control_pid
	FROM
	(
		-- Get cases
		SELECT subq.*
			,ROW_NUMBER() OVER (PARTITION BY pt_age
				,sex
				,race
				,hispanic  ORDER BY randnum
				 ) AS join_row_1
		FROM (
			SELECT npc.person_id
				,npc.pt_age
				,npc.sex
				,npc.race
				,npc.hispanic
				,cm.buddy_num
				,RANDOM() AS randnum
			FROM @resultsDatabaseSchema.n3c_case_cohort npc
			JOIN @resultsDatabaseSchema.N3C_CONTROL_MAP cm
			ON npc.person_id = cm.case_person_id
			AND cm.control_person_id IS NULL
		) subq
	) cases
	INNER JOIN
	(
			-- Get cases
		SELECT subq.*
			,ROW_NUMBER() OVER (PARTITION BY pt_age
				,sex
				,race
				,hispanic  ORDER BY randnum
				 ) AS join_row_1
		FROM (
			SELECT npc.person_id
				,npc.pt_age
				,npc.sex
				,npc.race
				,npc.hispanic
				,RANDOM() AS randnum
			FROM @resultsDatabaseSchema.n3c_control_cohort npc
			WHERE npc.person_id NOT IN ( SELECT DISTINCT control_person_id FROM @resultsDatabaseSchema.N3C_CONTROL_MAP WHERE control_person_id IS NOT NULL)

		) subq

	) controls
	ON cases.pt_age = controls.pt_age
		AND cases.sex = controls.sex
		AND cases.race = controls.race
		AND cases.hispanic = controls.hispanic
		AND cases.join_row_1 = controls.join_row_1

) y
WHERE control_person_id IS NULL
AND case_person_id = y.case_pid
AND buddy_num = y.bud_num
;





-- Match #2 - age, sex, race
UPDATE @resultsDatabaseSchema.N3C_CONTROL_MAP
SET control_person_id = y.control_pid
FROM
(
	SELECT cases.person_id as case_pid, cases.buddy_num bud_num, controls.person_id control_pid
	FROM
	(
		-- Get cases
		SELECT subq.*
			,ROW_NUMBER() OVER (PARTITION BY pt_age
				,sex
				,race
				  ORDER BY randnum
				 ) AS join_row_1
		FROM (
			SELECT npc.person_id
				,npc.pt_age
				,npc.sex
				,npc.race
				,cm.buddy_num
				,RANDOM() AS randnum
			FROM @resultsDatabaseSchema.n3c_case_cohort npc
			JOIN @resultsDatabaseSchema.N3C_CONTROL_MAP cm
			ON npc.person_id = cm.case_person_id
			AND cm.control_person_id IS NULL
		) subq
	) cases
	INNER JOIN
	(
			-- Get cases
		SELECT subq.*
			,ROW_NUMBER() OVER (PARTITION BY pt_age
				,sex
				,race
				  ORDER BY randnum
				 ) AS join_row_1
		FROM (
			SELECT npc.person_id
				,npc.pt_age
				,npc.sex
				,npc.race
				,RANDOM() AS randnum
			FROM @resultsDatabaseSchema.n3c_control_cohort npc
			WHERE npc.person_id NOT IN ( SELECT DISTINCT control_person_id FROM @resultsDatabaseSchema.N3C_CONTROL_MAP WHERE control_person_id IS NOT NULL)

		) subq

	) controls
	ON cases.pt_age = controls.pt_age
		AND cases.sex = controls.sex
		AND cases.race = controls.race
		AND cases.join_row_1 = controls.join_row_1

) y
WHERE control_person_id IS NULL
AND case_person_id = y.case_pid
AND buddy_num = y.bud_num
;




-- Match #3 -- age, sex
UPDATE @resultsDatabaseSchema.N3C_CONTROL_MAP
SET control_person_id = y.control_pid
FROM
(
	SELECT cases.person_id as case_pid, cases.buddy_num bud_num, controls.person_id control_pid
	FROM
	(
		-- Get cases
		SELECT subq.*
			,ROW_NUMBER() OVER (PARTITION BY pt_age
				,sex
				  ORDER BY randnum
				 ) AS join_row_1
		FROM (
			SELECT npc.person_id
				,npc.pt_age
				,npc.sex
				,cm.buddy_num
				,RANDOM() AS randnum
			FROM @resultsDatabaseSchema.n3c_case_cohort npc
			JOIN @resultsDatabaseSchema.N3C_CONTROL_MAP cm
			ON npc.person_id = cm.case_person_id
			AND cm.control_person_id IS NULL
		) subq
	) cases
	INNER JOIN
	(
			-- Get cases
		SELECT subq.*
			,ROW_NUMBER() OVER (PARTITION BY pt_age
				,sex
				  ORDER BY randnum
				 ) AS join_row_1
		FROM (
			SELECT npc.person_id
				,npc.pt_age
				,npc.sex
				,RANDOM() AS randnum
			FROM @resultsDatabaseSchema.n3c_control_cohort npc
			WHERE npc.person_id NOT IN ( SELECT DISTINCT control_person_id FROM @resultsDatabaseSchema.N3C_CONTROL_MAP WHERE control_person_id IS NOT NULL)

		) subq

	) controls
	ON cases.pt_age = controls.pt_age
		AND cases.sex = controls.sex
		AND cases.join_row_1 = controls.join_row_1

) y
WHERE control_person_id IS NULL
AND case_person_id = y.case_pid
AND buddy_num = y.bud_num
;



-- Match #4 - sex
UPDATE @resultsDatabaseSchema.N3C_CONTROL_MAP
SET control_person_id = y.control_pid
FROM
(
	SELECT cases.person_id as case_pid, cases.buddy_num bud_num, controls.person_id control_pid
	FROM
	(
		-- Get cases
		SELECT subq.*
			,ROW_NUMBER() OVER (PARTITION BY
				sex
				  ORDER BY randnum
				 ) AS join_row_1
		FROM (
			SELECT npc.person_id
				,npc.sex
				,cm.buddy_num
				,RANDOM() AS randnum
			FROM @resultsDatabaseSchema.n3c_case_cohort npc
			JOIN @resultsDatabaseSchema.N3C_CONTROL_MAP cm
			ON npc.person_id = cm.case_person_id
			AND cm.control_person_id IS NULL
		) subq
	) cases
	INNER JOIN
	(
			-- Get cases
		SELECT subq.*
			,ROW_NUMBER() OVER (PARTITION BY
				sex
				  ORDER BY randnum
				 ) AS join_row_1
		FROM (
			SELECT npc.person_id
				,npc.sex
				,RANDOM() AS randnum
			FROM @resultsDatabaseSchema.n3c_control_cohort npc
			WHERE npc.person_id NOT IN ( SELECT DISTINCT control_person_id FROM @resultsDatabaseSchema.N3C_CONTROL_MAP WHERE control_person_id IS NOT NULL)

		) subq

	) controls
	ON cases.sex = controls.sex
		AND cases.join_row_1 = controls.join_row_1

) y
WHERE control_person_id IS NULL
AND case_person_id = y.case_pid
AND buddy_num = y.bud_num
;


INSERT INTO @resultsDatabaseSchema.N3C_COHORT
SELECT DISTINCT case_person_id AS person_id
FROM @resultsDatabaseSchema.N3C_CONTROL_MAP

UNION

SELECT DISTINCT control_person_id
FROM @resultsDatabaseSchema.N3C_CONTROL_MAP
WHERE control_person_id IS NOT NULL;
