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

Instructions:
Cohorts were assembled using OHDSI Atlas (atlas-covid19.ohdsi.org)
This MS SQL script is the artifact of this ATLAS cohort definition: http://atlas-covid19.ohdsi.org/#/cohortdefinition/1119
If desired to evaluate feasibility of each cohort, individual cohorts are available:
1- Lab-confirmed positive cases (http://atlas-covid19.ohdsi.org/#/cohortdefinition/655)
2- Lab-confirmed negative cases (http://atlas-covid19.ohdsi.org/#/cohortdefinition/656)
3- Suspected positive cases	(http://atlas-covid19.ohdsi.org/#/cohortdefinition/657)
4- Possible positive cases (http://atlas-covid19.ohdsi.org/#/cohortdefinition/658)

To run, you will need to find and replace @cdmDatabaseSchema, @cdmDatabaseSchema with your local OMOP schema details
Harmonization note:
In OHDSI conventions, we do not usually write tables to the main database schema.
NOTE: OHDSI uses @resultsDatabaseSchema as a results schema build cohort tables for specific analysis. We built the N3C_COHORT table in this results schema as we know many OMOP analyst do not have write access to their @cdmDatabaseSchema.


Begin building cohort following OHDSI standard cohort definition process


**/

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
create table @tempDatabaseSchema.nrbjfyyocodesets (
  codeset_id INT64 not null,
  concept_id INT64 not null
)
;

insert into @tempDatabaseSchema.nrbjfyyocodesets (codeset_id, concept_id)
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
insert into @tempDatabaseSchema.nrbjfyyocodesets (codeset_id, concept_id)
select 2 as codeset_id, c.concept_id from (select distinct i.concept_id from
( 
  select concept_id from @cdmDatabaseSchema.concept where concept_id in (260125,260139,46271075,4307774,4195694,257011,442555,4059022,4059021,256451,4059003,4168213,434490,439676,254761,4048098,37311061,4100065,320136,4038519,312437,4060052,4263848,37311059,37016200,4011766,437663,4141062,4164645,4047610,4260205,4185711,4289517,4140453,4090569,4109381,4330445,255848,4102774,436235,261326,320651)

) i
) c;
insert into @tempDatabaseSchema.nrbjfyyocodesets (codeset_id, concept_id)
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
insert into @tempDatabaseSchema.nrbjfyyocodesets (codeset_id, concept_id)
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
insert into @tempDatabaseSchema.nrbjfyyocodesets (codeset_id, concept_id)
select 5 as codeset_id, c.concept_id from (select distinct i.concept_id from
( 
  select concept_id from @cdmDatabaseSchema.concept where concept_id in (260125,260139,46271075,4307774,4195694,257011,442555,4059022,4059021,256451,4059003,4168213,434490,439676,254761,4048098,37311061,4100065,320136,4038519,312437,4060052,4263848,37311059,37016200,4011766,437663,4141062,4164645,4047610,4260205,4185711,4289517,4140453,4090569,4109381,4330445,255848,4102774,436235,261326)

) i
) c;
insert into @tempDatabaseSchema.nrbjfyyocodesets (codeset_id, concept_id)
select 6 as codeset_id, c.concept_id from (select distinct i.concept_id from
( 
  select concept_id from @cdmDatabaseSchema.concept where concept_id in (45595484)

) i
) c;


CREATE TABLE @tempDatabaseSchema.nrbjfyyoqualified_events
 AS WITH primary_events   as (select p.ordinal  as event_id,p.person_id as person_id,p.start_date as start_date,p.end_date as end_date,op_start_date as op_start_date,op_end_date as op_end_date,cast(p.visit_occurrence_id  as int64)  as visit_occurrence_id from (
  select e.person_id, e.start_date, e.end_date,
         row_number() over (partition by e.person_id order by e.sort_date asc) ordinal,
         op.observation_period_start_date as op_start_date, op.observation_period_end_date as op_end_date, cast(e.visit_occurrence_id  as int64) as visit_occurrence_id
  from 
  (
  -- Begin Measurement Criteria
select c.person_id, c.measurement_id as event_id, c.measurement_date as start_date, DATE_ADD(cast(c.measurement_date as date), interval 1 DAY) as end_date,
       c.measurement_concept_id as target_concept_id, c.visit_occurrence_id,
       c.measurement_date as sort_date
from 
(
  select m.* 
  from @cdmDatabaseSchema.measurement m
join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
) c

where c.measurement_date >= DATE(2020, 01, 01)
and ( c.value_as_concept_id in (4126681,45877985,45884084,9191)
	or
	c.value_source_value in ('Positive', 'Present', 'Detected')
	)
-- End Measurement Criteria

union all
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
) c

where (c.condition_start_date >= DATE(2020, 01, 01) and c.condition_start_date <= DATE(2020, 03, 31))
-- End Condition Occurrence Criteria

union all
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
) c

where c.condition_start_date >= DATE(2020, 04, 01)
-- End Condition Occurrence Criteria

union all
select pe.person_id, pe.event_id, pe.start_date, pe.end_date, pe.target_concept_id, pe.visit_occurrence_id, pe.sort_date from (
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
) c

where (c.condition_start_date >= DATE(2020, 01, 01) and c.condition_start_date <= DATE(2020, 03, 31))
-- End Condition Occurrence Criteria

) pe
join (
-- Begin Criteria Group
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
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
) c

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
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
) c

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
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
) c


-- End Condition Occurrence Criteria

) a on a.person_id = p.person_id  and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date and a.start_date >= DATE_ADD(cast(p.start_date as date), interval 0 DAY) and a.start_date <= DATE_ADD(cast(p.start_date as date), interval 0 DAY)
  group by  p.person_id, p.event_id
 having count(distinct a.target_concept_id) >= 2
-- End Correlated Criteria

   ) cq on e.person_id = cq.person_id and e.event_id = cq.event_id
    group by  e.person_id, e.event_id
   having count(index_id) = 1
 ) g
