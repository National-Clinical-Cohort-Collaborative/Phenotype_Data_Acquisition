--PCORNet 5.1 extraction code for N3C
--Written by Emily Pfaff, UNC Chapel Hill; Harold Lehmann, JHU
--Code written for MS SQL Server
--This extract purposefully excludes the following PCORnet tables: ENROLLMENT, HARVEST, HASH_TOKEN, PCORNET_TRIAL
--Assumptions: 
--	1. You have already built the N3C_COHORT table (with that name) prior to running this extract
--	2. You are extracting data with a lookback period to 1-1-2018

--DEMOGRAPHIC
--OUTPUT_FILE: DEMOGRAPHIC.csv
select
   demographic.patid,
   SUBSTR(cast(birth_date as STRING),0,7) as birth_date, --purposely removing day from birth date
   '00:00' as birth_time, --purposely removing time from birth date
   sex,
   sexual_orientation,
   gender_identity,
   hispanic,
   race,
   biobank_flag,
   pat_pref_language_spoken,
   null as raw_sex,
   null as raw_sexual_orientation,
   null as raw_gender_identity,
   null as raw_hispanic,
   null as raw_race,
   null as raw_pat_pref_language_spoken 
from @cdmDatabaseSchema.demographic join @resultsDatabaseSchema.n3c_cohort on demographic.patid = n3c_cohort.patid;

--ENCOUNTER
--OUTPUT_FILE: ENCOUNTER.csv
select
   encounterid,
   encounter.patid,
   cast(admit_date as datetime) as admit_date,
   admit_time,
   cast(discharge_date as datetime) as discharge_date,
   discharge_time,
   providerid,
   null as facility_location,
   enc_type,
   null as facilityid,
   discharge_disposition,
   discharge_status,
   drg,
   drg_type,
   admitting_source,
   payer_type_primary,
   payer_type_secondary,
   facility_type,
   null as raw_siteid,
   null as raw_enc_type,
   null as raw_discharge_disposition,
   null as raw_discharge_status,
   null as raw_drg_type,
   null as raw_admitting_source,
   null as raw_facility_type,
   null as raw_payer_type_primary,
   null as raw_payer_name_primary,
   null as raw_payer_id_primary,
   null as raw_payer_type_secondary,
   null as raw_payer_name_secondary,
   null as raw_payer_id_secondary 
from @cdmDatabaseSchema.encounter join @resultsDatabaseSchema.n3c_cohort on encounter.patid = n3c_cohort.patid
where admit_date >= '1/1/2018';

--CONDITION
--OUTPUT_FILE: CONDITION.csv
select
   conditionid,
   condition.patid,
   encounterid,
   cast(report_date as datetime) as report_date,
   cast(resolve_date as datetime) as resolve_date,
   cast(onset_date as datetime) as onset_date,
   condition_status,
   condition,
   condition_type,
   condition_source,
   null as raw_condition_status,
   null as raw_condition,
   null as raw_condition_type,
   null as raw_condition_source 
from @cdmDatabaseSchema.condition join @resultsDatabaseSchema.n3c_cohort on condition.patid = n3c_cohort.patid
where report_date >= '1/1/2018';

--DEATH
--OUTPUT_FILE: DEATH.csv
--No lookback period for death
select
   death.patid,
   cast(death_date as datetime) as death_date,
   death_date_impute,
   death_source,
   death_match_confidence 
from @cdmDatabaseSchema.death join @resultsDatabaseSchema.n3c_cohort on death.patid = n3c_cohort.patid;

--DEATH CAUSE
--OUTPUT_FILE: DEATH_CAUSE.csv
--No lookback period for death cause
select
   death_cause.patid,
   death_cause,
   death_cause_code,
   death_cause_type,
   death_cause_source,
   death_cause_confidence 
from @cdmDatabaseSchema.death_cause join @resultsDatabaseSchema.n3c_cohort on death_cause.patid = n3c_cohort.patid;

