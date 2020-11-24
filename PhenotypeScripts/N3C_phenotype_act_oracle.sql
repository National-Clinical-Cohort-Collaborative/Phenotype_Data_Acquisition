--Phenotype 3.0
--ACT
--This script was tested with the following indexes and observation_fact partitioned on concept_cd
--CONCEPT_DIMENSION 
-- CONCEPT_CD
-- CONCEPT_PATH
-- CONCEPT_PATH, CONCEPT_CD
-- NAME_CHAR

--OBSERVATION_FACT
-- CONCEPT_CD
-- CONCEPT_CD, ENCOUNTER_NUM, INSTANCE_NUM, START_DATE, PROVIDER_ID, PATIENT_NUM
-- CONCEPT_CD, INSTANCE_NUM, PATIENT_NUM, ENCOUNTER_NUM
-- CONCEPT_CD, START_DATE, PATIENT_NUM
-- ENCOUNTER_NUM, CONCEPT_CD, START_DATE
-- ENCOUNTER_NUM, INSTANCE_NUM, CONCEPT_CD, START_DATE, PROVIDER_ID, PATIENT_NUM
-- LOCATION_CD
-- MODIFIER_CD, CONCEPT_CD, PATIENT_NUM
-- PATIENT_NUM
-- PATIENT_NUM, START_DATE, CONCEPT_CD, ENCOUNTER_NUM
-- START_DATE, CONCEPT_CD, PATIENT_NUM

--PATIENT_DIMENSION
-- BIRTH_DATE
-- BIRTH_DATE, PATIENT_NUM
-- PATIENT_NUM
-- PATIENT_NUM, BIRTH_DATE

-- It ran in 12sec  against approx 175k mart yielding approx 21k cases/42k controls on Oracle
-- This script assumes you have coded your COVID lab values per the ACT guidance 
-- https://github.com/shyamvis/ACT-COVID-Ontology/blob/master/ontology/ExampleStepsForMappingLabs.md
-- This script SELECTed ICD10CM directly from the fact table. If your ICD10CM prefix is not ICD10CM: 
--   please edit script accrdingly


--Create table to hold all cases and controls before matching
CREATE TABLE N3C_PRE_COHORT (
	patid			VARCHAR(50)  NOT NULL,
	inc_dx_strong		INT  NOT NULL,
	inc_dx_weak			INT  NOT NULL,
	inc_lab_any				INT  NOT NULL,
	inc_lab_pos       INT  NOT NULL,
	phenotype_version 		VARCHAR(10),
	pt_age              VARCHAR(20),
    sex                 VARCHAR(20),
    hispanic           VARCHAR(20),
    race                VARCHAR(20),
    current_age  int
);

--Create table to hold all cases
CREATE TABLE N3C_CASE_COHORT (
    patid			VARCHAR(50)  NOT NULL,
	inc_dx_strong		INT  NOT NULL,
	inc_dx_weak			INT  NOT NULL,
	inc_lab_any			INT  NOT NULL,
	inc_lab_pos       INT  NOT NULL
);

--Create table to hold control-case matches
--TODO: Need to add control map to the extract
CREATE TABLE N3C_CONTROL_MAP (
    case_patid   VARCHAR(50) NOT NULL,
    buddy_num   INT NOT NULL,
    control_patid VARCHAR(50),
    case_age    VARCHAR(20),
    case_sex    VARCHAR(20),
    case_race   VARCHAR(20),
    case_ethn   VARCHAR(20),
    control_age    VARCHAR(20),
    control_sex    VARCHAR(20),
    control_race   VARCHAR(20),
    control_ethn   VARCHAR(20)
);

--create table to hold all patients
CREATE TABLE N3C_COHORT (
    patid VARCHAR(50) NOT NULL
);

--before beginning, remove any patients from the last run from the PRE cohort and the case table.
--IMPORTANT: do NOT truncate or drop the control-map table.
TRUNCATE TABLE N3C_PRE_COHORT;
TRUNCATE TABLE N3C_CASE_COHORT;



-- Fill the table of all patients who have had a COVID test or potential diagnosis
INSERT INTO N3C_PRE_COHORT