-- End Criteria Group
) ac on ac.person_id = pe.person_id and ac.event_id = pe.event_id

union all
select pe.person_id, pe.event_id, pe.start_date, pe.end_date, pe.target_concept_id, pe.visit_occurrence_id, pe.sort_date from (
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
) c

where (c.condition_start_date >= DATE(2020, 04, 01) and c.condition_start_date <= DATE(2020, 05, 01))
-- End Condition Occurrence Criteria

) pe
join (
-- Begin Criteria Group
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
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
) c

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
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
) c

where (c.condition_start_date >= DATE(2020, 04, 01) and c.condition_start_date <= DATE(2020, 05, 01))
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
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
) c


-- End Condition Occurrence Criteria

) a on a.person_id = p.person_id  and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date and a.start_date >= DATE_ADD(cast(p.start_date as date), interval 0 DAY) and a.start_date <= DATE_ADD(cast(p.start_date as date), interval 0 DAY)
  group by  p.person_id, p.event_id
 having count(distinct a.target_concept_id) >= 2
-- End Correlated Criteria

   ) cq on e.person_id = cq.person_id and e.event_id = cq.event_id
    group by  e.person_id, e.event_id
   having count(index_id) = 1
 ) g
-- End Criteria Group
) ac on ac.person_id = pe.person_id and ac.event_id = pe.event_id

union all
select pe.person_id, pe.event_id, pe.start_date, pe.end_date, pe.target_concept_id, pe.visit_occurrence_id, pe.sort_date from (
-- Begin Observation Criteria
select c.person_id, c.observation_id as event_id, c.observation_date as start_date, DATE_ADD(cast(c.observation_date as date), interval 1 DAY) as end_date,
       c.observation_concept_id as target_concept_id, c.visit_occurrence_id,
       c.observation_date as sort_date
from 
(
  select o.* 
  from @cdmDatabaseSchema.observation o
join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
) c

where c.observation_date >= DATE(2020, 04, 01)
-- End Observation Criteria

) pe
join (
-- Begin Criteria Group
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
join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
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
join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
) c

