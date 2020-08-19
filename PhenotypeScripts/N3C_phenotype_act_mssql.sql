--N3C covid-19 phenotype, ACT/i2b2, MS SQL Server
--N3C phenotype V2.1
--Modified Marshall's code to fit ACT
--04.29.2020 Michele Morris hardcode variables, comment where multifact table i2b2s need to change table name
--05.01.2020 Michele Morris add create table
--05.15.2020 Emily Pfaff converted to SQL Server
--05.27.2020 Michele Morris added 1.5 loincs
--07.08.2020 Adapted Emily Pfaff's Phenotype 2.0 for ACT
--Significant changes from V1:
--THE PHENOTYPE NEEDS TO KNOW HOW YOU CODE COVID POSITIVE CASES
--Weak diagnoses no longer checked after May 1, 2020
--Added asymptomatic test code (Z11.59) to diagnosis list
--Added new temp table definition "dx_asymp" to capture asymptomatic test patients who got that code after April 1, 2020, 
--  had a covid lab (regardless of result), and doesnt have a strong dx
--Added new temp table covid_lab_pos to capture positive lab tests
--Added new temp table covid_pos_list to capture a given site's definition of positive
--Added a column to the n3c_cohort table to capture the exc_dx_asymp flag
--Added a column to the final select statement to populate that field
--Added a WHERE to the final select to exclude asymptomatic patients
--Code assumes that COVID Labs are coded per the ACT Guidance https://github.com/shyamvis/ACT-COVID-Ontology/blob/master/ontology/ExampleStepsForMappingLabs.md
--Added V2.1 LOINCs 8/11/2020
--Removed procedures
--Added phenotype version for manifest table
--Merge path based with hard coded concepts


--DROP TABLE IF EXISTS @resultsDatabaseSchema.n3c_cohort; 
IF OBJECT_ID('@resultsDatabaseSchema.n3c_cohort', 'U') IS NOT NULL          -- Drop table if it exists
  DROP TABLE @resultsDatabaseSchema.n3c_cohort;
  
   
-- Create dest table
CREATE TABLE @resultsDatabaseSchema.n3c_cohort (
	patient_num			VARCHAR(50)  NOT NULL,
	inc_dx_strong		INT  NOT NULL,
	inc_dx_weak			INT  NOT NULL,
	inc_procedure		INT  NOT NULL,
	inc_lab				INT  NOT NULL,
    	dx_asymp            INT  NOT NULL,
	phenotype_version 	VARCHAR(10)
);


