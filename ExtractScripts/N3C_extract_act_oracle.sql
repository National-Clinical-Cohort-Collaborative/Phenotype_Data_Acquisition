--ACT/i2b2 extraction code for N3C
--ACT Ontology Version 2.0.1 and optionally ACT_COVID V3
--Written by Michele Morris, UPitt
--Code written for Oracle
--This extract includes only i2b2 fact relevant tables and the concept dimension table for mapping concept codes
--Assumptions: 
--	1. You have already built the N3C_COHORT table (with that name) prior to running this extract
--	2. You are extracting data with a lookback period of 2 years (Not Yet)
--  3. This currently only works for the traditional i2b2 single fact table

-- N3C_VOCAB_MAP and 
-- ACT to OMOP Terminology Map
-- Edit if your standard terminology prefixes are different from ACT
-- This does not include local coding
-- For example if your ICD10CM prefix is ICD10 include, but if the code that follows that
-- prefix is not a valid ICD10CM code do not include that prefix
-- Sites that use adapter mapping will need to create a concept_dimension table that links your adapter_mapping 'table'
-- to concept_dimension where the shrine path becomes the concept_path 


--MANIFEST TABLE: CHANGE PER YOUR SITE'S SPECS
--OUTPUT_FILE: MANIFEST.csv
SELECT distinct '@siteAbbrev' as SITE_ABBREV,
   '@siteName'    AS SITE_NAME,
   '@contactName' as CONTACT_NAME,
   '@contactEmail' as CONTACT_EMAIL,
   'ACT' as CDM_NAME, ---- hardwired null for ACT
   '@cdmVersion' as CDM_VERSION,
   null AS VOCABULARY_VERSION, -- hardwired null for ACT
   '@n3cPhenotypeYN' as N3C_PHENOTYPE_YN,
   phenotype_version  as N3C_PHENOTYPE_VERSION,
   CAST(SYSDATE as date) as RUN_DATE,
   CAST( (SYSDATE + NUMTODSINTERVAL(-@dataLatencyNumDays, 'day')) as date) as UPDATE_DATE,	--change integer based on your site's data latency
   CAST( (SYSDATE + NUMTODSINTERVAL(@daysBetweenSubmissions, 'day')) as date) as NEXT_SUBMISSION_DATE FROM DUAL;

