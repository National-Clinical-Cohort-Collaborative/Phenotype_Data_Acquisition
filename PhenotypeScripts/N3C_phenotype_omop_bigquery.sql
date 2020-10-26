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


-- OHDSI ATLAS generated cohort logic
/** This block of code generates concept sets to be used in this phenotype**/
create table @tempDatabaseSchema.u6v5jn5hcodesets (
  codeset_id INT64 not null,
  concept_id INT64 not null
)
;

/**This code creates the [CD2H Lab Concepts] concept set - which pulls LOINC codes for inclusion.
In phenotype 2.2 - we readded 756055 per the request of a site using this OMOP extension code.**/
insert into @tempDatabaseSchema.u6v5jn5hcodesets (codeset_id, concept_id)
select 0 as codeset_id, c.concept_id from (select distinct i.concept_id from
( 
  select concept_id from @cdmDatabaseSchema.concept where concept_id in (586515,586522,706179,586521,723459,706181,706177,706176,706180,706178,706167,706157,706155,757678,706161,586520,706175,706156,706154,706168,715262,586526,757677,706163,715260,715261,706170,706158,706169,706160,706173,586519,586516,757680,757679,586517,757686,756055)
union distinct select c.concept_id
  from @cdmDatabaseSchema.concept c
  join @cdmDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (756055)
  and c.invalid_reason is null

) i
) c;
/**This code creates the [CD2H Weak Positive After to 04-01-2020] concept set- which pulls the updated list of SNOMED codes that ICD10 codes map to.
In the phenotype, we have 04-01-2020 as a cut point related to changes in CDC coding guidance.
We have removed the descendant concepts from this after concept set because the coding stringency has changed.**/
insert into @tempDatabaseSchema.u6v5jn5hcodesets (codeset_id, concept_id)
select 2 as codeset_id, c.concept_id from (select distinct i.concept_id from
( 
  select concept_id from @cdmDatabaseSchema.concept where concept_id in (260125,260139,46271075,4307774,4195694,257011,442555,4059022,4059021,256451,4059003,4168213,434490,439676,254761,4048098,37311061,4100065,320136,4038519,312437,4060052,4263848,37311059,37016200,4011766,437663,4141062,4164645,4047610,4260205,4185711,4289517,4140453,4090569,4109381,4330445,255848,4102774,436235,261326,320651)

) i
) c;
insert into @tempDatabaseSchema.u6v5jn5hcodesets (codeset_id, concept_id)
/**This code creates the [CD2H Strong Positive Prior to 04-01-2020] concept set-which pulls the prior list of SNOMED codes that ICD10 codes map to.
In the phenotype, we have 04-01-2020 as a cut point related to changes in CDC coding guidance.
We have left the descendant concepts in the earlier concept set because there was less specificity in coding at that point in time. **/
select 3 as codeset_id, c.concept_id from (select distinct i.concept_id from
( 
  select concept_id from @cdmDatabaseSchema.concept where concept_id in (756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,320651,4100065)
union distinct select c.concept_id
  from @cdmDatabaseSchema.concept c
  join @cdmDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,320651,4100065)
  and c.invalid_reason is null

) i
) c;
/**This code creates the [CD2H Strong Positive After 04-01-2020] concept set-which pulls the prior list of SNOMED codes that ICD10 codes map to.
In the phenotype, we have 04-01-2020 as a cut point related to changes in CDC coding guidance.
We have removed the descendant concepts from this after concept set because the coding stringency has changed.**/
insert into @tempDatabaseSchema.u6v5jn5hcodesets (codeset_id, concept_id)
/
select 4 as codeset_id, c.concept_id from (select distinct i.concept_id from
( 
  select concept_id from @cdmDatabaseSchema.concept where concept_id in (756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,756023,756044,756061,756031,37311061,756081,37310285,756039,37311060)
union distinct select c.concept_id
  from @cdmDatabaseSchema.concept c
  join @cdmDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,756023,756044,756061,756031,37311061,756081,37310285,756039,37311060)
  and c.invalid_reason is null

) i
) c;
/**This code creates the [CD2H Weak Positive Prior to 04-01-2020] concept set-which pulls the prior list of SNOMED codes that ICD10 codes map to.
In the phenotype, we have 04-01-2020 as a cut point related to changes in CDC coding guidance.
We have left the descendant concepts in the earlier concept set because there was less specificity in coding at that point in time. **/
insert into @tempDatabaseSchema.u6v5jn5hcodesets (codeset_id, concept_id)
select 5 as codeset_id, c.concept_id from (select distinct i.concept_id from
( 
  select concept_id from @cdmDatabaseSchema.concept where concept_id in (260125,260139,46271075,4307774,4195694,257011,442555,4059022,4059021,256451,4059003,4168213,434490,439676,254761,4048098,37311061,4100065,320136,4038519,312437,4060052,4263848,37311059,37016200,4011766,437663,4141062,4164645,4047610,4260205,4185711,4289517,4140453,4090569,4109381,4330445,255848,4102774,436235,261326)

) i
) c;
/**This code creates the [CD2H Asymptomatic] concept set. This is an unusual concept set because we're using a non-standard code. 
The rationale here is that the standard concept that Z11.59 maps to is "too generic" than the source concept. In this case, we are allowing a non-standard code to be used.
You will see logic in the use of this concept set to indicate to the CDM where to pull this from. If you do not do this, you run the risk of ATLAS not pulling from the right column as Standard concepts and Source concepts live in different columns in the domain.**/
insert into @tempDatabaseSchema.u6v5jn5hcodesets (codeset_id, concept_id)
select 6 as codeset_id, c.concept_id from (select distinct i.concept_id from
( 
  select concept_id from @cdmDatabaseSchema.concept where concept_id in (45595484)

) i
) c;

