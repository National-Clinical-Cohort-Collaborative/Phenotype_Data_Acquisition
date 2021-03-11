--Phenotype 3.2
--PCORnet

--Create table to hold all cases and controls before matching
CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.N3C_PRE_COHORT (
		patid			VARCHAR(50)  NOT NULL,
		inc_dx_strong		INT  NOT NULL,
		inc_dx_weak			INT  NOT NULL,
		inc_lab_any				INT  NOT NULL,
		inc_lab_pos       INT  NOT NULL,
		phenotype_version 		VARCHAR(10),
		pt_age              VARCHAR(20),
		sex                 VARCHAR(20),
		hispanic           VARCHAR(20),
		race                VARCHAR(20)
	);
	
	
--Create table to hold all cases
CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.N3C_CASE_COHORT (
		patid			VARCHAR(50)  NOT NULL,
		inc_dx_strong		INT  NOT NULL,
		inc_dx_weak			INT  NOT NULL,
		inc_lab_any			INT  NOT NULL,
		inc_lab_pos       INT  NOT NULL
	);

--Create table to hold control-case matches
-- DO NOT DROP OR TRUNCATE THIS TABLE
CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.N3C_CONTROL_MAP (
		case_patid   VARCHAR(50) NOT NULL,
		buddy_num   INT NOT NULL,
		control_patid VARCHAR(50),
		case_age    VARCHAR(10),
		case_sex    VARCHAR(10),
		case_race   VARCHAR(10),
		case_ethn   VARCHAR(10),
		control_age    VARCHAR(10),
		control_sex    VARCHAR(10),
		control_race   VARCHAR(10),
		control_ethn   VARCHAR(10)
	);

--create table to hold all patients
CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.N3C_COHORT (
		patid VARCHAR(50) NOT NULL
	);

-- Create table to hold valid controls before matching
CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.N3C_PRE_CONTROLS (
		patid VARCHAR(50)  NOT NULL,
		maxenc DATE  NOT NULL,
		minenc DATE  NOT NULL,
		daysonhand INT  NOT NULL,
		randnum INT
	);
	

-- temp table for initial map
CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.N3C_PRE_MAP (
		patid			VARCHAR(50)  NOT NULL,
		pt_age              VARCHAR(20),
		sex                 VARCHAR(20),
		hispanic           VARCHAR(20),
		race                VARCHAR(20),
		buddy_num	INT,
		randnum		INT
	);
	
-- temp table for control query
CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.N3C_PENULTIMATE_MAP (
		patid varchar(50) NOT NULL,
		buddy_num int NOT NULL,
		control_patid varchar(50) NULL,
		map_1_patid varchar(50) NULL,
		map_2_patid varchar(50) NULL,
		map_3_patid varchar(50) NULL,
		map_4_patid varchar(50) NULL,
		map_1_control_patid varchar(50) NULL,
		map_2_control_patid varchar(50) NULL,
		map_3_control_patid varchar(50) NULL,
		map_4_control_patid varchar(50) NULL,
		map_1_pt_age varchar(20) NULL,
		map_1_sex varchar(20) NULL,
		map_1_race varchar(20) NULL,
		map_1_hispanic varchar(20) NULL
	);

-- temp table for control query
CREATE TABLE IF NOT EXISTS @resultsDatabaseSchema.N3C_FINAL_MAP (
		case_patid varchar(50) NOT NULL,
		control_patid varchar(50) NULL,
		buddy_num int NOT NULL,
		map_1_control_patid varchar(50) NULL,
		map_2_control_patid varchar(50) NULL,
		map_3_control_patid varchar(50) NULL,
		map_4_control_patid varchar(50) NULL,
		case_age int NULL,
		case_sex varchar(100) NULL,
		case_race varchar(100) NULL,
		case_ethn varchar(100) NULL,
		control_age int NULL,
		control_sex varchar(100) NULL,
		control_race varchar(100) NULL,
		control_ethn varchar(100) NULL
	);