-- This script assumes you have coded your COVID Positive lab values per the ACT guidance 
--https://github.com/shyamvis/ACT-COVID-Ontology/blob/master/ontology/ExampleStepsForMappingLabs.md
--
-- Lab LOINC codes from phenotype doc
with covid_loinc as
(
	select 'LOINC:94307-6' as loinc UNION
	select 'LOINC:94308-4' as loinc UNION
	select 'LOINC:94309-2' as loinc UNION
	select 'LOINC:94310-0' as loinc UNION
	select 'LOINC:94311-8' as loinc UNION
	select 'LOINC:94312-6' as loinc UNION
	select 'LOINC:94313-4' as loinc UNION
	select 'LOINC:94314-2' as loinc UNION
	select 'LOINC:94315-9' as loinc UNION
	select 'LOINC:94316-7' as loinc UNION
	select 'LOINC:94500-6' as loinc UNION
	select 'LOINC:94502-2' as loinc UNION
	select 'LOINC:94505-5' as loinc UNION
	select 'LOINC:94506-3' as loinc UNION
	select 'LOINC:94507-1' as loinc UNION
	select 'LOINC:94508-9' as loinc UNION
	select 'LOINC:94509-7' as loinc UNION
	select 'LOINC:94510-5' as loinc UNION
	select 'LOINC:94511-3' as loinc UNION
	select 'LOINC:94532-9' as loinc UNION
	select 'LOINC:94533-7' as loinc UNION
	select 'LOINC:94534-5' as loinc UNION
	select 'LOINC:94547-7' as loinc UNION
	select 'LOINC:94558-4' as loinc UNION
	select 'LOINC:94559-2' as loinc UNION
	select 'LOINC:94562-6' as loinc UNION
	select 'LOINC:94563-4' as loinc UNION
	select 'LOINC:94564-2' as loinc UNION
	select 'LOINC:94565-9' as loinc UNION
	select 'LOINC:94639-2' as loinc UNION
	select 'LOINC:94640-0' as loinc UNION
	select 'LOINC:94641-8' as loinc UNION
	select 'LOINC:94642-6' as loinc UNION
	select 'LOINC:94643-4' as loinc UNION
	select 'LOINC:94644-2' as loinc UNION
	select 'LOINC:94645-9' as loinc UNION
	select 'LOINC:94646-7' as loinc UNION
	select 'LOINC:94647-5' as loinc UNION
	select 'LOINC:94660-8' as loinc UNION
	select 'LOINC:94661-6' as loinc UNION
    select 'UMLS:C1611271' as loinc UNION --ACT_COVID ontology terms
    select 'UMLS:C1335447' as loinc UNION
    select 'UMLS:C1334932' as loinc UNION
    select 'UMLS:C1334932' as loinc UNION
    select 'UMLS:C1335447' as loinc UNION
	select 'LOINC:94720-0' as loinc UNION
	select 'LOINC:94758-0' as loinc UNION
	select 'LOINC:94759-8' as loinc UNION
	select 'LOINC:94760-6' as loinc UNION
	select 'LOINC:94762-2' as loinc UNION
	select 'LOINC:94763-0' as loinc UNION
	select 'LOINC:94764-8' as loinc UNION
	select 'LOINC:94765-5' as loinc UNION
	select 'LOINC:94766-3' as loinc UNION
	select 'LOINC:94767-1' as loinc UNION
	select 'LOINC:94768-9' as loinc UNION
	select 'LOINC:94769-7' as loinc UNION
	select 'LOINC:94819-0' as loinc UNION
	-- new for v1.5
	select 'LOINC:94745-7' as loinc UNION    
	select 'LOINC:94746-5' as loinc UNION    
	select 'LOINC:94756-4' as loinc UNION    
	select 'LOINC:94757-2' as loinc UNION    
	select 'LOINC:94761-4' as loinc UNION    
	select 'LOINC:94822-4' as loinc UNION    
	select 'LOINC:94845-5' as loinc UNION    
	select 'LOINC:95125-1' as loinc UNION    
	select 'LOINC:95209-3' as loinc UNION
	-- new for v1.6
	SELECT 'LOINC:95406-5' AS LOINC UNION 
	SELECT 'LOINC:95409-9' AS LOINC UNION 
	SELECT 'LOINC:95410-7' AS LOINC UNION 
	SELECT 'LOINC:95411-5' AS LOINC UNION
	-- new for v2.1
	select 'LOINC:95416-4' as loinc UNION    
	select 'LOINC:95424-8' as loinc UNION    
	select 'LOINC:95425-5' as loinc UNION    
	select 'LOINC:95427-1' as loinc UNION    
	select 'LOINC:95428-9' as loinc UNION    
	select 'LOINC:95429-7' as loinc UNION    
	select 'LOINC:95521-1' as loinc UNION    
	select 'LOINC:95522-9' as loinc UNION
    
    --Path based
    SELECT CONCEPT_CD as loinc FROM CONCEPT_DIMENSION 
        WHERE (CONCEPT_PATH LIKE '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0022885\%' 
              AND CONCEPT_PATH NOT LIKE '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0022885\UMLS_C0086143\%') 
),
-- Diagnosis ICD-10 codes from phenotype doc
early_dx as 
(
SELECT 'ICD10CM:B97.21' as icd10_code, '1_strong_positive' as dx_category FROM DUAL  
UNION SELECT 'ICD10CM:B97.29' as icd10_code, '1_strong_positive' as dx_category FROM DUAL 
UNION SELECT CONCEPT_CD as icd10_code, '1_strong_positive' as dx_category FROM CONCEPT_DIMENSION  
        WHERE CONCEPT_PATH = '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18905737\A18908307\A17799167\A17824942\A17850346\'
UNION SELECT CONCEPT_CD  icd10_code, '1_strong_positive' as dx_category FROM CONCEPT_DIMENSION  
        WHERE CONCEPT_PATH = '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18905737\A18908307\A17799167\A17824942\A17773639\'
),
covid_dx_path as
(
SELECT icd10_code, dx_category from early_dx
UNION SELECT CONCEPT_CD as icd10_code, 'asymptomatic' as dx_category  FROM CONCEPT_DIMENSION WHERE CONCEPT_PATH = '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18916190\A18918864\A17785940\A17837149\A17837150\'
UNION SELECT CONCEPT_CD as icd10_code,	'1_strong_positive' as dx_category  FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH = '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18905737\A18908307\A17799167\A17824942\A17850346\'
UNION SELECT CONCEPT_CD  icd10_code,	'1_strong_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH = '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18905737\A18908307\A17799167\A17824942\A17773639\'
UNION SELECT CONCEPT_CD  icd10_code,	'1_strong_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH = '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0037088\SNOMED_3947183016\ICD10CM_U07.1\'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH = '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18916190\A27153708\A17837157\A17849894\A17811595\A17862489\'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH LIKE '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18905737\A18916203\A17786353\A17799079\'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH LIKE '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18919275\A18924508\A17816202\%'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH LIKE '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18919275\A18921837\A17867137\%'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH LIKE '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18919275\A18921837\A17790457\A17867138\%'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH LIKE '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18916341\A18919020\A17826561\%'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION WHERE CONCEPT_PATH LIKE '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18916341\A18919020\A17788101\%'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH LIKE '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18916341\A18913759\A17800859\%'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH LIKE '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18916341\A18916350\A17775366\'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH LIKE '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18916341\A18913759\A17813746\%'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH LIKE '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18916341\A18924251\A17826641\%'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH LIKE '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18916341\A18913759\A17839331\%'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH = '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18916341\A18924231\A17852005\A17864701\'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH = '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18916341\A18924251\A17800917\A17839382\'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH LIKE '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18916341\A18919034\A17800896\%'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH = '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18919275\A18906113\A17777753\A17867199\'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH = '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18919275\A18906113\A17777753\A17777754\'
UNION SELECT CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category   FROM CONCEPT_DIMENSION  WHERE CONCEPT_PATH = '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18919275\A18921837\A17828930\A17867142\'
UNION select CONCEPT_CD  icd10_code,	'2_weak_positive' as dx_category  FROM CONCEPT_DIMENSION WHERE CONCEPT_PATH = '\ACT\Diagnosis\ICD10\V2_2018AA\A20098492\A18919275\A18924508\A17829004\A17777779\A17777780\'
),
covid_dx_coded as 
(
    select icd10_code, dx_category from early_dx UNION 
    select 'ICD10CM:Z11.59' as icd10_code, 'asymptomatic' as dx_category UNION
	select 'ICD10CM:U07.1' as icd10_code,	'1_strong_positive' as dx_category UNION
	select 'ICD10CM:Z20.828' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:B34.2' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:R50%' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:R05%' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:R06.0%' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:J12%' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:J18%' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:J20%' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:J40%' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:J21%' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:J96%' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:J22%' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:J06.9' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:J98.8' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:J80%' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:R43.0' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:R43.2' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:R07.1' as icd10_code,	'2_weak_positive' as dx_category UNION
	select 'ICD10CM:R68.83' as icd10_code,	'2_weak_positive' as dx_category 
),
covid_icd10 as 
(
select icd10_code, dx_category from covid_dx_coded
union 
select icd10_code, dx_category from covid_dx_path
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
        observation_fact.start_date >= CAST('2020-01-01' as datetime)
        and 
        (
            observation_fact.concept_cd in (select loinc from covid_loinc)
        )
),