--DIAGNOSIS
--OUTPUT_FILE: DIAGNOSIS.csv
select
   diagnosisid,
   diagnosis.patid,
   encounterid,
   enc_type,
   cast(admit_date as date) as admit_date,
   providerid,
   dx,
   dx_type,
   cast(dx_date as date) as dx_date,
   dx_source,
   dx_origin,
   pdx,
   dx_poa,
   null as raw_dx,
   null as raw_dx_type,
   null as raw_dx_source,
   null as raw_pdx,
   null as raw_dx_poa 
from @cdmDatabaseSchema.diagnosis join @resultsDatabaseSchema.n3c_cohort on diagnosis.patid = n3c_cohort.patid
where dx_date >= '1/1/2018';

--DISPENSING
--OUTPUT_FILE: DISPENSING.csv
select
   dispensingid,
   dispensing.patid,
   prescribingid,
   cast(dispense_date as date) as dispense_date,
   ndc,
   dispense_source,
   dispense_sup,
   dispense_amt,
   dispense_dose_disp,
   dispense_dose_disp_unit,
   dispense_route,
   null as raw_ndc,
   null as raw_dispense_dose_disp,
   null as raw_dispense_dose_disp_unit,
   null as raw_dispense_route 
from @cdmDatabaseSchema.dispensing join @resultsDatabaseSchema.n3c_cohort on dispensing.patid = n3c_cohort.patid
where dispense_date >= '1/1/2018';

--IMMUNIZATION
--OUTPUT_FILE: IMMUNIZATION.csv
--No lookback period for immunizations
select
   immunizationid,
   immunization.patid,
   encounterid,
   proceduresid,
   vx_providerid,
   cast(vx_record_date as datetime) as vx_record_date,
   cast(vx_admin_date as datetime) as vx_admin_date,
   vx_code_type,
   vx_code,
   vx_status,
   vx_status_reason,
   vx_source,
   vx_dose,
   vx_dose_unit,
   vx_route,
   vx_body_site,
   vx_manufacturer,
   vx_lot_num,
   cast(vx_exp_date as datetime) as vx_exp_date,
   null as raw_vx_name,
   null as raw_vx_code,
   null as raw_vx_code_type,
   null as raw_vx_dose,
   null as raw_vx_dose_unit,
   null as raw_vx_route,
   null as raw_vx_body_site,
   null as raw_vx_status,
   null as raw_vx_status_reason,
   null as raw_vx_manufacturer 
from @cdmDatabaseSchema.immunization join @resultsDatabaseSchema.n3c_cohort on immunization.patid = n3c_cohort.patid;

--LAB_RESULT_CM
--OUTPUT_FILE: LAB_RESULT_CM.csv
select
   lab_result_cm_id,
   lab_result_cm.patid,
   encounterid,
   specimen_source,
   lab_loinc,
   lab_result_source,
   lab_loinc_source,
   priority,
   result_loc,
   lab_px,
   lab_px_type,
   cast(lab_order_date as datetime) as lab_order_date,
   cast(specimen_date as datetime) as specimen_date,
   specimen_time,
   cast(result_date as datetime) as result_date,
   result_time,
   result_qual,
   result_snomed,
   result_num,
   result_modifier,
   result_unit,
   norm_range_low,
   norm_modifier_low,
   norm_range_high,
   norm_modifier_high,
   abn_ind,
   raw_lab_name,
   null as raw_lab_code,
   null as raw_panel,
   raw_result,
   raw_unit,
   null as raw_order_dept,
   null as raw_facility_code 
from @cdmDatabaseSchema.lab_result_cm join @resultsDatabaseSchema.n3c_cohort on lab_result_cm.patid = n3c_cohort.patid
where lab_order_date >= '1/1/2018';

--LDS_ADDRESS_HISTORY
--OUTPUT_FILE: LDS_ADDRESS_HISTORY.csv
select
   addressid,
   lds_address_history.patid,
   address_use,
   address_type,
   address_preferred,
   address_city,
   address_state,
   address_zip5,
   address_zip9,
   address_period_start,
   address_period_end 
from @cdmDatabaseSchema.lds_address_history join @resultsDatabaseSchema.n3c_cohort on lds_address_history.patid = n3c_cohort.patid
where address_period_end is null or address_period_end >= '1/1/2018';