--before beginning, remove any patients from the last run from the PRE cohort and the case table.
--IMPORTANT: do NOT truncate or drop the control-map table.
TRUNCATE TABLE @resultsDatabaseSchema.N3C_PRE_COHORT;
TRUNCATE TABLE @resultsDatabaseSchema.N3C_CASE_COHORT;
TRUNCATE TABLE @resultsDatabaseSchema.N3C_COHORT;
TRUNCATE TABLE @resultsDatabaseSchema.N3C_PRE_CONTROLS;
TRUNCATE TABLE @resultsDatabaseSchema.N3C_PRE_MAP;
TRUNCATE TABLE @resultsDatabaseSchema.N3C_PENULTIMATE_MAP;
TRUNCATE TABLE @resultsDatabaseSchema.N3C_FINAL_MAP;

--Script to populate the pre-cohort table.

--Script to populate the pre-cohort table.


-- Lab LOINC codes from phenotype doc
WITH 
covid_loinc  AS 
(
	SELECT '95209-3' as loinc    UNION
	SELECT '94307-6' as loinc    UNION
	SELECT '94308-4' as loinc     UNION 
	SELECT '94309-2' as loinc     UNION 
	SELECT '94311-8' as loinc     UNION 
	SELECT '94312-6' as loinc     UNION 
	SELECT '94314-2' as loinc     UNION 
	SELECT '94316-7' as loinc     UNION 
	SELECT '94500-6' as loinc     UNION 
	SELECT '94505-5' as loinc     UNION 
	SELECT '94506-3' as loinc     UNION 
	SELECT '94507-1' as loinc     UNION 
	SELECT '94508-9' as loinc     UNION 
	SELECT '94510-5' as loinc     UNION 
	SELECT '94511-3' as loinc     UNION 
	SELECT '94533-7' as loinc     UNION 
	SELECT '94534-5' as loinc     UNION 
	SELECT '94547-7' as loinc     UNION 
	SELECT '94558-4' as loinc     UNION 
	SELECT '94559-2' as loinc     UNION 
	SELECT '94562-6' as loinc     UNION 
	SELECT '94563-4' as loinc     UNION 
	SELECT '94564-2' as loinc     UNION 
	SELECT '94565-9' as loinc     UNION 
	SELECT '94639-2' as loinc     UNION 
	SELECT '94640-0' as loinc     UNION 
	SELECT '94641-8' as loinc     UNION 
	SELECT '94642-6' as loinc     UNION 
	SELECT '94643-4' as loinc     UNION 
	SELECT '94644-2' as loinc     UNION 
	SELECT '94645-9' as loinc     UNION 
	SELECT '94646-7' as loinc     UNION 
	SELECT '94660-8' as loinc     UNION 
	SELECT '94661-6' as loinc     UNION 
	SELECT '94306-8' as loinc     UNION 
	SELECT '94503-0' as loinc     UNION 
	SELECT '94504-8' as loinc     UNION 
	SELECT '94531-1' as loinc     UNION 
	SELECT '94720-0' as loinc     UNION 
	SELECT '94759-8' as loinc     UNION 
	SELECT '94760-6' as loinc     UNION 
	SELECT '94762-2' as loinc     UNION 
	SELECT '94763-0' as loinc     UNION 
	SELECT '94764-8' as loinc     UNION 
	SELECT '94766-3' as loinc     UNION 
	SELECT '94767-1' as loinc     UNION 
	SELECT '94768-9' as loinc     UNION 
	SELECT '94769-7' as loinc     UNION 
	SELECT '94819-0' as loinc     UNION 
	SELECT '94745-7' as loinc     UNION 
	SELECT '94746-5' as loinc     UNION 
	SELECT '94756-4' as loinc     UNION 
	SELECT '94757-2' as loinc     UNION 
	SELECT '94761-4' as loinc     UNION 
	SELECT '94822-4' as loinc     UNION 
	SELECT '94845-5' as loinc     UNION 
	SELECT '95125-1' as loinc     UNION 
	SELECT '95406-5' as loinc     UNION 
	SELECT '95409-9' as loinc     UNION 
	SELECT '95410-7' as loinc     UNION 
	SELECT '95411-5' as loinc	  UNION 
	select '95416-4' as loinc  UNION  
	select '95424-8' as loinc  UNION  
	select '95425-5' as loinc  UNION  
	select '95427-1' as loinc  UNION  
	select '95428-9' as loinc  UNION  
	select '95429-7' as loinc  UNION  
	select '95521-1' as loinc  UNION  
	select '95522-9' as loinc 
),

 --The ways that your site describes a positive COVID test
 --TODO: We should still parameterize this