--MAPPING POSITIVE LAB VALUES
--patients with positive covid lab test
--Option #1
covid_lab_pos as
(SELECT 
    distinct OBSERVATION_FACT.PATIENT_NUM
    FROM @cdmDatabaseSchema.OBSERVATION_FACT 
    	WHERE OBSERVATION_FACT.START_DATE >= CAST('2020-01-01' as datetime) AND  
	(OBSERVATION_FACT.CONCEPT_CD like 'LOINC:% POSITIVE'
		OR OBSERVATION_FACT.CONCEPT_CD = 'UMLS:C1335447' 
		OR OBSERVATION_FACT.CONCEPT_CD = 'ACT|LOCAL|LAB:ANY POSITIVE ANTIBODY TEST'
        OR OBSERVATION_FACT.CONCEPT_CD 
            IN (SELECT CONCEPT_CD FROM CONCEPT_DIMENSION WHERE CONCEPT_PATH LIKE '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0022885\UMLS_C1335447\%')
    )
 ),
--Option #2 if you have not mapped to the ACT COVID Ontology
--Search TVAL_CHAR for your COVID labs for strings that mean Positive. YOu may need to increase the list in the 
--WHERE clause below
--covid_lab_pos as
--(SELECT 
--    DISTINCT OBSERVATION_FACT.PATIENT_NUM
--    FROM @cdmDatabaseSchema.OBSERVATION_FACT 
--	 JOIN COVID_LOINC ON LOINC = OBSERVATION_FACT.CONCEPT_CD
--       WHERE (UPPER(OBSERVATION_FACT.TVAL_CHAR) like 'POSITIVE' OR UPPER(OBSERVATION_FACT.TVAL_CHAR) LIKE 'DETECT%')
--        AND OBSERVATION_FACT.START_DATE >= CAST('2020-01-01' as datetime) 
--),



