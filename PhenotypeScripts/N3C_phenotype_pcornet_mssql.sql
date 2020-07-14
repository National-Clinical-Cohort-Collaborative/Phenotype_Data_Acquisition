--N3C covid-19 phenotype, PCORnet CDM
--N3C phenotype V2.0

--Significant changes from V1:
--Weak diagnoses no longer checked after May 1, 2020
--Added asymptomatic test code (Z11.59) to diagnosis list
--Added new temp table definition "dx_asymp" to capture asymptomatic test patients who got that code after April 1, 2020, 
--  had a covid lab (regardless of result), and doesnt have a strong dx
--Added new temp table covid_lab_pos to capture positive lab tests
--Added new temp table covid_pos_list to capture a given site's definition of positive
--Added a column to the n3c_cohort table to capture the exc_dx_asymp flag
--Added a column to the final select statement to populate that field
--Added a WHERE to the final select to exclude asymptomatic patients

-- start date is set to '2020-01-01'

-- modify covid_lab table expression to include your lab raw name

-- Clear previous execution
IF OBJECT_ID('@resultsDatabaseSchema.n3c_cohort', 'U') IS NOT NULL           -- Drop temp table if it exists
  DROP TABLE @resultsDatabaseSchema.n3c_cohort;
  
  
-- Create dest table
CREATE TABLE @resultsDatabaseSchema.n3c_cohort (
	patid				VARCHAR(50)  NOT NULL,
	inc_dx_strong		INT  NOT NULL,
	inc_dx_weak			INT  NOT NULL,
	inc_procedure		INT  NOT NULL,
	inc_lab				INT  NOT NULL,
	exc_dx_asymp        INT  NOT NULL
);
  

-- Lab LOINC codes from phenotype doc
with covid_loinc as
(
	select '94307-6' as loinc UNION
	select '94308-4' as loinc UNION
	select '94309-2' as loinc UNION
	select '94310-0' as loinc UNION
	select '94311-8' as loinc UNION
	select '94312-6' as loinc UNION
	select '94313-4' as loinc UNION
	select '94314-2' as loinc UNION
	select '94315-9' as loinc UNION
	select '94316-7' as loinc UNION
	select '94500-6' as loinc UNION
	select '94502-2' as loinc UNION
	select '94505-5' as loinc UNION
	select '94506-3' as loinc UNION
	select '94507-1' as loinc UNION
	select '94508-9' as loinc UNION
	select '94509-7' as loinc UNION
	select '94510-5' as loinc UNION
	select '94511-3' as loinc UNION
	select '94532-9' as loinc UNION
	select '94533-7' as loinc UNION
	select '94534-5' as loinc UNION
	select '94547-7' as loinc UNION
	select '94558-4' as loinc UNION
	select '94559-2' as loinc UNION
	select '94562-6' as loinc UNION
	select '94563-4' as loinc UNION
	select '94564-2' as loinc UNION
	select '94565-9' as loinc UNION
	select '94639-2' as loinc UNION
	select '94640-0' as loinc UNION
	select '94641-8' as loinc UNION
	select '94642-6' as loinc UNION
	select '94643-4' as loinc UNION
	select '94644-2' as loinc UNION
	select '94645-9' as loinc UNION
	select '94646-7' as loinc UNION
	select '94647-5' as loinc UNION
	select '94660-8' as loinc UNION
	select '94661-6' as loinc UNION
    	select '94306-8' as loinc UNION
	select '94503-0' as loinc UNION
	select '94504-8' as loinc UNION
	select '94531-1' as loinc UNION
	select '94720-0' as loinc UNION
	select '94758-0' as loinc UNION
	select '94759-8' as loinc UNION
	select '94760-6' as loinc UNION
	select '94762-2' as loinc UNION
	select '94763-0' as loinc UNION
	select '94764-8' as loinc UNION
	select '94765-5' as loinc UNION
	select '94766-3' as loinc UNION
	select '94767-1' as loinc UNION
	select '94768-9' as loinc UNION
	select '94769-7' as loinc UNION
	select '94819-0' as loinc UNION
    -- new for v1.5
	select '94745-7' as loinc UNION    
	select '94746-5' as loinc UNION    
	select '94756-4' as loinc UNION    
	select '94757-2' as loinc UNION    
	select '94761-4' as loinc UNION    
	select '94822-4' as loinc UNION    
	select '94845-5' as loinc UNION    
	select '95125-1' as loinc UNION    
	select '95209-3' as loinc UNION
	-- new for v1.6
	select '95406-5' as loinc UNION
	select '95409-9' as loinc UNION
	select '95410-7' as loinc UNION
	select '95411-5' as loinc	
),

 --The ways that your site describes a positive COVID test
