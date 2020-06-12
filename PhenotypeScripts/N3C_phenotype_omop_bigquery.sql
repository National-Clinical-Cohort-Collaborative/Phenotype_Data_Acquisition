/**
Change log:
Version 1 - initial commit
Version 2 - updated possible positive cases (typo in name of concept set name) and added additional NIH VSAC codeset_id
NOTE: as of V2, OMOP vocabularies have released an update to include new LOINC codes but the load of these concept_ids into atlas-covid19 has not been completed, when this is done we will include these into the concept_set generated
Version 3 - consolidated to single cohort definition and added N3C COHORT table + labeling statements
Version 4 - reconfiguration using SQLRender
Version 5 - updating LOINC concept sets, subset of Weak Positive and Strong Positive concept sets into before and after April 1 and new logic to include this distinction

Instructions:
Cohorts were assembled using OHDSI Atlas (atlas-covid19.ohdsi.org)
This MS SQL script is the artifact of this ATLAS cohort definition: http://atlas-covid19.ohdsi.org/#/cohortdefinition/1015
If desired to evaluate feasibility of each cohort, individual cohorts are available:
1- Lab-confirmed positive cases (http://atlas-covid19.ohdsi.org/#/cohortdefinition/655)
2- Lab-confirmed negative cases (http://atlas-covid19.ohdsi.org/#/cohortdefinition/656)
3- Suspected positive cases	(http://atlas-covid19.ohdsi.org/#/cohortdefinition/657)
4- Possible positive cases (http://atlas-covid19.ohdsi.org/#/cohortdefinition/658)

To run, you will need to find and replace @cdmDatabaseSchema, @vocabularyDatabaseSchema with your local OMOP schema details
Harmonization note:
In OHDSI conventions, we do not usually write tables to the main database schema.
NOTE: OHDSI uses @resultsDatabaseSchema as a results schema build cohort tables for specific analysis. We built the N3C_COHORT table in this results schema as we know many OMOP analyst do not have write access to their @cdmDatabaseSchema.


Begin building cohort following OHDSI standard cohort definition process


**/

--DROP TABLE IF EXISTS @resultsDatabaseSchema.n3c_cohort; -- RUN THIS LINE AFTER FIRST BUILD
DROP TABLE IF EXISTS @resultsDatabaseSchema.n3c_cohort;

-- Create dest table
create table @resultsDatabaseSchema.n3c_cohort (
	person_id			STRING  not null,
	start_date			date  not null,
	end_date			date  not null
);

create table zhzrphhlcodesets (
  codeset_id INT64 not null,
  concept_id INT64 not null
)
;

