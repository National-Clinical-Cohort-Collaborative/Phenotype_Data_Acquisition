--N3C covid-19 phenotype, ACT/i2b2, MS SQL Server
--N3C phenotype V1.5
--Modified Marshall's code to fit ACT
--04.29.2020 Michele Morris hardcode variables, comment where multifact table i2b2s need to change table name
--05.01.2020 Michele Morris add create table
--05.15.2020 Emily Pfaff converted to SQL Server
--05.27.2020 Michele Morris added 1.5 loincs

--DROP TABLE IF EXISTS @resultsDatabaseSchema.n3c_cohort; 
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE @resultsDatabaseSchema.n3c_cohort';
  EXECUTE IMMEDIATE 'DROP TABLE @resultsDatabaseSchema.n3c_cohort';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;


-- Lab LOINC codes from phenotype doc
with covid_loinc as
(SELECT 'LOINC:94307-6' as loinc  FROM DUAL  UNION SELECT 'LOINC:94308-4'  loinc   FROM DUAL  UNION SELECT 'LOINC:94309-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94310-0'  loinc   FROM DUAL  UNION SELECT 'LOINC:94311-8'  loinc   FROM DUAL  UNION SELECT 'LOINC:94312-6'  loinc   FROM DUAL  UNION SELECT 'LOINC:94313-4'  loinc   FROM DUAL  UNION SELECT 'LOINC:94314-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94315-9'  loinc   FROM DUAL  UNION SELECT 'LOINC:94316-7'  loinc   FROM DUAL  UNION SELECT 'LOINC:94500-6'  loinc   FROM DUAL  UNION SELECT 'LOINC:94502-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94505-5'  loinc   FROM DUAL  UNION SELECT 'LOINC:94506-3'  loinc   FROM DUAL  UNION SELECT 'LOINC:94507-1'  loinc   FROM DUAL  UNION SELECT 'LOINC:94508-9'  loinc   FROM DUAL  UNION SELECT 'LOINC:94509-7'  loinc   FROM DUAL  UNION SELECT 'LOINC:94510-5'  loinc   FROM DUAL  UNION SELECT 'LOINC:94511-3'  loinc   FROM DUAL  UNION SELECT 'LOINC:94532-9'  loinc   FROM DUAL  UNION SELECT 'LOINC:94533-7'  loinc   FROM DUAL  UNION SELECT 'LOINC:94534-5'  loinc   FROM DUAL  UNION SELECT 'LOINC:94547-7'  loinc   FROM DUAL  UNION SELECT 'LOINC:94558-4'  loinc   FROM DUAL  UNION SELECT 'LOINC:94559-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94562-6'  loinc   FROM DUAL  UNION SELECT 'LOINC:94563-4'  loinc   FROM DUAL  UNION SELECT 'LOINC:94564-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94565-9'  loinc   FROM DUAL  UNION SELECT 'LOINC:94639-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94640-0'  loinc   FROM DUAL  UNION SELECT 'LOINC:94641-8'  loinc   FROM DUAL  UNION SELECT 'LOINC:94642-6'  loinc   FROM DUAL  UNION SELECT 'LOINC:94643-4'  loinc   FROM DUAL  UNION SELECT 'LOINC:94644-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94645-9'  loinc   FROM DUAL  UNION SELECT 'LOINC:94646-7'  loinc   FROM DUAL  UNION SELECT 'LOINC:94647-5'  loinc   FROM DUAL  UNION SELECT 'LOINC:94660-8'  loinc   FROM DUAL  UNION SELECT 'LOINC:94661-6'  loinc   FROM DUAL  UNION SELECT 'UMLS:C1611271'  loinc   FROM DUAL  UNION SELECT 'UMLS:C1335447'  loinc   FROM DUAL  UNION SELECT 'UMLS:C1334932'  loinc   FROM DUAL  UNION SELECT 'UMLS:C1334932'  loinc   FROM DUAL  UNION SELECT 'UMLS:C1335447'  loinc   FROM DUAL  UNION SELECT 'LOINC:94720-0'  loinc   FROM DUAL  UNION SELECT 'LOINC:94758-0'  loinc   FROM DUAL  UNION SELECT 'LOINC:94759-8'  loinc   FROM DUAL  UNION SELECT 'LOINC:94760-6'  loinc   FROM DUAL  UNION SELECT 'LOINC:94762-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94763-0'  loinc   FROM DUAL  UNION SELECT 'LOINC:94764-8'  loinc   FROM DUAL  UNION SELECT 'LOINC:94765-5'  loinc   FROM DUAL  UNION SELECT 'LOINC:94766-3'  loinc   FROM DUAL  UNION SELECT 'LOINC:94767-1'  loinc   FROM DUAL  UNION SELECT 'LOINC:94768-9'  loinc   FROM DUAL  UNION SELECT 'LOINC:94769-7'  loinc   FROM DUAL  UNION SELECT 'LOINC:94819-0'  loinc   FROM DUAL  UNION SELECT 'LOINC:94745-7'  loinc   FROM DUAL  UNION SELECT 'LOINC:94746-5'  loinc   FROM DUAL  UNION SELECT 'LOINC:94756-4'  loinc   FROM DUAL  UNION SELECT 'LOINC:94757-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94761-4'  loinc   FROM DUAL  UNION SELECT 'LOINC:94822-4'  loinc   FROM DUAL  UNION SELECT 'LOINC:94845-5'  loinc   FROM DUAL  UNION SELECT 'LOINC:95125-1'  loinc   FROM DUAL   UNION select 'LOINC:95209-3'  loinc
	

  FROM DUAL ),
