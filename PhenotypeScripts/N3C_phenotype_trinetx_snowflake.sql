---------------------------------------------------------------------------------------------------------
-- 1. Create tables if it does not exist in current schema
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'START PHENO SCRIPT' as log_entry;
CREATE TABLE IF NOT EXISTS n3c_cohort (
    patient_id          VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS n3c_pheno_version (
    version             VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS n3c_pre_cohort (
    patient_id                      VARCHAR(200)
    , inc_dx_strong                 INT
    , inc_dx_weak                   INT
    , inc_lab_any                   INT
    , inc_lab_pos                   INT
    , pt_age                        VARCHAR(40)
    , sex                           VARCHAR(40)
    , race                          VARCHAR(40)
    , ethnicity                     VARCHAR(40)
);

CREATE TABLE IF NOT EXISTS n3c_case_cohort (
    patient_id                      VARCHAR(200)
    , inc_dx_strong                 INT
    , inc_dx_weak                   INT
    , inc_lab_any                   INT
    , inc_lab_pos                   INT
);

CREATE TABLE IF NOT EXISTS n3c_pre_controls (
    patient_id                      VARCHAR(200)
    , maxenc                        DATE
    , minenc                        DATE
    , daysonhand                    INT
    , randnum                       FLOAT
);

CREATE TABLE IF NOT EXISTS n3c_pre_map (
    patient_id                      VARCHAR(200)
    , pt_age                        VARCHAR(40)
    , sex                           VARCHAR(40)
    , race                          VARCHAR(40)
    , ethnicity                     VARCHAR(40)
    , buddy_num                     INT
    , randnum                       FLOAT
);

CREATE TABLE IF NOT EXISTS n3c_penultimate_map (
    patient_id                      VARCHAR(200)
    , buddy_num                     INT
    , control_patient_id            VARCHAR(200)
    , map_1_patient_id              VARCHAR(200)
    , map_2_patient_id              VARCHAR(200)
    , map_3_patient_id              VARCHAR(200)
    , map_4_patient_id              VARCHAR(200)
    , map_1_control_patient_id      VARCHAR(200)
    , map_2_control_patient_id      VARCHAR(200)
    , map_3_control_patient_id      VARCHAR(200)
    , map_4_control_patient_id      VARCHAR(200)
    , map_1_pt_age                  VARCHAR(40)
    , map_1_sex                     VARCHAR(40)
    , map_1_race                    VARCHAR(40)
    , map_1_ethnicity               VARCHAR(40)
);

CREATE TABLE IF NOT EXISTS n3c_final_map (
    case_patient_id                 VARCHAR(200)
    , buddy_num                     INT
    , control_patient_id            VARCHAR(200)
    , map_1_control_patient_id      VARCHAR(200)
    , map_2_control_patient_id      VARCHAR(200)
    , map_3_control_patient_id      VARCHAR(200)
    , map_4_control_patient_id      VARCHAR(200)
    , case_age                      VARCHAR(40)
    , case_sex                      VARCHAR(40)
    , case_race                     VARCHAR(40)
    , case_ethnicity                VARCHAR(40)
    , control_age                   VARCHAR(40)
    , control_sex                   VARCHAR(40)
    , control_race                  VARCHAR(40)
    , control_ethnicity             VARCHAR(40)
);

--Keeping control table in one schema as it needs to endure multiple runs
----- DO NOT DROP OR TRUNCATE
CREATE TABLE IF NOT EXISTS data_a.n3c_control_map (
    case_patient_id                 VARCHAR(200)
    , buddy_num                     INT
    , control_patient_id            VARCHAR(200)
    , case_age                      VARCHAR(40)
    , case_sex                      VARCHAR(40)
    , case_race                     VARCHAR(40)
    , case_ethnicity                VARCHAR(40)
    , control_age                   VARCHAR(40)
    , control_sex                   VARCHAR(40)
    , control_race                  VARCHAR(40)
    , control_ethnicity             VARCHAR(40)
);

---------------------------------------------------------------------------------------------------------
-- 1-b. Supporting tables for various N3C things
---------------------------------------------------------------------------------------------------------
--Adding a filter table to remove certain codes and/or sources
----- DO NOT DROP OR TRUNCATE
CREATE TABLE IF NOT EXISTS data_a.n3c_filter (
    table_name                      VARCHAR(40)
    , code_system                   VARCHAR(40)
    , code                          VARCHAR(40)
    , reason                        VARCHAR(200)
);
--Adding a table for customization in extract for N3C enhancements (e.g. - long covid)
----- DO NOT DROP OR TRUNCATE
CREATE TABLE IF NOT EXISTS data_a.n3c_initiative (
    initiative                      VARCHAR(40)
    , table_name                    VARCHAR(40)
    , code_system                   VARCHAR(40)
    , code                          VARCHAR(200)
    , reason                        VARCHAR(200)
);

---------------------------------------------------------------------------------------------------------
-- 2. Update pheno version table
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'UPDATING PHENO VERSION TABLE' as log_entry;
TRUNCATE TABLE n3c_pheno_version;
INSERT INTO n3c_pheno_version
SELECT '4.0';

---------------------------------------------------------------------------------------------------------
-- 3. Clear out existing tables
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'TRUNCATING TABLES' as log_entry;
TRUNCATE TABLE n3c_cohort;
TRUNCATE TABLE n3c_pre_cohort;
TRUNCATE TABLE n3c_case_cohort;
TRUNCATE TABLE n3c_pre_controls;
TRUNCATE TABLE n3c_pre_map;
TRUNCATE TABLE n3c_penultimate_map;
TRUNCATE TABLE n3c_final_map;

---------------------------------------------------------------------------------------------------------
-- 4. Create deduplicated patient table for reference
--  Change Log:
--      11/03/23 - Filter out orphan patients to remove duplicates
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'CREATING n3c_dedup_patients' as log_entry;
DROP TABLE IF EXISTS n3c_dedup_patients;
CREATE TABLE n3c_dedup_patients AS
SELECT pt.*
    , DATEDIFF(year, birth_date, GETDATE()) -
        CASE
            WHEN (
                MONTH(GETDATE()) < MONTH(birth_date)
                ) THEN 1
            WHEN (
                MONTH(GETDATE()) = MONTH(birth_date) AND
                DAY(GETDATE()) < DAY(birth_date)
                ) THEN 1
            ELSE 0
        END AS age_in_years
FROM patient pt
    JOIN (
        SELECT source_id, patient_id, RANK() OVER(PARTITION BY patient_id ORDER BY batch_id DESC) AS rnk FROM patient WHERE source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'patient' AND code_system = 'source_id')
    ) ptDedupFilter ON ptDedupFilter.patient_id = pt.patient_id AND ptDedupFilter.source_id = pt.source_id AND ptDedupFilter.rnk = 1
WHERE pt.orphan = 'f'
;

---------------------------------------------------------------------------------------------------------
-- 5. Insert patients into table
--     Change Log:
--        05/11/20 - Updated handling for B97.21
--                 - Added new codes for phenotype v1.4
--         05/29/20 - Added new codes for phenotype v1.5
--        06/08/20 - Added new codes for phenotype v1.6
--        07/13/20 - Update to v2.0
--        08/11/20 - Update to v2.1
--        09/17/20 - Update to v2.2 - Remove some LOINC codes
--        11/18/20 - Update to v3.0
--        02/09/21 - Update to v3.1
--        06/16/21 - Update to v3.3 - Add LOINC codes
--      03/17/22 - Update to v4.0 - Add long covid dx and revise loinc list
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'STARTING INSERT INTO n3c_pre_cohort' as log_entry;
INSERT INTO n3c_pre_cohort
SELECT 
    results.patient_id
    , SUBSTR(results.key,2,1)::int      AS inc_dx_strong
    , SUBSTR(results.key,5,1)::int      AS inc_dx_weak
    , SUBSTR(results.key,4,1)::int      AS inc_lab_any
    , SUBSTR(results.key,1,1)::int      AS inc_lab_pos
    , CASE WHEN age_in_years BETWEEN 0 AND 4 THEN '0-4'
           WHEN age_in_years BETWEEN 5 AND 9 THEN '5-9'
           WHEN age_in_years BETWEEN 10 AND 14 THEN '10-14'
           WHEN age_in_years BETWEEN 15 AND 19 THEN '15-19'
           WHEN age_in_years BETWEEN 20 AND 24 THEN '20-24'
           WHEN age_in_years BETWEEN 25 AND 29 THEN '25-29'
           WHEN age_in_years BETWEEN 30 AND 34 THEN '30-34'
           WHEN age_in_years BETWEEN 35 AND 39 THEN '35-39'
           WHEN age_in_years BETWEEN 40 AND 44 THEN '40-44'
           WHEN age_in_years BETWEEN 45 AND 49 THEN '45-49'
           WHEN age_in_years BETWEEN 50 AND 54 THEN '50-54'
           WHEN age_in_years BETWEEN 55 AND 59 THEN '55-59'
           WHEN age_in_years BETWEEN 60 AND 64 THEN '60-64'
           WHEN age_in_years BETWEEN 65 AND 69 THEN '65-69'
           WHEN age_in_years BETWEEN 70 AND 74 THEN '70-74'
           WHEN age_in_years BETWEEN 75 AND 79 THEN '75-79'
           WHEN age_in_years BETWEEN 80 AND 84 THEN '80-84'
           WHEN age_in_years BETWEEN 85 AND 89 THEN '85-89'
           WHEN age_in_years >= 90 THEN '90+'
      END                               AS pt_age
    , COALESCE(map_sx.mt_code, pat.gender)::varchar(40)         AS sex          --Use mapped value if available -- limit to 40 characters for sites with long unmapped values
    , COALESCE(map_rc.mt_code, pat.race)::varchar(40)           AS race         --Use mapped value if available -- limit to 40 characters for sites with long unmapped values
    , COALESCE(map_et.mt_code, pat.ethnicity)::varchar(40)      AS ethnicity    --Use mapped value if available -- limit to 40 characters for sites with long unmapped values
FROM (
    SELECT 
        patient_id
        , LPAD(SUM(key)::varchar,5,'0')    as key
    FROM (
        ---------------------------------------------------------------------------------------------------------
        -- DX Strong - Patient has one of the codes
        ---------------------------------------------------------------------------------------------------------
        SELECT distinct 
            dx.patient_id    AS patient_id
            , '01000'        AS key            --second digit indicates strong dx
        FROM diagnosis dx
        JOIN mapping mp on mp.provider_code = (dx.code_system || ':' || dx.code)
        LEFT JOIN data_a.n3c_filter flt ON flt.table_name = 'diagnosis' AND flt.code_system = dx.code_system AND flt.code = dx.code
        WHERE flt.reason IS NULL
        AND dx.date >= '2020-01-01'
        AND 
        (    -- Strong DX List
            mp.mt_code IN ('UMLS:ICD10CM:U07.1', 'UMLS:ICD10CM:J12.82', 'UMLS:ICD10CM:M35.81', 'UMLS:ICD10CM:U09.9')
            -- special handling for B97.21 & B97.29
            OR (mp.mt_code IN ('UMLS:ICD10CM:B97.21', 'UMLS:ICD10CM:B97.29') AND dx.date < '2020-04-01')
        )
        AND dx.source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'diagnosis' AND code_system = 'source_id')
        ---------------------------------------------------------------------------------------------------------
        -- DX Weak - Patient has 2 or more of the codes on same encounter/date 
        ---------------------------------------------------------------------------------------------------------
        UNION
        SELECT distinct
            dx_weak.patient_id    AS patient_id
            , '00001'            AS key            --fifth digit indicates weak dx
        FROM (
            SELECT distinct patient_id
            FROM (
                SELECT 
                    dx.patient_id
                    , dx.encounter_id
                    , count(distinct mp.mt_code) as dx_cnt
                FROM diagnosis dx
                JOIN mapping mp on mp.provider_code = (dx.code_system || ':' || dx.code)
                LEFT JOIN data_a.n3c_filter flt ON flt.table_name = 'diagnosis' AND flt.code_system = dx.code_system AND flt.code = dx.code
                WHERE flt.reason IS NULL
                AND dx.date >= '2020-01-01' AND dx.date <= '2020-05-01'
                AND 
                (    -- Weak DX List - Individual Codes
                    mp.mt_code IN ('UMLS:ICD10CM:Z20.828'
                        , 'UMLS:ICD10CM:B34.2'
                        , 'UMLS:ICD10CM:J06.9'
                        , 'UMLS:ICD10CM:J98.8'
                        , 'UMLS:ICD10CM:R43.0'
                        , 'UMLS:ICD10CM:R43.2'
                        , 'UMLS:ICD10CM:R07.1'
                        , 'UMLS:ICD10CM:R68.83')
                    -- special handling for B97.21 & B97.29
                    OR (mp.mt_code IN ('UMLS:ICD10CM:B97.21', 'UMLS:ICD10CM:B97.29') AND dx.date >= '2020-04-01')
                    -- Weak DX List - Code Ranges
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:R50%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:R05%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:R06.0%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J12%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J18%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J20%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J40%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J21%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J96%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J22%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J80%'
                )
                AND dx.source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'diagnosis' AND code_system = 'source_id')
                GROUP BY dx.patient_id, dx.encounter_id
                HAVING count(distinct mp.mt_code) >= 2
            ) dx_weak_enc
            UNION
            SELECT distinct patient_id
            FROM (
                SELECT 
                    dx.patient_id
                    , dx.date
                    , count(distinct mp.mt_code) as dx_cnt
                FROM diagnosis dx
                JOIN mapping mp on mp.provider_code = (dx.code_system || ':' || dx.code)
                LEFT JOIN data_a.n3c_filter flt ON flt.table_name = 'diagnosis' AND flt.code_system = dx.code_system AND flt.code = dx.code
                WHERE flt.reason IS NULL
                AND dx.date >= '2020-01-01' AND dx.date <= '2020-05-01'
                AND 
                (    -- Weak DX List - Individual Codes
                    mp.mt_code IN ('UMLS:ICD10CM:Z20.828'
                        , 'UMLS:ICD10CM:B34.2'
                        , 'UMLS:ICD10CM:J06.9'
                        , 'UMLS:ICD10CM:J98.8'
                        , 'UMLS:ICD10CM:R43.0'
                        , 'UMLS:ICD10CM:R43.2'
                        , 'UMLS:ICD10CM:R07.1'
                        , 'UMLS:ICD10CM:R68.83')
                    -- special handling for B97.21 & B97.29
                    OR (mp.mt_code IN ('UMLS:ICD10CM:B97.21', 'UMLS:ICD10CM:B97.29') AND dx.date >= '2020-04-01')
                    -- Weak DX List - Code Ranges
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:R50%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:R05%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:R06.0%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J12%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J18%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J20%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J40%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J21%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J96%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J22%'
                    OR mp.mt_code LIKE 'UMLS:ICD10CM:J80%'
                )
                AND dx.source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'diagnosis' AND code_system = 'source_id')
                GROUP BY dx.patient_id, dx.date
                HAVING count(distinct mp.mt_code) >= 2
            ) dx_weak_date
        ) dx_weak
        ---------------------------------------------------------------------------------------------------------
        -- LAB - Patient has one of the codes
        ---------------------------------------------------------------------------------------------------------
        UNION
        SELECT
            labs.patient_id    AS patient_id
            , CASE 
                WHEN labs.numPositive > 0 THEN '10010'    --first digit indicates positive covid lab
                ELSE '00010'                            --fourth digit indicates any covid lab
                END            AS key
        FROM (
            SELECT 
                lr.patient_id    AS patient_id
                , COUNT(1)        AS numLabs
                , SUM(CASE WHEN mpRes.mt_code = 'TNX:LAB_RESULT:Positive' THEN 1 ELSE 0 END)    as numPositive
            FROM lab_result lr
            LEFT JOIN mapping mpLab on mpLab.provider_code = (lr.observation_code_system || ':' || lr.observation_code)
            LEFT JOIN mapping mpRes on mpRes.provider_code = ('TNX:LAB_RESULT:' || lr.lab_result_text_val)
            LEFT JOIN data_a.n3c_filter flt ON flt.table_name = 'lab_result' AND flt.code_system = lr.observation_code_system AND flt.code = lr.observation_code
            WHERE flt.reason IS NULL
            AND lr.test_date >=  '2020-01-01'
            AND 
            (    -- LOINC List
                mpLab.mt_code IN ('UMLS:LNC:94307-6'
                    ,'UMLS:LNC:94308-4'
                    ,'UMLS:LNC:94309-2'
                    ,'UMLS:LNC:94314-2'
                    ,'UMLS:LNC:94316-7'
                    ,'UMLS:LNC:94500-6'
                    ,'UMLS:LNC:94507-1'
                    ,'UMLS:LNC:94508-9'
                    ,'UMLS:LNC:94533-7'
                    ,'UMLS:LNC:94534-5'
                    ,'UMLS:LNC:94547-7'
                    ,'UMLS:LNC:94558-4'
                    ,'UMLS:LNC:94559-2'
                    ,'UMLS:LNC:94562-6'
                    ,'UMLS:LNC:94563-4'
                    ,'UMLS:LNC:94564-2'
                    ,'UMLS:LNC:94565-9'
                    ,'UMLS:LNC:94639-2'
                    ,'UMLS:LNC:94640-0'
                    ,'UMLS:LNC:94641-8'
                    ,'UMLS:LNC:94660-8'
                    ,'UMLS:LNC:94756-4'
                    ,'UMLS:LNC:94757-2'
                    ,'UMLS:LNC:94759-8'
                    ,'UMLS:LNC:94760-6'
                    ,'UMLS:LNC:94761-4'
                    ,'UMLS:LNC:94762-2'
                    ,'UMLS:LNC:94763-0'
                    ,'UMLS:LNC:94766-3'
                    ,'UMLS:LNC:94767-1'
                    ,'UMLS:LNC:94768-9'
                    ,'UMLS:LNC:94822-4'
                    ,'UMLS:LNC:94845-5'
                    ,'UMLS:LNC:95125-1'
                    ,'UMLS:LNC:95209-3'
                    ,'UMLS:LNC:95406-5'
                    ,'UMLS:LNC:95409-9'
                    ,'UMLS:LNC:95411-5'
                    ,'UMLS:LNC:95416-4'
                    ,'UMLS:LNC:95424-8'
                    ,'UMLS:LNC:95425-5'
                    ,'UMLS:LNC:95542-7'
                    ,'UMLS:LNC:95608-6'
                    ,'UMLS:LNC:95609-4'
                    ,'UMLS:LNC:95823-1'
                    ,'UMLS:LNC:95824-9'
                    ,'UMLS:LNC:95825-6'
                    ,'UMLS:LNC:95970-0'
                    ,'UMLS:LNC:95971-8'
                    ,'UMLS:LNC:96091-4'
                    ,'UMLS:LNC:96119-3'
                    ,'UMLS:LNC:96120-1'
                    ,'UMLS:LNC:96121-9'
                    ,'UMLS:LNC:96122-7'
                    ,'UMLS:LNC:96123-5'
                    ,'UMLS:LNC:96448-6'
                    ,'UMLS:LNC:96603-6'
                    ,'UMLS:LNC:96752-1'
                    ,'UMLS:LNC:96763-8'
                    ,'UMLS:LNC:96765-3'
                    ,'UMLS:LNC:96797-6'
                    ,'UMLS:LNC:96829-7'
                    ,'UMLS:LNC:96957-6'
                    ,'UMLS:LNC:96958-4'
                    ,'UMLS:LNC:96986-5'
                    ,'UMLS:LNC:97097-0'
                    ,'UMLS:LNC:97098-8'
                    ,'UMLS:LNC:98069-8'
                    ,'UMLS:LNC:98131-6'
                    ,'UMLS:LNC:98132-4'
                    ,'UMLS:LNC:98493-0'
                    ,'UMLS:LNC:98494-8'
                    ,'UMLS:LNC:99596-9'
                    ,'UMLS:LNC:99597-7'
                    ,'UMLS:LNC:99772-6')
                --OTHER LAB
                -- xxxxxxxxxxxxxxxxxxxxxxxxxxxx
                -- Name match removed in v4.0
                -- xxxxxxxxxxxxxxxxxxxxxxxxxxxx
                --OR UPPER(lr.observation_desc) LIKE '%COVID-19%'
                --OR UPPER(lr.observation_desc) LIKE '%SARS-COV-2%'
            )
            AND lr.source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'lab_result' AND code_system = 'source_id')
            GROUP BY lr.patient_id
        ) labs
    ) pt_list
    GROUP BY patient_id
) results
    LEFT JOIN n3c_dedup_patients pat on pat.patient_id = results.patient_id
    LEFT JOIN mapping map_sx ON map_sx.provider_code = ('DEM|GENDER:' || pat.gender)
    LEFT JOIN mapping map_rc ON map_rc.provider_code = ('DEM|RACE:' || pat.race)
    LEFT JOIN mapping map_et ON map_et.provider_code = ('DEM|ETHNICITY:' || pat.ethnicity)