-- Lab LOINC positive codes from phenotype doc
-- PCR and Antibody POSITIVE codes
WITH COVID_LAB_POS_CODES AS 
(
-- CODES NOT IN ACT ONTOLOGY
SELECT 'LOINC:94720-0 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94745-7 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94746-5 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94756-4 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94757-2 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94761-4 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94822-4 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94845-5 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95125-1 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95209-3 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95406-5 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95409-9 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95410-7 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95411-5 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95416-4 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95424-8 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95425-5 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95427-1 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95428-9 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95429-7 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95521-1 POSITIVE' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95522-9 POSITIVE' AS LOINC FROM DUAL UNION
--codes in ACT ontology and your concept_dimension table
SELECT DISTINCT concept_cd COVID_LOINC_CODE FROM CONCEPT_DIMENSION CD
                        WHERE CONCEPT_PATH LIKE '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0022885\UMLS_C1335447\%' --PCR POS
                                OR CONCEPT_PATH LIKE '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0022885\ACT_LOCAL_LAB_ANY_POSITIVE\%' --ANTIBODY POS 
        
),

--all covid labs - PCR and Antibody
COVID_LAB_CODES AS 
(
-- CODES NOT IN ACT ONTOLOGY
SELECT 'LOINC:94720-0' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94745-7' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94746-5' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94756-4' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94757-2' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94761-4' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94822-4' AS LOINC FROM DUAL UNION
SELECT 'LOINC:94845-5' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95125-1' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95209-3' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95406-5' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95409-9' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95410-7' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95411-5' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95416-4' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95424-8' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95425-5' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95427-1' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95428-9' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95429-7' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95521-1' AS LOINC FROM DUAL UNION
SELECT 'LOINC:95522-9' AS LOINC FROM DUAL UNION
--codes in ACT ontology and your concept_dimension table
SELECT DISTINCT concept_cd LOINC FROM CONCEPT_DIMENSION CD
                WHERE CONCEPT_PATH LIKE '\ACT\UMLS_C0031437\SNOMED_3947185011\UMLS_C0022885\%' 
),

-- Diagnosis ICD-10 codes from phenotype doc
COVID_DX_CODES as
(
	SELECT 'ICD10CM:B97.21' AS DX_CODE,	'dx_strong_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:B97.29' AS DX_CODE,	'dx_strong_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:U07.1' AS DX_CODE,	'dx_strong_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:Z20.828' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:B34.2' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:R50%' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:R05%' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:R06.0%' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:J12%' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:J18%' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:J20%' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:J40%' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:J21%' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:J96%' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:J22%' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:J06.9' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:J98.8' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:J80%' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:R43.0' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:R43.2' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:R07.1' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY  FROM DUAL UNION
	SELECT 'ICD10CM:R68.83' AS DX_CODE,	'dx_weak_positive' AS DX_CATEGORY FROM DUAL 
),

--patients who have tested positive since Jan 2020
COVID_LAB_POS AS (
SELECT 
    DISTINCT OBS.PATIENT_NUM AS PATIENT_NUM
    FROM OBSERVATION_FACT OBS
    	WHERE TRUNC(OBS.START_DATE) >= '01-JAN-20' AND  
            EXISTS (SELECT 1 FROM COVID_LAB_POS_CODES CLC
                        WHERE CLC.LOINC = OBS.CONCEPT_CD)
),
--all patients who have a covid lab (any result) since Jan 2020
COVID_LAB AS (
SELECT 
    DISTINCT OBS.PATIENT_NUM AS PATIENT_NUM
    FROM OBSERVATION_FACT OBS
    	WHERE TRUNC(OBS.START_DATE) >= '01-JAN-20' AND  
            EXISTS (SELECT 1 FROM COVID_LAB_CODES CLC
                        WHERE CLC.LOINC = OBS.CONCEPT_CD)
),

 -- patients with covid related diagnosis since start_date
