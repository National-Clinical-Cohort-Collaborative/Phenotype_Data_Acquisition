---------------------------------------------------------------------------------------------------------
-- 1. Create table if it does not exist in current schema
---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS :TNX_SCHEMA.n3c_cohort (
	patient_id	VARCHAR(200)
);

---------------------------------------------------------------------------------------------------------
-- 2. Clear out existing patient list
---------------------------------------------------------------------------------------------------------
TRUNCATE TABLE :TNX_SCHEMA.n3c_cohort;

---------------------------------------------------------------------------------------------------------
-- 3. Insert patients into table
-- 	Change Log:
--		5/11/20 - Updated handling for B97.21
--				- Added new codes for phenotype v1.4
---------------------------------------------------------------------------------------------------------

INSERT INTO n3c_cohort
SELECT distinct patient_id
FROM (
	---------------------------------------------------------------------------------------------------------
	-- DX Strong - Patient has one of the codes
	---------------------------------------------------------------------------------------------------------
	SELECT distinct dx.patient_id
	FROM :TNX_SCHEMA.diagnosis dx
	JOIN :TNX_SCHEMA.mapping mp on mp.provider_code = (dx.code_system || ':' || dx.code)
	WHERE dx.date >= '2020-01-01'
	AND 
	(	-- Strong DX List
		mp.mt_code IN ('UMLS:ICD10CM:U07.1')
		-- special handling for B97.21 & B97.29
		OR (mp.mt_code IN ('UMLS:ICD10CM:B97.21', 'UMLS:ICD10CM:B97.29') AND dx.date < '2020-04-01')
	)
	---------------------------------------------------------------------------------------------------------
	-- DX Weak - Patient has 2 or more of the codes on same encounter/date 
	---------------------------------------------------------------------------------------------------------
	UNION
	SELECT distinct patient_id
	FROM (
		SELECT 
			dx.patient_id
			, dx.encounter_id
			, count(distinct mp.mt_code) as dx_cnt
		FROM :TNX_SCHEMA.diagnosis dx
		JOIN :TNX_SCHEMA.mapping mp on mp.provider_code = (dx.code_system || ':' || dx.code)
		WHERE dx.date >= '2020-01-01'
		AND 
		(	-- Weak DX List - Individual Codes
			mp.mt_code IN ('UMLS:ICD10CM:Z20.828'
				, 'UMLS:ICD10CM:B34.2'
				, 'UMLS:ICD10CM:J06.9'
				, 'UMLS:ICD10CM:J98.8'
				, 'UMLS:ICD10CM:R43.0'
				, 'UMLS:ICD10CM:R43.2'
				, 'UMLS:ICD10CM:R07.1'		-- New in 1.4
				, 'UMLS:ICD10CM:R68.83')	-- New in 1.4
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
		FROM :TNX_SCHEMA.diagnosis dx
		JOIN :TNX_SCHEMA.mapping mp on mp.provider_code = (dx.code_system || ':' || dx.code)
		WHERE dx.date >= '2020-01-01'
		AND 
		(	-- Weak DX List - Individual Codes
			mp.mt_code IN ('UMLS:ICD10CM:Z20.828'
				, 'UMLS:ICD10CM:B34.2'
				, 'UMLS:ICD10CM:J06.9'
				, 'UMLS:ICD10CM:J98.8'
				, 'UMLS:ICD10CM:R43.0'
				, 'UMLS:ICD10CM:R43.2'
				, 'UMLS:ICD10CM:R07.1'		-- New in 1.4
				, 'UMLS:ICD10CM:R68.83')	-- New in 1.4
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
		GROUP BY dx.patient_id, dx.date
		HAVING count(distinct mp.mt_code) >= 2
	) dx_weak_date
	---------------------------------------------------------------------------------------------------------
	-- PX - Patient has one of the codes
	---------------------------------------------------------------------------------------------------------
	UNION
	SELECT distinct px.patient_id
	FROM :TNX_SCHEMA.procedure px
	JOIN :TNX_SCHEMA.mapping mp on mp.provider_code = (px.code_system || ':' || px.code)
	WHERE px.date >= '2020-01-01'
	AND 
	(	-- PX List
		mp.mt_code IN ('UMLS:HCPCS:U0001'
			, 'UMLS:HCPCS:U0002'
			, 'UMLS:CPT:87635'
			, 'UMLS:CPT:86318'
			, 'UMLS:CPT:86328'
			, 'UMLS:CPT:86769')
	)
	---------------------------------------------------------------------------------------------------------
	-- LAB - Patient has one of the codes
	---------------------------------------------------------------------------------------------------------
	UNION
	SELECT distinct lr.patient_id
	FROM :TNX_SCHEMA.lab_result lr
	LEFT JOIN :TNX_SCHEMA.mapping mp on mp.provider_code = (lr.observation_code_system || ':' || lr.observation_code)
	WHERE lr.test_date >=  '2020-01-01'
	AND 
	(	-- LOINC List
		mp.mt_code IN ('UMLS:LNC:94306-8'	--new in 1.4
			,'UMLS:LNC:94307-6'
			,'UMLS:LNC:94308-4'
			,'UMLS:LNC:94309-2'
			,'UMLS:LNC:94310-0'
			,'UMLS:LNC:94311-8'
			,'UMLS:LNC:94312-6'
			,'UMLS:LNC:94313-4'
			,'UMLS:LNC:94314-2'
			,'UMLS:LNC:94315-9'
			,'UMLS:LNC:94316-7'
			,'UMLS:LNC:94500-6'
			,'UMLS:LNC:94502-2'
			,'UMLS:LNC:94503-0'		--new in 1.4
			,'UMLS:LNC:94504-8'		--new in 1.4
			,'UMLS:LNC:94505-5'
			,'UMLS:LNC:94506-3'
			,'UMLS:LNC:94507-1'
			,'UMLS:LNC:94508-9'
			,'UMLS:LNC:94509-7'
			,'UMLS:LNC:94510-5'
			,'UMLS:LNC:94511-3'
			,'UMLS:LNC:94531-1'		--new in 1.4
			,'UMLS:LNC:94532-9'
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
			,'UMLS:LNC:94642-6'
			,'UMLS:LNC:94643-4'
			,'UMLS:LNC:94644-2'
			,'UMLS:LNC:94645-9'
			,'UMLS:LNC:94646-7'
			,'UMLS:LNC:94647-5'
			,'UMLS:LNC:94660-8'
			,'UMLS:LNC:94661-6'
			,'UMLS:LNC:94702-0'		--new in 1.4
			,'UMLS:LNC:94758-0'		--new in 1.4
			,'UMLS:LNC:94759-8'		--new in 1.4
			,'UMLS:LNC:94760-6'		--new in 1.4
			,'UMLS:LNC:94762-2'		--new in 1.4
			,'UMLS:LNC:94763-0'		--new in 1.4
			,'UMLS:LNC:94764-8'		--new in 1.4
			,'UMLS:LNC:94765-5'		--new in 1.4
			,'UMLS:LNC:94766-3'		--new in 1.4
			,'UMLS:LNC:94767-1'		--new in 1.4
			,'UMLS:LNC:94768-9'		--new in 1.4
			,'UMLS:LNC:94769-7'		--new in 1.4
			,'UMLS:LNC:94819-0')	--new in 1.4
		--OTHER LAB
		OR UPPER(lr.observation_desc) LIKE '%COVID-19%'
		OR UPPER(lr.observation_desc) LIKE '%SARS-COV-2%'
	)
) pt_list
WHERE patient_id not IN (SELECT patient_id FROM :TNX_SCHEMA.n3c_cohort)