--MED_ADMIN
--OUTPUT_FILE: MED_ADMIN.csv
select
   medadminid,
   med_admin.patid,
   encounterid,
   prescribingid,
   medadmin_providerid,
   cast(medadmin_start_date as datetime) as medadmin_start_date,
   medadmin_start_time,
   cast(medadmin_stop_date as datetime) as medadmin_stop_date,
   medadmin_stop_time,
   medadmin_type,
   medadmin_code,
   medadmin_dose_admin,
   medadmin_dose_admin_unit,
   medadmin_route,
   medadmin_source,
   raw_medadmin_med_name,
   null as raw_medadmin_code,
   null as raw_medadmin_dose_admin,
   null as raw_medadmin_dose_admin_unit,
   null as raw_medadmin_route 
from @cdmDatabaseSchema.med_admin join @resultsDatabaseSchema.n3c_cohort on med_admin.patid = n3c_cohort.patid
where medadmin_start_date >= '1/1/2018';

--OBS_CLIN
--OUTPUT_FILE: OBS_CLIN.csv
select
   obsclinid,
   obs_clin.patid,
   encounterid,
   obsclin_providerid,
   cast(obsclin_date as datetime) as obsclin_date,
   obsclin_time,
   obsclin_type,
   obsclin_code,
   obsclin_result_qual,
   obsclin_result_text,
   obsclin_result_snomed,
   obsclin_result_num,
   obsclin_result_modifier,
   obsclin_result_unit,
   obsclin_source,
   null as raw_obsclin_name,
   null as raw_obsclin_code,
   null as raw_obsclin_type,
   null as raw_obsclin_result,
   null as raw_obsclin_modifier,
   null as raw_obsclin_unit 
from @cdmDatabaseSchema.obs_clin join @resultsDatabaseSchema.n3c_cohort on obs_clin.patid = n3c_cohort.patid
where obsclin_date >= '1/1/2018';

--OBS_GEN
--OUTPUT_FILE: OBS_GEN.csv
select
   obsgenid,
   obs_gen.patid,
   encounterid,
   obsgen_providerid,
   cast(obsgen_date as datetime) as obsgen_date,
   obsgen_time,
   obsgen_type,
   obsgen_code,
   obsgen_result_qual,
   obsgen_result_text,
   obsgen_result_num,
   obsgen_result_modifier,
   obsgen_result_unit,
   obsgen_table_modified,
   obsgen_id_modified,
   obsgen_source,
   null as raw_obsgen_name,
   null as raw_obsgen_code,
   null as raw_obsgen_type,
   null as raw_obsgen_result,
   null as raw_obsgen_unit 
from @cdmDatabaseSchema.obs_gen join @resultsDatabaseSchema.n3c_cohort on obs_gen.patid = n3c_cohort.patid
where obsgen_date >= '1/1/2018';

--PRESCRIBING
--OUTPUT_FILE: PRESCRIBING.csv
select
   prescribingid,
   prescribing.patid,
   encounterid,
   rx_providerid,
   cast(rx_order_date as datetime) as rx_order_date,
   rx_order_time,
   cast(rx_start_date as datetime) as rx_start_date,
   cast(rx_end_date as datetime) as rx_end_date,
   rx_dose_ordered,
   rx_dose_ordered_unit,
   rx_quantity,
   rx_dose_form,
   rx_refills,
   rx_days_supply,
   rx_frequency,
   rx_prn_flag,
   rx_route,
   rx_basis,
   rxnorm_cui,
   rx_source,
   rx_dispense_as_written,
   raw_rx_med_name,
   null as raw_rx_frequency,
   null as raw_rxnorm_cui,
   null as raw_rx_quantity,
   null as raw_rx_ndc,
   null as raw_rx_dose_ordered,
   null as raw_rx_dose_ordered_unit,
   null as raw_rx_route,
   null as raw_rx_refills 
from @cdmDatabaseSchema.prescribing join @resultsDatabaseSchema.n3c_cohort on prescribing.patid = n3c_cohort.patid
where rx_start_date >= '1/1/2018';

