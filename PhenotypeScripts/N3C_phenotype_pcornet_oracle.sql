--N3C covid-19 phenotype, PCORnet CDM
--N3C phenotype V2.1

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
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE @resultsDatabaseSchema.n3c_cohort';
  EXECUTE IMMEDIATE 'DROP TABLE @resultsDatabaseSchema.n3c_cohort';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
  
  
-- Create dest table
CREATE TABLE @resultsDatabaseSchema.n3c_cohort (
	patid			VARCHAR(50)  NOT NULL,
	inc_dx_strong		INT  NOT NULL,
	inc_dx_weak			INT  NOT NULL,
	inc_lab				INT  NOT NULL,
	exc_dx_asymp        INT  NOT NULL,
	phenotype_version 		VARCHAR(10)
);
  

-- Lab LOINC codes from phenotype doc
INSERT INTO @resultsDatabaseSchema.n3c_cohort 
 WITH covid_loinc  AS (SELECT '94307-6' as loinc  FROM DUAL  UNION SELECT '94308-4'  loinc   FROM DUAL  UNION SELECT '94309-2'  loinc   FROM DUAL  UNION SELECT '94311-8'  loinc   FROM DUAL  UNION SELECT '94312-6'  loinc   FROM DUAL  UNION SELECT '94314-2'  loinc   FROM DUAL  UNION SELECT '94316-7'  loinc   FROM DUAL  UNION SELECT '94500-6'  loinc   FROM DUAL  UNION SELECT '94505-5'  loinc   FROM DUAL  UNION SELECT '94506-3'  loinc   FROM DUAL  UNION SELECT '94507-1'  loinc   FROM DUAL  UNION SELECT '94508-9'  loinc   FROM DUAL  UNION SELECT '94510-5'  loinc   FROM DUAL  UNION SELECT '94511-3'  loinc   FROM DUAL  UNION SELECT '94533-7'  loinc   FROM DUAL  UNION SELECT '94534-5'  loinc   FROM DUAL  UNION SELECT '94547-7'  loinc   FROM DUAL  UNION SELECT '94558-4'  loinc   FROM DUAL  UNION SELECT '94559-2'  loinc   FROM DUAL  UNION SELECT '94562-6'  loinc   FROM DUAL  UNION SELECT '94563-4'  loinc   FROM DUAL  UNION SELECT '94564-2'  loinc   FROM DUAL  UNION SELECT '94565-9'  loinc   FROM DUAL  UNION SELECT '94639-2'  loinc   FROM DUAL  UNION SELECT '94640-0'  loinc   FROM DUAL  UNION SELECT '94641-8'  loinc   FROM DUAL  UNION SELECT '94642-6'  loinc   FROM DUAL  UNION SELECT '94643-4'  loinc   FROM DUAL  UNION SELECT '94644-2'  loinc   FROM DUAL  UNION SELECT '94645-9'  loinc   FROM DUAL  UNION SELECT '94646-7'  loinc   FROM DUAL  UNION SELECT '94660-8'  loinc   FROM DUAL  UNION SELECT '94661-6'  loinc   FROM DUAL  UNION SELECT '94306-8'  loinc   FROM DUAL  UNION SELECT '94503-0'  loinc   FROM DUAL  UNION SELECT '94504-8'  loinc   FROM DUAL  UNION SELECT '94531-1'  loinc   FROM DUAL  UNION SELECT '94720-0'  loinc   FROM DUAL  UNION SELECT '94759-8'  loinc   FROM DUAL  UNION SELECT '94760-6'  loinc   FROM DUAL  UNION SELECT '94762-2'  loinc   FROM DUAL  UNION SELECT '94763-0'  loinc   FROM DUAL  UNION SELECT '94764-8'  loinc   FROM DUAL  UNION SELECT '94766-3'  loinc   FROM DUAL  UNION SELECT '94767-1'  loinc   FROM DUAL  UNION SELECT '94768-9'  loinc   FROM DUAL  UNION SELECT '94769-7'  loinc   FROM DUAL  UNION SELECT '94819-0'  loinc   FROM DUAL  UNION SELECT '94745-7'  loinc   FROM DUAL  UNION SELECT '94746-5'  loinc   FROM DUAL  UNION SELECT '94756-4'  loinc   FROM DUAL  UNION SELECT '94757-2'  loinc   FROM DUAL  UNION SELECT '94761-4'  loinc   FROM DUAL  UNION SELECT '94822-4'  loinc   FROM DUAL  UNION SELECT '94845-5'  loinc   FROM DUAL  UNION SELECT '95125-1'  loinc   FROM DUAL  UNION SELECT '95406-5'  loinc   FROM DUAL  UNION SELECT '95409-9'  loinc   FROM DUAL  UNION SELECT '95410-7'  loinc   FROM DUAL   UNION select '95411-5'  loinc	
  FROM DUAL UNION select '95416-4' as loinc FROM DUAL UNION  select '95424-8' as loinc FROM DUAL UNION  select '95425-5' as loinc FROM DUAL UNION  select '95427-1' as loinc FROM DUAL UNION  select '95428-9' as loinc FROM DUAL UNION  select '95429-7' as loinc FROM DUAL UNION  select '95521-1' as loinc FROM DUAL UNION  select '95522-9' as loinc FROM DUAL
),

 --The ways that your site describes a positive COVID test
covid_pos_list as (SELECT 'POSITIVE' as word FROM DUAL UNION SELECT 'DETECTED' as word from DUAL),
 
