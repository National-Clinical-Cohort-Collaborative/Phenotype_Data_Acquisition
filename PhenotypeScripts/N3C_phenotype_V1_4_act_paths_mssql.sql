--N3C covid-19 phenotype, ACT/i2b2, MS SQL Server
--N3C phenotype V1.2
--Modified Marshall's code to fit ACT
--04.27.2020 Michele Morris
--04.29.2020 Michele Morris hardcode variables
--05.15.2020 Emily Pfaff converted to SQL Server

--This is for sites that have implemented the ACT_COVID ontology which contains the new COVID concepts
--This code utilizes i2b2 ontology paths to determine the code set
--Sites using multi-fact tables will need to modify the observation fact table names to match their setup
--If a local ontology has been created to contain the appropriate terms this code should be 
--easily modified

--drop table n3c_cohort;
create table n3c_cohort as

-- Lab LOINC codes from phenotype doc
with covid_loinc_concepts as
(
    select concept_cd, name_char, concept_path 
    from concept_dimension 
    where concept_path like '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0022885\UMLS_C1334932\%'	--ANY Negative Lab Test
    UNION
    select concept_cd, name_char, concept_path 
    from concept_dimension 
    where concept_path like '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0022885\UMLS_C1335447\%'	--ANY Positive Lab Test
    UNION
    select concept_cd, name_char, concept_path 
    from concept_dimension 
    where concept_path like '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0022885\UMLS_C1611271\%'	--ANY Pending Lab Test
    UNION
    select concept_cd, name_char, concept_path 
    from concept_dimension 
    where concept_path like '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0022885\UMLS_C4303880\%'	--ANY Equivocal Lab Test
),
covid_loinc as 
(
    select concept_cd as loinc from covid_loinc_concepts 
),
-- Diagnosis ICD-10 codes from phenotype doc
covid_dx_confirmed_pos as 
(
    select concept_cd, name_char, concept_path, '1_strong_positive' as dx_category 
    from concept_dimension 
    where concept_path like '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0037088\SNOMED_3947183016\%'  --U07.1
),
covid_dx_time_depend_pos as 
(
    select concept_cd, name_char, concept_path, '1_strong_positive' as dx_category 
    from concept_dimension 
    where concept_path like '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0037088\SNOMED_3947197012\ICD10CM_B97.29\%' 
    UNION 
    select concept_cd, name_char, concept_path, '1_strong_positive' as dx_category 
    from concept_dimension 
    where concept_path like '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0037088\UMLS_C0478147\A17850346\%' --B97.21
),
covid_dx_weak_pos as
(
    select concept_cd, name_char, concept_path, '2_weak_positive' as dx_category 
    from concept_dimension 
    where concept_path like '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0037088\SNOMED_3947197012\%'	--Suspected Case
    UNION
    select concept_cd, name_char, concept_path, '2_weak_positive' as dx_category 
    from concept_dimension 
    where concept_path like '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0037088\UMLS_C0478147\%'	--Symptoms indicating suspected case
),
covid_icd10 as
(
    select concept_cd as icd10_code, dx_category from covid_dx_confirmed_pos 
    UNION
    select concept_cd as icd10_code, dx_category from covid_dx_time_depend_pos
    UNION
    select concept_cd as icd10_code, dx_category from covid_dx_weak_pos
),
-- procedure codes from phenotype doc
covid_proc_concepts as
(
    select concept_cd, name_char, concept_path 
    from concept_dimension 
    where concept_path like '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0022885\UMLS_C0086143\%' --Lab Orders
),
covid_proc_codes as
(
    select concept_cd as procedure_code --Need to add CPTs to ACT COVID Ontology
    from covid_proc_concepts 
),
-- patients with covid related lab since start_date
-- if using multifact i2b2 change the name of observation_fact table appropriately
covid_labs as
(
    select
        observation_fact.*
    from
        observation_fact
    where
        observation_fact.start_date >= convert(DATETIME, '2020-01-01')
        and 
        (
            observation_fact.concept_cd in (select loinc from covid_loinc)
        )
),
covid_labs_patients as 
(
	select distinct patient_num from covid_labs
),
-- patients with covid related diagnosis since start_date
-- if using multifact i2b2 change the name of observation_fact table appropriately
covid_diagnosis as
(
    select
        dxq.*,
        start_date as best_dx_date,  -- use for later queries
        -- custom dx_category for one ICD-10 code, see phenotype doc
		case
			when dx in (select concept_cd from covid_dx_time_depend_pos) and start_date < convert(DATETIME, '2020-04-01')  then '1_strong_positive'
			when dx in (select concept_cd from covid_dx_time_depend_pos) and start_date >= convert(DATETIME, '2020-04-01') then '2_weak_positive'
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
             observation_fact.start_date >= convert(DATETIME, '2020-01-01')
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
-- if using multifact i2b2 change the name of observation_fact table appropriately
covid_procedures as
(
    select
        observation_fact.*
    from
        observation_fact
    where
        observation_fact.start_date >=  convert(DATETIME, '2020-01-01')
        and observation_fact.concept_cd in (select procedure_code from covid_proc_codes)

),
covid_proc_patients as 
(
	select distinct patient_num from covid_procedures
),
covid_cohort as
(
    select distinct patient_num from dx_strong 
    UNION
    select distinct patient_num from dx_weak  -- need to modify the ACT Ontology to account for DX* cases
    UNION
    select distinct patient_num from covid_procedures -- need to modify the ACT Ontology to add missing CPTs
    UNION
    select distinct patient_num from covid_labs 
),
n3c_cohort as
(
	select
		covid_cohort.patient_num,
        case when dx_strong.patient_num is not null then 1 else 0 end as inc_dx_strong,
        case when dx_weak.patient_num is not null then 1 else 0 end as inc_dx_weak,
        case when covid_proc_patients.patient_num is not null then 1 else 0 end as inc_procedure,
        case when covid_labs_patients.patient_num is not null then 1 else 0 end as inc_lab
	from
		covid_cohort
		left outer join dx_strong on covid_cohort.patient_num = dx_strong.patient_num
		left outer join dx_weak on covid_cohort.patient_num = dx_weak.patient_num
		left outer join covid_proc_patients on covid_cohort.patient_num = covid_proc_patients.patient_num
		left outer join covid_labs_patients on covid_cohort.patient_num = covid_labs_patients.patient_num

)
select * from n3c_cohort;