-- ACT duplicate key validation script
-- VALIDATION_SCRIPT
-- OUTPUT_FILE: EXTRACT_VALIDATION.csv
 SELECT * FROM (SELECT 'OBSERVATION_FACT' as TABLE_NAME, 
	(SELECT COUNT(*) 
		FROM (SELECT ofct.ENCOUNTER_NUM, ofct.PATIENT_NUM, ofct.CONCEPT_CD, standard_hash(ofct.PROVIDER_ID,'MD5') AS provider_id,
		      ofct.START_DATE, ofct.MODIFIER_CD, ofct.INSTANCE_NUM, COUNT(*) as COUNT_N 
			FROM @cdmDatabaseSchema.OBSERVATION_FACT ofct 
				JOIN @resultsDatabaseSchema.N3C_COHORT ON ofct.PATIENT_NUM = @resultsDatabaseSchema.N3C_COHORT.PATIENT_NUM 
				    AND ofct.START_DATE >= TO_DATE(TO_CHAR(2018,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD')
			GROUP BY ofct.ENCOUNTER_NUM, ofct.PATIENT_NUM, ofct.CONCEPT_CD, standard_hash(ofct.PROVIDER_ID,'MD5'), 
		            ofct.START_DATE, ofct.MODIFIER_CD, ofct.INSTANCE_NUM 
			HAVING COUNT(*) >= 2
		 ) tbl
  ) as DUP_COUNT
	  FROM DUAL  UNION SELECT 'VISIT_DIMENSION'  TABLE_NAME,
	(SELECT COUNT(*) FROM (SELECT vd.ENCOUNTER_NUM, COUNT(*) as COUNT_N
			FROM @cdmDatabaseSchema.VISIT_DIMENSION vd 
				JOIN @resultsDatabaseSchema.N3C_COHORT ON vd.PATIENT_NUM = @resultsDatabaseSchema.N3C_COHORT.PATIENT_NUM 
					AND vd.START_DATE >= TO_DATE(TO_CHAR(2018,'0000')||'-'||TO_CHAR(01,'00')||'-'||TO_CHAR(01,'00'), 'YYYY-MM-DD') 
			GROUP BY ENCOUNTER_NUM 
			HAVING COUNT(*) >= 2
		 ) tbl
	 ) as DUP_COUNT
	   FROM DUAL  UNION SELECT 'PATIENT_DIMENSION'  TABLE_NAME,
	 (SELECT COUNT(*) FROM (SELECT pd.PATIENT_NUM, COUNT(*) as COUNT_N 
			FROM @cdmDatabaseSchema.PATIENT_DIMENSION pd 
				JOIN @resultsDatabaseSchema.N3C_COHORT ON pd.PATIENT_NUM = @resultsDatabaseSchema.N3C_COHORT.PATIENT_NUM  
			GROUP BY pd.PATIENT_NUM 
			HAVING COUNT(*) >= 2
		 ) tbl
	 ) as DUP_COUNT
	  FROM DUAL) subq
  WHERE dup_count > 0;
          
--N3C_VOCAB_MAP TABLE
--OUTPUT_FILE: N3C_VOCAB_MAP.CSV
select 'DEM|HISP:' local_prefix, 'Ethnicity' omop_vocab from dual 
union
select 'DEM|RACE:' local_prefix, 'Race' omop_vocab from dual 
union
select 'DEM|SEX:' local_prefix, 'Gender' omop_vocab from dual 
union
select 'RXNORM:' local_prefix, 'RXNORM' omop_vocab from dual 
union
select 'NDC:' local_prefix, 'NDC' omop_vocab from dual 
union
select 'NUI:' local_prefix, 'NDFRT' omop_vocab from dual 
union
select 'ICD10CM:' local_prefix, 'ICD10CM' omop_vocab from dual 
union
select 'ICD9CM:' local_prefix, 'ICD9CM' omop_vocab from dual 
union
select 'ICD10PCS:' local_prefix, 'ICD10PCS' omop_vocab from dual 
union
select 'ICD9PROC:' local_prefix, 'ICD9PROC' omop_vocab from dual 
union
select 'LOINC:' local_prefix, 'LOINC' omop_vocab from dual 
union
select 'CPT4:' local_prefix, 'CPT4' omop_vocab from dual 
union
select 'HCPCS:' local_prefix, 'HCPCS' omop_vocab from dual 
order by omop_vocab;



--Create non-standard code to standard code map
--ACT_STANDARD2LOCAL_CODE_MAP TABLE
--OUTPUT_FILE: ACT_STANDARD2LOCAL_CODE_MAP.csv
with N3C_VOCAB_MAP AS 
(
select 'DEM|HISP:%' local_prefix, 'Ethnicity' omop_vocab from dual 
union
select 'DEM|RACE:%' local_prefix, 'Race' omop_vocab from dual 
union
select 'DEM|SEX:%' local_prefix, 'Gender' omop_vocab from dual 
union
select 'RXNORM:%' local_prefix, 'RXNORM' omop_vocab from dual 
union
select 'NDC:%' local_prefix, 'NDC' omop_vocab from dual 
union
select 'NUI:%' local_prefix, 'NDFRT' omop_vocab from dual 
union
select 'ICD10CM:%' local_prefix, 'ICD10CM' omop_vocab from dual 
union
select 'ICD9CM:%' local_prefix, 'ICD9CM' omop_vocab from dual 
union
select 'ICD10PCS:%' local_prefix, 'ICD10PCS' omop_vocab from dual 
union
select 'ICD9PROC:%' local_prefix, 'ICD9PROC' omop_vocab from dual 
union
select 'LOINC:%' local_prefix, 'LOINC' omop_vocab from dual 
union
select 'CPT4:%' local_prefix, 'CPT4' omop_vocab from dual 
union
select 'HCPCS:%' local_prefix, 'HCPCS' omop_vocab from dual 
order by omop_vocab
 ),
n3c_concept_dimension as 
(
    select * from @cdmDatabaseSchema.concept_dimension
),
med_standard_codes as 
(
select concept_path, concept_cd, name_char from n3c_concept_dimension where concept_path like '\ACT\Medications\%'  and
(concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'RXNORM' and rownum = 1) 
     or concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'NDC' and rownum = 1)
     or concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'NDFRT' and rownum = 1))