;

---------------------------------------------------------------------------------------------------------
-- 6. Create Case Cohort
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'STARTING INSERT INTO n3c_case_cohort' as log_entry;
INSERT INTO n3c_case_cohort
SELECT
    patient_id
    , inc_dx_strong
    , inc_dx_weak
    , inc_lab_any
    , inc_lab_pos
FROM n3c_pre_cohort
WHERE inc_dx_strong = 1
    OR inc_lab_pos = 1
    OR inc_dx_weak = 1
;

---------------------------------------------------------------------------------------------------------
-- 7. Removals from n3c_control_map
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'STARTING DELETE FROM n3c_control_map' as log_entry;
-- Remove if someone who was in the control group is now a case
DELETE FROM data_a.n3c_control_map WHERE control_patient_id IN (SELECT patient_id FROM n3c_case_cohort);

-- Remove if patient id does not exist anymore
DELETE FROM data_a.n3c_control_map WHERE case_patient_id NOT IN (SELECT patient_id FROM patient);
DELETE FROM data_a.n3c_control_map WHERE control_patient_id NOT IN (SELECT patient_id FROM patient);

-- Remove if case no longer meets phenotype criteria
DELETE FROM data_a.n3c_control_map WHERE case_patient_id NOT IN (SELECT patient_id FROM n3c_case_cohort);