where c.observation_date >= DATE(2020, 04, 01)
-- End Observation Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) p
inner join
(
  select pe.person_id, pe.event_id, pe.start_date, pe.end_date, pe.target_concept_id, pe.visit_occurrence_id, pe.sort_date from (
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
) c

where c.condition_start_date >= DATE(2020, 04, 01)
-- End Condition Occurrence Criteria

) pe
join (
-- Begin Criteria Group
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
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
) c

where c.condition_start_date >= DATE(2020, 04, 01)
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
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
) c

where c.condition_start_date >= DATE(2020, 04, 01)
-- End Condition Occurrence Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) p
inner join
(
  -- Begin Measurement Criteria
select c.person_id, c.measurement_id as event_id, c.measurement_date as start_date, DATE_ADD(cast(c.measurement_date as date), interval 1 DAY) as end_date,
       c.measurement_concept_id as target_concept_id, c.visit_occurrence_id,
       c.measurement_date as sort_date
from 
(
  select m.* 
  from @cdmDatabaseSchema.measurement m
join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
) c

where c.value_as_concept_id in (45878583,37079494,1177295,36307756,36309158,36308436,9189)
-- End Measurement Criteria

) a on a.person_id = p.person_id  and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date
  group by  p.person_id, p.event_id
 having count(a.target_concept_id) >= 1
-- End Correlated Criteria

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
-- Begin Correlated Criteria
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
join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
) c

where c.observation_date >= DATE(2020, 04, 01)
-- End Observation Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) p
inner join
(
  select pe.person_id, pe.event_id, pe.start_date, pe.end_date, pe.target_concept_id, pe.visit_occurrence_id, pe.sort_date from (
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from 
(
  select co.* 
  from @cdmDatabaseSchema.condition_occurrence co
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
) c

where (c.condition_start_date >= DATE(2020, 01, 01) and c.condition_start_date <= DATE(2020, 03, 31))
-- End Condition Occurrence Criteria

) pe
join (
-- Begin Criteria Group
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
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
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
  join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
) c

where (c.condition_start_date >= DATE(2020, 01, 01) and c.condition_start_date <= DATE(2020, 03, 31))
-- End Condition Occurrence Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) p
inner join
(
  -- Begin Measurement Criteria
select c.person_id, c.measurement_id as event_id, c.measurement_date as start_date, DATE_ADD(cast(c.measurement_date as date), interval 1 DAY) as end_date,
       c.measurement_concept_id as target_concept_id, c.visit_occurrence_id,
       c.measurement_date as sort_date
from 
(
  select m.* 
  from @cdmDatabaseSchema.measurement m
join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
) c

where c.value_as_concept_id in (45878583,37079494,1177295,36307756,36309158,36308436,9189)
-- End Measurement Criteria

) a on a.person_id = p.person_id  and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date and a.start_date >= p.op_start_date and a.start_date <= p.op_end_date
  group by  p.person_id, p.event_id
 having count(a.target_concept_id) >= 1
-- End Correlated Criteria

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
join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((o.observation_source_concept_id = codesets.concept_id and codesets.codeset_id = 6))
) c

where c.observation_date >= DATE(2020, 04, 01)
-- End Observation Criteria
) q
join @cdmDatabaseSchema.observation_period op on q.person_id = op.person_id 
  and op.observation_period_start_date <= q.start_date and op.observation_period_end_date >= q.start_date
) p
inner join
(
  -- Begin Measurement Criteria
select c.person_id, c.measurement_id as event_id, c.measurement_date as start_date, DATE_ADD(cast(c.measurement_date as date), interval 1 DAY) as end_date,
       c.measurement_concept_id as target_concept_id, c.visit_occurrence_id,
       c.measurement_date as sort_date
from 
(
  select m.* 
  from @cdmDatabaseSchema.measurement m
join @tempDatabaseSchema.nrbjfyyocodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
) c

where c.value_as_concept_id in (4126681,45877985,45884084,9191)
-- End Measurement Criteria

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

)
 SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id
 FROM (
  select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date asc) as ordinal, cast(pe.visit_occurrence_id  as int64) as visit_occurrence_id
  from primary_events pe
  
) qe

