---------------------------------------------------------------------------------------------------------
-- 1. Create tables if it does not exist in current schema
---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS :TNX_SCHEMA.n3c_cohort (
	patient_id	VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS :TNX_SCHEMA.n3c_pheno_version (
 version VARCHAR(200)
);

---------------------------------------------------------------------------------------------------------
-- 2. Update pheno version table
---------------------------------------------------------------------------------------------------------
TRUNCATE TABLE :TNX_SCHEMA.n3c_pheno_version;
INSERT INTO :TNX_SCHEMA.n3c_pheno_version
SELECT '2.1';

---------------------------------------------------------------------------------------------------------
-- 3. Clear out existing patient list
---------------------------------------------------------------------------------------------------------
TRUNCATE TABLE :TNX_SCHEMA.n3c_cohort;

---------------------------------------------------------------------------------------------------------
-- 4. Insert patients into table
-- 	Change Log:
--		5/11/20 - Updated handling for B97.21
--				- Added new codes for phenotype v1.4
-- 		5/29/20 - Added new codes for phenotype v1.5
--		6/08/20 - Added new codes for phenotype v1.6
--		7/13/20 - Update to v2.0
--				- Adding 5 digit binary key to help with exclusion
--					1 - Lab Positive
--					2 - Strong Diagnosis
--					3 - Procedure
--					4 - Any Lab Test
--					5 - Weak Diagnosis
--		8/11/20 - Update to v2.1
---------------------------------------------------------------------------------------------------------

INSERT INTO :TNX_SCHEMA.n3c_cohort
SELECT distinct results.patient_id
FROM (
	SELECT 
		patient_id
		, LPAD(SUM(key)::varchar,5,'0')	as key
	FROM (
		---------------------------------------------------------------------------------------------------------
		-- DX Strong - Patient has one of the codes
		---------------------------------------------------------------------------------------------------------
		SELECT distinct 
			dx.patient_id	AS patient_id
			, '01000'		AS key			--second digit indicates strong dx
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
		SELECT distinct
			dx_weak.patient_id	AS patient_id
			, '00001'			AS key			--fifth digit indicates weak dx
		FROM (
			SELECT distinct patient_id
			FROM (
				SELECT 
					dx.patient_id
					, dx.encounter_id
					, count(distinct mp.mt_code) as dx_cnt
				FROM :TNX_SCHEMA.diagnosis dx
				JOIN :TNX_SCHEMA.mapping mp on mp.provider_code = (dx.code_system || ':' || dx.code)
				WHERE dx.date >= '2020-01-01' and dx.date <= '2020-05-01'
				AND 
				(	-- Weak DX List - Individual Codes
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
				WHERE dx.date >= '2020-01-01' and dx.date <= '2020-05-01'
				AND 
				(	-- Weak DX List - Individual Codes
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
				GROUP BY dx.patient_id, dx.date
				HAVING count(distinct mp.mt_code) >= 2
			) dx_weak_date
		) dx_weak
		---------------------------------------------------------------------------------------------------------
		-- LAB - Patient has one of the codes
		---------------------------------------------------------------------------------------------------------
		UNION
		SELECT
			labs.patient_id	AS patient_id
			, CASE 
				WHEN labs.numPositive > 0 THEN '10001'	--first digit indicates positive covid lab
				ELSE '00001'							--fifth digit indicates any covid lab
				END			AS key
		FROM (
			SELECT 
				lr.patient_id	AS patient_id
				, COUNT(1)		AS numLabs
				, SUM(CASE WHEN mpRes.mt_code = 'TNX:LAB_RESULT:Positive' THEN 1 ELSE 0 END)	as numPositive
			FROM :TNX_SCHEMA.lab_result lr
			LEFT JOIN :TNX_SCHEMA.mapping mpLab on mpLab.provider_code = (lr.observation_code_system || ':' || lr.observation_code)
			LEFT JOIN :TNX_SCHEMA.mapping mpRes on mpRes.provider_code = ('TNX:LAB_RESULT:' || lr.lab_result_text_val)
			WHERE lr.test_date >=  '2020-01-01'
			AND 
			(	-- LOINC List
				mpLab.mt_code IN ('UMLS:LNC:94306-8'	--new in 1.4
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
					,'UMLS:LNC:94503-0'
					,'UMLS:LNC:94504-8'
					,'UMLS:LNC:94505-5'
					,'UMLS:LNC:94506-3'
					,'UMLS:LNC:94507-1'
					,'UMLS:LNC:94508-9'
					,'UMLS:LNC:94509-7'
					,'UMLS:LNC:94510-5'
					,'UMLS:LNC:94511-3'
					,'UMLS:LNC:94531-1'
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
					,'UMLS:LNC:94720-0'
					,'UMLS:LNC:94745-7'
					,'UMLS:LNC:94746-5'
					,'UMLS:LNC:94756-4'
					,'UMLS:LNC:94757-2'
					,'UMLS:LNC:94758-0'
					,'UMLS:LNC:94759-8'
					,'UMLS:LNC:94760-6'
					,'UMLS:LNC:94761-4'
					,'UMLS:LNC:94762-2'
					,'UMLS:LNC:94763-0'
					,'UMLS:LNC:94764-8'
					,'UMLS:LNC:94765-5'
					,'UMLS:LNC:94766-3'
					,'UMLS:LNC:94767-1'
					,'UMLS:LNC:94768-9'
					,'UMLS:LNC:94769-7'
					,'UMLS:LNC:94819-0'
					,'UMLS:LNC:94822-4'
					,'UMLS:LNC:94845-5'
					,'UMLS:LNC:95125-1'
					,'UMLS:LNC:95209-3'
					,'UMLS:LNC:95406-5'
					,'UMLS:LNC:95409-9'
					,'UMLS:LNC:95410-7'
					,'UMLS:LNC:95411-5'
					,'UMLS:LNC:95416-4'
					,'UMLS:LNC:95424-8'
					,'UMLS:LNC:95425-5'
					,'UMLS:LNC:95427-1'
					,'UMLS:LNC:95428-9'
					,'UMLS:LNC:95429-7'
					,'UMLS:LNC:95521-1'
					,'UMLS:LNC:95522-9')
				--OTHER LAB
				OR UPPER(lr.observation_desc) LIKE '%COVID-19%'
				OR UPPER(lr.observation_desc) LIKE '%SARS-COV-2%'
			)
			GROUP BY lr.patient_id
		) labs
	) pt_list
	GROUP BY patient_id
) results
LEFT JOIN (
	SELECT distinct patient_id
	FROM :TNX_SCHEMA.diagnosis dx
	JOIN :TNX_SCHEMA.mapping mp on mp.provider_code = (dx.code_system || ':' || dx.code)
	WHERE dx.date >= '2020-04-01'
	AND mp.mt_code = 'UMLS:ICD10CM:Z11.59'
) phenoExcl on phenoExcl.patient_id = results.patient_id 
	and SUBSTR(results.key,4,1) = '1'	--Has a lab
	and SUBSTR(results.key,1,1) != '1'	--No positive lab
	and SUBSTR(results.key,2,1) != '1'	--No strong dx
WHERE phenoExcl.patient_id IS NULL
;
COMMIT;