covid_diagnosis as
(SELECT dxq.patient_num,
        dxq.encounter_num,
        dxq.dx,
        dxq.start_date AS best_dx_date,  -- use for later queries
        -- custom DX_CATEGORY for one ICD-10 code, see phenotype doc
		case
			when dxq.dx in ('ICD10CM:B97.29','ICD10CM:B97.21') and start_date < CAST('01-APR-2020' AS TIMESTAMP)  then 'dx_strong_positive'
			when dxq.dx in ('ICD10CM:B97.29','ICD10CM:B97.21') and start_date >= CAST('01-APR-2020' AS TIMESTAMP) then 'dx_weak_positive'
			else dxq.orig_DX_CATEGORY
		end AS DX_CATEGORY        
    FROM (SELECT observation_fact.patient_num,
            observation_fact.encounter_num,
            observation_fact.concept_cd AS dx,
            observation_fact.start_date,
            covid_dx_codes.DX_CATEGORY AS orig_DX_CATEGORY
        FROM observation_fact
           join covid_dx_codes on observation_fact.concept_cd like covid_dx_codes.dx_code
          WHERE TRUNC(start_date) >= CAST('01-JAN-2020' AS TIMESTAMP)
     ) dxq
 ),
 
-- patients with strong positive DX
dx_strong as
(SELECT DISTINCT
        patient_num
    FROM covid_diagnosis
      WHERE DX_CATEGORY='dx_strong_positive'           
 ),
 
-- patients with two different weak DX in same encounter and/or on same date included
DX_WEAK as
(SELECT DISTINCT patient_num FROM (SELECT patient_num,
            encounter_num,
            count(*) AS dx_count
        FROM (SELECT DISTINCT
                patient_num, encounter_num, dx
            FROM covid_diagnosis
              WHERE DX_CATEGORY='dx_weak_positive' and best_dx_date <= '01-MAY-2020'
         ) subq
        group by
            patient_num,
            encounter_num
        having
            count(*) >= 2
     ) dx_same_encounter
    
      UNION
    
    -- or two different DX on same date
    SELECT DISTINCT patient_num FROM (SELECT patient_num,
            best_dx_date,
            count(*) AS dx_count
        FROM (SELECT DISTINCT
                patient_num, best_dx_date, dx
            FROM covid_diagnosis
              WHERE DX_CATEGORY='dx_weak_positive' and best_dx_date <= '01-MAY-2020'
         ) subq
        group by
            patient_num,
            best_dx_date
        having
            count(*) >= 2
     ) dx_same_date
 ),
 
covid_cohort_1 as
(SELECT DISTINCT patient_num FROM dx_strong
      UNION
    SELECT DISTINCT patient_num FROM dx_weak
      UNION
    SELECT DISTINCT patient_num FROM covid_lab
--     UNION                                  
--    SELECT DISTINCT patient_num FROM dx_asymp
 ),
 
cohort as
(SELECT covid_cohort_1.patient_num,
	case when dx_strong.patient_num is not null then 1 else 0 end AS inc_dx_strong,
	case when dx_weak.patient_num is not null then 1 else 0 end AS inc_dx_weak,
	case when covid_lab.patient_num is not null then 1 else 0 end AS inc_lab_any,        --CHANGE: name of this flag
	case when covid_lab_pos.patient_num is not null then 1 else 0 end AS inc_lab_pos     --CHANGE: new flag
--	case when dx_asymp.patient_num is not null then 1 else 0 end AS exc_dx_asymp        --CHANGE: no longer need this flag
FROM covid_cohort_1
	left outer join dx_strong on covid_cohort_1.patient_num = dx_strong.patient_num
	left outer join dx_weak on covid_cohort_1.patient_num = dx_weak.patient_num
	left outer join covid_lab on covid_cohort_1.patient_num = covid_lab.patient_num
	left outer join covid_lab_pos on covid_cohort_1.patient_num = covid_lab_pos.patient_num          
 ),
 
 --IF ethnicity_cd exists in your patient_dimension table edit
 demographics AS 
 (
 SELECT p.patient_num, p.race_cd AS race_cd, p.birth_date AS birth_date, p.sex_cd AS sex_cd, 
  floor(months_between(sysdate,birth_date)/12) AS current_age,
  --p.ethnicity_cd AS ethnicity_cd from patient_dimension p;
  obs.concept_cd AS ethnicity_cd from patient_dimension p
 left outer join observation_fact obs on obs.patient_num = p.patient_num and concept_cd like 'DEM|HISP:%'
 ) 
 