covid_pos_list as (SELECT 'POSITIVE' as word UNION SELECT 'DETECTED' as word),

-- Diagnosis ICD-10/SNOMED codes from phenotype doc
covid_dx_codes as
(
    -- ICD-10
        SELECT 'Z11.59' as dx_code,'asymptomatic' as dx_category UNION
	select 'B97.21' as dx_code,	'dx_strong_positive' as dx_category UNION
	select 'B97.29' as dx_code,	'dx_strong_positive' as dx_category UNION
	select 'U07.1' as dx_code,	'dx_strong_positive' as dx_category UNION
	select 'Z20.828' as dx_code,'dx_weak_positive' as dx_category UNION
	select 'B34.2' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'R50%' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'R05%' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'R06.0%' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'J12%' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'J18%' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'J20%' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'J40%' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'J21%' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'J96%' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'J22%' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'J06.9' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'J98.8' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'J80%' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'R43.0' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'R43.2' as dx_code,	'dx_weak_positive' as dx_category UNION
    	select 'R07.1' as dx_code,	'dx_weak_positive' as dx_category UNION
	select 'R68.83' as dx_code,	'dx_weak_positive' as dx_category UNION
    -- SNOMED
	select '840539006' as dx_code,	'dx_strong_positive' as dx_category UNION
	select '840544004' as dx_code,	'dx_strong_positive' as dx_category UNION
	select '840546002' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '103001002' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '11833005' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '267036007' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '28743005' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '36955009' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '426000000' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '44169009' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '49727002' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '135883003' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '161855003' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '161939006' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '161940008' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '161941007' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '2237002' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '23141003' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '247410004' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '274640006' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '274664007' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '284523002' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '386661006' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '409702008' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '426976009' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '43724002' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '60845006' as dx_code,	'dx_weak_positive' as dx_category UNION
	select '75483001' as dx_code,	'dx_weak_positive' as dx_category

),

-- procedure codes from phenotype doc
covid_proc_codes as
(
    select 'U0001' as procedure_code UNION
    select 'U0002' as procedure_code UNION
    select '87635' as procedure_code UNION
    select '86318' as procedure_code UNION
    select '86328' as procedure_code UNION
    select '86769' as procedure_code
),

-- patients with covid related lab since start_date
covid_lab as
(
    select distinct
        lab_result_cm.patid
    from
	@cdmDatabaseSchema.lab_result_cm
    where
        lab_result_cm.result_date >= CAST('2020-01-01' as datetime)
        and 
        (
            lab_result_cm.lab_loinc in (select loinc from covid_loinc)
            or
			upper(lab_result_cm.raw_lab_name) like '%COVID-19%'
			or
			upper(lab_result_cm.raw_lab_name) like '%SARS-COV-2%'            
        )
),

 --patients with positive covid lab test
 covid_lab_pos as
(SELECT distinct
        lab_result_cm.patid
    FROM @cdmDatabaseSchema.lab_result_cm JOIN covid_pos_list ON LAB_RESULT_CM.RESULT_QUAL = covid_pos_list.word
      WHERE lab_result_cm.result_date >= CAST('2020-01-01' as datetime)
        and 
        (
            lab_result_cm.lab_loinc in (SELECT loinc FROM covid_loinc )
            or
			upper(lab_result_cm.raw_lab_name) like '%COVID-19%'
			or
			upper(lab_result_cm.raw_lab_name) like '%SARS-COV-2%'            
        )
 ),