--PRO_CM
--OUTPUT_FILE: PRO_CM.csv
select
   pro_cm_id,
   pro_cm.patid,
   encounterid,
   cast(pro_date as datetime) as pro_date,
   pro_time,
   pro_type,
   pro_item_name,
   pro_item_loinc,
   pro_response_text,
   pro_response_num,
   pro_method,
   pro_mode,
   pro_cat,
   pro_source,
   pro_item_version,
   pro_measure_name,
   pro_measure_seq,
   pro_measure_score,
   pro_measure_theta,
   pro_measure_scaled_tscore,
   pro_measure_standard_error,
   pro_measure_count_scored,
   pro_measure_loinc,
   pro_measure_version,
   pro_item_fullname,
   pro_item_text,
   pro_measure_fullname 
from @cdmDatabaseSchema.pro_cm join @resultsDatabaseSchema.n3c_cohort on pro_cm.patid = n3c_cohort.patid
where pro_date >= '1/1/2018';

--PROCEDURES
--OUTPUT_FILE: PROCEDURES.csv
select
   proceduresid,
   procedures.patid,
   encounterid,
   enc_type,
   cast(admit_date as datetime) as admit_date,
   providerid,
   cast(px_date as datetime) as px_date,
   px,
   px_type,
   px_source,
   ppx,
   null as raw_px,
   null as raw_px_type,
   null as raw_ppx 
from @cdmDatabaseSchema.procedures join @resultsDatabaseSchema.n3c_cohort on procedures.patid = n3c_cohort.patid
where px_date >= '1/1/2018';

--PROVIDER
--OUTPUT_FILE: PROVIDER.csv
select
   providerid,
   provider_sex,
   provider_specialty_primary,
   null as provider_npi,	--to avoid accidentally identifying sites
   null as provider_npi_flag,
   null as raw_provider_specialty_primary 
from @cdmDatabaseSchema.provider
;
--VITAL
--OUTPUT_FILE: VITAL.csv
select
   vitalid,
   vital.patid,
   encounterid,
   cast(measure_date as datetime) as measure_date,
   measure_time,
   vital_source,
   ht,
   wt,
   diastolic,
   systolic,
   original_bmi,
   bp_position,
   smoking,
   tobacco,
   tobacco_type,
   null as raw_diastolic,
   null as raw_systolic,
   null as raw_bp_position,
   null as raw_smoking,
   null as raw_tobacco,
   null as raw_tobacco_type 
from @cdmDatabaseSchema.vital join @resultsDatabaseSchema.n3c_cohort on vital.patid = n3c_cohort.patid
where measure_date >= '1/1/2018';