/** This block of code is beginning to ascribe the "Index" event to how someone qualifies for the phenotype.
It will begin to assemble a cohort based off of any rules related to observation_period (aka the time someone is continuously followed in the data).
In the case of N3C, we don't impart any rules here.**/
CREATE TABLE @tempDatabaseSchema.u6v5jn5hqualified_events
 AS WITH primary_events   as (select p.ordinal  as event_id,p.person_id as person_id,p.start_date as start_date,p.end_date as end_date,op_start_date as op_start_date,op_end_date as op_end_date,cast(p.visit_occurrence_id  as int64)  as visit_occurrence_id from (
  select e.person_id, e.start_date, e.end_date,
         row_number() over (partition by e.person_id order by e.sort_date asc) ordinal,
         op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date, cast(e.visit_occurrence_id  as int64) as visit_occurrence_id
  from 
  (
/**This block of code begins a series of boolean statements (e.g. this OR that OR that). 
The first being looking at the MEASUREMENT domain to see if someone has a lab [the list of which we specified in that concept set above] on or after the Jan 1, 2020**/
  -- Begin Measurement Criteria
select c.person_id, c.measurement_id as event_id, c.measurement_date as start_date, DATE_ADD(cast(c.measurement_date as date), interval 1 DAY) as end_date,
       c.measurement_concept_id as target_concept_id, c.visit_occurrence_id,
       c.measurement_date as sort_date
from 
(
  select m.* 
  from @cdmDatabaseSchema.measurement m
join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
) c

where c.measurement_date >= DATE(2020, 01, 01)
/** THIS LOGIC WAS INADVERTENTLY PLACED IN THE WRONG EVENT AREA IN V2.1/2.2. IT IS NOW COMMENTED OUT FOR TRANSPARENCY AND WILL BE REMOVED IN SIMPLIFICATION.
 AND ( C.value_as_concept_id in (4126681,45877985,45884084,9191)
 OR
 C.value_source_value in ('Positive', 'Present', 'Detected')
 ) **/
 -- End Measurement Criteria

union all
/**Now, we're looking for people who meet eligibility if they meet one of the two CONDITION_OCCURRENCE criteria.**/

-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
/**The next code is saying to look for a strong positive before 04-01-2020**/
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
) c

where (c.condition_start_date >= DATE(2020, 01, 01) and c.condition_start_date <= DATE(2020, 03, 31))
-- End Condition Occurrence Criteria

union all

/**The next code is saying to look for a strong positive on or after 04-01-2020**/
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
) c

where c.condition_start_date >= DATE(2020, 04, 01)
-- End Condition Occurrence Criteria

union all
/**The next code is saying to look for a Weak Positive before 04-01-2020**/
select pe.person_id, pe.event_id, pe.start_date, pe.end_date, pe.target_concept_id, pe.visit_occurrence_id, pe.sort_date from (
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
) c

where (c.condition_start_date >= DATE(2020, 01, 01) and c.condition_start_date <= DATE(2020, 03, 31))
-- End Condition Occurrence Criteria

) pe
/**The next code is making sure you have TWO distinct occurrences of the Weak Positive before 04-01-2020 on the same day.
It looks really complicated because it's a nested thought: "Find me someone who has a CONDITION_OCCURRENCE of the allowable Weak Positive concepts before 04-01-2020
AND THEN look at that person's records and find me someone who has TWO DISTINCT CONDITION_OCCURRENCE of the allowable Weak Positive concepts before 04-01-2020 on the same day.
It'll be coalescing dates to understand "what is the same day" and it will use the concept set (=5) multiple times to look up this list of allowable concepts.**/
join (
-- Begin Criteria Group
select 0 as index_id, person_id, event_id
from
/* This code says look for that initial CONDITION_OCCURRENCE of a qualifying Weak Positive**/
(
    select e.person_id, e.event_id 
    from (select q.person_id, q.event_id, q.start_date, q.end_date, q.visit_occurrence_id, op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date
from (-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
/* This code tells it which concept set to pull: Weak Positive before 04-01-2020**/
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
) c
/* This code tells it what dates: before 04-01-2020**/
where (c.condition_start_date >= DATE(2020, 01, 01) and c.condition_start_date <= DATE(2020, 03, 31))
-- End Condition Occurrence Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) e
  inner join
  (
    -- Begin Correlated Criteria
  select 0 as index_id, p.person_id, p.event_id
  from (select q.person_id, q.event_id, q.start_date, q.end_date, q.visit_occurrence_id, op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date
from (-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
/* This code tells it which concept set to pull: Weak Positive before 04-01-2020**/
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
) c
/** This code tells it what dates: before 04-01-2020**/
where (c.condition_start_date >= DATE(2020, 01, 01) and c.condition_start_date <= DATE(2020, 03, 31))
-- End Condition Occurrence Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) p
inner join
(
  -- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
/** This code tells it which concept set to pull: Weak Positive before 04-01-2020**/
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
) c


-- End Condition Occurrence Criteria
/**The next code is making sure you have TWO distinct occurrences of the Weak Positive before 04-01-2020**/
) a on a.person_id = p.person_id  and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date and a.start_date >= DATE_ADD(cast(p.start_date as date), interval 0 DAY) and a.start_date <= DATE_ADD(cast(p.start_date as date), interval 0 DAY)
  group by  p.person_id, p.event_id
 having count(distinct a.target_concept_id) >= 2
-- End Correlated Criteria
/**The next code is making sure you have it on the same day**/
   ) cq on e.person_id = cq.person_id and e.event_id = cq.event_id
    group by  e.person_id, e.event_id
   having count(index_id) = 1
 ) g