-- Remove if control patient ID is null
DELETE FROM data_a.n3c_control_map WHERE control_patient_id IS NULL;

---------------------------------------------------------------------------------------------------------
-- 8. Create Additional Control Tables
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'STARTING INSERT INTO n3c_pre_controls' as log_entry;
INSERT INTO n3c_pre_controls
SELECT
    c.patient_id
    , max(e.start_date)
    , min(e.start_date)
    , DATEDIFF(day, min(e.start_date), max(e.start_date))
    , RANDOM()
FROM n3c_pre_cohort c
JOIN encounter e ON c.patient_id = e.patient_id AND e.start_date BETWEEN '2018-01-01' AND CURRENT_DATE()
WHERE c.inc_lab_any = 1
    AND c.inc_dx_strong = 0
    AND c.inc_lab_pos = 0
    AND c.inc_dx_weak = 0
    AND c.patient_id NOT IN (SELECT control_patient_id FROM data_a.n3c_control_map)
    AND e.source_id NOT IN (SELECT code FROM data_a.n3c_filter WHERE table_name = 'encounter' AND code_system = 'source_id')
GROUP BY c.patient_id
HAVING DATEDIFF(day, min(e.start_date), max(e.start_date)) >= 10
;

SELECT CURRENT_TIMESTAMP as date_time, 'STARTING INSERT INTO n3c_pre_map' as log_entry;
INSERT INTO n3c_pre_map
SELECT
    c.patient_id
    , c.pt_age
    , c.sex
    , c.race
    , c.ethnicity
    , buddies.buddy_num
    , RANDOM() AS randnum