order by concept_path
),
med_nonstandard_codes as --local codes
(
select * from n3c_concept_dimension where concept_path like '\ACT\Medications\%' 
and (concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'RXNORM' and rownum = 1) 
     and concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'NDC' and rownum = 1)
     and concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'NDFRT' and rownum = 1))
order by concept_path
),
med_nonstandard_parents as 
(
select 
    concept_cd, 
    name_char, 
    replace(concept_path,regexp_substr(rtrim(concept_path,'\'), '[^\]+$', 1, 1)||'\','')  parent, 
    regexp_substr(rtrim(concept_path,'\'), '[^\]+$', 1, 1)  path_element, 
    concept_path 
from med_nonstandard_codes
),
med_nonstandard_codes_mapped as  
(
select 
    s.concept_cd act_standard_code, 
    p.concept_cd local_concept_cd, 
    p.name_char, 
    p.parent parent_concept_path,
    s.concept_path concept_path, 
    p.path_element
from med_nonstandard_parents p
inner join med_standard_codes s on s.concept_path = p.parent
),

-- Diagnosis Code Mapping
dx_standard_codes as 
(
select concept_path, concept_cd, name_char from n3c_concept_dimension 
where (concept_path like '\ACT\Diagnosis\%' or concept_path like '\Diagnoses\%') and
(concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'ICD10CM' and rownum = 1) 
     or concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'ICD9CM' and rownum = 1))
order by concept_path
),
dx_nonstandard_codes as --local codes
(
select * from n3c_concept_dimension 
where (concept_path like '\ACT\Diagnosis\%' or concept_path like '\Diagnoses\%') and
(concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'ICD10CM' and rownum = 1) 
     and concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'ICD9CM' and rownum = 1))
order by concept_path
),
dx_nonstandard_parents as 
(
select 
    concept_cd, 
    name_char, 
    replace(concept_path,regexp_substr(rtrim(concept_path,'\'), '[^\]+$', 1, 1)||'\','')  parent, 
    regexp_substr(rtrim(concept_path,'\'), '[^\]+$', 1, 1)  path_element, 
    concept_path 
from dx_nonstandard_codes
),
dx_nonstandard_codes_mapped as  
(
select 
    s.concept_cd act_standard_code, 
    p.concept_cd local_concept_cd, 
    p.name_char, 
    p.parent parent_concept_path,
    s.concept_path concept_path, 
    p.path_element
from dx_nonstandard_parents p
inner join dx_standard_codes s on s.concept_path = p.parent
),

-- Lab Code Mapping
lab_standard_codes as 
(
select concept_path, concept_cd, name_char from n3c_concept_dimension 
where (concept_path like '\ACT\Labs\%' or concept_path like '\ACT\Lab\%') and
(concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'LOINC' and rownum = 1))
order by concept_path
),
lab_nonstandard_codes as --local codes
(
select * from n3c_concept_dimension 
where (concept_path like '\ACT\Labs\%' or concept_path like '\ACT\Lab\%') and
(concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'LOINC' and rownum = 1))
order by concept_path
),
lab_nonstandard_parents as 
(
select 
    concept_cd, 
    name_char, 
    replace(concept_path,regexp_substr(rtrim(concept_path,'\'), '[^\]+$', 1, 1)||'\','')  parent, 
    regexp_substr(rtrim(concept_path,'\'), '[^\]+$', 1, 1)  path_element, 
    concept_path 
from lab_nonstandard_codes
),
lab_nonstandard_codes_mapped as  
(
select 
    s.concept_cd act_standard_code, 
    p.concept_cd local_concept_cd, 
    p.name_char, 
    p.parent parent_concept_path,
    s.concept_path concept_path, 
    p.path_element
from lab_nonstandard_parents p
inner join lab_standard_codes s on s.concept_path = p.parent
),

-- Procedures Code Mapping
px_standard_codes as 
(
select concept_path, concept_cd, name_char from n3c_concept_dimension 
where (concept_path like '\ACT\Procedures\%' or concept_path like '\Diagnoses\%') and
    (concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'ICD10PCS' and rownum = 1) 
     or concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'ICD9PROC' and rownum = 1)
     or concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'CPT4' and rownum = 1)
     or concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'HCPCS' and rownum = 1))
order by concept_path
),
px_nonstandard_codes as --local codes
(
select * from n3c_concept_dimension 
where (concept_path like '\ACT\Procedures\%' or concept_path like '\Diagnoses\%') and
    (concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'ICD10PCS' and rownum = 1) 
     and concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'ICD9PROC' and rownum = 1)
     and concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'CPT4' and rownum = 1)
     and concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'ICD10CM' and rownum = 1)
     and concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'ICD9CM' and rownum = 1)
     and concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'HCPCS' and rownum = 1))