;

--- Inclusion Rule Inserts

create table @tempDatabaseSchema.nrbjfyyoinclusion_events (inclusion_rule_id INT64,
	person_id INT64,
	event_id INT64
);

CREATE TABLE @tempDatabaseSchema.nrbjfyyoincluded_events
 AS WITH cteincludedevents  as (select event_id as event_id,person_id as person_id,start_date as start_date,end_date as end_date,op_start_date as op_start_date,op_end_date as op_end_date,row_number() over (partition by person_id order by start_date asc)  as ordinal from (
     select q.event_id, q.person_id, q.start_date, q.end_date, q.op_start_date, q.op_end_date, sum(coalesce(cast(power(cast(2  as int64), i.inclusion_rule_id) as int64), 0)) as inclusion_rule_mask
     from @tempDatabaseSchema.nrbjfyyoqualified_events q
    left join @tempDatabaseSchema.nrbjfyyoinclusion_events i on i.person_id = q.person_id and i.event_id = q.event_id
     group by  q.event_id, q.person_id, q.start_date, q.end_date, q.op_start_date, q.op_end_date
   ) mg -- matching groups

)
 SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date
 FROM cteincludedevents results
where results.ordinal = 1
;



-- generate cohort periods into #final_cohort
CREATE TABLE @tempDatabaseSchema.nrbjfyyocohort_rows
 AS WITH cohort_ends   as (select event_id as event_id,person_id as person_id,op_end_date  as end_date from @tempDatabaseSchema.nrbjfyyoincluded_events
), first_ends   as (select f.person_id as person_id,f.start_date as start_date,f.end_date
	 as end_date from (
	  select i.event_id, i.person_id, i.start_date, e.end_date, row_number() over (partition by i.person_id, i.event_id order by e.end_date) as ordinal 
	  from @tempDatabaseSchema.nrbjfyyoincluded_events i
	  join cohort_ends e on i.event_id = e.event_id and i.person_id = e.person_id and e.end_date >= i.start_date
	) f
	where f.ordinal = 1
)
 SELECT person_id, start_date, end_date
 FROM first_ends;

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
			from @tempDatabaseSchema.nrbjfyyocohort_rows
		
			union all
		

			select
				person_id
				, DATE_ADD(cast(end_date as date), interval 0 DAY) as end_date
				, 1 as event_type
				, null
			from @tempDatabaseSchema.nrbjfyyocohort_rows
		) rawdata
	) e
	where (2 * e.start_ordinal) - e.overall_ord = 0
), cteends   as ( select c.person_id
		 as person_id,c.start_date
		 as start_date,min(e.end_date)  as end_date  from @tempDatabaseSchema.nrbjfyyocohort_rows c
	join cteenddates e on c.person_id = e.person_id and e.end_date >= c.start_date
	 group by  c.person_id, c.start_date
 ), final_cohort   as ( select person_id as person_id,min(start_date)  as start_date,end_date
 as end_date  from cteends
 group by  1, 3 )

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


DELETE FROM @tempDatabaseSchema.nrbjfyyocohort_rows WHERE True;
drop table @tempDatabaseSchema.nrbjfyyocohort_rows;

DELETE FROM @tempDatabaseSchema.nrbjfyyoinclusion_events WHERE True;
drop table @tempDatabaseSchema.nrbjfyyoinclusion_events;

DELETE FROM @tempDatabaseSchema.nrbjfyyoqualified_events WHERE True;
drop table @tempDatabaseSchema.nrbjfyyoqualified_events;

DELETE FROM @tempDatabaseSchema.nrbjfyyoincluded_events WHERE True;
drop table @tempDatabaseSchema.nrbjfyyoincluded_events;

DELETE FROM @tempDatabaseSchema.nrbjfyyocodesets WHERE True;
drop table @tempDatabaseSchema.nrbjfyyocodesets;