-- Diagnosis ICD-10/SNOMED codes from phenotype doc
covid_dx_codes as
(SELECT 'Z11.59' as dx_code,'asymptomatic' as dx_category  FROM DUAL  UNION SELECT 'B97.21' as dx_code,	'dx_strong_positive' as dx_category  FROM DUAL  UNION SELECT 'B97.29'  dx_code,	'dx_strong_positive' as dx_category   FROM DUAL  UNION SELECT 'U07.1'  dx_code,	'dx_strong_positive' as dx_category   FROM DUAL  UNION SELECT 'Z20.828'  dx_code,'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'B34.2'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'R50%'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'R05%'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'R06.0%'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'J12%'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'J18%'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'J20%'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'J40%'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'J21%'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'J96%'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'J22%'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'J06.9'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'J98.8'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'J80%'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'R43.0'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'R43.2'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'R07.1'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT 'R68.83'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '840539006'  dx_code,	'dx_strong_positive' as dx_category   FROM DUAL  UNION SELECT '840544004'  dx_code,	'dx_strong_positive' as dx_category   FROM DUAL  UNION SELECT '840546002'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '103001002'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '11833005'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '267036007'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '28743005'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '36955009'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '426000000'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '44169009'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '49727002'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '135883003'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '161855003'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '161939006'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '161940008'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '161941007'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '2237002'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '23141003'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '247410004'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '274640006'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '274664007'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '284523002'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '386661006'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '409702008'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '426976009'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '43724002'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL  UNION SELECT '60845006'  dx_code,	'dx_weak_positive' as dx_category   FROM DUAL   UNION select '75483001'  dx_code,	'dx_weak_positive' as dx_category
  FROM DUAL ),
  
-- patients with covid related lab since start_date
covid_lab as
(SELECT distinct
        lab_result_cm.patid
    FROM @cdmDatabaseSchema.lab_result_cm
      WHERE lab_result_cm.result_date >= CAST('01-JAN-2020' as TIMESTAMP)
        and 
        (
            lab_result_cm.lab_loinc in (SELECT loinc FROM covid_loinc )
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
      WHERE lab_result_cm.result_date >= CAST('01-JAN-2020' as TIMESTAMP)
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
(SELECT dxq.*,
        coalesce(dx_date,admit_date) as best_dx_date,  -- use for later queries
        -- custom dx_category for one ICD-10 code, see phenotype doc
		case
			when dx in ('B97.29','B97.21') and coalesce(dx_date,admit_date) < CAST('01-APR-2020' as TIMESTAMP)  then 'dx_strong_positive'
			when dx in ('B97.29','B97.21') and coalesce(dx_date,admit_date) >= CAST('01-APR-2020' as TIMESTAMP) then 'dx_weak_positive'
			else dxq.orig_dx_category
		end as dx_category        
    FROM (SELECT diagnosis.patid,
            diagnosis.encounterid,
            diagnosis.dx,
            diagnosis.admit_date,
            diagnosis.dx_date,
            covid_dx_codes.dx_category as orig_dx_category
        FROM @cdmDatabaseSchema.diagnosis
           join covid_dx_codes on diagnosis.dx like covid_dx_codes.dx_code
          WHERE coalesce(dx_date,admit_date) >= CAST('01-JAN-2020' as TIMESTAMP)
     ) dxq
 ),
 
-- patients with strong positive DX included
dx_strong as
(SELECT distinct
        patid
    FROM covid_diagnosis
      WHERE dx_category='dx_strong_positive'           
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
        JOIN covid_lab on cda.patid = covid_lab.patid and cda.dx_category='asymptomatic' and cda.best_dx_date >= '01-APR-2020'
        LEFT JOIN covid_diagnosis cds ON cda.patid = cds.patid AND cds.dx_category='dx_strong_positive'
        LEFT JOIN covid_lab_pos cpl ON cda.patid = cpl.patid
     WHERE     
        cds.patid is null AND cpl.patid is null
 ),
 
-- patients with two different weak DX in same encounter and/or on same date included
dx_weak as
(SELECT distinct patid FROM (SELECT patid,
            encounterid,
            count(*) as dx_count
        FROM (SELECT distinct
                patid, encounterid, dx
            FROM covid_diagnosis
              WHERE dx_category='dx_weak_positive' and best_dx_date <= '01-MAY-2020'
         ) subq
        group by
            patid,
            encounterid
        having
            count(*) >= 2
     ) dx_same_encounter
    
      UNION
    
    -- or two different DX on same date
    select distinct patid FROM (SELECT patid,
            best_dx_date,
            count(*) as dx_count
        FROM (SELECT distinct
                patid, best_dx_date, dx
            FROM covid_diagnosis
              WHERE dx_category='dx_weak_positive' and best_dx_date <= '01-MAY-2020'
         ) subq
        group by
            patid,
            best_dx_date
        having
            count(*) >= 2
     ) dx_same_date
 ),

covid_cohort as
(SELECT distinct patid FROM dx_strong
      UNION
    SELECT distinct patid FROM dx_weak
      UNION
    select distinct patid FROM covid_lab
     UNION
    select distinct patid FROM dx_asymp
 ),
 
cohort as
(SELECT covid_cohort.patid,
	case when dx_strong.patid is not null then 1 else 0 end as inc_dx_strong,
	case when dx_weak.patid is not null then 1 else 0 end as inc_dx_weak,
	case when covid_lab.patid is not null then 1 else 0 end as inc_lab,
	case when dx_asymp.patid is not null then 1 else 0 end as exc_dx_asymp
FROM covid_cohort
	left outer join dx_strong on covid_cohort.patid = dx_strong.patid
	left outer join dx_weak on covid_cohort.patid = dx_weak.patid
	left outer join covid_lab on covid_cohort.patid = covid_lab.patid
	left outer join dx_asymp on covid_cohort.patid = dx_asymp.patid
 )


SELECT patid, inc_dx_strong, inc_dx_weak, inc_lab, exc_dx_asymp, '2.2' as phenotype_version
FROM cohort 
where exc_dx_asymp = 0;