insert into zhzrphhlcodesets (codeset_id, concept_id)
select 0 as codeset_id, c.concept_id from (select distinct i.concept_id from
(
  select concept_id from @vocabularyDatabaseSchema.concept where concept_id in (706179,706166,706174,723459,706181,706177,706176,706180,706178,706167,706157,706155,706161,706175,706156,706154,706168,706163,706170,706158,706169,706160,706173,706172,706171,706165,706159,586523,586526,715272,586515,586516,586517,586518,586520,586519,586521,586522,715262,715261,715260)
union distinct select c.concept_id
  from @vocabularyDatabaseSchema.concept c
  join @vocabularyDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (706179,706166,706174,723459,706181,706177,706176,706180,706178,706167,706157,706155,706161,706175,706156,706154,706168,706163,706170,706158,706169,706160,706173,706172,706171,706165,706159,586523,586526,715272,586515,586516,586517,586518,586520,586519,586521,586522,715262,715261,715260)
  and c.invalid_reason is null

) i
) c;
insert into zhzrphhlcodesets (codeset_id, concept_id)
select 1 as codeset_id, c.concept_id from (select distinct i.concept_id from
(
  select concept_id from @vocabularyDatabaseSchema.concept where concept_id in (2212793,700360,40218805,40218804)
union distinct select c.concept_id
  from @vocabularyDatabaseSchema.concept c
  join @vocabularyDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (2212793,700360,40218805,40218804)
  and c.invalid_reason is null

) i
) c;
insert into zhzrphhlcodesets (codeset_id, concept_id)
select 2 as codeset_id, c.concept_id from (select distinct i.concept_id from
(
  select concept_id from @vocabularyDatabaseSchema.concept where concept_id in (260125,260139,46271075,4307774,4195694,257011,442555,4059022,4059021,256451,4059003,4168213,434490,439676,254761,4048098,37311061,4100065,320136,4038519,312437,4060052,4263848,37311059,37016200,4011766,437663,4141062,4164645,4047610,4260205,4185711,4289517,4140453,4090569,4109381,4330445,255848,4102774,436235,261326,320651)
union distinct select c.concept_id
  from @vocabularyDatabaseSchema.concept c
  join @vocabularyDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (260125,260139,46271075,4307774,4195694,257011,442555,4059022,4059021,256451,4059003,4168213,434490,439676,254761,4048098,37311061,4100065,320136,4038519,312437,4060052,4263848,37311059,37016200,4011766,437663,4141062,4164645,4047610,4260205,4185711,4289517,4140453,4090569,4109381,4330445,255848,4102774,436235,261326,320651)
  and c.invalid_reason is null

) i
) c;
insert into zhzrphhlcodesets (codeset_id, concept_id)
select 3 as codeset_id, c.concept_id from (select distinct i.concept_id from
(
  select concept_id from @vocabularyDatabaseSchema.concept where concept_id in (756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,320651,4100065)
union distinct select c.concept_id
  from @vocabularyDatabaseSchema.concept c
  join @vocabularyDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,320651,4100065)
  and c.invalid_reason is null

) i
) c;
insert into zhzrphhlcodesets (codeset_id, concept_id)
select 4 as codeset_id, c.concept_id from (select distinct i.concept_id from
(
  select concept_id from @vocabularyDatabaseSchema.concept where concept_id in (756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,756023,756044,756061,756031,37311061,756081,37310285,756039,37311060)
union distinct select c.concept_id
  from @vocabularyDatabaseSchema.concept c
  join @vocabularyDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (756023,756044,756061,756031,37311061,756081,37310285,756039,37311060,756023,756044,756061,756031,37311061,756081,37310285,756039,37311060)
  and c.invalid_reason is null

) i
) c;
insert into zhzrphhlcodesets (codeset_id, concept_id)
select 5 as codeset_id, c.concept_id from (select distinct i.concept_id from
(
  select concept_id from @vocabularyDatabaseSchema.concept where concept_id in (260125,260139,46271075,4307774,4195694,257011,442555,4059022,4059021,256451,4059003,4168213,434490,439676,254761,4048098,37311061,4100065,320136,4038519,312437,4060052,4263848,37311059,37016200,4011766,437663,4141062,4164645,4047610,4260205,4185711,4289517,4140453,4090569,4109381,4330445,255848,4102774,436235,261326)
union distinct select c.concept_id
  from @vocabularyDatabaseSchema.concept c
  join @vocabularyDatabaseSchema.concept_ancestor ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (260125,260139,46271075,4307774,4195694,257011,442555,4059022,4059021,256451,4059003,4168213,434490,439676,254761,4048098,37311061,4100065,320136,4038519,312437,4060052,4263848,37311059,37016200,4011766,437663,4141062,4164645,4047610,4260205,4185711,4289517,4140453,4090569,4109381,4330445,255848,4102774,436235,261326)
  and c.invalid_reason is null

) i
) c;


CREATE TABLE zhzrphhlqualified_events
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
join zhzrphhlcodesets codesets on ((m.measurement_concept_id = codesets.concept_id and codesets.codeset_id = 0))
) c

where c.measurement_date >= DATE(2020, 01, 01)
-- End Measurement Criteria

union all
-- Begin Procedure Occurrence Criteria
select c.person_id, c.procedure_occurrence_id as event_id, c.procedure_date as start_date, DATE_ADD(cast(c.procedure_date as date), interval 1 DAY) as end_date,
       c.procedure_concept_id as target_concept_id, c.visit_occurrence_id,
       c.procedure_date as sort_date
from
(
  select po.*
  from @cdmDatabaseSchema.procedure_occurrence po
join zhzrphhlcodesets codesets on ((po.procedure_concept_id = codesets.concept_id and codesets.codeset_id = 1))
) c

where c.procedure_date >= DATE(2020, 01, 01)
-- End Procedure Occurrence Criteria

