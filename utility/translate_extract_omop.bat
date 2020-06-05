java -jar SqlRender.jar ..\ExtractScripts\N3C_extract_omop_mssql.sql ..\ExtractScripts\N3C_extract_omop_oracle.sql -translate oracle
java -jar SqlRender.jar ..\ExtractScripts\N3C_extract_omop_mssql.sql ..\ExtractScripts\N3C_extract_omop_postgres.sql -translate postgresql
java -jar SqlRender.jar ..\ExtractScripts\N3C_extract_omop_mssql.sql ..\ExtractScripts\N3C_extract_omop_redshift.sql -translate redshift
java -jar SqlRender.jar ..\ExtractScripts\N3C_extract_omop_mssql.sql ..\ExtractScripts\N3C_extract_omop_bigquery.sql -translate bigquery