-- patients with covid related diagnosis since start_date
covid_diagnosis as
(
    select
        dxq.*,
        coalesce(dx_date,admit_date) as best_dx_date,  -- use for later queries
        -- custom dx_category for one ICD-10 code, see phenotype doc
		case
			when dx in ('B97.29','B97.21') and coalesce(dx_date,admit_date) < CAST('2020-04-01' as datetime)  then 'dx_strong_positive'
			when dx in ('B97.29','B97.21') and coalesce(dx_date,admit_date) >= CAST('2020-04-01' as datetime) then 'dx_weak_positive'
			else dxq.orig_dx_category
		end as dx_category        
    from
    (
        select
            diagnosis.patid,
            diagnosis.encounterid,
            diagnosis.dx,
            diagnosis.admit_date,
            diagnosis.dx_date,
            covid_dx_codes.dx_category as orig_dx_category
        from
           @cdmDatabaseSchema.diagnosis
           join covid_dx_codes on diagnosis.dx like covid_dx_codes.dx_code
        where
            coalesce(dx_date,admit_date) >= CAST('2020-01-01' as datetime)
    ) dxq
),

-- patients with strong positive DX included
dx_strong as
(
    select distinct
        patid
    from
        covid_diagnosis
    where
        dx_category='dx_strong_positive'    
        
),

-- patients with asymptomatic DX 
-- ensure they had a covid lab, and that the code was after April 1
-- and make sure they are not in the strong positive set OR positive lab set, which overrules the asymptomatic
-- these are patients who will be EXCLUDED, not INCLUDED
dx_asymp as
(SELECT distinct
        cda.patid
    FROM 
        covid_diagnosis cda 
        JOIN covid_lab on cda.patid = covid_lab.patid and cda.dx_category='asymptomatic' and cda.best_dx_date >= CAST('2020-04-01' as datetime)
        LEFT JOIN covid_diagnosis cds ON cda.patid = cds.patid AND cds.dx_category='dx_strong_positive'
        LEFT JOIN covid_lab_pos cpl ON cda.patid = cpl.patid
     WHERE     
        cds.patid is null AND cpl.patid is null
 ),

-- patients with two different weak DX in same encounter and/or on same date included
dx_weak as
(
    -- two different DX at same encounter
    select distinct patid from
    (
        select
            patid,
            encounterid,
            count(*) as dx_count
        from
        (
            select distinct
                patid, encounterid, dx
            from
                covid_diagnosis
            where
                dx_category='dx_weak_positive' and best_dx_date <= CAST('2020-05-01' as datetime)
        ) subq
        group by
            patid,
            encounterid
        having
            count(*) >= 2
    ) dx_same_encounter
    
    UNION
    
    -- or two different DX on same date
    select distinct patid from
    (
        select
            patid,
            best_dx_date,
            count(*) as dx_count
        from
        (
            select distinct
                patid, best_dx_date, dx
            from
                covid_diagnosis
            where
                dx_category='dx_weak_positive' and best_dx_date <= CAST('2020-05-01' as datetime)
        ) subq
        group by
            patid,
            best_dx_date
        having
            count(*) >= 2
    ) dx_same_date
),

-- patients with a covid related procedure since start_date
covid_procedure as
(
    select distinct
        procedures.patid
    from
		@cdmDatabaseSchema.procedures
		join covid_proc_codes on procedures.px = covid_proc_codes.procedure_code
    where
        procedures.px_date >=  CAST('2020-01-01' as datetime)

),

covid_cohort as
(
    select distinct patid from dx_strong
    UNION
    select distinct patid from dx_weak
    UNION
    select distinct patid from covid_procedure
    UNION
    select distinct patid from covid_lab
     UNION
    select distinct patid FROM dx_asymp
),

cohort as
(
select
	covid_cohort.patid,
	case when dx_strong.patid is not null then 1 else 0 end as inc_dx_strong,
	case when dx_weak.patid is not null then 1 else 0 end as inc_dx_weak,
	case when covid_procedure.patid is not null then 1 else 0 end as inc_procedure,
	case when covid_lab.patid is not null then 1 else 0 end as inc_lab,
	case when dx_asymp.patid is not null then 1 else 0 end as exc_dx_asymp
from
	covid_cohort
	left outer join dx_strong on covid_cohort.patid = dx_strong.patid
	left outer join dx_weak on covid_cohort.patid = dx_weak.patid
	left outer join covid_procedure on covid_cohort.patid = covid_procedure.patid
	left outer join covid_lab on covid_cohort.patid = covid_lab.patid
	left outer join dx_asymp on covid_cohort.patid = dx_asymp.patid
)


INSERT INTO  @resultsDatabaseSchema.n3c_cohort 
SELECT patid, inc_dx_strong, inc_dx_weak, inc_procedure, inc_lab, exc_dx_asymp
FROM cohort
where exc_dx_asymp = 0;