--DATA_COUNTS TABLE
--OUTPUT_FILE: DATA_COUNTS.csv
(select 
   'DEMOGRAPHIC' as table_name, 
   (select count(*) from @cdmDatabaseSchema.demographic join @resultsDatabaseSchema.n3c_cohort on demographic.patid = n3c_cohort.patid) as row_count

union distinct select 
   'ENCOUNTER' as table_name,
   (select count(*) from @cdmDatabaseSchema.encounter join @resultsDatabaseSchema.n3c_cohort on encounter.patid = n3c_cohort.patid and admit_date >= '1/1/2018') as row_count

union distinct select 
   'CONDITION' as table_name,
   (select count(*) from @cdmDatabaseSchema.condition join @resultsDatabaseSchema.n3c_cohort on condition.patid = n3c_cohort.patid and report_date >= '1/1/2018') as row_count

union distinct select 
   'DEATH' as table_name,
   (select count(*) from @cdmDatabaseSchema.death join @resultsDatabaseSchema.n3c_cohort on death.patid = n3c_cohort.patid) as row_count

union distinct select 
   'DEATH_CAUSE' as table_name,
   (select count(*) from @cdmDatabaseSchema.death_cause join @resultsDatabaseSchema.n3c_cohort on death_cause.patid = n3c_cohort.patid) as row_count

union distinct select 
   'DIAGNOSIS' as table_name,
   (select count(*) from @cdmDatabaseSchema.diagnosis join @resultsDatabaseSchema.n3c_cohort on diagnosis.patid = n3c_cohort.patid and (dx_date >= '1/1/2018' or admit_date >= '1/1/2018')) as row_count

union distinct select 
   'DISPENSING' as table_name,
   (select count(*) from @cdmDatabaseSchema.dispensing join @resultsDatabaseSchema.n3c_cohort on dispensing.patid = n3c_cohort.patid and dispense_date >= '1/1/2018') as row_count

union distinct select 
   'IMMUNIZATION' as table_name,
   (select count(*) from @cdmDatabaseSchema.immunization join @resultsDatabaseSchema.n3c_cohort on immunization.patid = n3c_cohort.patid) as row_count

union distinct select 
   'LAB_RESULT_CM' as table_name,
   (select count(*) from @cdmDatabaseSchema.lab_result_cm join @resultsDatabaseSchema.n3c_cohort on lab_result_cm.patid = n3c_cohort.patid and (lab_order_date >= '1/1/2018' or result_date >= '1/1/2018')) as row_count

union distinct select 
   'LDS_ADDRESS_HISTORY' as table_name,
   (select count(*) from @cdmDatabaseSchema.lds_address_history join @resultsDatabaseSchema.n3c_cohort on lds_address_history.patid = n3c_cohort.patid
	and (address_period_end is null or address_period_end >= '1/1/2018')) as row_count

union distinct select 
   'MED_ADMIN' as table_name,
   (select count(*) from @cdmDatabaseSchema.med_admin join @resultsDatabaseSchema.n3c_cohort on med_admin.patid = n3c_cohort.patid and medadmin_start_date >= '1/1/2018') as row_count

union distinct select 
   'OBS_CLIN' as table_name,
   (select count(*) from @cdmDatabaseSchema.obs_clin join @resultsDatabaseSchema.n3c_cohort on obs_clin.patid = n3c_cohort.patid and obsclin_date >= '1/1/2018') as row_count

union distinct select 
   'OBS_GEN' as table_name,
   (select count(*) from @cdmDatabaseSchema.obs_gen join @resultsDatabaseSchema.n3c_cohort on obs_gen.patid = n3c_cohort.patid and obsgen_date >= '1/1/2018') as row_count

union distinct select 
   'PRESCRIBING' as table_name,
   (select count(*) from @cdmDatabaseSchema.prescribing join @resultsDatabaseSchema.n3c_cohort on prescribing.patid = n3c_cohort.patid and rx_start_date >= '1/1/2018') as row_count

union distinct select 
   'PRO_CM' as table_name,
   (select count(*) from @cdmDatabaseSchema.pro_cm join @resultsDatabaseSchema.n3c_cohort on pro_cm.patid = n3c_cohort.patid and pro_date >= '1/1/2018') as row_count

union distinct select 
   'PROCEDURES' as table_name,
   (select count(*) from @cdmDatabaseSchema.procedures join @resultsDatabaseSchema.n3c_cohort on procedures.patid = n3c_cohort.patid and px_date >= '1/1/2018') as row_count

union distinct select 
   'PROVIDER' as table_name,
   (select count(*) from @cdmDatabaseSchema.provider) as row_count

union distinct select 
   'VITAL' as table_name,
   (select count(*) from @cdmDatabaseSchema.vital join @resultsDatabaseSchema.n3c_cohort on vital.patid = n3c_cohort.patid and measure_date >= '1/1/2018') as row_count
);

--MANIFEST TABLE: CHANGE PER YOUR SITE'S SPECS
--OUTPUT_FILE: MANIFEST.csv
select
   'UNC' as site_abbrev,
   'University of North Carolina at Chapel Hill' as site_name,
   'Jane Doe' as contact_name,
   'jane_doe@unc.edu' as contact_email,
   'PCORNET' as cdm_name,
   '5.1' as cdm_version,
   null as vocabulary_version, --leave null as this only applies to OMOP
   'Y' as n3c_phenotype_yn,
   '1.3' as n3c_phenotype_version,
   cast(CURRENT_DATE() as datetime) as run_date,
   cast( DATE_ADD(cast(CURRENT_DATE() as date), interval -2 DAY) as date) as update_date,	--change integer based on your site's data latency
   cast( DATE_ADD(cast(CURRENT_DATE() as date), interval 3 DAY) as date) as next_submission_date					--change integer based on your site's load frequency
;
