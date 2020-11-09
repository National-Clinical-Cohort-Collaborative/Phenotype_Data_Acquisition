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
You will need to find and replace @cdmDatabaseSchema and @resultsDatabaseSchema, @cdmDatabaseSchema with your local OMOP schema details. This is the only modification you should make to this script.

USER NOTES:
In OHDSI conventions, we do not usually write tables to the main database schema.
OHDSI uses @resultsDatabaseSchema as a results schema build cohort tables for specific analysis.
We built the N3C_COHORT table in this results schema as we know many OMOP analyst do not have write access to their @cdmDatabaseSchema.
To follow the logic used in this code, visit: https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/wiki/Latest-Phenotype

SCRIPT RELEASE DATE: 11-05-2020

**/

/** Creating the N3C Cohort table **/

--DROP TABLE IF EXISTS @resultsDatabaseSchema.n3c_cohort; -- RUN THIS LINE AFTER FIRST BUILD
DROP TABLE IF EXISTS @resultsDatabaseSchema.n3c_cohort;

-- Create dest table
create table @resultsDatabaseSchema.n3c_cohort (
	person_id			INT64  not null
);

--DROP TABLE IF EXISTS @resultsDatabaseSchema.phenotype_execution; -- RUN THIS LINE AFTER FIRST BUILD
DROP TABLE IF EXISTS @resultsDatabaseSchema.phenotype_execution;

-- Create dest table
-- Here we need to know when you ran the phenotype, what version you're using and what vocabulary version you've built your OMOP concepts on
create table @resultsDatabaseSchema.phenotype_execution (
	run_datetime datetime not null,
	phenotype_version STRING not null,
	vocabulary_version STRING
);


insert into @resultsDatabaseSchema.n3c_cohort
-- Phenotype Entry Criteria: A lab confirmed positive test
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
			45878583
			,37079494
			,1177295
			,36307756
			,36309158
			,36308436
			,9189
			)
	-- To be exhaustive, we also look for Positive strings in the value_source_value field
		or value_source_value in (
			'Positive'
			,'Present'
			,'Detected'
			)
		)

union distinct select distinct person_id
from @cdmDatabaseSchema.condition_occurrence
where condition_concept_id in (
		select concept_id
		from @cdmDatabaseSchema.concept
		-- The list of ICD-10 codes in the Phenotype Wiki
		-- This is the list of standard concepts that represent those terms
		where concept_id in (
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

		union distinct select c.concept_id
		from @cdmDatabaseSchema.concept c
		join @cdmDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
		-- Here we pull the descendants (aka terms that are more specific than the concepts selected above)
			and ca.ancestor_concept_id in (
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
			and c.invalid_reason is null
		)

	and condition_start_date >= DATE(2020, 04, 01)

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
		and condition_start_date >= DATE(2020, 04, 01)
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
		and condition_start_date >= DATE(2020, 04, 01)
-- Now we group by person_id and visit_occurrence_id to find people who have 2 or more
		  group by  1, condition_start_date
	 having count(*) >= 2
	 ) dx_same_date

union distinct select distinct person_id
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
	-- existence of Z11.59
	-- Z11.59 here is being pulled from the source_concept_id
	-- we want to make extra sure that we're ONLY looking at Z11.59 not the more general SNOMED code that would be in the standard concept id column for this
	and person_id not in (
		select person_id
		from @cdmDatabaseSchema.observation
		where observation_source_concept_id = 45595484
			and observation_date >= DATE(2020, 04, 01)
		)
		;



insert into @resultsDatabaseSchema.phenotype_execution
select
    CURRENT_DATE() as run_datetime
    ,'2.2' as phenotype_version
    , (SELECT  vocabulary_version from @cdmDatabaseSchema.vocabulary where vocabulary_id='None' LIMIT 1) as vocabulary_version;