--EVERYTHING BELOW HERE IS NEW FOR 3.0
--populate the pre-cohort table
SELECT DISTINCT
    c.patient_num as patid, 
    inc_dx_strong, 
    inc_dx_weak, 
    inc_lab_any, 
    inc_lab_pos, 
    '3.0' AS phenotype_version,
    case when floor(months_between(sysdate,d.birth_date)/12) between 0 and 4 then '0-4'
        when floor(months_between(sysdate,d.birth_date)/12) between 5 and 9 then '5-9'
        when floor(months_between(sysdate,d.birth_date)/12) between 10 and 14 then '10-14'
        when floor(months_between(sysdate,d.birth_date)/12) between 15 and 19 then '15-19'
        when floor(months_between(sysdate,d.birth_date)/12) between 20 and 24 then '20-24'
        when floor(months_between(sysdate,d.birth_date)/12) between 25 and 29 then '25-29'
        when floor(months_between(sysdate,d.birth_date)/12) between 30 and 34 then '30-34'
        when floor(months_between(sysdate,d.birth_date)/12) between 35 and 39 then '35-39'
        when floor(months_between(sysdate,d.birth_date)/12) between 40 and 44 then '40-44'
        when floor(months_between(sysdate,d.birth_date)/12) between 45 and 49 then '45-49'
        when floor(months_between(sysdate,d.birth_date)/12) between 50 and 54 then '50-54'
        when floor(months_between(sysdate,d.birth_date)/12) between 55 and 59 then '55-59'
        when floor(months_between(sysdate,d.birth_date)/12) between 60 and 64 then '60-64'
        when floor(months_between(sysdate,d.birth_date)/12) between 65 and 69 then '65-69'
        when floor(months_between(sysdate,d.birth_date)/12) between 70 and 74 then '70-74'
        when floor(months_between(sysdate,d.birth_date)/12) between 75 and 79 then '75-79'
        when floor(months_between(sysdate,d.birth_date)/12) between 80 and 84 then '80-84'
	when floor(months_between(sysdate,d.birth_date)/12) between 85 and 89 then '85-89'
        when floor(months_between(sysdate,d.birth_date)/12) >= 90 then '90+'
        end AS pt_age,
        d.sex_cd AS sex,
        d.ethnicity_cd AS hispanic, 
        d.race_cd AS race,
        d.current_age AS current_age
FROM cohort c JOIN demographics d ON c.patient_num = d.patient_num;

--populate the case table
INSERT INTO N3C_CASE_COHORT
SELECT 
    patient_num as patid, 
    inc_dx_strong, 
    inc_dx_weak, 
    inc_lab_any, 
    inc_lab_pos
FROM 
    N3C_PRE_COHORT
WHERE
    inc_dx_strong = 1 or inc_lab_pos = 1 or inc_dx_weak = 1;


--Now that the pre-cohort and case tables are populated, we start matching cases and controls, and updating the case 
--and control tables AS needed.
--all cases need two control "buddies". we SELECT on progressively looser patient_dimension criteria until every 
--case has two control matches, or we run out of patients in the control pool.

--first handle instances where someone who was in the control group in the prior run is now a case
--just delete both the case and the control from the mapping table. the case will repopulate automatically 
--with a replaced control.
DELETE FROM N3C_CONTROL_MAP WHERE CONTROL_patid IN (SELECT patid FROM N3C_CASE_COHORT);

--remove cases and controls from the mapping table if those people are no longer in the person table 
--(due to merges or other reasons)
DELETE FROM N3C_CONTROL_MAP WHERE CASE_patid NOT IN (SELECT patient_num FROM patient_dimension);
DELETE FROM N3C_CONTROL_MAP WHERE CONTROL_patid NOT IN (SELECT patient_num FROM patient_dimension);

--remove cases who no longer meet the phenotype definition
DELETE FROM N3C_CONTROL_MAP WHERE CASE_patid NOT IN (SELECT patid FROM N3C_CASE_COHORT);