-- End Criteria Group
) ac on ac.person_id = pe.person_id and ac.event_id = pe.event_id
/**That's the end of the Weak Positive before 04-01-2020. But we're not done, we have to apply similar logic for Weak Positive between 04-01-2020 and 05-01-2020**/

union all
/**The next code is making sure you have TWO distinct occurrences of the Weak Positive between 04-01-2020 and 05-01-2020**/
/**First we establish that someone has a condition occurrence of Weak Positive between 04-01-2020 and 05-01-2020**//
select pe.person_id, pe.event_id, pe.start_date, pe.end_date, pe.target_concept_id, pe.visit_occurrence_id, pe.sort_date from (
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
/** This code tells it which concept set to pull: Weak Positive between 04-01-2020 and 05-01-2020**/
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
) c
/** This code tells it what dates: between 04-01-2020 and 05-01-2020**/
where (c.condition_start_date >= DATE(2020, 04, 01) and c.condition_start_date <= DATE(2020, 05, 01))
-- End Condition Occurrence Criteria

) pe
join (
-- Begin Criteria Group
/**The next code is making sure you have TWO distinct occurrences of the Weak Positive between 04-01-2020 and 05-01-2020**/
/**OCCURRENCE 1**/
select 0 as index_id, person_id, event_id
from
(
    select e.person_id, e.event_id 
    from (select q.person_id, q.event_id, q.start_date, q.end_date, q.visit_occurrence_id, op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date
from (-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
/** This code tells it which concept set to pull: Weak Positive between 04-01-2020 and 05-01-2020**/
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
) c
/** This code tells it what dates: between 04-01-2020 and 05-01-2020**/
where (c.condition_start_date >= DATE(2020, 04, 01) and c.condition_start_date <= DATE(2020, 05, 01))
-- End Condition Occurrence Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) e
  inner join
  (
    -- Begin Correlated Criteria
  select 0 as index_id, p.person_id, p.event_id
  from (select q.person_id, q.event_id, q.start_date, q.end_date, q.visit_occurrence_id, op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date
from (-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
/** This code tells it which concept set to pull: Weak Positive between 04-01-2020 and 05-01-2020**/
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
) c
/** This code tells it what dates: between 04-01-2020 and 05-01-2020**/
where (c.condition_start_date >= DATE(2020, 04, 01) and c.condition_start_date <= DATE(2020, 05, 01))
-- End Condition Occurrence Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) p
inner join
/**OCCURRENCE 2**/
(
  -- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
/** This code tells it which concept set to pull: Weak Positive between 04-01-2020 and 05-01-2020**/
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
) c


-- End Condition Occurrence Criteria
/**The next code is making extra sure it's TWO distinct occurrences of the Weak Positive between 04-01-2020 and 05-01-2020**/
) a on a.person_id = p.person_id  and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date and a.start_date >= DATE_ADD(cast(p.start_date as date), interval 0 DAY) and a.start_date <= DATE_ADD(cast(p.start_date as date), interval 0 DAY)
  group by  p.person_id, p.event_id
 having count(distinct a.target_concept_id) >= 2
-- End Correlated Criteria
/**The next code is making sure you have it on the same day**/
   ) cq on e.person_id = cq.person_id and e.event_id = cq.event_id
    group by  e.person_id, e.event_id
   having count(index_id) = 1
 ) g
