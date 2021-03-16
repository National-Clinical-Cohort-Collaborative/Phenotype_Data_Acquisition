/**
N3C Phenotype 3.2 - OMOP GBQ
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


CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.n3c_pre_cohort  (person_id INT64 not null
		,inc_dx_strong INT64 not null
		,inc_dx_weak INT64 not null
		,inc_lab_any INT64 not null
		,inc_lab_pos INT64 not null
		,phenotype_version STRING
		,pt_age STRING
		,sex INT64
		,hispanic INT64
		,race INT64
		,vocabulary_version STRING
		);




CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.n3c_case_cohort  (person_id INT64 not null
		,pt_age STRING
		,sex INT64
		,hispanic INT64
		,race INT64
		);



CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.n3c_control_cohort  (person_id INT64 not null
		,pt_age STRING
		,sex INT64
		,hispanic INT64
		,race INT64
		);

CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.n3c_control_map  (case_person_id INT64 not null
		,buddy_num INT64 not null
		,control_person_id INT64
		);

CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.n3c_cohort  (person_id INT64 not null);

DROP TABLE IF EXISTS @resultsDatabaseSchema.final_map;

-- before beginning, remove any patients from the last run
-- IMPORTANT: do NOT truncate or drop the control-map table.
DELETE FROM @resultsDatabaseSchema.n3c_pre_cohort WHERE True;
DELETE FROM @resultsDatabaseSchema.n3c_case_cohort WHERE True;
DELETE FROM @resultsDatabaseSchema.n3c_control_cohort WHERE True;
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
			where concept_id IN (
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
			or value_source_value in (
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
					)
			)
		-- This logic imposes the restriction: these codes were only valid as Strong Positive codes between January 1, 2020 and March 31, 2020
		and condition_start_date between DATE(2020, 01, 01)
			and DATE(2020, 03, 31)

	union distinct select distinct person_id
	from @cdmDatabaseSchema.observation
	where observation_concept_id in (
			select concept_id
			from @cdmDatabaseSchema.concept
			-- The list of ICD-10 codes in the Phenotype Wiki
			-- This is the list of standard concepts that represent those terms
			where concept_id in (37311060)
			)
		-- This logic imposes the restriction: these codes were only valid as Strong Positive codes between January 1, 2020 and March 31, 2020
		and observation_date between DATE(2020, 01, 01)
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
					,37310254
					)
				and c.invalid_reason is null
			)

		and condition_start_date >= DATE(2020, 04, 01)
	
	union distinct select distinct person_id
	from @cdmDatabaseSchema.observation
	where observation_concept_id in (
			select concept_id
			from @cdmDatabaseSchema.concept
			-- The list of ICD-10 codes in the Phenotype Wiki were translated into OMOP standard concepts
			-- This is the list of standard concepts that represent those terms
			where concept_id in (37311060)

			union distinct select c.concept_id
			from @cdmDatabaseSchema.concept c
			join @cdmDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
				-- Here we pull the descendants (aka terms that are more specific than the concepts selected above)
				and ca.ancestor_concept_id in (37311060)
				and c.invalid_reason is null
			)

		and observation_date >= DATE(2020, 04, 01)
	)
	,
	-- UNION
	-- 3) TWO or more of the Weak Positive diagnosis codes from the ICD-10 or SNOMED tables (below) during the same encounter or on the same date
	-- Here we start looking in the CONDITION_OCCCURRENCE table for visits on the same date
	-- BEFORE 04-01-2020 WEAK POSITIVE LOGIC:
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
		 having count(distinct condition_concept_id) >= 2
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
		 having count(distinct condition_concept_id) >= 2
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
				and DATE(2020, 05, 01)
		-- Now we group by person_id and visit_occurrence_id to find people who have 2 or more
		  group by  1, visit_occurrence_id
		 having count(distinct condition_concept_id) >= 2
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
				and DATE(2020, 05, 01)
		-- Now we group by person_id and visit_occurrence_id to find people who have 2 or more
		  group by  1, condition_start_date
		 having count(distinct condition_concept_id) >= 2
		 ) dx_same_date
	)
	,
	-- UNION
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
					,36659631
					,36661377
					,36661378
					,36661372
					,36661373
					,36661374
					,36661370
					,36661371
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
 SELECT distinct c.person_id
	,inc_dx_strong
	,inc_dx_weak
	,inc_lab_any
	,inc_lab_pos
	,'3.2' as phenotype_version
	,case
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 0
				and 4
			then '0-4'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 5
				and 9
			then '5-9'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 10
				and 14
			then '10-14'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 15
				and 19
			then '15-19'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 20
				and 24
			then '20-24'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 25
				and 29
			then '25-29'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 30
				and 34
			then '30-34'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 35
				and 39
			then '35-39'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 40
				and 44
			then '40-44'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 45
				and 49
			then '45-49'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 50
				and 54
			then '50-54'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 55
				and 59
			then '55-59'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 60
				and 64
			then '60-64'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 65
				and 69
			then '65-69'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 70
				and 74
			then '70-74'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 75
				and 79
			then '75-79'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 80
				and 84
			then '80-84'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) between 85
				and 89
			then '85-89'
		when date_diff(cast(d.birth_datetime as DATE), CURRENT_DATE(), year) >= 90
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
insert into @resultsDatabaseSchema.n3c_case_cohort (person_id
									,pt_age
									,sex
									,hispanic
									,race )
select 	person_id
		,pt_age
		,sex
		,hispanic
		,race
from @resultsDatabaseSchema.n3c_pre_cohort
where inc_dx_strong = 1
	or inc_lab_pos = 1
	or inc_dx_weak = 1;

insert into @resultsDatabaseSchema.n3c_control_cohort  (person_id
									,pt_age
									,sex
									,hispanic
									,race )
select npc.person_id
		,pt_age
		,sex
		,hispanic
		,race
from @resultsDatabaseSchema.n3c_pre_cohort npc
join (
		  select person_id
		  from @cdmDatabaseSchema.visit_occurrence
		where visit_start_date > DATE(2018, 01, 01)
		  group by  1 having DATE_DIFF(cast(max(visit_start_date) as date), cast(min(visit_start_date) as date), DAY) >= 10
 ) e
on npc.person_id = e.person_id
where inc_dx_strong = 0
	and inc_lab_pos = 0
	and inc_dx_weak = 0
	and inc_lab_any = 1;


-- Now that the pre-cohort and case tables are populated, we start matching cases and controls, and updating the case and control tables as needed.
-- all cases need two control buddies. We select on progressively looser demographic criteria until every case has two control matches, or we run out of patients in the control pool.
-- First handle instances where someone who was in the control group in the prior run is now a case
-- just delete both the case and the control from the mapping table. The case will repopulate automatically with a replaced control.
delete
from @resultsDatabaseSchema.n3c_control_map
where control_person_id in (
		select person_id
		from @resultsDatabaseSchema.n3c_case_cohort
		);

-- Remove cases and controls from the mapping table if those people are no longer in the person table (due to merges or other reasons)
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

-- Remove cases who no longer meet the phenotype definition
delete
from @resultsDatabaseSchema.n3c_control_map
where case_person_id not in (
		select person_id
		from @resultsDatabaseSchema.n3c_case_cohort
		where person_id is not null
		);


insert into @resultsDatabaseSchema.n3c_control_map
select
		person_id, 1 as buddy_num, null
		from @resultsDatabaseSchema.n3c_case_cohort
		where person_id not in (
			select case_person_id
			from @resultsDatabaseSchema.n3c_control_map
			where buddy_num = 1
			)

		union distinct select person_id, 2 as buddy_num, null
		from @resultsDatabaseSchema.n3c_case_cohort
		where person_id not in (
			select case_person_id
			from @resultsDatabaseSchema.n3c_control_map
			where buddy_num = 2
			)
;

-- Match #1 - age, sex, race, ethnicity
update @resultsDatabaseSchema.n3c_control_map
set control_person_id = y.control_pid
from
(
	select cases.person_id as case_pid, cases.buddy_num bud_num, controls.person_id control_pid
	from
	(
		-- Get cases
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
				,cm.buddy_num
				,rand() as randnum
			from @resultsDatabaseSchema.n3c_case_cohort npc
			join @resultsDatabaseSchema.n3c_control_map cm
			on npc.person_id = cm.case_person_id
			and cm.control_person_id is null
		) subq
	) cases
	inner join
	(
			-- Get cases
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
			from @resultsDatabaseSchema.n3c_control_cohort npc
			where npc.person_id not in ( select distinct control_person_id from @resultsDatabaseSchema.n3c_control_map where control_person_id is not null)

		) subq

	) controls
	on cases.pt_age = controls.pt_age
		and cases.sex = controls.sex
		and cases.race = controls.race
		and cases.hispanic = controls.hispanic
		and cases.join_row_1 = controls.join_row_1

) y
where control_person_id is null
and case_person_id = y.case_pid
and buddy_num = y.bud_num
;





-- Match #2 - age, sex, race
update @resultsDatabaseSchema.n3c_control_map
set control_person_id = y.control_pid
from
(
	select cases.person_id as case_pid, cases.buddy_num bud_num, controls.person_id control_pid
	from
	(
		-- Get cases
		select subq.*
			,row_number() over (
				partition by pt_age
				,sex
				,race
				 order by randnum
				) as join_row_1
		from (
			select npc.person_id
				,npc.pt_age
				,npc.sex
				,npc.race
				,cm.buddy_num
				,rand() as randnum
			from @resultsDatabaseSchema.n3c_case_cohort npc
			join @resultsDatabaseSchema.n3c_control_map cm
			on npc.person_id = cm.case_person_id
			and cm.control_person_id is null
		) subq
	) cases
	inner join
	(
			-- Get cases
		select subq.*
			,row_number() over (
				partition by pt_age
				,sex
				,race
				 order by randnum
				) as join_row_1
		from (
			select npc.person_id
				,npc.pt_age
				,npc.sex
				,npc.race
				,rand() as randnum
			from @resultsDatabaseSchema.n3c_control_cohort npc
			where npc.person_id not in ( select distinct control_person_id from @resultsDatabaseSchema.n3c_control_map where control_person_id is not null)

		) subq

	) controls
	on cases.pt_age = controls.pt_age
		and cases.sex = controls.sex
		and cases.race = controls.race
		and cases.join_row_1 = controls.join_row_1

) y
where control_person_id is null
and case_person_id = y.case_pid
and buddy_num = y.bud_num
;




-- Match #3 -- age, sex
update @resultsDatabaseSchema.n3c_control_map
set control_person_id = y.control_pid
from
(
	select cases.person_id as case_pid, cases.buddy_num bud_num, controls.person_id control_pid
	from
	(
		-- Get cases
		select subq.*
			,row_number() over (
				partition by pt_age
				,sex
				 order by randnum
				) as join_row_1
		from (
			select npc.person_id
				,npc.pt_age
				,npc.sex
				,cm.buddy_num
				,rand() as randnum
			from @resultsDatabaseSchema.n3c_case_cohort npc
			join @resultsDatabaseSchema.n3c_control_map cm
			on npc.person_id = cm.case_person_id
			and cm.control_person_id is null
		) subq
	) cases
	inner join
	(
			-- Get cases
		select subq.*
			,row_number() over (
				partition by pt_age
				,sex
				 order by randnum
				) as join_row_1
		from (
			select npc.person_id
				,npc.pt_age
				,npc.sex
				,rand() as randnum
			from @resultsDatabaseSchema.n3c_control_cohort npc
			where npc.person_id not in ( select distinct control_person_id from @resultsDatabaseSchema.n3c_control_map where control_person_id is not null)

		) subq

	) controls
	on cases.pt_age = controls.pt_age
		and cases.sex = controls.sex
		and cases.join_row_1 = controls.join_row_1

) y
where control_person_id is null
and case_person_id = y.case_pid
and buddy_num = y.bud_num
;



-- Match #4 - sex
update @resultsDatabaseSchema.n3c_control_map
set control_person_id = y.control_pid
from
(
	select cases.person_id as case_pid, cases.buddy_num bud_num, controls.person_id control_pid
	from
	(
		-- Get cases
		select subq.*
			,row_number() over (
				partition by
				sex
				 order by randnum
				) as join_row_1
		from (
			select npc.person_id
				,npc.sex
				,cm.buddy_num
				,rand() as randnum
			from @resultsDatabaseSchema.n3c_case_cohort npc
			join @resultsDatabaseSchema.n3c_control_map cm
			on npc.person_id = cm.case_person_id
			and cm.control_person_id is null
		) subq
	) cases
	inner join
	(
			-- Get cases
		select subq.*
			,row_number() over (
				partition by
				sex
				 order by randnum
				) as join_row_1
		from (
			select npc.person_id
				,npc.sex
				,rand() as randnum
			from @resultsDatabaseSchema.n3c_control_cohort npc
			where npc.person_id not in ( select distinct control_person_id from @resultsDatabaseSchema.n3c_control_map where control_person_id is not null)

		) subq

	) controls
	on cases.sex = controls.sex
		and cases.join_row_1 = controls.join_row_1

) y
where control_person_id is null
and case_person_id = y.case_pid
and buddy_num = y.bud_num
;


insert into @resultsDatabaseSchema.n3c_cohort
select distinct case_person_id as person_id
from @resultsDatabaseSchema.n3c_control_map

union distinct select distinct control_person_id
from @resultsDatabaseSchema.n3c_control_map
where control_person_id is not null;
