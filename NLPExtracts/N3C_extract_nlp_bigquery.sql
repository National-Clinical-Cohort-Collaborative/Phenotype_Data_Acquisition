--N3C NLP extract script - OMOP BigQuery
--Use this extra extract file if your site is participating in the NLP portion of N3C.

--NOTE
--OUTPUT_FILE: NOTE.csv
select nt.note_id,
   nt.person_id,
   cast(note_date as timestamp) as note_date,
   cast(note_datetime as timestamp) as note_datetime,
   note_type_concept_id,
   note_class_concept_id,
   null as note_title,
   null as note_text,
   encoding_concept_id,
   language_concept_id,
   provider_id,
   null as visit_occurrence_id,
   null as visit_detail_id,
   null as note_source_value
from @cdmDatabaseSchema.note nt
join @resultsDatabaseSchema.n3c_cohort n
  on nt.person_id = n.person_id
  where nt.note_date >= to_date(to_char(2018,'0000')||'-'||to_char(01,'00')||'-'||to_char(01,'00'), 'YYYY-MM-DD') ;

--NOTE_NLP
--OUTPUT_FILE: NOTE_NLP.csv
select note_nlp_id,
   ntnlp.note_id,
   section_concept_id,
   null as snippet,
   offset,
   null as lexical_variant,
   note_nlp_concept_id,
   note_nlp_source_concept_id,
   nlp_system,
   cast(nlp_date as timestamp) as nlp_date,
   cast(nlp_datetime as timestamp) as nlp_datetime,
   term_exists,
   term_temporal,
   term_modifiers
from @cdmDatabaseSchema.note_nlp ntnlp
	join @cdmDatabaseSchema.note nt on ntnlp.note_id = nt.note_id
	join @resultsDatabaseSchema.n3c_cohort n on nt.person_id = n.person_id
  where nt.note_date >= to_date(to_char(2018,'0000')||'-'||to_char(01,'00')||'-'||to_char(01,'00'), 'YYYY-MM-DD') ;

--NOTE ROW COUNT
--OUTPUT_FILE: DATA_COUNTS_APPEND.csv
select 'NOTE' as table_name
    ,count(*) as row_count
 from @cdmDatabaseSchema.note nt
 join @resultsDatabaseSchema.n3c_cohort n on nt.person_id = n.person_id
  where nt.note_date >= to_date(to_char(2018,'0000')||'-'||to_char(01,'00')||'-'||to_char(01,'00'), 'YYYY-MM-DD') ;

--NOTE_NLP ROW COUNT
--OUTPUT_FILE: DATA_COUNTS_APPEND.csv
select 'NOTE_NLP' as table_name
    ,count(*) as row_count
from @cdmDatabaseSchema.note_nlp ntnlp
  join @cdmDatabaseSchema.note nt on ntnlp.note_id = nt.note_id
  join @resultsDatabaseSchema.n3c_cohort n on nt.person_id = n.person_id
  where nt.note_date >= to_date(to_char(2018,'0000')||'-'||to_char(01,'00')||'-'||to_char(01,'00'), 'YYYY-MM-DD') ;