covid_pos_list as 
(
	SELECT 'POSITIVE' as word  UNION 
	SELECT 'DETECTED' as word 
),

-- Diagnosis ICD-10/SNOMED codes from phenotype doc
-- Note that Z11.59 has been removed
covid_dx_codes as
(
	SELECT 'J12.82' as dx_code,	'dx_strong_positive' as dx_category    UNION
	SELECT 'M35.81' as dx_code,	'dx_strong_positive' as dx_category    UNION
	SELECT 'B97.21' as dx_code,	'dx_strong_positive' as dx_category    UNION 
	SELECT 'B97.29'  dx_code,	'dx_strong_positive' as dx_category     UNION 
	SELECT 'U07.1'  dx_code,	'dx_strong_positive' as dx_category     UNION 
	SELECT 'Z20.828'  dx_code,'dx_weak_positive' as dx_category     UNION 
	SELECT 'B34.2'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'R50%'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'R05%'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'R06.0%'  dx_code,	'dx_weak_positive' as dx_category     UNION
	SELECT 'J12%'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'J18%'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'J20%'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'J40%'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'J21%'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'J96%'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'J22%'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'J06.9'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'J98.8'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'J80%'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'R43.0'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'R43.2'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'R07.1'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT 'R68.83'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '840539006'  dx_code,	'dx_strong_positive' as dx_category     UNION 
	SELECT '840544004'  dx_code,	'dx_strong_positive' as dx_category     UNION 
	SELECT '840546002'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '103001002'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '11833005'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '267036007'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '28743005'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '36955009'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '426000000'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '44169009'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '49727002'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '135883003'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '161855003'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '161939006'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '161940008'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '161941007'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '2237002'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '23141003'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '247410004'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '274640006'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '274664007'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '284523002'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '386661006'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '409702008'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '426976009'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '43724002'  dx_code,	'dx_weak_positive' as dx_category     UNION 
	SELECT '60845006'  dx_code,	'dx_weak_positive' as dx_category      UNION 
	select '75483001'  dx_code,	'dx_weak_positive' as dx_category
   ),
  
-- patients with covid related lab since start_date
covid_lab as
(
	SELECT distinct
        lab_result_cm.patid
    FROM 
		@cdmDatabaseSchema.lab_result_cm
	WHERE 
		lab_result_cm.result_date >= TO_DATE('2020-01-01','YYYY-MM-DD')
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
(
	SELECT distinct
        lab_result_cm.patid
    FROM 
		@cdmDatabaseSchema.lab_result_cm 
		JOIN covid_pos_list ON LAB_RESULT_CM.RESULT_QUAL = covid_pos_list.word
	WHERE 
		lab_result_cm.result_date >= TO_DATE('2020-01-01','YYYY-MM-DD')
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
	SELECT dxq.*,
        coalesce(dx_date,admit_date) as best_dx_date,  -- use for later queries
        -- custom dx_category for one ICD-10 code, see phenotype doc
		case
			when dx in ('B97.29','B97.21') and coalesce(dx_date,admit_date) < TO_DATE('2020-04-01','YYYY-MM-DD')   then 'dx_strong_positive'
			when dx in ('B97.29','B97.21') and coalesce(dx_date,admit_date) >= TO_DATE('2020-04-01','YYYY-MM-DD')   then 'dx_weak_positive'
			else dxq.orig_dx_category
		end as dx_category        
    FROM 
	(
		SELECT 
			diagnosis.patid,
            diagnosis.encounterid,
            diagnosis.dx,
            diagnosis.admit_date,
            diagnosis.dx_date,
            covid_dx_codes.dx_category as orig_dx_category
        FROM 
			@cdmDatabaseSchema.diagnosis
			join covid_dx_codes on diagnosis.dx like covid_dx_codes.dx_code
		WHERE coalesce(dx_date,admit_date) >= TO_DATE('2020-01-01','YYYY-MM-DD') 
     ) dxq
 ),
 
-- patients with strong positive DX
dx_strong as
(
    select distinct
        patid
    from
        covid_diagnosis
    where
        dx_category='dx_strong_positive'    
        
),
 
---- patients with asymptomatic DX 
---- ensure they had a covid lab, and that the code was after April 1
---- and make sure they are not in the strong positive set OR positive lab set, which overrules the asymptomatic
---- these are patients who will be EXCLUDED, not INCLUDED
--dx_asymp as
--(SELECT distinct
--        cda.patid
--    FROM 
--        covid_diagnosis cda 
--        JOIN covid_lab on cda.patid = covid_lab.patid and cda.dx_category='asymptomatic' and cda.best_dx_date >= '01-APR-2020'
--        LEFT JOIN covid_diagnosis cds ON cda.patid = cds.patid AND cds.dx_category='dx_strong_positive'
--        LEFT JOIN covid_lab_pos cpl ON cda.patid = cpl.patid
--     WHERE     
--        cds.patid is null AND cpl.patid is null
-- ),
 
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
                dx_category='dx_weak_positive' and best_dx_date <= TO_DATE('2020-05-01','YYYY-MM-DD') 
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
                dx_category='dx_weak_positive' and best_dx_date <= TO_DATE('2020-05-01','YYYY-MM-DD') 
        ) subq
        group by
            patid,
            best_dx_date
        having
            count(*) >= 2
    ) dx_same_date
),
 
