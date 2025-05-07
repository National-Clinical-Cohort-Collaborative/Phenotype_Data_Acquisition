SELECT CURRENT_TIMESTAMP as date_time, 'Starting ADT extract...' as log_entry;

---------------------------------------------------------------------------------------------------------
-- Supporting table for raw data
---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS data_a.n3c_adt_raw (
    patient_id              VARCHAR(200)
    , encounter_id          VARCHAR(200)
    , start_datetime        DATETIME
    , end_datetime          DATETIME
    , location              VARCHAR(200)
    , service               VARCHAR(100)
    , accommodation_code    VARCHAR(100)
    , level_of_care         VARCHAR(100)
);

---------------------------------------------------------------------------------------------------------
-- ADT Events
-- OUTPUT_FILE: ADT.csv
---------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS n3c_adt;

SELECT CURRENT_TIMESTAMP as date_time, 'Extracting ADT data' as log_entry;
CREATE TABLE n3c_adt AS
SELECT
    n3c.patient_id              AS PATIENT_ID
    , COALESCE((HASH(COALESCE((select code from data_a.n3c_initiative where initiative = 'Source ID Replacement' and table_name = 'encounter' and code_system = enc.source_id), enc.source_id)) || enc.encounter_id), adt.encounter_id)	AS ENCOUNTER_ID
    , adt.start_datetime        AS ADT_EVENT_START_DATETIME
    , adt.end_datetime          AS ADT_EVENT_END_DATETIME
    , adt.location              AS ADT_EVENT_LOCATION
    , adt.service               AS ADT_EVENT_SERVICE
    , adt.accommodation_code    AS ADT_EVENT_ACCOMMODATION_CODE
    , adt.level_of_care         AS ADT_EVENT_LEVEL_OF_CARE
    , CASE WHEN loc.reason like '%ICU%' THEN TRUE
        WHEN svc.reason like '%ICU%' THEN TRUE
        WHEN ac.reason  like '%ICU%' THEN TRUE
        WHEN lvl.reason like '%ICU%' THEN TRUE
        ELSE FALSE 
        END                     AS ADT_EVENT_IS_ICU
    , CASE WHEN loc.reason like '%ED%' THEN TRUE
        WHEN svc.reason like '%ED%' THEN TRUE
        WHEN ac.reason  like '%ED%' THEN TRUE
        WHEN lvl.reason like '%ED%' THEN TRUE
        ELSE FALSE 
        END                     AS ADT_EVENT_IS_ED
FROM n3c_cohort n3c
    JOIN data_a.n3c_adt_raw adt ON adt.patient_id = n3c.patient_id
    LEFT JOIN encounter enc ON enc.encounter_id = adt.encounter_id
    LEFT JOIN data_a.n3c_initiative loc ON loc.code = adt.location AND loc.table_name = 'n3c_adt_raw' AND loc.code_system = 'location'
    LEFT JOIN data_a.n3c_initiative svc ON svc.code = adt.service AND svc.table_name = 'n3c_adt_raw' AND svc.code_system = 'service'
    LEFT JOIN data_a.n3c_initiative ac ON ac.code = adt.accommodation_code AND ac.table_name = 'n3c_adt_raw' AND ac.code_system = 'accommodation_code'
    LEFT JOIN data_a.n3c_initiative lvl ON lvl.code = adt.level_of_care AND lvl.table_name = 'n3c_adt_raw' AND lvl.code_system = 'level_of_care'
;

---------------------------------------------------------------------------------------------------------
-- UPDATE DATA COUNTS
---------------------------------------------------------------------------------------------------------
SELECT CURRENT_TIMESTAMP as date_time, 'Adding ADT to n3c_data_counts' as log_entry;

INSERT INTO n3c_data_counts SELECT 'ADT', count(1) FROM n3c_adt;
COMMIT;