order by concept_path
),
px_nonstandard_parents as 
(
select 
    concept_cd, 
    name_char, 
    replace(concept_path,regexp_substr(rtrim(concept_path,'\'), '[^\]+$', 1, 1)||'\','')  parent, 
    regexp_substr(rtrim(concept_path,'\'), '[^\]+$', 1, 1)  path_element, 
    concept_path 
from px_nonstandard_codes
),
px_nonstandard_codes_mapped as  
(
select 
    s.concept_cd act_standard_code, 
    p.concept_cd local_concept_cd, 
    p.name_char, 
    p.parent parent_concept_path,
    s.concept_path concept_path, 
    p.path_element
from px_nonstandard_parents p
inner join px_standard_codes s on s.concept_path = p.parent
),

-- Demographics Code Mapping
dem_standard_codes as 
(
select concept_path, concept_cd, name_char from n3c_concept_dimension 
where concept_path like '\ACT\Demographics\%' and
(concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'Race' and rownum = 1) 
     or concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'Gender' and rownum = 1)
     or concept_cd like (select local_prefix from n3c_vocab_map where omop_vocab = 'Ethnicity' and rownum = 1))
order by concept_path
),
dem_nonstandard_codes as --local codes
(
select * from n3c_concept_dimension 
where concept_path like '\ACT\Demographics\%' and
    (concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'Race' and rownum = 1) 
     and concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'Gender' and rownum = 1)
     and concept_cd not like (select local_prefix from n3c_vocab_map where omop_vocab = 'Ethnicity' and rownum = 1))
order by concept_path
),
dem_nonstandard_parents as 
(
select 
    concept_cd, 
    name_char, 
    replace(concept_path,regexp_substr(rtrim(concept_path,'\'), '[^\]+$', 1, 1)||'\','')  parent, 
    regexp_substr(rtrim(concept_path,'\'), '[^\]+$', 1, 1)  path_element, 
    concept_path 
from dem_nonstandard_codes
),
dem_nonstandard_codes_mapped as  
(
select 
    s.concept_cd act_standard_code, 
    p.concept_cd local_concept_cd, 
    p.name_char, 
    p.parent parent_concept_path,
    s.concept_path concept_path, 
    p.path_element
from dem_nonstandard_parents p
inner join dem_standard_codes s on s.concept_path = p.parent
)
select * from med_nonstandard_codes_mapped
union
select * from lab_nonstandard_codes_mapped
union
select * from dx_nonstandard_codes_mapped
union
select * from px_nonstandard_codes_mapped
union
select * from dem_nonstandard_codes_mapped;

--This is no longer needed - just commenting out now
--CONCEPT_DIMENSION TABLE
--OUTPUT_FILE: CONCEPT_DIMENSION.CSV
--SELECT concept_path,
--    concept_cd,
--    name_char,
--    update_date,
--    download_date,
--    import_date,
--    sourcesystem_cd,
--    upload_id
--FROM @cdmDatabaseSchema.concept_dimension ;

--OBSERVATION_FACT TABLE
--OUTPUT_FILE: OBSERVATION_FACT.CSV
--Extract OBSERVATION_FACTS represented in the ACT Ontology
--This should extract standard and non-standard prefixes
--select all facts - concept_cd when mapped to OMOP determines domain/value    
with n3c_concepts as 
(
    select distinct concept_cd as concept_cd
    from @cdmDatabaseSchema.concept_dimension 
    where
    concept_path like '\ACT\Demographics\%'
    or concept_path like '\ACT\Visit Details\%'
    or concept_path like '\ACT\Diagnosis\%'
    or concept_path like '\Diagnoses\%'
    or concept_path like '\ACT\Procedures\%'
    or concept_path like '\ACT\Lab\%'
    or concept_path like '\ACT\Labs\%'
    or concept_path like '\ACT\Medications\%'
    or concept_path like '\ACT\UMLS_C0031437\%' -- COVID Ontology
order by 1
)
select 
    encounter_num,
    observation_fact.patient_num,
    observation_fact.concept_cd,
    standard_hash(observation_fact.PROVIDER_ID,'MD5') AS provider_id,
    start_date,
    end_date,
    modifier_cd,
    instance_num,
    valtype_cd,
    --location_cd,
    tval_char,
    nval_num,
    valueflag_cd,
    units_cd,
    update_date,
    download_date,
    import_date,
    sourcesystem_cd,
    upload_id
from @cdmDatabaseSchema.observation_fact
    join @resultsDatabaseSchema.n3c_cohort on observation_fact.patient_num = n3c_cohort.patient_num 
    join n3c_concepts on n3c_concepts.concept_cd = observation_fact.concept_cd 
  WHERE start_date >= '01-JAN-2018';

    
--select patient dimension the demographic facts including ethnicity are included in observation_fact table as well
--PATIENT_DIMENSION TABLE
--OUTPUT_FILE: PATIENT_DIMENSION.csv
SELECT patient_dimension.patient_num,
    TO_CHAR(BIRTH_DATE, 'YYYY-MM') as birth_date,
    death_date,
    race_cd,
    sex_cd,
    vital_status_cd,
    age_in_years_num,
    language_cd,
    marital_status_cd,
    religion_cd,
    zip_cd,
    statecityzip_path,
    income_cd,
    update_date,
    download_date,
    import_date,
    sourcesystem_cd,
    upload_id
FROM @cdmDatabaseSchema.patient_dimension join @resultsDatabaseSchema.n3c_cohort on patient_dimension.patient_num = n3c_cohort.patient_num  ;

    
    
--select visit_dimensions (encounter/visit) vary by site  
--VISIT_DIMENSION TABLE
--OUTPUT_FILE: VISIT_DIMENSION.csv
SELECT visit_dimension.patient_num,
    encounter_num,
    active_status_cd,
    start_date,
    end_date,
    inout_cd,
    location_cd,
    location_path,
    length_of_stay,
    update_date,
    download_date,
    import_date,
    sourcesystem_cd,
    upload_id
FROM @cdmDatabaseSchema.visit_dimension join @resultsDatabaseSchema.n3c_cohort on visit_dimension.patient_num = n3c_cohort.patient_num
  WHERE start_date >= '01-JAN-2018' ;
    
--DATA_COUNTS TABLE
--OUTPUT_FILE: DATA_COUNTS.csv
SELECT * FROM (SELECT 'OBSERVATION_FACT' as TABLE_NAME, 
   (SELECT count(*) FROM @cdmDatabaseSchema.OBSERVATION_FACT join @resultsDatabaseSchema.n3c_cohort on observation_fact.patient_num = n3c_cohort.patient_num 
  WHERE start_date >= '01-JAN-2018' ) as ROW_COUNT

 FROM DUAL  UNION SELECT 'VISIT_DIMENSION'  TABLE_NAME,
   (SELECT count(*) FROM @cdmDatabaseSchema.VISIT_DIMENSION join @resultsDatabaseSchema.n3c_cohort on visit_dimension.patient_num = n3c_cohort.patient_num
  WHERE start_date >= '01-JAN-2018' ) as ROW_COUNT

  FROM DUAL  UNION SELECT 'PATIENT_DIMENSION'  TABLE_NAME,
   (SELECT count(*) FROM @cdmDatabaseSchema.PATIENT_DIMENSION join @resultsDatabaseSchema.n3c_cohort on patient_dimension.patient_num = n3c_cohort.patient_num ) as ROW_COUNT

  FROM DUAL   UNION select 
   'CONCEPT_DIMENSION'  TABLE_NAME,
   (SELECT count(*) FROM @cdmDatabaseSchema.CONCEPT_DIMENSION ) as ROW_COUNT
   FROM DUAL ) x ;




