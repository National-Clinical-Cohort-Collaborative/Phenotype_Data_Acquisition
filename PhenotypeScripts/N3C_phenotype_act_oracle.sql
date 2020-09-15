--N3C covid-19 phenotype, ACT/i2b2, MS SQL Server
--N3C phenotype V2.2
--Modified Marshall's code to fit ACT
--04.29.2020 Michele Morris hardcode variables, comment where multifact table i2b2s need to change table name
--05.01.2020 Michele Morris add create table
--05.15.2020 Emily Pfaff converted to SQL Server
--05.27.2020 Michele Morris added 1.5 loincs
--06.16.2020 Michele Morris added 1.6 loincs
--07.08.2020 Adapted Emily Pfaff's Phenotype 2.0 for ACT
--Significant changes from V1:
--Weak diagnoses no longer checked after May 1, 2020
--Added asymptomatic test code (Z11.59) to diagnosis list
--Added new temp table definition "dx_asymp" to capture asymptomatic test patients who got that code after April 1, 2020, 
--  had a covid lab (regardless of result), and doesnt have a strong dx
--Added new temp table covid_lab_pos to capture positive lab tests
--Added a column to the n3c_cohort table to capture the exc_dx_asymp flag
--Added a column to the final select statement to populate that field
--Added a WHERE to the final select to exclude asymptomatic patients
--Added V2.1 LOINCs 8/11/2020
--Removed procedures
--Added phenotype version for manifest table

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
 
-- Create dest table -- cohort table 44,086 rows inserted. before 43,953 rows inserted no weak after may 1 remove asymptomatic negative test takers 21415

CREATE TABLE @resultsDatabaseSchema.n3c_cohort (
	patient_num			VARCHAR(50)  NOT NULL,
	inc_dx_strong		INT  NOT NULL,
	inc_dx_weak			INT  NOT NULL,
	inc_lab				INT  NOT NULL,
	exc_dx_asymp        INT  NOT NULL,
    phenotype_version 	VARCHAR2(10)
);



-- Lab LOINC codes from phenotype doc
INSERT INTO @resultsDatabaseSchema.n3c_cohort 
WITH covid_loinc  AS (SELECT 'LOINC:94307-6' as loinc  FROM DUAL  UNION SELECT 'LOINC:94308-4'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94309-2'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94311-8'  loinc FROM DUAL  
		       UNION SELECT 'LOINC:94312-6'  loinc   FROM DUAL    
		       UNION SELECT 'LOINC:94314-2'  loinc   FROM DUAL    
		       UNION SELECT 'LOINC:94316-7'  loinc   FROM DUAL  UNION SELECT 'LOINC:94500-6'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94505-5'  loinc   FROM DUAL 
		       UNION SELECT 'LOINC:94506-3'  loinc   FROM DUAL  UNION SELECT 'LOINC:94507-1'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94510-5'  loinc   FROM DUAL  UNION SELECT 'LOINC:94511-3'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94533-7'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94534-5'  loinc   FROM DUAL  UNION SELECT 'LOINC:94547-7'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94558-4'  loinc   FROM DUAL  UNION SELECT 'LOINC:94559-2'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94562-6'  loinc   FROM DUAL  UNION SELECT 'LOINC:94563-4'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94564-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94565-9'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94639-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94640-0'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94641-8'  loinc   FROM DUAL  UNION SELECT 'LOINC:94642-6'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94643-4'  loinc   FROM DUAL  UNION SELECT 'LOINC:94644-2'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94645-9'  loinc   FROM DUAL  UNION SELECT 'LOINC:94646-7'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94660-8'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94661-6'  loinc   FROM DUAL  UNION SELECT 'UMLS:C1611271'  loinc   FROM DUAL  
		       UNION SELECT 'UMLS:C1335447'  loinc   FROM DUAL  UNION SELECT 'UMLS:C1334932'  loinc   FROM DUAL  
		       UNION SELECT 'UMLS:C1334932'  loinc   FROM DUAL  UNION SELECT 'UMLS:C1335447'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94720-0'  loinc   FROM DUAL    
		       UNION SELECT 'LOINC:94759-8'  loinc   FROM DUAL  UNION SELECT 'LOINC:94760-6'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94762-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94763-0'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94764-8'  loinc   FROM DUAL    
		       UNION SELECT 'LOINC:94766-3'  loinc   FROM DUAL  UNION SELECT 'LOINC:94767-1'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94768-9'  loinc   FROM DUAL  UNION SELECT 'LOINC:94769-7'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94819-0'  loinc   FROM DUAL  UNION SELECT 'LOINC:94745-7'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94746-5'  loinc   FROM DUAL  UNION SELECT 'LOINC:94756-4'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94757-2'  loinc   FROM DUAL  UNION SELECT 'LOINC:94761-4'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:94822-4'  loinc   FROM DUAL  UNION SELECT 'LOINC:94845-5'  loinc   FROM DUAL  
		       UNION SELECT 'LOINC:95125-1'  loinc   FROM DUAL   
		       UNION SELECT 'LOINC:95406-5' AS LOINC FROM DUAL  
		       UNION SELECT 'LOINC:95410-7' AS LOINC FROM DUAL UNION SELECT 'LOINC:95411-5' AS LOINC FROM DUAL 
               UNION SELECT 'LOINC:94307-6' as loinc  FROM DUAL  UNION SELECT 'LOINC:95416-4' as loinc  FROM DUAL  UNION
               SELECT 'LOINC:95424-8' as loinc  FROM DUAL  UNION SELECT 'LOINC:95425-5' as loinc  FROM DUAL  UNION
               SELECT 'LOINC:95427-1' as loinc  FROM DUAL  UNION SELECT 'LOINC:95428-9' as loinc  FROM DUAL  UNION
               SELECT 'LOINC:95429-7' as loinc  FROM DUAL  UNION SELECT 'LOINC:95521-1' as loinc  FROM DUAL  UNION
               SELECT 'LOINC:95522-9' as loinc  FROM DUAL  
),
-- Diagnosis ICD-10 codes from phenotype doc
covid_dx_codes as
(SELECT 'ICD10CM:Z11.59' as dx_code,'asymptomatic' as dx_category  FROM DUAL UNION SELECT 'ICD10CM:B97.21' as icd10_code,	'1_strong_positive' as dx_category  FROM DUAL  UNION SELECT 'ICD10CM:B97.29'  icd10_code,	'1_strong_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:U07.1'  icd10_code,	'1_strong_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:Z20.828'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:B34.2'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:R50%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:R05%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:R06.0%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J12%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J18%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J20%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J40%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J21%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J96%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J22%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J06.9'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J98.8'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:J80%'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:R43.0'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:R43.2'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'ICD10CM:R07.1'  icd10_code,	'2_weak_positive' as dx_category   FROM DUAL   UNION select 'ICD10CM:R68.83'  icd10_code,	'2_weak_positive' as dx_category 
  FROM DUAL ),