covid_cohort as
(
	SELECT distinct patid FROM dx_strong
	UNION
	SELECT distinct patid FROM dx_weak
	UNION
	select distinct patid FROM covid_lab
	--     UNION                                  
	--    select distinct patid FROM dx_asymp
 ),
 
cohort as
(
	SELECT 
		covid_cohort.patid,
		case when dx_strong.patid is not null then 1 else 0 end as inc_dx_strong,
		case when dx_weak.patid is not null then 1 else 0 end as inc_dx_weak,
		case when covid_lab.patid is not null then 1 else 0 end as inc_lab_any,        --CHANGE: name of this flag
		case when covid_lab_pos.patid is not null then 1 else 0 end as inc_lab_pos     --CHANGE: new flag
	--	case when dx_asymp.patid is not null then 1 else 0 end as exc_dx_asymp        --CHANGE: no longer need this flag
FROM 
	covid_cohort
	left outer join dx_strong on covid_cohort.patid = dx_strong.patid
	left outer join dx_weak on covid_cohort.patid = dx_weak.patid
	left outer join covid_lab on covid_cohort.patid = covid_lab.patid
	left outer join covid_lab_pos on covid_cohort.patid = covid_lab_pos.patid          --CHANGE: add new table
--	left outer join dx_asymp on covid_cohort.patid = dx_asymp.patid                     --CHANGE: no longer need this table
 )
--EVERYTHING BELOW HERE IS NEW FOR 3.0
--populate the pre-cohort table
INSERT INTO @resultsDatabaseSchema.N3C_PRE_COHORT (patid, inc_dx_strong, inc_dx_weak, inc_lab_any, inc_lab_pos, phenotype_version, pt_age, sex, hispanic, race)
SELECT distinct
    c.patid, 
    inc_dx_strong, 
    inc_dx_weak, 
    inc_lab_any, 
    inc_lab_pos, 
    '3.2' as phenotype_version,
   CASE
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 0
				AND 4
			THEN '0-4'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 5
				AND 9
			THEN '5-9'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 10
				AND 14
			THEN '10-14'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 15
				AND 19
			THEN '15-19'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 20
				AND 24
			THEN '20-24'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 25
				AND 29
			THEN '25-29'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 30
				AND 34
			THEN '30-34'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 35
				AND 39
			THEN '35-39'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 40
				AND 44
			THEN '40-44'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 45
				AND 49
			THEN '45-49'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 50
				AND 54
			THEN '50-54'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 55
				AND 59
			THEN '55-59'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 60
				AND 64
			THEN '60-64'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 65
				AND 69
			THEN '65-69'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 70
				AND 74
			THEN '70-74'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 75
				AND 79
			THEN '75-79'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 80
				AND 84
			THEN '80-84'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) BETWEEN 85
				AND 89
			THEN '85-89'
		WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', d.birth_date) >= 90
			THEN '90+'
		END AS pt_age,
        d.sex as sex,
        d.hispanic as hispanic,
        d.race as race