FROM n3c_pre_cohort c
JOIN (SELECT 1 AS buddy_num UNION SELECT 2) buddies on 1=1
WHERE c.inc_dx_strong = 1
    OR c.inc_lab_pos = 1
    OR c.inc_dx_weak = 1
;
-- Delete any case patients who already have a buddy match
DELETE FROM n3c_pre_map WHERE (patient_id, buddy_num) IN (SELECT case_patient_id, buddy_num FROM data_a.n3c_control_map where control_patient_id IS NOT NULL);

---------------------------------------------------------------------------------------------------------
-- 9. Buddy Match
--    - Now that the pre-cohort and case tables are populated, we start matching cases and controls, 
--      and updating the case and control tables as needed.
--    - All cases need two control "buddies". 
--    - We select on progressively looser demographic criteria until every case has two control matches,
--      or we run out of patients in the control pool.
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'STARTING INSERT INTO n3c_penultimate_map' as log_entry;
INSERT INTO n3c_penultimate_map
WITH
cases_1 AS (
    SELECT
        pre_map.*
        , ROW_NUMBER() OVER(PARTITION BY pt_age, sex, race, ethnicity ORDER BY randnum) AS join_row_1
    FROM n3c_pre_map pre_map
),
controls_1 AS (
    SELECT
        subq.*
        , ROW_NUMBER() OVER(PARTITION BY pt_age, sex, race, ethnicity ORDER BY randnum) AS join_row_1
    FROM (
        SELECT
            c.patient_id
            , c.pt_age
            , c.sex
            , c.race
            , c.ethnicity
            , pre.randnum
        FROM n3c_pre_cohort c
            JOIN n3c_pre_controls pre on pre.patient_id = c.patient_id
    ) subq
),
map_1 AS (
    SELECT
        cases.*
        , controls.patient_id as control_patient_id
    FROM cases_1 cases
        LEFT OUTER JOIN controls_1 controls ON cases.pt_age = controls.pt_age
            AND cases.sex = controls.sex
            AND cases.race = controls.race
            AND cases.ethnicity = controls.ethnicity
            AND cases.join_row_1 = controls.join_row_1
),
cases_2 AS (
    SELECT
        map_1.*
        , ROW_NUMBER() OVER(PARTITION BY pt_age, sex, race ORDER BY randnum) AS join_row_2
    FROM map_1
    WHERE control_patient_id IS NULL
),
controls_2 AS (
    SELECT
        controls_1.*
        , ROW_NUMBER() OVER(PARTITION BY pt_age, sex, race ORDER BY randnum) AS join_row_2
    FROM controls_1
    WHERE patient_id NOT IN (SELECT control_patient_id FROM map_1 WHERE control_patient_id IS NOT NULL)
),
map_2 AS (
    SELECT
        cases.patient_id
        , cases.pt_age
        , cases.sex
        , cases.race
        , cases.ethnicity
        , cases.buddy_num
        , cases.randnum
        , cases.join_row_1
        , cases.join_row_2
        , controls.patient_id as control_patient_id
    FROM cases_2 cases
        LEFT OUTER JOIN controls_2 controls ON cases.pt_age = controls.pt_age
            AND cases.sex = controls.sex
            AND cases.race = controls.race
            AND cases.join_row_2 = controls.join_row_2
),
cases_3 AS (
    SELECT
        map_2.*
        , ROW_NUMBER() OVER(PARTITION BY pt_age, sex ORDER BY randnum) AS join_row_3
    FROM map_2
    WHERE control_patient_id IS NULL
),
controls_3 AS (
    SELECT
        controls_2.*
        , ROW_NUMBER() OVER(PARTITION BY pt_age, sex ORDER BY randnum) AS join_row_3
    FROM controls_2
    WHERE patient_id NOT IN (SELECT control_patient_id FROM map_2 WHERE control_patient_id IS NOT NULL)
),
map_3 AS (
    SELECT
        cases.patient_id
        , cases.pt_age
        , cases.sex
        , cases.race
        , cases.ethnicity
        , cases.buddy_num
        , cases.randnum
        , cases.join_row_1
        , cases.join_row_2
        , cases.join_row_3
        , controls.patient_id as control_patient_id
    FROM cases_3 cases
        LEFT OUTER JOIN controls_3 controls ON cases.pt_age = controls.pt_age
            AND cases.sex = controls.sex
            AND cases.join_row_3 = controls.join_row_3
),
cases_4 AS (
    SELECT
        map_3.*
        , ROW_NUMBER() OVER(PARTITION BY sex ORDER BY randnum) AS join_row_4
    FROM map_3
    WHERE control_patient_id IS NULL
),
controls_4 AS (
    SELECT
        controls_3.*
        , ROW_NUMBER() OVER(PARTITION BY sex ORDER BY randnum) AS join_row_4
    FROM controls_3
    WHERE patient_id NOT IN (SELECT control_patient_id FROM map_3 WHERE control_patient_id IS NOT NULL)
),
map_4 AS (
    SELECT
        cases.patient_id
        , cases.pt_age
        , cases.sex
        , cases.race
        , cases.ethnicity
        , cases.buddy_num
        , cases.randnum
        , cases.join_row_1
        , cases.join_row_2
        , cases.join_row_3
        , cases.join_row_4
        , controls.patient_id as control_patient_id
    FROM cases_4 cases
        LEFT OUTER JOIN controls_4 controls ON cases.sex = controls.sex
            AND cases.join_row_4 = controls.join_row_4
)
SELECT
    map_1.patient_id
    , map_1.buddy_num
    , COALESCE(map_1.control_patient_id, map_2.control_patient_id, map_3.control_patient_id, map_4.control_patient_id)
    , map_1.patient_id
    , map_2.patient_id
    , map_3.patient_id
    , map_4.patient_id
    , map_1.control_patient_id
    , map_2.control_patient_id
    , map_3.control_patient_id
    , map_4.control_patient_id
    , map_1.pt_age
    , map_1.sex
    , map_1.race
    , map_1.ethnicity