-- Diagnosis ICD-10 codes from phenotype doc
covid_icd10 as
(SELECT 'ICD10CM:B97.21' as icd10_code,	'1_strong_positive' as dx_category  FROM DUAL  UNION SELECT 'ICD10CM:B97.29'  icd10_code,	'1_strong_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:U07.1'  icd10_code,	'1_strong_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:Z20.828'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:B34.2'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:R50%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:R05%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:R06.0%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J12%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J18%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J20%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J40%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J21%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J96%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J22%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J06.9'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J98.8'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J80%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:R43.0'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:R43.2'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:R07.1'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL   UNION select 'ICD10CM:R68.83'  icd10_code,	'2_weak_positive' as dx_category 
  FROM DUAL ),
-- procedure codes from phenotype doc
covid_proc_codes as
(SELECT 'HCPCS:U0001' as procedure_code  FROM DUAL  UNION SELECT 'HCPCS:U0002'  procedure_code   FROM DUAL  UNION SELECT 'CPT4:87635'  procedure_code   FROM DUAL  UNION SELECT 'CPT4:86318'  procedure_code   FROM DUAL  UNION SELECT 'CPT4:86328'  procedure_code   FROM DUAL   UNION select 'CPT4:86769'  procedure_code
  FROM DUAL ),
-- patients with covid related lab since start_date
-- if using i2b2 multi-fact table please substitute 'obseravation_fact' with appropriate fact view
covid_lab as
(SELECT distinct observation_fact.patient_num
    FROM @cdmDatabaseSchema.observation_fact
      WHERE observation_fact.start_date >= CAST('2020-01-01' as TIMESTAMP)
        and 
        (
            observation_fact.concept_cd in (SELECT loinc FROM covid_loinc )
        )
 ),
-- patients with covid related diagnosis since start_date
-- if using i2b2 multi-fact table please substitute 'observation_fact' with appropriate fact view
covid_diagnosis as
(SELECT dxq.*,
      start_date as best_dx_date,  -- use for later queries
        -- custom dx_category for one ICD-10 code, see phenotype doc
		case
			when dx in ('ICD10CM:B97.29','ICD10CM:B97.21') and start_date < CAST('2020-04-01' as TIMESTAMP)  then '1_strong_positive'
			when dx in ('ICD10CM:B97.29','ICD10CM:B97.21') and start_date >= CAST('2020-04-01' as TIMESTAMP) then '2_weak_positive'
			else dxq.orig_dx_category
		end as dx_category        
    FROM (SELECT observation_fact.patient_num,
            observation_fact.encounter_num,
            observation_fact.concept_cd dx,
            observation_fact.start_date,
            covid_icd10.dx_category as orig_dx_category
        FROM @cdmDatabaseSchema.observation_fact
            join covid_icd10 on observation_fact.concept_cd like covid_icd10.icd10_code
          WHERE observation_fact.start_date >= CAST('2020-01-01' as TIMESTAMP)
     ) dxq
 ),
-- patients with strong positive DX included
dx_strong as
(SELECT distinct
        patient_num
    FROM covid_diagnosis
      WHERE dx_category='1_strong_positive'    
        
 ),
-- patients with two different weak DX in same encounter and/or on same date included
dx_weak as
(SELECT distinct patient_num FROM (SELECT patient_num,
            encounter_num,
            count(*) as dx_count
        FROM (SELECT distinct
                patient_num, encounter_num, dx
            FROM covid_diagnosis
              WHERE dx_category='2_weak_positive'
         ) subq
        group by
            patient_num,
            encounter_num
        having
            count(*) >= 2
     ) dx_same_encounter
    
      UNION
    
    -- or two different DX on same date
    select distinct patient_num FROM (SELECT patient_num,
            best_dx_date,
            count(*) as dx_count
        FROM (SELECT distinct
                patient_num, best_dx_date, dx
            FROM covid_diagnosis
              WHERE dx_category='2_weak_positive'
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
covid_procedure as
(SELECT distinct observation_fact.patient_num
    FROM @cdmDatabaseSchema.observation_fact
      WHERE observation_fact.start_date >=  CAST('2020-01-01' as TIMESTAMP)
        and observation_fact.concept_cd in (SELECT procedure_code FROM covid_proc_codes )

 ),
covid_cohort as
(SELECT distinct patient_num FROM dx_strong
      UNION
    SELECT distinct patient_num FROM dx_weak
      UNION
    SELECT distinct patient_num FROM covid_procedure
      UNION
    select distinct patient_num FROM covid_lab
 ),
n3c_cohort as
(SELECT covid_cohort.patient_num,
        case when dx_strong.patient_num is not null then 1 else 0 end as inc_dx_strong,
        case when dx_weak.patient_num is not null then 1 else 0 end as inc_dx_weak,
        case when covid_procedure.patient_num is not null then 1 else 0 end as inc_procedure,
        case when covid_lab.patient_num is not null then 1 else 0 end as inc_lab
	FROM covid_cohort
		left outer join dx_strong on covid_cohort.patient_num = dx_strong.patient_num
		left outer join dx_weak on covid_cohort.patient_num = dx_weak.patient_num
		left outer join covid_procedure on covid_cohort.patient_num = covid_procedure.patient_num
		left outer join covid_lab on covid_cohort.patient_num = covid_lab.patient_num

 )
select * into 
@resultsDatabaseSchema.n3c_cohort 
from n3c_cohort