FROM 
	cohort c 
	JOIN @cdmDatabaseSchema.demographic d ON c.patid = d.patid;
	
	
--populate the case table
INSERT INTO @resultsDatabaseSchema.N3C_CASE_COHORT (patid, inc_dx_strong, inc_dx_weak, inc_lab_any, inc_lab_pos)
SELECT 
    patid, 
    inc_dx_strong, 
    inc_dx_weak, 
    inc_lab_any, 
    inc_lab_pos
FROM 
    @resultsDatabaseSchema.N3C_PRE_COHORT
WHERE
    inc_dx_strong = 1 or inc_lab_pos = 1 or inc_dx_weak = 1;

--Now that the pre-cohort and case tables are populated, we start matching cases and controls, and updating the case and control tables as needed.
--all cases need two control "buddies". we select on progressively looser demographic criteria until every case has two control matches, or we run out of patients in the control pool.

--first handle instances where someone who was in the control group in the prior run is now a case
--just delete both the case and the control from the mapping table. the case will repopulate automatically with a replaced control.
DELETE FROM @resultsDatabaseSchema.N3C_CONTROL_MAP WHERE CONTROL_PATID IN (SELECT patid FROM @resultsDatabaseSchema.N3C_CASE_COHORT);

--remove cases and controls from the mapping table if those people are no longer in the person table (due to merges or other reasons)
DELETE FROM @resultsDatabaseSchema.N3C_CONTROL_MAP WHERE CASE_PATID NOT IN (SELECT PATID FROM @cdmDatabaseSchema.DEMOGRAPHIC);
DELETE FROM @resultsDatabaseSchema.N3C_CONTROL_MAP WHERE CONTROL_PATID NOT IN (SELECT PATID FROM @cdmDatabaseSchema.DEMOGRAPHIC);

--remove cases who no longer meet the phenotype definition
DELETE FROM @resultsDatabaseSchema.N3C_CONTROL_MAP WHERE CASE_PATID NOT IN (SELECT PATID FROM @resultsDatabaseSchema.N3C_CASE_COHORT);	

--remove rows with no control_patid match from the last phenotype run
DELETE FROM @resultsDatabaseSchema.N3C_CONTROL_MAP WHERE CONTROL_PATID IS NULL;

-- all available controls, joined to encounter table to eliminate patients with almost no data
-- right now we're looking for patients with at least 10 days between their min and max visit dates.
INSERT INTO @resultsDatabaseSchema.N3C_PRE_CONTROLS (patid, maxenc, minenc, daysonhand, randnum)
	select
		npc.patid,
		max(e.ADMIT_DATE) as maxenc,
		min(e.ADMIT_DATE) as minenc,
		(max(e.ADMIT_DATE)-min(e.ADMIT_DATE)) as daysonhand,
		RANDOM() AS randnum -- random number
	from
		@resultsDatabaseSchema.n3c_pre_cohort npc 
		JOIN @cdmDatabaseSchema.encounter  e ON npc.patid = e.patid
	where 
		inc_lab_any = 1 and inc_dx_strong = 0 and inc_lab_pos = 0 and inc_dx_weak = 0 
		and e.ADMIT_DATE between TO_DATE('2018-01-01','YYYY-MM-DD') and current_date
		and npc.patid not in (SELECT control_patid FROM @resultsDatabaseSchema.N3C_CONTROL_MAP where control_patid is not null)
	group by
		npc.patid
	having
		(max(e.ADMIT_DATE)-min(e.ADMIT_DATE)) >= 10;
		