--start progressively matching cases to controls. we will do a diff between the results here and 
--what's already in the control_map table later.
insert into N3C_CONTROL_MAP (CASE_patid, BUDDY_NUM, CONTROL_patid, case_age, case_sex, case_race, 
case_ethn, control_age, control_sex, control_race, control_ethn)
WITH cases_1 as
(
	SELECT
		subq.*,
		ROW_NUMBER() over(partition by pt_age, sex, race, hispanic order by randnum) AS join_row_1 -- most restrictive
	from
	(
		SELECT
			patid,
			pt_age,
			sex,
			race,
			hispanic,
			1 AS buddy_num,
			dbms_random.random AS randnum -- random number
		from
			n3c_pre_cohort
		where 
    			(inc_dx_strong = 1 or inc_lab_pos = 1 or inc_dx_weak = 1)


		UNION

		SELECT
			patid,
			pt_age,
			sex,
			race,
			hispanic,
			2 AS buddy_num,
			dbms_random.random AS randnum -- random number
		from
			n3c_pre_cohort
		where 
    			(inc_dx_strong = 1 or inc_lab_pos = 1 or inc_dx_weak = 1)
	) subq
),

-- all available controls, joined to encounter table to eliminate patients with almost no data
--right now we're looking for patients with at least 10 days between their min and max visit dates.
pre_controls AS (
        SELECT
			npc.patid,
			max(e.START_DATE) AS maxenc,
			min(e.START_DATE) AS minenc,
			max(e.START_DATE) - min(e.START_DATE) AS daysonhand
		from
			n3c_pre_cohort npc JOIN visit_dimension e ON npc.patid = to_char(e.patient_num)
		where 
    	    inc_lab_any = 1 and inc_dx_strong = 0 and inc_lab_pos = 0 and inc_dx_weak = 0 
    	    and e.START_DATE between '01-JAN-2018' and sysdate
	    and npc.patid not in (SELECT control_patid FROM N3C_CONTROL_MAP)
    	group by
    	    npc.patid
    	having
    	    max(e.START_DATE) - min(e.START_DATE) >= 10
),

controls_1 as
(
	SELECT
		subq.*,
		ROW_NUMBER() over(partition by pt_age, sex, race, hispanic order by randnum) AS join_row_1
	from
	(
		SELECT
			npc.patid,
			npc.pt_age,
			npc.sex,
			npc.race,
			npc.hispanic,
			dbms_random.random AS randnum
		from
			n3c_pre_cohort npc JOIN pre_controls pre ON npc.patid = pre.patid
	) subq
),

--match cases to controls where all patient_dimension criteria match
map_1 as
(
	SELECT
		cases.*,
		controls.patid AS control_patid
	from
		cases_1 cases
		left outer join controls_1 controls on 
			cases.pt_age = controls.pt_age
			and cases.sex = controls.sex 
			and cases.race = controls.race
			and cases.hispanic = controls.hispanic
			and cases.join_row_1 = controls.join_row_1
),

--narrow down to those cases that are missing one or more control buddies
--drop the hispanic criterion first
cases_2 AS (
	SELECT
		map_1.*,
		ROW_NUMBER() over(partition by pt_age, sex, race  order by randnum) AS join_row_2
	from
		map_1
	where
		control_patid is null -- missing a buddy
),

controls_2 AS (
	SELECT
		controls_1.*,
		ROW_NUMBER() over(partition by pt_age, sex, race order by randnum) AS join_row_2
	from
		controls_1
	where
		patid NOT in (SELECT control_patid from map_1 where control_patid is not null) -- doesn't already have a buddy
),

map_2 AS (
	SELECT
		cases.patid,
		cases.pt_age,
		cases.sex,
		cases.race,
		cases.hispanic,
		cases.buddy_num,
		cases.randnum,
		cases.join_row_1,
		cases.join_row_2,
		controls.patid AS control_patid
	from
		cases_2 cases
		left outer join controls_2 controls on
			cases.pt_age = controls.pt_age
			and cases.sex = controls.sex 
			and cases.race = controls.race
			and cases.join_row_2 = controls.join_row_2
),

--narrow down to those cases that are still missing one or more control buddies
--drop the race criterion now

cases_3 as
(
	SELECT
		map_2.*,
		ROW_NUMBER() over(partition by pt_age, sex order by randnum) AS join_row_3
	from
		map_2
	where
		control_patid is null
),

controls_3 as
(
	SELECT
		controls_2.*,
		ROW_NUMBER() over(partition by pt_age, sex order by randnum) AS join_row_3
	from
		controls_2
	where
		patid NOT in (SELECT control_patid from map_2 where control_patid is not null)
),

