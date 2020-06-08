--N3C covid-19 phenotype, ACT/i2b2, MS SQL Server
--N3C phenotype V1.5
--Modified Marshall's code to fit ACT
--04.29.2020 Michele Morris hardcode variables, comment where multifact table i2b2s need to change table name
--05.01.2020 Michele Morris add create table
--05.15.2020 Emily Pfaff converted to SQL Server
--05.27.2020 Michele Morris added 1.5 loincs

--DROP TABLE IF EXISTS @resultsDatabaseSchema.n3c_cohort; 
DROP TABLE IF EXISTS @resultsDatabaseSchema.n3c_cohort;


-- Lab LOINC codes from phenotype doc
with covid_loinc as
(
	select 'LOINC:94307-6' as loinc union distinct select 'LOINC:94308-4' as loinc union distinct select 'LOINC:94309-2' as loinc union distinct select 'LOINC:94310-0' as loinc union distinct select 'LOINC:94311-8' as loinc union distinct select 'LOINC:94312-6' as loinc union distinct select 'LOINC:94313-4' as loinc union distinct select 'LOINC:94314-2' as loinc union distinct select 'LOINC:94315-9' as loinc union distinct select 'LOINC:94316-7' as loinc union distinct select 'LOINC:94500-6' as loinc union distinct select 'LOINC:94502-2' as loinc union distinct select 'LOINC:94505-5' as loinc union distinct select 'LOINC:94506-3' as loinc union distinct select 'LOINC:94507-1' as loinc union distinct select 'LOINC:94508-9' as loinc union distinct select 'LOINC:94509-7' as loinc union distinct select 'LOINC:94510-5' as loinc union distinct select 'LOINC:94511-3' as loinc union distinct select 'LOINC:94532-9' as loinc union distinct select 'LOINC:94533-7' as loinc union distinct select 'LOINC:94534-5' as loinc union distinct select 'LOINC:94547-7' as loinc union distinct select 'LOINC:94558-4' as loinc union distinct select 'LOINC:94559-2' as loinc union distinct select 'LOINC:94562-6' as loinc union distinct select 'LOINC:94563-4' as loinc union distinct select 'LOINC:94564-2' as loinc union distinct select 'LOINC:94565-9' as loinc union distinct select 'LOINC:94639-2' as loinc union distinct select 'LOINC:94640-0' as loinc union distinct select 'LOINC:94641-8' as loinc union distinct select 'LOINC:94642-6' as loinc union distinct select 'LOINC:94643-4' as loinc union distinct select 'LOINC:94644-2' as loinc union distinct select 'LOINC:94645-9' as loinc union distinct select 'LOINC:94646-7' as loinc union distinct select 'LOINC:94647-5' as loinc union distinct select 'LOINC:94660-8' as loinc union distinct select 'LOINC:94661-6' as loinc union distinct select 'UMLS:C1611271' as loinc union distinct select 'UMLS:C1335447' as loinc union distinct select 'UMLS:C1334932' as loinc union distinct select 'UMLS:C1334932' as loinc union distinct select 'UMLS:C1335447' as loinc union distinct select 'LOINC:94720-0' as loinc union distinct select 'LOINC:94758-0' as loinc union distinct select 'LOINC:94759-8' as loinc union distinct select 'LOINC:94760-6' as loinc union distinct select 'LOINC:94762-2' as loinc union distinct select 'LOINC:94763-0' as loinc union distinct select 'LOINC:94764-8' as loinc union distinct select 'LOINC:94765-5' as loinc union distinct select 'LOINC:94766-3' as loinc union distinct select 'LOINC:94767-1' as loinc union distinct select 'LOINC:94768-9' as loinc union distinct select 'LOINC:94769-7' as loinc union distinct select 'LOINC:94819-0' as loinc union distinct select 'LOINC:94745-7' as loinc union distinct select 'LOINC:94746-5' as loinc union distinct select 'LOINC:94756-4' as loinc union distinct select 'LOINC:94757-2' as loinc union distinct select 'LOINC:94761-4' as loinc union distinct select 'LOINC:94822-4' as loinc union distinct select 'LOINC:94845-5' as loinc union distinct select 'LOINC:95125-1' as loinc union distinct select 'LOINC:95209-3' as loinc
	

),
-- Diagnosis ICD-10 codes from phenotype doc
covid_icd10 as
(
	select 'ICD10CM:B97.21' as icd10_code,	'1_strong_positive' as dx_category union distinct select 'ICD10CM:B97.29' as icd10_code,	'1_strong_positive' as dx_category union distinct select 'ICD10CM:U07.1' as icd10_code,	'1_strong_positive' as dx_category union distinct select 'ICD10CM:Z20.828' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:B34.2' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:R50%' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:R05%' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:R06.0%' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:J12%' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:J18%' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:J20%' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:J40%' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:J21%' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:J96%' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:J22%' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:J06.9' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:J98.8' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:J80%' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:R43.0' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:R43.2' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:R07.1' as icd10_code,	'2_weak_positive' as dx_category union distinct select 'ICD10CM:R68.83' as icd10_code,	'2_weak_positive' as dx_category 
),
-- procedure codes from phenotype doc
covid_proc_codes as
(
    select 'HCPCS:U0001' as procedure_code union distinct select 'HCPCS:U0002' as procedure_code union distinct select 'CPT4:87635' as procedure_code union distinct select 'CPT4:86318' as procedure_code union distinct select 'CPT4:86328' as procedure_code union distinct select 'CPT4:86769' as procedure_code
),
-- patients with covid related lab since start_date
-- if using i2b2 multi-fact table please substitute 'obseravation_fact' with appropriate fact view
covid_lab as
(
    select
        distinct observation_fact.patient_num
    from
        @cdmDatabaseSchema.observation_fact
    where
        observation_fact.start_date >= cast('2020-01-01' as datetime)
        and 
        (
            observation_fact.concept_cd in (select loinc from covid_loinc)
        )
),
-- patients with covid related diagnosis since start_date
-- if using i2b2 multi-fact table please substitute 'observation_fact' with appropriate fact view
covid_diagnosis as
(
    select
        dxq.*,
      start_date as best_dx_date,  -- use for later queries
        -- custom dx_category for one ICD-10 code, see phenotype doc
		case
			when dx in ('ICD10CM:B97.29','ICD10CM:B97.21') and start_date < cast('2020-04-01' as datetime)  then '1_strong_positive'
			when dx in ('ICD10CM:B97.29','ICD10CM:B97.21') and start_date >= cast('2020-04-01' as datetime) then '2_weak_positive'
			else dxq.orig_dx_category
		end as dx_category        
    from
    (
        select
            observation_fact.patient_num,
            observation_fact.encounter_num,
            observation_fact.concept_cd dx,
            observation_fact.start_date,
            covid_icd10.dx_category as orig_dx_category
        from
            @cdmDatabaseSchema.observation_fact
            join covid_icd10 on observation_fact.concept_cd like covid_icd10.icd10_code
        where
             observation_fact.start_date >= cast('2020-01-01' as datetime)
    ) dxq
),
-- patients with strong positive DX included
dx_strong as
(
    select distinct
        patient_num
    from
        covid_diagnosis
    where
        dx_category='1_strong_positive'    
        
),
-- patients with two different weak DX in same encounter and/or on same date included
dx_weak as
(
    -- two different DX at same encounter
    select distinct patient_num from
    (
          select patient_num,
            encounter_num,
            count(*) as dx_count
          from (
            select distinct
                patient_num, encounter_num, dx
            from
                covid_diagnosis
            where
                dx_category='2_weak_positive'
        ) subq
          group by  1, 2 having
            count(*) >= 2
     ) dx_same_encounter
    
    union distinct select distinct patient_num from
    (
          select patient_num,
            best_dx_date,
            count(*) as dx_count
          from (
            select distinct
                patient_num, best_dx_date, dx
            from
                covid_diagnosis
            where
                dx_category='2_weak_positive'
        ) subq
          group by  1, 2 having
            count(*) >= 2
     ) dx_same_date
),
-- patients with a covid related procedure since start_date
-- if using i2b2 multi-fact table please substitute obseravation_fact with appropriate fact view
covid_procedure as
(
    select
        distinct observation_fact.patient_num
    from
        @cdmDatabaseSchema.observation_fact
    where
        observation_fact.start_date >=  cast('2020-01-01' as datetime)
        and observation_fact.concept_cd in (select procedure_code from covid_proc_codes)

),
covid_cohort as
(
    select distinct patient_num from dx_strong
    union distinct select distinct patient_num from dx_weak
    union distinct select distinct patient_num from covid_procedure
    union distinct select distinct patient_num from covid_lab
),
n3c_cohort as
(
	select
		covid_cohort.patient_num,
        case when dx_strong.patient_num is not null then 1 else 0 end as inc_dx_strong,
        case when dx_weak.patient_num is not null then 1 else 0 end as inc_dx_weak,
        case when covid_procedure.patient_num is not null then 1 else 0 end as inc_procedure,
        case when covid_lab.patient_num is not null then 1 else 0 end as inc_lab
	from
		covid_cohort
		left outer join dx_strong on covid_cohort.patient_num = dx_strong.patient_num
		left outer join dx_weak on covid_cohort.patient_num = dx_weak.patient_num
		left outer join covid_procedure on covid_cohort.patient_num = covid_procedure.patient_num
		left outer join covid_lab on covid_cohort.patient_num = covid_lab.patient_num

)
select * into 
@resultsDatabaseSchema.n3c_cohort 
from n3c_cohort