-- create pre-map table with random nums
INSERT INTO @resultsDatabaseSchema.N3C_PRE_MAP (patid, pt_age, sex, race, hispanic, buddy_num, randnum)
	select
		patid,
		pt_age,
		sex,
		race,
		hispanic,
		1 as buddy_num,
		ABS(RANDOM()) AS randnum -- random number
	from
		@resultsDatabaseSchema.n3c_pre_cohort
	where 
    		(inc_dx_strong = 1 or inc_lab_pos = 1 or inc_dx_weak = 1)
		and patid NOT in (select case_patid from @resultsDatabaseSchema.n3c_control_map where buddy_num=1 and case_patid is not null and control_patid is not null)

	UNION

	select
		patid,
		pt_age,
		sex,
		race,
		hispanic,
		2 as buddy_num,
		ABS(RANDOM()) AS randnum -- random number
	from
		@resultsDatabaseSchema.n3c_pre_cohort
	where 
    		(inc_dx_strong = 1 or inc_lab_pos = 1 or inc_dx_weak = 1)
		and patid NOT in (select case_patid from @resultsDatabaseSchema.n3c_control_map where buddy_num=2 and case_patid is not null and control_patid is not null)
;	

--start progressively matching cases to controls. we will do a diff between the results here and what's already in the control_map table later.
with
cases_1 as
(
	select
		n3c_pre_map.*,
		ROW_NUMBER() over(partition by pt_age, sex, race, hispanic order by randnum) as join_row_1 -- most restrictive
	from
		@resultsDatabaseSchema.n3c_pre_map
)
,
controls_1 as
(
	select
		subq.*,
		ROW_NUMBER() over(partition by pt_age, sex, race, hispanic order by randnum) as join_row_1
	from
	(
		select
			npc.patid,
			npc.pt_age,
			npc.sex,
			npc.race,
			npc.hispanic,
			pre.randnum
		from
			@resultsDatabaseSchema.n3c_pre_cohort npc 
			JOIN @resultsDatabaseSchema.N3C_PRE_CONTROLS pre ON npc.patid = pre.patid
	) subq
)
,