-- patients with covid related diagnosis since start_date
-- if using i2b2 multi-fact table please substitute 'observation_fact' with appropriate fact view
covid_diagnosis as
(
    select
        dxq.*,
      start_date as best_dx_date,  -- use for later queries
        -- custom dx_category for one ICD-10 code, see phenotype doc
		case
			when dx in (select icd10_code from early_dx) and start_date < CAST('2020-04-01' as datetime)  then '1_strong_positive'
			when dx in (select icd10_code from early_dx) and start_date >= CAST('2020-04-01' as datetime) then '2_weak_positive'
            when dx in (select icd10_code from asymp_dx) and start_date >= CAST('2020-04-01' as datetime) then 'asymptomatic'
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
             observation_fact.start_date >= CAST('2020-01-01' as datetime)
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
                dx_category='2_weak_positive' and best_dx_date <= CAST('2020-05-01' as datetime)
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
                dx_category='2_weak_positive' and best_dx_date <= CAST('2020-05-01' as datetime)
        ) subq
        group by
            patient_num,
            best_dx_date
        having
            count(*) >= 2
    ) dx_same_date
),
-- patients with asymptomatic DX 
-- ensure they had a covid lab, and that the code was after April 1
-- and make sure they are not in the strong positive set OR positive lab set, which overrules the asymptomatic
-- these are patients who will be EXCLUDED, not INCLUDED
dx_asymp as
(SELECT distinct
        cda.patient_num
    FROM 
        covid_diagnosis cda 
        JOIN covid_lab on cda.patient_num = covid_lab.patient_num and cda.dx_category='asymptomatic' and cda.best_dx_date >= '01-APR-2020'
        LEFT JOIN covid_diagnosis cds ON cda.patient_num = cds.patient_num AND cds.dx_category='dx_strong_positive'
        LEFT JOIN covid_lab_pos cpl ON cda.patient_num = cpl.patient_num
     WHERE     
        cds.patient_num is null AND cpl.patient_num is null
 ),
covid_cohort as
(
    select distinct patient_num from dx_strong
    UNION
    select distinct patient_num from dx_weak
    UNION
    select distinct patient_num from covid_lab
    UNION
    select distinct patient_num FROM dx_asymp
),
n3c_cohort as
(
	select
		covid_cohort.patient_num,
        case when dx_strong.patient_num is not null then 1 else 0 end as inc_dx_strong,
        case when dx_weak.patient_num is not null then 1 else 0 end as inc_dx_weak,
	case when covid_lab.patient_num is not null then 1 else 0 end as inc_lab,
        case when dx_asymp.patient_num is not null then 1 else 0 end as exc_dx_asymp

	from
		covid_cohort
		left outer join dx_strong on covid_cohort.patient_num = dx_strong.patient_num
		left outer join dx_weak on covid_cohort.patient_num = dx_weak.patient_num
		left outer join covid_lab on covid_cohort.patient_num = covid_lab.patient_num
        left outer join dx_asymp on covid_cohort.patient_num = dx_asymp.patient_num


)

INSERT INTO  @resultsDatabaseSchema.n3c_cohort 
SELECT patient_num, inc_dx_strong, inc_dx_weak, inc_lab, '2.1' as phenotype_version
from n3c_cohort
where exc_dx_asymp = 0
;
