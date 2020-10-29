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
DROP TABLE IF EXISTS @resultsDatabaseSchema.n3c_cohort;

-- Create dest table
create table @resultsDatabaseSchema.n3c_cohort (
	person_id			INT64  not null
);

--DROP TABLE IF EXISTS @resultsDatabaseSchema.phenotype_execution; -- RUN THIS LINE AFTER FIRST BUILD
DROP TABLE IF EXISTS @resultsDatabaseSchema.phenotype_execution;

-- Create dest table
create table @resultsDatabaseSchema.phenotype_execution (
	run_datetime datetime not null,
	phenotype_version STRING not null,
	vocabulary_version STRING
);


insert into @resultsDatabaseSchema.n3c_cohort
select distinct person_id
from
(

/**

INCLUSION:

1) Postive COVID Measurement
2) Strong positive dx
3) 2x Weak Dx
4) COVID Measurement & No occurrences of Z11.59 


**/

-- 1) Positive COVID Measurement
select distinct person_id
from @cdmDatabaseSchema.measurement
where measurement_concept_id in (
		select concept_id
		from @cdmDatabaseSchema.concept
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
			and ca.ancestor_concept_id in (756055)
			and c.invalid_reason is null
		)
	and measurement_date >= DATE(2020, 01, 01)
	and (
		value_as_concept_id in (
			4126681,
			45877985,
			45884084,
			9191
			)
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
		from @vocabulary_database_schema.concept
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
	and condition_start_date between DATE(2020, 01, 01)
		and DATE(2020, 03, 31)

union distinct select distinct person_id
from @cdmDatabaseSchema.condition_occurrence
where condition_concept_id in (
		select concept_id
		from @vocabulary_database_schema.concept
		where concept_id in (
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
		
		union distinct select c.concept_id
		from @vocabulary_database_schema.concept c
		join @vocabulary_database_schema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
			and ca.ancestor_concept_id in (
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
			and c.invalid_reason is null
		)
	and condition_start_date >= DATE(2020, 04, 01)

union distinct select distinct person_id
from (
	  select person_id
		,visit_occurrence_id
		,count(*)
	  from @cdmDatabaseSchema.condition_occurrence
	where condition_concept_id in (
			select concept_id
			from @vocabulary_database_schema.concept
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
					)
			)
		and condition_start_date between DATE(2020, 01, 01)
			and DATE(2020, 03, 31)
	  group by  1, 2 having count(*) >= 2
	 ) dx_same_encounter

union distinct select distinct person_id
from (
	  select person_id
		,condition_start_date
		,count(*)
	  from @cdmDatabaseSchema.condition_occurrence
	where condition_concept_id in (
			select concept_id
			from @vocabulary_database_schema.concept
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
					)
			)
		and condition_start_date between DATE(2020, 01, 01)
			and DATE(2020, 03, 31)
	  group by  1, 2 having count(*) >= 2
	 ) dx_same_date

union distinct select distinct person_id
from (
	  select person_id
		,visit_occurrence_id
		,count(*)
	  from @cdmDatabaseSchema.condition_occurrence
	where condition_concept_id in (
			select concept_id
			from @vocabulary_database_schema.concept
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
		and condition_start_date >= DATE(2020, 04, 01)
	  group by  1, 2 having count(*) >= 2
	 ) dx_same_encounter

union distinct select distinct person_id
from (
	  select person_id
		,condition_start_date
		,count(*)
	  from @cdmDatabaseSchema.condition_occurrence
	where condition_concept_id in (
			select concept_id
			from @vocabulary_database_schema.concept
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
		and condition_start_date >= DATE(2020, 04, 01)
	  group by  1, 2 having count(*) >= 2
	 ) dx_same_date

union distinct select distinct person_id
from @cdmDatabaseSchema.measurement
where measurement_concept_id in (
		select concept_id
		from @cdmDatabaseSchema.concept
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
			and ca.ancestor_concept_id in (756055)
			and c.invalid_reason is null
		)
	and measurement_date >= DATE(2020, 01, 01)
	-- existence of Z11.59
	and person_id not in (
		select person_id
		from @cdmDatabaseSchema.observation
		where observation_source_concept_id = 45595484
			and observation_date >= DATE(2020, 04, 01)
		)
		
		
) 
;



insert into @resultsDatabaseSchema.phenotype_execution
select
    CURRENT_DATE() as run_datetime
    ,'2.2' as phenotype_version
    , (SELECT  vocabulary_version from @cdmDatabaseSchema.vocabulary where vocabulary_id='None' LIMIT 1) as vocabulary_version;