--match cases to controls where all demographic criteria match
map_1 as
(
	select
		cases.*,
		controls.patid as control_patid
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
cases_2 as (
	select
		map_1.*,
		ROW_NUMBER() over(partition by pt_age, sex, race  order by randnum) as join_row_2
	from
		map_1
	where
		control_patid is null -- missing a buddy
),

controls_2 as (
	select
		controls_1.*,
		ROW_NUMBER() over(partition by pt_age, sex, race order by randnum) as join_row_2
	from
		controls_1
	where
		patid NOT in (select control_patid from map_1 where control_patid is not null) -- doesn't already have a buddy
),

map_2 as (
	select
		cases.patid,
		cases.pt_age,
		cases.sex,
		cases.race,
		cases.hispanic,
		cases.buddy_num,
		cases.randnum,
		cases.join_row_1,
		cases.join_row_2,
		controls.patid as control_patid
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
	select
		map_2.*,
		ROW_NUMBER() over(partition by pt_age, sex order by randnum) as join_row_3
	from
		map_2
	where
		control_patid is null
),

controls_3 as
(
	select
		controls_2.*,
		ROW_NUMBER() over(partition by pt_age, sex order by randnum) as join_row_3
	from
		controls_2
	where
		patid NOT in (select control_patid from map_2 where control_patid is not null)
),

map_3 as (
	select
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
		controls.patid as control_patid
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
	select
		map_3.*,
		ROW_NUMBER() over(partition by sex order by randnum) as join_row_4
	from
		map_3
	where
		control_patid is null
)
,

controls_4 as
(
	select
		controls_3.*,
		ROW_NUMBER() over(partition by sex order by randnum) as join_row_4
	from
		controls_3
	where
		patid NOT in (select control_patid from map_3 where control_patid is not null)
),

map_4 as (
	select
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
		controls.patid as control_patid
	from
		cases_4 cases
		left outer join controls_4 controls on
			cases.sex = controls.sex 
			and cases.join_row_4 = controls.join_row_4
)
,

penultimate_map as (
	select
		map_1.patid,
		map_1.buddy_num,
		coalesce(map_1.control_patid, map_2.control_patid, map_3.control_patid, map_4.control_patid) as control_patid,
		map_1.patid as map_1_patid,
		map_2.patid as map_2_patid,
		map_3.patid as map_3_patid,
		map_4.patid as map_4_patid,
		map_1.control_patid as map_1_control_patid,
		map_2.control_patid as map_2_control_patid,
		map_3.control_patid as map_3_control_patid,
		map_4.control_patid as map_4_control_patid,
		map_1.pt_age as map_1_pt_age,
		map_1.sex as map_1_sex,
		map_1.race as map_1_race,
		map_1.hispanic as map_1_hispanic
	from
		map_1
		left outer join map_2 on map_1.patid = map_2.patid and map_1.buddy_num = map_2.buddy_num
		left outer join map_3 on map_1.patid = map_3.patid and map_1.buddy_num = map_3.buddy_num
		left outer join map_4 on map_1.patid = map_4.patid and map_1.buddy_num = map_4.buddy_num
)
INSERT INTO @resultsDatabaseSchema.N3C_PENULTIMATE_MAP (patid,buddy_num,control_patid,map_1_patid,map_2_patid,map_3_patid,map_4_patid,map_1_control_patid,map_2_control_patid,map_3_control_patid,map_4_control_patid,map_1_pt_age,map_1_sex,map_1_race,map_1_hispanic)
select patid,buddy_num,control_patid,map_1_patid,map_2_patid,map_3_patid,map_4_patid,map_1_control_patid,map_2_control_patid,map_3_control_patid,map_4_control_patid,map_1_pt_age,map_1_sex,map_1_race,map_1_hispanic FROM penultimate_map;

with
final_map as (
select
	penultimate_map.patid as case_patid,
	penultimate_map.control_patid,
	penultimate_map.buddy_num,
	penultimate_map.map_1_control_patid,
	penultimate_map.map_2_control_patid,
	penultimate_map.map_3_control_patid,
	penultimate_map.map_4_control_patid,
	floor((DATE_PART('year', demog1.birth_date) - DATE_PART('year', current_date)) * 12 +
              (DATE_PART('month', demog1.birth_date) - DATE_PART('month', current_date))) as case_age,
	demog1.sex as case_sex,
	demog1.race as case_race,
	demog1.hispanic as case_ethn,
	floor((DATE_PART('year', demog2.birth_date) - DATE_PART('year', current_date)) * 12 +
              (DATE_PART('month', demog2.birth_date) - DATE_PART('month', current_date))) as control_age,
	demog2.sex as control_sex,
	demog2.race as control_race,
	demog2.hispanic as control_ethn
from
	@resultsDatabaseSchema.N3C_PENULTIMATE_MAP penultimate_map
	join @cdmDatabaseSchema.demographic demog1 on penultimate_map.patid = demog1.patid
	left outer join @cdmDatabaseSchema.demographic demog2 on penultimate_map.control_patid = demog2.patid
)
insert into @resultsDatabaseSchema.N3C_FINAL_MAP (case_patid,control_patid,buddy_num,map_1_control_patid,map_2_control_patid,map_3_control_patid,map_4_control_patid,case_age,case_sex,case_race,case_ethn,control_age,control_sex,control_race,control_ethn)
select case_patid,control_patid,buddy_num,map_1_control_patid,map_2_control_patid,map_3_control_patid,map_4_control_patid,case_age,case_sex,case_race,case_ethn,control_age,control_sex,control_race,control_ethn from final_map;

insert into @resultsDatabaseSchema.N3C_CONTROL_MAP (CASE_PATID, BUDDY_NUM, CONTROL_PATID, case_age, case_sex, case_race, case_ethn, control_age, control_sex, control_race, control_ethn)
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
   @resultsDatabaseSchema.N3C_FINAL_MAP final_map
where
   NOT EXISTS(select 1 from @resultsDatabaseSchema.N3C_CONTROL_MAP where final_map.case_patid=N3C_CONTROL_MAP.case_patid and final_map.buddy_num=N3C_CONTROL_MAP.buddy_num);

--populate final table with all members of cohort in a single column
INSERT INTO @resultsDatabaseSchema.N3C_COHORT
    SELECT case_patid
    FROM @resultsDatabaseSchema.N3C_CONTROL_MAP
    UNION
    SELECT control_patid
    FROM @resultsDatabaseSchema.N3C_CONTROL_MAP
	where control_patid is not null;
	