-- End Criteria Group
) ac on ac.person_id = pe.person_id and ac.event_id = pe.event_id
/**That's the end of the Weak Positive logic inclusive of through 05-01-2020**/

union all
/**We have to now apply logic to look for Asymptomatic patients.
This one is going to get extra confusing because we're using a non-standard concept for Z11.59 so we have to do some extra gymnastics.
Z11.59 is a condition code in ICD-10 vocabulary but in OMOP, you will find it in the OBSERVATION domain because the absence of a condition is not an active condition.
It's an observation about the patient. Thus, it lives in the DOMAIN_ID = OBSERVATION.
So we start by building a piece of logic to look at the OBSERVATION domain.**/
select pe.person_id, pe.event_id, pe.start_date, pe.end_date, pe.target_concept_id, pe.visit_occurrence_id, pe.sort_date from (
-- Begin Observation Criteria
select c.person_id, c.observation_id as event_id, c.observation_date as start_date, DATE_ADD(cast(c.observation_date as date), interval 1 DAY) as end_date,
       c.observation_concept_id as target_concept_id, c.visit_occurrence_id,
       c.observation_date as sort_date
from 
/** Now, we break devout OMOP rules. We ask the logic, "can you look for this in the source_concept_ids?" because the code is not a standard that's in the concept set.**/
(
  select o.* 
  from @cdmDatabaseSchema.observation o
join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
) c
/**And we say, well we want this on or after 04-01-2020, when the CDC guidance started.**/
where c.observation_date >= DATE(2020, 04, 01)
-- End Observation Criteria

) pe
join (
-- Begin Criteria Group
/**Here's where things get interesting... we want to restrict Z11.59 to be with:
At least 1 Strong Positive On or After 04-01-2020
 --> but not people who have a lab-confirmed negative
OR
At least 1 Strong Positive Before 04-01-2020
 --> but not people who have a lab-confirmed negative
 OR
At least 1 Lab-confirmed Positive **/

/**We state what we want: People with Z11.59 on or after 04-01-2020-- same exact logic as what you saw above**/
select 0 as index_id, person_id, event_id
from
(
    select e.person_id, e.event_id 
    from (select q.person_id, q.event_id, q.start_date, q.end_date, q.visit_occurrence_id, op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date
from (-- Begin Observation Criteria
select c.person_id, c.observation_id as event_id, c.observation_date as start_date, DATE_ADD(cast(c.observation_date as date), interval 1 DAY) as end_date,
       c.observation_concept_id as target_concept_id, c.visit_occurrence_id,
       c.observation_date as sort_date
from 
(
  select o.* 
  from @cdmDatabaseSchema.observation o
join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
) c

where c.observation_date >= DATE(2020, 04, 01)
-- End Observation Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) e
  inner join
  (
    -- Begin Correlated Criteria
  select 0 as index_id, p.person_id, p.event_id
  from (select q.person_id, q.event_id, q.start_date, q.end_date, q.visit_occurrence_id, op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date
from (-- Begin Observation Criteria
select c.person_id, c.observation_id as event_id, c.observation_date as start_date, DATE_ADD(cast(c.observation_date as date), interval 1 DAY) as end_date,
       c.observation_concept_id as target_concept_id, c.visit_occurrence_id,
       c.observation_date as sort_date
from 
(
  select o.* 
  from @cdmDatabaseSchema.observation o
join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
) c

where c.observation_date >= DATE(2020, 04, 01)
-- End Observation Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) p
inner join
/*Now we're going to specify logic to get to at least 1 Strong Positive On or After 04-01-2020... and soon we will filter: but not people who have a lab-confirmed negative**/
(
  select pe.person_id, pe.event_id, pe.start_date, pe.end_date, pe.target_concept_id, pe.visit_occurrence_id, pe.sort_date from (
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
/**This is where we give the concept set: Strong Positive On or After 04-01-2020**/
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
) c
/**This is where we impart the date rule: on or after 04-01-2020**/
where c.condition_start_date >= DATE(2020, 04, 01)
-- End Condition Occurrence Criteria

) pe
join (
-- Begin Criteria Group
/** Now we want to take the Strong Positive On or After 04-01-2020 cohort and filter it further.
We're going to create a Criteria grouping here to look at the people who meet Strong Positive On or After 04-01-2020 and then filter out people who have negative results.
We start by respecify the CONDITION_OCCURRENCE criteria.**/
select 0 as index_id, person_id, event_id
from
(
    select e.person_id, e.event_id 
    from (select q.person_id, q.event_id, q.start_date, q.end_date, q.visit_occurrence_id, op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date
from (-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
/**We make sure to link this to the concept set for Strong Positive On or After 04-01-2020**/
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
) c
/**We add the date criteria: on or after 04-01-2020**/
where c.condition_start_date >= DATE(2020, 04, 01)
-- End Condition Occurrence Criteria
) q
/** Now we want to take the Strong Positive On or After 04-01-2020 cohort and filter it further.
We're going to create a Criteria grouping here to look at the people who meet Strong Positive On or After 04-01-2020 and then filter out people who have negative results.
We start by respecify the CONDITION_OCCURRENCE criteria.**/
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) e
  left join
  (
    -- Begin Correlated Criteria
  select 0 as index_id, p.person_id, p.event_id
  from (select q.person_id, q.event_id, q.start_date, q.end_date, q.visit_occurrence_id, op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date
from (-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
) c

where c.condition_start_date >= DATE(2020, 04, 01)
-- End Condition Occurrence Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) p
/**We restrict the Strong Positive On or After 04-01-2020 cohort that's specified to now look for who has measurement data**/
inner join
(
  -- Begin Measurement Criteria
select c.person_id, c.measurement_id as event_id, c.measurement_date as start_date, DATE_ADD(cast(c.measurement_date as date), interval 1 DAY) as end_date,
       c.measurement_concept_id as target_concept_id, c.visit_occurrence_id,
       c.measurement_date as sort_date
from 
/**This statement below allows us to look up the allowable LOINC / HCPCS code for COVID labs**/
(
  select m.* 
  from @cdmDatabaseSchema.measurement m
join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
) c
/**This statement below says: "If there is a lab, find me the ones who are NEGATIVE." 
In OMOP, value_as_concept_id is the standard representation of the qualitative results.**/
where c.value_as_concept_id in (45878583,37079494,1177295,36307756,36309158,36308436,9189)
-- End Measurement Criteria
/**Counting people who have a Z11.59 + a lab-confirmed negative.**/
) a on a.person_id = p.person_id  and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date
  group by  p.person_id, p.event_id
 having count(a.target_concept_id) >= 1
-- End Correlated Criteria

   ) 
  /**Restricting to people who DO NOT have a lab-confirmed negative test.**/
  cq on e.person_id = cq.person_id and e.event_id = cq.event_id
    group by  e.person_id, e.event_id
   having count(index_id) <= 0
 ) g
-- End Criteria Group
) ac on ac.person_id = pe.person_id and ac.event_id = pe.event_id
/**Keeping people who have a Z11.59 + a Strong Positive On or After 04-01-2020.**/
) a on a.person_id = p.person_id  and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date
  group by  p.person_id, p.event_id
 having count(a.target_concept_id) >= 1
-- End Correlated Criteria

union all
-- Begin Correlated Criteria

/**Now we've got to move on in our logic... we want to find people who have a Z11.59 + a Strong Positive Before 04-01-2020.**/
/**Here's the OBSERVATION logic again where we're looking for Z11.59 after 04-01-2020**/
  select 1 as index_id, p.person_id, p.event_id
  from (select q.person_id, q.event_id, q.start_date, q.end_date, q.visit_occurrence_id, op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date
from (-- Begin Observation Criteria
select c.person_id, c.observation_id as event_id, c.observation_date as start_date, DATE_ADD(cast(c.observation_date as date), interval 1 DAY) as end_date,
       c.observation_concept_id as target_concept_id, c.visit_occurrence_id,
       c.observation_date as sort_date
from 
(
  select o.* 
  from @cdmDatabaseSchema.observation o
join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
) c

where c.observation_date >= DATE(2020, 04, 01)
-- End Observation Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) p
inner 
/** Now we want to take the Strong Positive Before 04-01-2020 cohort and filter it further.
We're going to create a Criteria grouping here to look at the people who meet Strong Positive On or After 04-01-2020 and then filter out people who have negative results.
We start by respecify the CONDITION_OCCURRENCE criteria.**/
(
  select pe.person_id, pe.event_id, pe.start_date, pe.end_date, pe.target_concept_id, pe.visit_occurrence_id, pe.sort_date from (
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
/** This pulling the concept set for Strong Positive Before 04-01-2020**/
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
) c
/**Restricting to after 01-01-2020 and before 04-01-2020**/
where (c.condition_start_date >= DATE(2020, 01, 01) and c.condition_start_date <= DATE(2020, 03, 31))
-- End Condition Occurrence Criteria

) pe
join (
-- Begin Criteria Group
/*Now we're going to respecify the logic to get to at least 1 Strong Positive Before  04-01-2020... and soon we will filter: but not people who have a lab-confirmed negative**/
select 0 as index_id, person_id, event_id
from
(
    select e.person_id, e.event_id 
    from (select q.person_id, q.event_id, q.start_date, q.end_date, q.visit_occurrence_id, op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date
from (-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
) c

where (c.condition_start_date >= DATE(2020, 01, 01) and c.condition_start_date <= DATE(2020, 03, 31))
-- End Condition Occurrence Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) e
  left join
  (
    -- Begin Correlated Criteria
  select 0 as index_id, p.person_id, p.event_id
  from (select q.person_id, q.event_id, q.start_date, q.end_date, q.visit_occurrence_id, op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date
from (-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
) c

where (c.condition_start_date >= DATE(2020, 01, 01) and c.condition_start_date <= DATE(2020, 03, 31))
-- End Condition Occurrence Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) p
inner join
/*Now we specifiy the logic to look for a lab-confirmed negative.*/
(
  -- Begin Measurement Criteria
select c.person_id, c.measurement_id as event_id, c.measurement_date as start_date, DATE_ADD(cast(c.measurement_date as date), interval 1 DAY) as end_date,
       c.measurement_concept_id as target_concept_id, c.visit_occurrence_id,
       c.measurement_date as sort_date
from 
/*Pulling from the concept set of LOINC and HCPCS codes for COVID.*/
(
  select m.* 
  from @cdmDatabaseSchema.measurement m
join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
) c
/*Looking specifically for people who are lab-confirmed negative using the value_as_concept_id field where we standardize qualitative results.*/
where c.value_as_concept_id in (45878583,37079494,1177295,36307756,36309158,36308436,9189)
-- End Measurement Criteria

) a on a.person_id = p.person_id  and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date
  group by  p.person_id, p.event_id
 having count(a.target_concept_id) >= 1
-- End Correlated Criteria
/**Filtering to keep Z11.59 AND Strong Positive before 04-01-2020 but only those who are NOT lab-confirmed negative.**/
   ) cq on e.person_id = cq.person_id and e.event_id = cq.event_id
    group by  e.person_id, e.event_id
   having count(index_id) <= 0
 ) g
-- End Criteria Group
) ac on ac.person_id = pe.person_id and ac.event_id = pe.event_id

) a on a.person_id = p.person_id  and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date
  group by  p.person_id, p.event_id
 having count(a.target_concept_id) >= 1
-- End Correlated Criteria

union all
/**One last OR criteria here... if we don't have you as Z11.59 with a Strong Positive... we want you if you're Z11.59 with a lab-confirmed positive.**/
/**We begin this by stating the Z11.59 criteria from the beginning -- looking at the observation table for that specific code.**/
-- Begin Correlated Criteria
  select 2 as index_id, p.person_id, p.event_id
  from (select q.person_id, q.event_id, q.start_date, q.end_date, q.visit_occurrence_id, op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date
from (-- Begin Observation Criteria
select c.person_id, c.observation_id as event_id, c.observation_date as start_date, DATE_ADD(cast(c.observation_date as date), interval 1 DAY) as end_date,
       c.observation_concept_id as target_concept_id, c.visit_occurrence_id,
       c.observation_date as sort_date
from 
(
  select o.* 
  from @cdmDatabaseSchema.observation o
join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
) c
/**Restricting to after 04-01-2020**/
where c.observation_date >= DATE(2020, 04, 01)
-- End Observation Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) p
inner join
/**Looking in the Measurement table for lab-confirmed positive**/
(
  -- Begin Measurement Criteria
select c.person_id, c.measurement_id as event_id, c.measurement_date as start_date, DATE_ADD(cast(c.measurement_date as date), interval 1 DAY) as end_date,
       c.measurement_concept_id as target_concept_id, c.visit_occurrence_id,
       c.measurement_date as sort_date
from 
/**Looking for the LOINC/HCPCS that are COVID**/
(
  select m.* 
  from @cdmDatabaseSchema.measurement m
join @tempDatabaseSchema.u6v5jn5hcodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
) c
/**Specifying the value_as_concept_ids for positive and allowing a string search for where people have not coded these lab-confirmed qualitative results.\
This is where the logic from MS SQL Line 159-163 should have gone.**/
where and ( c.value_as_concept_id in (4126681,45877985,45884084,9191)
or
c.value_source_value in ('Positive', 'Present', 'Detected')
	)


-- End Measurement Criteria
/**Now bringing this logic together to look for people who are Z11.59 and Lab-confirmed positive**/
) a on a.person_id = p.person_id  and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date
  group by  p.person_id, p.event_id
 having count(a.target_concept_id) >= 1
-- End Correlated Criteria

     ) cq on e.person_id = cq.person_id and e.event_id = cq.event_id
    group by  e.person_id, e.event_id
   having count(index_id) >= 1
 ) g
-- End Criteria Group
) ac on ac.person_id = pe.person_id and ac.event_id = pe.event_id

  ) e
	join @cdmDatabaseSchema.observation_period op on e.person_id = op.person_id and e.start_date >=  op.observation_period_start_date and e.start_date <= op.observation_period_end_date
  where DATE_ADD(cast(op.observation_period_start_date as date), interval 0 DAY) <= e.start_date and DATE_ADD(cast(e.start_date as date), interval 0 DAY) <= op.observation_period_end_date
) p
where p.ordinal = 1
-- End Primary Events

) /*The following code is a vestigal part of Atlas-generated code. If we had additional qualifying logic that restricted cohort entry, we'd see it here. But we don't so it's largely just a shell of code. */
 SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id
 FROM (
  select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date asc) as ordinal, cast(pe.visit_occurrence_id  as int64) as visit_occurrence_id
  from primary_events pe
  
) qe