union all
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from
(
  select co.*
  from @cdmDatabaseSchema.condition_occurrence co
  join zhzrphhlcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 3))
) c

where (c.condition_start_date >= DATE(2020, 01, 01) and c.condition_start_date <= DATE(2020, 03, 31))
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
  join zhzrphhlcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
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
  join zhzrphhlcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
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
  join zhzrphhlcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
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
  join zhzrphhlcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 5))
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
-- Begin Condition Occurrence Criteria
select c.person_id, c.condition_occurrence_id as event_id, c.condition_start_date as start_date, coalesce(c.condition_end_date, DATE_ADD(cast(c.condition_start_date as date), interval 1 DAY)) as end_date,
       c.condition_concept_id as target_concept_id, c.visit_occurrence_id,
       c.condition_start_date as sort_date
from
(
  select co.*
  from @cdmDatabaseSchema.condition_occurrence co
  join zhzrphhlcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 4))
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
  join zhzrphhlcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
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
  join zhzrphhlcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
) c

where c.condition_start_date >= DATE(2020, 04, 01)
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
  join zhzrphhlcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
) c

where c.condition_start_date >= DATE(2020, 04, 01)
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
  join zhzrphhlcodesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 2))
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

create table zhzrphhlinclusion_events (inclusion_rule_id INT64,
	person_id INT64,
	event_id INT64
);

CREATE TABLE zhzrphhlincluded_events
 AS WITH cteincludedevents  as (select event_id as event_id,person_id as person_id,start_date as start_date,end_date as end_date,op_start_date as op_start_date,op_end_date as op_end_date,row_number() over (partition by person_id order by start_date asc)  as ordinal from (
     select q.event_id, q.person_id, q.start_date, q.end_date, q.op_start_date, q.op_end_date, sum(coalesce(cast(power(cast(2  as int64), i.inclusion_rule_id) as int64), 0)) as inclusion_rule_mask
     from zhzrphhlqualified_events q
    left join zhzrphhlinclusion_events i on i.person_id = q.person_id and i.event_id = q.event_id
     group by  q.event_id, q.person_id, q.start_date, q.end_date, q.op_start_date, q.op_end_date
   ) mg -- matching groups

)
 SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date
 FROM cteincludedevents results
where results.ordinal = 1
;



-- generate cohort periods into #final_cohort
CREATE TABLE zhzrphhlcohort_rows
 AS WITH cohort_ends   as (select event_id as event_id,person_id as person_id,op_end_date  as end_date from zhzrphhlincluded_events
), first_ends   as (select f.person_id as person_id,f.start_date as start_date,f.end_date
	 as end_date from (
	  select i.event_id, i.person_id, i.start_date, e.end_date, row_number() over (partition by i.person_id, i.event_id order by e.end_date) as ordinal
	  from zhzrphhlincluded_events i
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
			from zhzrphhlcohort_rows

			union all


			select
				person_id
				, DATE_ADD(cast(end_date as date), interval 0 DAY) as end_date
				, 1 as event_type
				, null
			from zhzrphhlcohort_rows
		) rawdata
	) e
	where (2 * e.start_ordinal) - e.overall_ord = 0
), cteends   as ( select c.person_id
		 as person_id,c.start_date
		 as start_date,min(e.end_date)  as end_date  from zhzrphhlcohort_rows c
	join cteenddates e on c.person_id = e.person_id and e.end_date >= c.start_date
	 group by  c.person_id, c.start_date
 ), final_cohort   as ( select person_id as person_id,min(start_date)  as start_date,end_date
 as end_date  from cteends
 group by  1, 3 )

--# BEGIN N3C_COHORT table to be retained

--SELECT person_id, event_date, event_type
 SELECT distinct person_id, start_date, end_date
from final_cohort;

DELETE FROM zhzrphhlcohort_rows WHERE True;
drop table zhzrphhlcohort_rows;

DELETE FROM zhzrphhlinclusion_events WHERE True;
drop table zhzrphhlinclusion_events;

DELETE FROM zhzrphhlqualified_events WHERE True;
drop table zhzrphhlqualified_events;

DELETE FROM zhzrphhlincluded_events WHERE True;
drop table zhzrphhlincluded_events;

DELETE FROM zhzrphhlcodesets WHERE True;
drop table zhzrphhlcodesets;
