/**
N3C Phenotype 3.0 - OMOP MSSQL
**/


CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.n3c_pre_cohort  (person_id INT64 not null
		,inc_dx_strong INT64 not null
		,inc_dx_weak INT64 not null
		,inc_lab_any INT64 not null
		,inc_lab_pos INT64 not null
		,phenotype_version STRING
		,pt_age STRING
		,sex STRING
		,hispanic STRING
		,race STRING
		,vocabulary_version STRING
		);


CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.n3c_case_cohort  (person_id INT64 not null
		,inc_dx_strong INT64 not null
		,inc_dx_weak INT64 not null
		,inc_lab_any INT64 not null
		,inc_lab_pos INT64 not null
		);

CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.n3c_control_map  (case_person_id INT64 not null
		,buddy_num INT64 not null
		,control_person_id INT64
		);

CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.n3c_cohort  (person_id INT64 not null);

-- before beginning, remove any patients from the last run
-- IMPORTANT: do NOT truncate or drop the control-map table.
DELETE FROM @resultsDatabaseSchema.n3c_pre_cohort WHERE True;
DELETE FROM @resultsDatabaseSchema.n3c_case_cohort WHERE True;
DELETE FROM @resultsDatabaseSchema.n3c_cohort WHERE True;

-- Phenotype Entry Criteria: A lab confirmed positive test
INSERT INTO @resultsDatabaseSchema.n3c_pre_cohort
-- populate the pre-cohort table
 WITH covid_lab_pos
as (
	select distinct person_id
	from @cdmDatabaseSchema.measurement
	where measurement_concept_id in (
			select concept_id
			from @cdmDatabaseSchema.concept
			-- here we look for the concepts that are the LOINC codes we're looking for in the phenotype
			where concept_id in (
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

			union distinct select c.concept_id
			from @cdmDatabaseSchema.concept c
			join @cdmDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
				-- Most of the LOINC codes do not have descendants but there is one OMOP Extension code (765055) in use that has descendants which we want to pull
				-- This statement pulls the descendants of that specific code
				and ca.ancestor_concept_id in (756055)
				and c.invalid_reason is null
			)
		-- Here we add a date restriction: after January 1, 2020
		and measurement_date >= DATE(2020, 01, 01)
		and (
			-- The value_as_concept field is where we store standardized qualitative results
			-- The concept ids here represent LOINC or SNOMED codes for standard ways to code a lab that is positive
			value_as_concept_id in (
				4126681
				,45877985
				,45884084
				,9191
				,4181412
				,45879438
				)
			-- To be exhaustive, we also look for Positive strings in the value_source_value field
			or value_source_value in (
				'Positive'
				,'Present'
				,'Detected'
				)
			)
	)
	,
	-- UNION
	-- Phenotype Entry Criteria: ONE or more of the â€œStrong Positiveâ€? diagnosis codes from the ICD-10 or SNOMED tables
	-- This section constructs entry logic prior to the CDC guidance issued on April 1, 2020
dx_strong
as (
	select distinct person_id
	from @cdmDatabaseSchema.condition_occurrence
	where condition_concept_id in (
			select concept_id
			from @cdmDatabaseSchema.concept
			-- The list of ICD-10 codes in the Phenotype Wiki
			-- This is the list of standard concepts that represent those terms
			where concept_id in (
					756023
					,756044
					,756061
					,756031
					,37311061
					,756081
					,37310285
					,756039
					,320651
					,37311060
					)
			)
		-- This logic imposes the restriction: these codes were only valid as Strong Positive codes between January 1, 2020 and March 31, 2020
		and condition_start_date between DATE(2020, 01, 01)
			and DATE(2020, 03, 31)

	union distinct select distinct person_id
	from @cdmDatabaseSchema.condition_occurrence
	where condition_concept_id in (
			select concept_id
			from @cdmDatabaseSchema.concept
			-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
			-- This is the list of standard concepts that represent those terms
			where concept_id in (
					37311061
					,37311060
					,756023
					,756031
					,756039
					,756044
					,756061
					,756081
					,37310285
					)

			union distinct select c.concept_id
			from @cdmDatabaseSchema.concept c
			join @cdmDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
				-- Here we pull the descendants (aka terms that are more specific than the concepts selected above)
				and ca.ancestor_concept_id in (
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
					,37311060
					,37310254
					)
				and c.invalid_reason is null
			)
		and condition_start_date >= DATE(2020, 04, 01)
	)
	,
	-- UNION
	-- 3) TWO or more of the â€œWeak Positiveâ€? diagnosis codes from the ICD-10 or SNOMED tables (below) during the same encounter or on the same date
	-- Here we start looking in the CONDITION_OCCCURRENCE table for visits on the same date
	-- BEFORE 04-01-2020 "WEAK POSITIVE" LOGIC:
dx_weak
as (
	select distinct person_id
	from (
		  select person_id
		  from @cdmDatabaseSchema.condition_occurrence
		where condition_concept_id in (
				select concept_id
				from @cdmDatabaseSchema.concept
				-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
				-- It also includes the OMOP only codes that are on the Phenotype Wiki
				-- This is the list of standard concepts that represent those terms
				where concept_id in (
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
			and condition_start_date between DATE(2020, 01, 01)
				and DATE(2020, 03, 31)
		-- Now we group by person_id and visit_occurrence_id to find people who have 2 or more
		  group by  1, visit_occurrence_id
		 having count(*) >= 2
		 ) dx_same_encounter

	union distinct select distinct person_id
	from (
		  select person_id
		  from @cdmDatabaseSchema.condition_occurrence
		where condition_concept_id in (
				select concept_id
				from @cdmDatabaseSchema.concept
				-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
				-- It also includes the OMOP only codes that are on the Phenotype Wiki
				-- This is the list of standard concepts that represent those terms
				where concept_id in (
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
			and condition_start_date between DATE(2020, 01, 01)
				and DATE(2020, 03, 31)
		  group by  1, condition_start_date
		 having count(*) >= 2
		 ) dx_same_date

	union distinct select distinct person_id
	from (
		  select person_id
		  from @cdmDatabaseSchema.condition_occurrence
		where condition_concept_id in (
				select concept_id
				from @cdmDatabaseSchema.concept
				-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
				-- It also includes the OMOP only codes that are on the Phenotype Wiki
				-- This is the list of standard concepts that represent those terms
				where concept_id in (
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
			and condition_start_date between DATE(2020, 04, 01)
				and DATE(2020, 05, 30)
		-- Now we group by person_id and visit_occurrence_id to find people who have 2 or more
		  group by  1, visit_occurrence_id
		 having count(*) >= 2
		 ) dx_same_encounter

	union distinct select distinct person_id
	from (
		  select person_id
		  from @cdmDatabaseSchema.condition_occurrence
		where condition_concept_id in (
				select concept_id
				from @cdmDatabaseSchema.concept
				-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
				-- It also includes the OMOP only codes that are on the Phenotype Wiki
				-- This is the list of standard concepts that represent those term
				where concept_id in (
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
			and condition_start_date between DATE(2020, 04, 01)
				and DATE(2020, 05, 30)
		-- Now we group by person_id and visit_occurrence_id to find people who have 2 or more
		  group by  1, condition_start_date
		 having count(*) >= 2
		 ) dx_same_date
	)
	,
	-- UNION
	-- ERP: Changed this comment to reflect new logic
	-- 4) ONE or more of the lab tests in the Labs table, regardless of result
	-- We begin by looking for ANY COVID measurement
covid_lab
as (
	select distinct person_id
	from @cdmDatabaseSchema.measurement
	where measurement_concept_id in (
			select concept_id
			from @cdmDatabaseSchema.concept
			-- here we look for the concepts that are the LOINC codes we're looking for in the phenotype
			where concept_id in (
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

			union distinct select c.concept_id
			from @cdmDatabaseSchema.concept c
			join @cdmDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
				-- Most of the LOINC codes do not have descendants but there is one OMOP Extension code (765055) in use that has descendants which we want to pull
				-- This statement pulls the descendants of that specific code
				and ca.ancestor_concept_id in (756055)
				and c.invalid_reason is null
			)
		and measurement_date >= DATE(2020, 01, 01)
	)
	,
	/* ERP: Getting rid of this criterion
	-- existence of Z11.59
	-- Z11.59 here is being pulled from the source_concept_id
	-- we want to make extra sure that we're ONLY looking at Z11.59 not the more general SNOMED code that would be in the standard concept id column for this
	AND person_id NOT IN (
		SELECT person_id
		FROM @cdmDatabaseSchema.OBSERVATION
		WHERE observation_source_concept_id = 45595484
			AND observation_date >= DATEFROMPARTS(2020, 04, 01)
		)
		;

*/
covid_cohort
as (
	select distinct person_id
	from dx_strong

	union distinct select distinct person_id
	from dx_weak

	union distinct select distinct person_id
	from covid_lab
	)
	,cohort
as (
	select covid_cohort.person_id
		,case
			when dx_strong.person_id is not null
				then 1
			else 0
			end as inc_dx_strong
		,case
			when dx_weak.person_id is not null
				then 1
			else 0
			end as inc_dx_weak
		,case
			when covid_lab.person_id is not null
				then 1
			else 0
			end as inc_lab_any
		,case
			when covid_lab_pos.person_id is not null
				then 1
			else 0
			end as inc_lab_pos
	from covid_cohort
	left outer join dx_strong on covid_cohort.person_id = dx_strong.person_id
	left outer join dx_weak on covid_cohort.person_id = dx_weak.person_id
	left outer join covid_lab on covid_cohort.person_id = covid_lab.person_id
	left outer join covid_lab_pos on covid_cohort.person_id = covid_lab_pos.person_id
	)
-- ERP: changed name of table
 SELECT distinct c.person_id
	,inc_dx_strong
	,inc_dx_weak
	,inc_lab_any
	,inc_lab_pos
	,'3.0' as phenotype_version
	,case
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 0
				and 4
			then '0-4'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 5
				and 9
			then '5-9'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 10
				and 14
			then '10-14'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 15
				and 19
			then '15-19'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 20
				and 24
			then '20-24'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 25
				and 29
			then '25-29'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 30
				and 34
			then '30-34'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 35
				and 39
			then '35-39'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 40
				and 44
			then '40-44'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 45
				and 49
			then '45-49'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 50
				and 54
			then '50-54'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 55
				and 59
			then '55-59'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 60
				and 64
			then '60-64'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 65
				and 69
			then '65-69'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 70
				and 74
			then '70-74'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 75
				and 79
			then '75-79'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 80
				and 84
			then '80-84'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) between 85
				and 89
			then '85-89'
		when datediff(year, d.birth_datetime, CURRENT_DATE()) >= 90
			then '90+'
		end as pt_age
	,d.gender_concept_id as sex
	,d.ethnicity_concept_id as hispanic
	,d.race_concept_id as race
	,(SELECT  vocabulary_version
		from @cdmDatabaseSchema.vocabulary
		where vocabulary_id = 'None'
		 LIMIT 1) as vocabulary_version
from cohort c
join @cdmDatabaseSchema.person d on c.person_id = d.person_id;

--populate the case table
insert into @resultsDatabaseSchema.n3c_case_cohort
select person_id
	,inc_dx_strong
	,inc_dx_weak
	,inc_lab_any
	,inc_lab_pos
from @resultsDatabaseSchema.n3c_pre_cohort
where inc_dx_strong = 1
	or inc_lab_pos = 1
	or inc_dx_weak = 1;

-- Now that the pre-cohort and case tables are populated, we start matching cases and controls, and updating the case and control tables as needed.
-- all cases need two control "buddies". we select on progressively looser demographic criteria until every case has two control matches, or we run out of patients in the control pool.
-- first handle instances where someone who was in the control group in the prior run is now a case
-- just delete both the case and the control from the mapping table. the case will repopulate automatically with a replaced control.
delete
from @resultsDatabaseSchema.n3c_control_map
where control_person_id in (
		select person_id
		from @resultsDatabaseSchema.n3c_case_cohort
		);

-- remove cases and controls from the mapping table if those people are no longer in the person table (due to merges or other reasons)
delete
from @resultsDatabaseSchema.n3c_control_map
where case_person_id not in (
		select person_id
		from @cdmDatabaseSchema.person
		);

delete
from @resultsDatabaseSchema.n3c_control_map
where control_person_id not in (
		select person_id
		from @cdmDatabaseSchema.person
		);

-- remove cases who no longer meet the phenotype definition
delete
from @resultsDatabaseSchema.n3c_control_map
where case_person_id not in (
		select person_id
		from @resultsDatabaseSchema.n3c_case_cohort
		);

-- start progressively matching cases to controls. we will do a diff between the results here and what is already in the control_map table later.
INSERT INTO @resultsDatabaseSchema.n3c_control_map (
	case_person_id
	,buddy_num
	,control_person_id
	)
 WITH cases_1
as (
	select subq.*
		,row_number() over (
			partition by pt_age
			,sex
			,race
			,hispanic order by randnum
			) as join_row_1 -- most restrictive
	from (
		select person_id
			,pt_age
			,sex
			,race
			,hispanic
			,1 as buddy_num
			,rand() as randnum -- random number
		from @resultsDatabaseSchema.n3c_pre_cohort
		where (
				inc_dx_strong = 1
				or inc_lab_pos = 1
				or inc_dx_weak = 1
				)

		union distinct select person_id
			,pt_age
			,sex
			,race
			,hispanic
			,2 as buddy_num
			,rand() as randnum -- random number
		from @resultsDatabaseSchema.n3c_pre_cohort
		where (
				inc_dx_strong = 1
				or inc_lab_pos = 1
				or inc_dx_weak = 1
				)
		) subq
	)
	,
	-- all available controls, joined to encounter table to eliminate patients with almost no data
	-- right now we're looking for patients with at least 10 days between their min and max visit dates.
pre_controls
as (
	select npc.person_id
	from (
		select person_id
		from @resultsDatabaseSchema.n3c_pre_cohort
		where inc_lab_any = 1
			and inc_dx_strong = 0
			and inc_lab_pos = 0
			and inc_dx_weak = 0
			and person_id not in (
				select control_person_id
				from @resultsDatabaseSchema.n3c_control_map
				)
		) npc
	join (
		  select person_id
		  from @cdmDatabaseSchema.visit_occurrence
		where visit_start_date > DATE(2018, 01, 01)
		  group by  1 having DATE_DIFF(cast(max(visit_start_date) as date), cast(min(visit_start_date) as date), DAY) >= 10
		 ) e on npc.person_id = e.person_id
	)
	,controls_1
as (
	select subq.*
		,row_number() over (
			partition by pt_age
			,sex
			,race
			,hispanic order by randnum
			) as join_row_1
	from (
		select npc.person_id
			,npc.pt_age
			,npc.sex
			,npc.race
			,npc.hispanic
			,rand() as randnum
		from @resultsDatabaseSchema.n3c_pre_cohort npc
		join pre_controls pre on npc.person_id = pre.person_id
		) subq
	)
	,
	-- match cases to controls where all demographic criteria match
map_1
as (
	select cases.*
		,controls.person_id as control_person_id
	from cases_1 cases
	left outer join controls_1 controls on cases.pt_age = controls.pt_age
		and cases.sex = controls.sex
		and cases.race = controls.race
		and cases.hispanic = controls.hispanic
		and cases.join_row_1 = controls.join_row_1
	)
	,
	-- narrow down to those cases that are missing one or more control buddies
	-- drop the hispanic criterion first
cases_2
as (
	select map_1.*
		,row_number() over (
			partition by pt_age
			,sex
			,race order by randnum
			) as join_row_2
	from map_1
	where control_person_id is null -- missing a buddy
	)
	,controls_2
as (
	select controls_1.*
		,row_number() over (
			partition by pt_age
			,sex
			,race order by randnum
			) as join_row_2
	from controls_1
	where person_id not in (
			select control_person_id
			from map_1
			where control_person_id is not null
			) -- doesn't already have a buddy
	)
	,map_2
as (
	select cases.person_id
		,cases.pt_age
		,cases.sex
		,cases.race
		,cases.hispanic
		,cases.buddy_num
		,cases.randnum
		,cases.join_row_1
		,cases.join_row_2
		,controls.person_id as control_person_id
	from cases_2 cases
	left outer join controls_2 controls on cases.pt_age = controls.pt_age
		and cases.sex = controls.sex
		and cases.race = controls.race
		and cases.join_row_2 = controls.join_row_2
	)
	,
	-- narrow down to those cases that are still missing one or more control buddies
	-- drop the race criterion now
cases_3
as (
	select map_2.*
		,row_number() over (
			partition by pt_age
			,sex order by randnum
			) as join_row_3
	from map_2
	where control_person_id is null
	)
	,controls_3
as (
	select controls_2.*
		,row_number() over (
			partition by pt_age
			,sex order by randnum
			) as join_row_3
	from controls_2
	where person_id not in (
			select control_person_id
			from map_2
			where control_person_id is not null
			)
	)
	,map_3
as (
	select cases.person_id
		,cases.pt_age
		,cases.sex
		,cases.race
		,cases.hispanic
		,cases.buddy_num
		,cases.randnum
		,cases.join_row_1
		,cases.join_row_2
		,cases.join_row_3
		,controls.person_id as control_person_id
	from cases_3 cases
	left outer join controls_3 controls on cases.pt_age = controls.pt_age
		and cases.sex = controls.sex
		and cases.join_row_3 = controls.join_row_3
	)
	,
	-- narrow down to those cases that are still missing one or more control buddies
	-- drop the age criterion now
cases_4
as (
	select map_3.*
		,row_number() over (
			partition by sex order by randnum
			) as join_row_4
	from map_3
	where control_person_id is null
	)
	,controls_4
as (
	select controls_3.*
		,row_number() over (
			partition by sex order by randnum
			) as join_row_4
	from controls_3
	where person_id not in (
			select control_person_id
			from map_3
			where control_person_id is not null
			)
	)
	,map_4
as (
	select cases.person_id
		,cases.pt_age
		,cases.sex
		,cases.race
		,cases.hispanic
		,cases.buddy_num
		,cases.randnum
		,cases.join_row_1
		,cases.join_row_2
		,cases.join_row_3
		,cases.join_row_4
		,controls.person_id as control_person_id
	from cases_4 cases
	left outer join controls_4 controls on cases.sex = controls.sex
		and cases.join_row_4 = controls.join_row_4
	)
	,penultimate_map
as (
	select map_1.person_id
		,map_1.buddy_num
		,coalesce(map_1.control_person_id, map_2.control_person_id, map_3.control_person_id, map_4.control_person_id) as control_person_id
		,map_1.person_id as map_1_person_id
		,map_2.person_id as map_2_person_id
		,map_3.person_id as map_3_person_id
		,map_4.person_id as map_4_person_id
		,map_1.control_person_id as map_1_control_person_id
		,map_2.control_person_id as map_2_control_person_id
		,map_3.control_person_id as map_3_control_person_id
		,map_4.control_person_id as map_4_control_person_id
		,map_1.pt_age as map_1_pt_age
		,map_1.sex as map_1_sex
		,map_1.race as map_1_race
		,map_1.hispanic as map_1_hispanic
	from map_1
	left outer join map_2 on map_1.person_id = map_2.person_id
		and map_1.buddy_num = map_2.buddy_num
	left outer join map_3 on map_1.person_id = map_3.person_id
		and map_1.buddy_num = map_3.buddy_num
	left outer join map_4 on map_1.person_id = map_4.person_id
		and map_1.buddy_num = map_4.buddy_num
	)
	,final_map
as (
	select penultimate_map.person_id as case_person_id
		,penultimate_map.control_person_id
		,penultimate_map.buddy_num
		,penultimate_map.map_1_control_person_id
		,penultimate_map.map_2_control_person_id
		,penultimate_map.map_3_control_person_id
		,penultimate_map.map_4_control_person_id
		,demog1.pt_age as case_age
		,demog1.sex as case_sex
		,demog1.race as case_race
		,demog1.hispanic as case_hispanic
		,demog2.pt_age as control_age
		,demog2.sex as control_sex
		,demog2.race as control_race
		,demog2.hispanic as control_hispanic
	from penultimate_map
	join @resultsDatabaseSchema.n3c_pre_cohort demog1 on penultimate_map.person_id = demog1.person_id
	left join @resultsDatabaseSchema.n3c_pre_cohort demog2 on penultimate_map.control_person_id = demog2.person_id
	)
 SELECT case_person_id
	,buddy_num
	,control_person_id
from final_map
where not exists (
		select 1
		from @resultsDatabaseSchema.n3c_control_map
		where final_map.case_person_id = n3c_control_map.case_person_id
			and final_map.buddy_num = n3c_control_map.buddy_num
		);

insert into @resultsDatabaseSchema.n3c_cohort
select distinct case_person_id as person_id
from @resultsDatabaseSchema.n3c_control_map

union distinct select distinct control_person_id
from @resultsDatabaseSchema.n3c_control_map
where control_person_id is not null;