FROM map_1
    LEFT OUTER JOIN map_2 ON map_2.patient_id = map_1.patient_id AND map_2.buddy_num = map_1.buddy_num
    LEFT OUTER JOIN map_3 ON map_3.patient_id = map_1.patient_id AND map_3.buddy_num = map_1.buddy_num
    LEFT OUTER JOIN map_4 ON map_4.patient_id = map_1.patient_id AND map_4.buddy_num = map_1.buddy_num
;

SELECT CURRENT_TIMESTAMP as date_time, 'STARTING INSERT INTO n3c_final_map' as log_entry;
INSERT INTO n3c_final_map
SELECT
    pen.patient_id
    , pen.buddy_num
    , pen.control_patient_id
    , pen.map_1_control_patient_id
    , pen.map_2_control_patient_id
    , pen.map_3_control_patient_id
    , pen.map_4_control_patient_id
    , case_pt.age_in_years
    , COALESCE(pen.map_1_sex, case_pt.gender)::varchar(40)            --Use saved value for case patient else patient value -- limit to 40 characters for sites with long unmapped values
    , COALESCE(pen.map_1_race, case_pt.race)::varchar(40)            --Use saved value for case patient else patient value -- limit to 40 characters for sites with long unmapped values
    , COALESCE(pen.map_1_ethnicity, case_pt.ethnicity)::varchar(40)    --Use saved value for case patient else patient value -- limit to 40 characters for sites with long unmapped values
    , control_pt.age_in_years
    , COALESCE(map_sx.mt_code, control_pt.gender)::varchar(40)            --Use mapped value if available -- limit to 40 characters for sites with long unmapped values
    , COALESCE(map_rc.mt_code, control_pt.race)::varchar(40)            --Use mapped value if available -- limit to 40 characters for sites with long unmapped values
    , COALESCE(map_et.mt_code, control_pt.ethnicity)::varchar(40)        --Use mapped value if available -- limit to 40 characters for sites with long unmapped values