map_3 AS (
	SELECT
		cases.patid,
		cases.pt_age,
		cases.sex,
		cases.race,
		cases.hispanic,
		cases.buddy_num,
		cases.randnum,
		cases.join_row_1,
		cases.join_row_2,
		cases.join_row_3,
		controls.patid AS control_patid
	from
		cases_3 cases
		left outer join controls_3 controls on
			cases.pt_age = controls.pt_age
			and cases.sex = controls.sex 
			and cases.join_row_3 = controls.join_row_3
),

--narrow down to those cases that are still missing one or more control buddies
--drop the age criterion now

cases_4 as
(
	SELECT
		map_3.*,
		ROW_NUMBER() over(partition by sex order by randnum) AS join_row_4
	from
		map_3
	where
		control_patid is null
),

controls_4 as
(
	SELECT
		controls_3.*,
		ROW_NUMBER() over(partition by sex order by randnum) AS join_row_4
	from
		controls_3
	where
		patid NOT in (SELECT control_patid from map_3 where control_patid is not null)
),

map_4 AS (
	SELECT
		cases.patid,
		cases.pt_age,
		cases.sex,
		cases.race,
		cases.hispanic,
		cases.buddy_num,
		cases.randnum,
		cases.join_row_1,
		cases.join_row_2,
		cases.join_row_3,
		cases.join_row_4,
		controls.patid AS control_patid
	from
		cases_4 cases
		left outer join controls_4 controls on
			cases.sex = controls.sex 
			and cases.join_row_4 = controls.join_row_4
),

penultimate_map AS (
	SELECT
		map_1.patid,
		map_1.buddy_num,
		coalesce(map_1.control_patid, map_2.control_patid, map_3.control_patid, map_4.control_patid) AS control_patid,
		map_1.patid AS map_1_patid,
		map_2.patid AS map_2_patid,
		map_3.patid AS map_3_patid,
		map_4.patid AS map_4_patid,
		map_1.control_patid AS map_1_control_patid,
		map_2.control_patid AS map_2_control_patid,
		map_3.control_patid AS map_3_control_patid,
		map_4.control_patid AS map_4_control_patid,
		map_1.pt_age AS map_1_pt_age,
		map_1.sex AS map_1_sex,
		map_1.race AS map_1_race,
		map_1.hispanic AS map_1_hispanic
	from
		map_1
		left outer join map_2 on map_1.patid = map_2.patid and map_1.buddy_num = map_2.buddy_num
		left outer join map_3 on map_1.patid = map_3.patid and map_1.buddy_num = map_3.buddy_num
		left outer join map_4 on map_1.patid = map_4.patid and map_1.buddy_num = map_4.buddy_num
),

final_map AS (
SELECT
	penultimate_map.patid AS case_patid,
	penultimate_map.control_patid,
	penultimate_map.buddy_num,
	penultimate_map.map_1_control_patid,
	penultimate_map.map_2_control_patid,
	penultimate_map.map_3_control_patid,
	penultimate_map.map_4_control_patid,
	demog1.current_age AS case_age, 
	demog1.sex AS case_sex,
	demog1.race AS case_race,
	demog1.hispanic AS case_ethn,
	demog2.current_age AS control_age, 
	demog2.sex AS control_sex,
	demog2.race AS control_race,
	demog2.hispanic AS control_ethn
from
	penultimate_map
	join N3C_PRE_COHORT demog1 on penultimate_map.patid = demog1.patid
	left join N3C_PRE_COHORT demog2 on penultimate_map.control_patid = demog2.patid
)

SELECT 
   case_patid, 
   buddy_num, 
   control_patid,
   case_age,
   case_sex,
   case_race,
   case_ethn,
   control_age,
   control_sex,
   control_race,
   control_ethn
FROM 
   final_map
where
   NOT EXISTS(SELECT 1 from N3C_CONTROL_MAP where final_map.case_patid=N3C_CONTROL_MAP.case_patid and final_map.buddy_num=N3C_CONTROL_MAP.buddy_num);
   
--populate final table with all members of cohort in a single column
INSERT INTO N3C_COHORT
    SELECT case_patid
    FROM N3C_CONTROL_MAP
    UNION
    SELECT control_patid
    FROM N3C_CONTROL_MAP;

