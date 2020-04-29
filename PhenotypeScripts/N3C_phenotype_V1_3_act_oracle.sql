--N3C covid-19 phenotype, ACT/i2b2, Oracle
--N3C phenotype V1.2
--Modified Marshall's code to fit ACT
--04.29.2020 Michele Morris hardcode variables, comment where multifact table i2b2s need to change table name

-- start date '2020-01-01';

-- Lab LOINC codes from phenotype doc
with covid_loinc as
(
	select 'LOINC:94307-6' as loinc from dual UNION
	select 'LOINC:94308-4' as loinc from dual UNION
	select 'LOINC:94309-2' as loinc from dual UNION
	select 'LOINC:94310-0' as loinc from dual UNION
	select 'LOINC:94311-8' as loinc from dual UNION
	select 'LOINC:94312-6' as loinc from dual UNION
	select 'LOINC:94313-4' as loinc from dual UNION
	select 'LOINC:94314-2' as loinc from dual UNION
	select 'LOINC:94315-9' as loinc from dual UNION
	select 'LOINC:94316-7' as loinc from dual UNION
	select 'LOINC:94500-6' as loinc from dual UNION
	select 'LOINC:94502-2' as loinc from dual UNION
	select 'LOINC:94505-5' as loinc from dual UNION
	select 'LOINC:94506-3' as loinc from dual UNION
	select 'LOINC:94507-1' as loinc from dual UNION
	select 'LOINC:94508-9' as loinc from dual UNION
	select 'LOINC:94509-7' as loinc from dual UNION
	select 'LOINC:94510-5' as loinc from dual UNION
	select 'LOINC:94511-3' as loinc from dual UNION
	select 'LOINC:94532-9' as loinc from dual UNION
	select 'LOINC:94533-7' as loinc from dual UNION
	select 'LOINC:94534-5' as loinc from dual UNION
	select 'LOINC:94547-7' as loinc from dual UNION
	select 'LOINC:94558-4' as loinc from dual UNION
	select 'LOINC:94559-2' as loinc from dual UNION
	select 'LOINC:94562-6' as loinc from dual UNION
	select 'LOINC:94563-4' as loinc from dual UNION
	select 'LOINC:94564-2' as loinc from dual UNION
	select 'LOINC:94565-9' as loinc from dual UNION
	select 'LOINC:94639-2' as loinc from dual UNION
	select 'LOINC:94640-0' as loinc from dual UNION
	select 'LOINC:94641-8' as loinc from dual UNION
	select 'LOINC:94642-6' as loinc from dual UNION
	select 'LOINC:94643-4' as loinc from dual UNION
	select 'LOINC:94644-2' as loinc from dual UNION
	select 'LOINC:94645-9' as loinc from dual UNION
	select 'LOINC:94646-7' as loinc from dual UNION
	select 'LOINC:94647-5' as loinc from dual UNION
	select 'LOINC:94660-8' as loinc from dual UNION
	select 'LOINC:94661-6' as loinc from dual UNION
    select 'UMLS:C1611271' as loinc from dual UNION --ACT_COVID ontology terms
    select 'UMLS:C1335447' as loinc from dual UNION
    select 'UMLS:C1334932' as loinc from dual UNION
    select 'UMLS:C1334932' as loinc from dual UNION
    select 'UMLS:C1335447' as loinc from dual
),
-- Diagnosis ICD-10 codes from phenotype doc
covid_icd10 as
(
	select 'ICD10CM:B97.21' as icd10_code,	'1_strong_positive' as dx_category from dual UNION
	select 'ICD10CM:B97.29' as icd10_code,	'1_strong_positive' as dx_category from dual UNION
	select 'ICD10CM:U07.1' as icd10_code,	'1_strong_positive' as dx_category from dual UNION
	select 'ICD10CM:Z20.828' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:B34.2' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:R50%' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:R05%' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:R06.0%' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:J12%' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:J18%' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:J20%' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:J40%' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:J21%' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:J96%' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:J22%' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:J06.9' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:J98.8' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:J80%' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:R43.0' as icd10_code,	'2_weak_positive' as dx_category from dual UNION
	select 'ICD10CM:R43.2' as icd10_code,	'2_weak_positive' as dx_category from dual
),
-- procedure codes from phenotype doc
covid_proc_codes as
(
    select 'HCPCS:U0001' as procedure_code from dual UNION
    select 'HCPCS:U0002' as procedure_code from dual UNION
    select 'CPT4:87635' as procedure_code from dual UNION
    select 'CPT4:86318' as procedure_code from dual UNION
    select 'CPT4:86328' as procedure_code from dual UNION
    select 'CPT4:86769' as procedure_code from dual
),
-- patients with covid related lab since start_date
-- if using i2b2 multi-fact table please substitute 'obseravation_fact' with appropriate fact view
covid_lab_result_cm as
(
    select
        observation_fact.*
    from
        observation_fact
    where
        observation_fact.start_date >= to_date('2020-01-01','YYYY-MM-DD')
        and 
        (
            observation_fact.concept_cd in (select loinc from covid_loinc)
        )
),
-- patients with covid related diagnosis since start_date
-- if using i2b2 multi-fact table please substitute 'obseravation_fact' with appropriate fact view
covid_diagnosis as
(
    select
        dxq.*,
        start_date as best_dx_date,  -- use for later queries
        -- custom dx_category for one ICD-10 code, see phenotype doc
		case
			when dx in ('ICD10CM:B97.29','ICD10CM:B97.21') and start_date < to_date('2020-04-01','YYYY-MM-DD')  then '1_strong_positive'
			when dx in ('ICD10CM:B97.29','ICD10CM:B97.21') and start_date >= to_date('2020-04-01','YYYY-MM-DD') then '2_weak_positive'
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
            observation_fact
            join covid_icd10 on observation_fact.concept_cd like covid_icd10.icd10_code
        where
             observation_fact.start_date >= to_date('2020-01-01','YYYY-MM-DD')
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
        select
            patient_num,
            encounter_num,
            count(*) as dx_count
        from
        (
            select distinct
                patient_num, encounter_num, dx
            from
                covid_diagnosis
            where
                dx_category='2_weak_positive'
        ) subq
        group by
            patient_num,
            encounter_num
        having
            count(*) >= 2
    ) dx_same_encounter
    
    UNION
    
    -- or two different DX on same date
    select distinct patient_num from
    (
        select
            patient_num,
            best_dx_date,
            count(*) as dx_count
        from
        (
            select distinct
                patient_num, best_dx_date, dx
            from
                covid_diagnosis
            where
                dx_category='2_weak_positive'
        ) subq
        group by
            patient_num,
            best_dx_date
        having
            count(*) >= 2
    ) dx_same_date
),
-- patients with a covid related procedure since start_date
-- if using i2b2 multi-fact table please substitute obseravation_fact with appropriate fact view
covid_procedures as
(
    select
        observation_fact.*
    from
        observation_fact
    where
        observation_fact.start_date >=  to_date('2020-01-01','YYYY-MM-DD')
        and observation_fact.concept_cd in (select procedure_code from covid_proc_codes)

),
covid_cohort as
(
    select distinct patient_num from dx_strong
    UNION
    select distinct patient_num from dx_weak
    UNION
    select distinct patient_num from covid_procedures
    UNION
    select distinct patient_num from covid_lab_result_cm
)
select distinct patient_num from covid_cohort; 