;

/**The following code is a vestigal part of Atlas-generated code. If we had additional inclusion criteria that further filtered cohort entry, we'd see it here. But we don't so it's largely just a shell of code. **/

--- Inclusion Rule Inserts

create table @tempDatabaseSchema.u6v5jn5hinclusion_events (inclusion_rule_id INT64,
	person_id INT64,
	event_id INT64
);

CREATE TABLE @tempDatabaseSchema.u6v5jn5hincluded_events
 AS WITH cteincludedevents  as (select event_id as event_id,person_id as person_id,start_date as start_date,end_date as end_date,op_start_date as op_start_date,op_end_date as op_end_date,row_number() over (partition by person_id order by start_date asc)  as ordinal from (
     select q.event_id, q.person_id, q.start_date, q.end_date, q.op_start_date, q.op_end_date, sum(coalesce(cast(power(cast(2  as int64), i.inclusion_rule_id) as int64), 0)) as inclusion_rule_mask
     from @tempDatabaseSchema.u6v5jn5hqualified_events q
    left join @tempDatabaseSchema.u6v5jn5hinclusion_events i on i.person_id = q.person_id and i.event_id = q.event_id
     group by  q.event_id, q.person_id, q.start_date, q.end_date, q.op_start_date, q.op_end_date
   ) mg -- matching groups

)
 SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date
 FROM cteincludedevents results