FROM n3c_penultimate_map pen
    JOIN n3c_dedup_patients case_pt on case_pt.patient_id = pen.patient_id
    LEFT JOIN n3c_dedup_patients control_pt on control_pt.patient_id = pen.control_patient_id
    LEFT JOIN mapping map_sx ON map_sx.provider_code = ('DEM|GENDER:' || control_pt.gender)
    LEFT JOIN mapping map_rc ON map_rc.provider_code = ('DEM|RACE:' || control_pt.race)
    LEFT JOIN mapping map_et ON map_et.provider_code = ('DEM|ETHNICITY:' || control_pt.ethnicity)
;

SELECT CURRENT_TIMESTAMP as date_time, 'STARTING INSERT INTO n3c_control_map' as log_entry;
INSERT INTO data_a.n3c_control_map
SELECT
    case_patient_id
    , buddy_num
    , control_patient_id
    , REPLACE(case_age,'|',' ')
    , REPLACE(case_sex,'|',' ')
    , REPLACE(case_race,'|',' ')
    , REPLACE(case_ethnicity,'|',' ')
    , REPLACE(control_age,'|',' ')
    , REPLACE(control_sex,'|',' ')
    , REPLACE(control_race,'|',' ')
    , REPLACE(control_ethnicity,'|',' ')
FROM n3c_final_map fin
WHERE NOT EXISTS
(
    SELECT 1 
    FROM data_a.n3c_control_map
    WHERE fin.case_patient_id = n3c_control_map.case_patient_id 
        AND fin.buddy_num = n3c_control_map.buddy_num
)
;

---------------------------------------------------------------------------------------------------------
-- 10. Populate cohort table with all members of cohort
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'STARTING INSERT INTO n3c_cohort' as log_entry;
INSERT INTO n3c_cohort
SELECT DISTINCT case_patient_id
FROM data_a.n3c_control_map
UNION
SELECT DISTINCT control_patient_id
FROM data_a.n3c_control_map
WHERE control_patient_id IS NOT NULL
;

SELECT CURRENT_TIMESTAMP as date_time, 'DONE WITH PHENO SCRIPT' as log_entry;
COMMIT;