-- patients with covid related lab since start_date
-- if using i2b2 multi-fact table please substitute 'obseravation_fact' with appropriate fact view
covid_lab as
(SELECT distinct observation_fact.patient_num
    FROM @cdmDatabaseSchema.observation_fact
      WHERE observation_fact.start_date >= CAST('01-JAN-2020' as TIMESTAMP)
        and 
        (
            observation_fact.concept_cd in (SELECT loinc FROM covid_loinc )
        )
 ),

--MAPPING POSITIVE LAB VALUES
--patients with positive covid lab test
--Option #1
covid_lab_pos as
(SELECT 
    distinct OBSERVATION_FACT.PATIENT_NUM
    FROM @cdmDatabaseSchema.OBSERVATION_FACT 
    	WHERE OBSERVATION_FACT.START_DATE >= CAST('01-JAN-2020' as TIMESTAMP) AND  
	(OBSERVATION_FACT.CONCEPT_CD like 'LOINC:% POSITIVE'
		OR OBSERVATION_FACT.CONCEPT_CD = 'UMLS:C1335447' 
		OR OBSERVATION_FACT.CONCEPT_CD = 'ACT|LOCAL|LAB:ANY POSITIVE ANTIBODY TEST')
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
--        AND OBSERVATION_FACT.START_DATE >= CAST('01-JAN-2020' as TIMESTAMP) 
--),

-- patients with covid related diagnosis since start_date
-- if using i2b2 multi-fact table please substitute 'observation_fact' with appropriate fact view
covid_diagnosis as
(SELECT dxq.*,
      start_date as best_dx_date,  -- use for later queries
        -- custom dx_category for one ICD-10 code, see phenotype doc
		case
			when dx in ('ICD10CM:B97.29','ICD10CM:B97.21') and start_date < CAST('01-APR-2020' as TIMESTAMP)  then '1_strong_positive'
			when dx in ('ICD10CM:B97.29','ICD10CM:B97.21') and start_date >= CAST('01-APR-2020' as TIMESTAMP) then '2_weak_positive'
			else dxq.orig_dx_category
		end as dx_category        
    FROM (SELECT observation_fact.patient_num,
            observation_fact.encounter_num,
            observation_fact.concept_cd dx,
            observation_fact.start_date,
            covid_dx_codes.dx_category as orig_dx_category
        FROM @cdmDatabaseSchema.observation_fact
            join covid_dx_codes on observation_fact.concept_cd like covid_dx_codes.dx_code

            --join covid_icd10 on observation_fact.concept_cd like covid_icd10.icd10_code
          WHERE observation_fact.start_date >= CAST('01-JAN-2020' as TIMESTAMP)
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
              WHERE dx_category='2_weak_positive' and best_dx_date <= '01-MAY-2020'
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
              WHERE dx_category='2_weak_positive' and best_dx_date <= '01-MAY-2020'
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
(SELECT distinct patient_num FROM dx_strong
      UNION
    SELECT distinct patient_num FROM dx_weak
      UNION
    select distinct patient_num FROM covid_lab
    UNION
    select distinct patient_num FROM dx_asymp
 ),
n3c_cohort as
(SELECT covid_cohort.patient_num,
        case when dx_strong.patient_num is not null then 1 else 0 end as inc_dx_strong,
        case when dx_weak.patient_num is not null then 1 else 0 end as inc_dx_weak,
        case when covid_lab.patient_num is not null then 1 else 0 end as inc_lab,
        case when dx_asymp.patient_num is not null then 1 else 0 end as exc_dx_asymp

	FROM covid_cohort
		left outer join dx_strong on covid_cohort.patient_num = dx_strong.patient_num
		left outer join dx_weak on covid_cohort.patient_num = dx_weak.patient_num
		left outer join covid_lab on covid_cohort.patient_num = covid_lab.patient_num
        left outer join dx_asymp on covid_cohort.patient_num = dx_asymp.patient_num
 )

SELECT patient_num, inc_dx_strong, inc_dx_weak, inc_lab, exc_dx_asymp, '2.2' as phenotype_version
FROM n3c_cohort
where exc_dx_asymp = 0
 ;