where results.ordinal = 1
;


/**The following code looks to see how many times people qualify for the cohort because we DO allow people to qualify more than once.**/
-- generate cohort periods into #final_cohort
CREATE TABLE @tempDatabaseSchema.u6v5jn5hcohort_rows
 AS WITH cohort_ends   as (select event_id as event_id,person_id as person_id,op_end_date  as end_date from @tempDatabaseSchema.u6v5jn5hincluded_events
), first_ends   as (select f.person_id as person_id,f.start_date as start_date,f.end_date
	 as end_date from (
	  select i.event_id, i.person_id, i.start_date, e.end_date, row_number() over (partition by i.person_id, i.event_id order by e.end_date) as ordinal 
	  from @tempDatabaseSchema.u6v5jn5hincluded_events i
	  join cohort_ends e on i.event_id = e.event_id and i.person_id = e.person_id and e.end_date >= i.start_date
	) f
	where f.ordinal = 1
)
 SELECT person_id, start_date, end_date
 FROM first_ends;

/**More Atlas generated code that largely goes unused.**/
INSERT INTO @resultsDatabaseSchema.n3c_cohort
 WITH cteenddates   as (select person_id
		 as person_id,DATE_ADD(cast(event_date as date), interval -1 * 0 DAY)   as end_date from (
		select
			person_id
			, event_date
			, event_type
			, max(start_ordinal) over (partition by person_id order by event_date, event_type rows unbounded preceding) as start_ordinal 
			, row_number() over (partition by person_id order by event_date, event_type) as overall_ord
		from
		(
			select
				person_id
				, start_date as event_date
				, -1 as event_type
				, row_number() over (partition by person_id order by start_date) as start_ordinal
			from @tempDatabaseSchema.u6v5jn5hcohort_rows
		
			union all
		

			select
				person_id
				, DATE_ADD(cast(end_date as date), interval 0 DAY) as end_date
				, 1 as event_type
				, null
			from @tempDatabaseSchema.u6v5jn5hcohort_rows
		) rawdata
	) e
	where (2 * e.start_ordinal) - e.overall_ord = 0
), cteends   as ( select c.person_id
		 as person_id,c.start_date
		 as start_date,min(e.end_date)  as end_date  from @tempDatabaseSchema.u6v5jn5hcohort_rows c
	join cteenddates e on c.person_id = e.person_id and e.end_date >= c.start_date
	 group by  c.person_id, c.start_date
 ), final_cohort   as ( select person_id as person_id,min(start_date)  as start_date,end_date
 as end_date  from cteends
 group by  1, 3 )

/**The final collapsing of ALL the logic into the cohort table.**/
--# BEGIN N3C_COHORT table to be retained

--SELECT person_id
 SELECT distinct
    person_id
from final_cohort;

insert into @resultsDatabaseSchema.phenotype_execution
select
    CURRENT_DATE() as run_datetime
    ,'2.2' as phenotype_version
    , (SELECT  vocabulary_version from @cdmDatabaseSchema.vocabulary where vocabulary_id='None' LIMIT 1) as vocabulary_version;

/**Dropping out all the temp tables.**/

DELETE FROM @tempDatabaseSchema.u6v5jn5hcohort_rows WHERE True;
drop table @tempDatabaseSchema.u6v5jn5hcohort_rows;

DELETE FROM @tempDatabaseSchema.u6v5jn5hinclusion_events WHERE True;
drop table @tempDatabaseSchema.u6v5jn5hinclusion_events;

DELETE FROM @tempDatabaseSchema.u6v5jn5hqualified_events WHERE True;
drop table @tempDatabaseSchema.u6v5jn5hqualified_events;

DELETE FROM @tempDatabaseSchema.u6v5jn5hincluded_events WHERE True;
drop table @tempDatabaseSchema.u6v5jn5hincluded_events;

DELETE FROM @tempDatabaseSchema.u6v5jn5hcodesets WHERE True;
drop table @tempDatabaseSchema.u6v5jn5hcodesets;
