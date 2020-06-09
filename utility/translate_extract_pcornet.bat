java -jar SqlRender.jar ..\ExtractScripts\N3C_extract_pcornet_mssql.sql ..\ExtractScripts\N3C_extract_pcornet_oracle.sql -translate oracle
java -jar SqlRender.jar ..\ExtractScripts\N3C_extract_pcornet_mssql.sql ..\ExtractScripts\N3C_extract_pcornet_postgres.sql -translate postgresql
java -jar SqlRender.jar ..\ExtractScripts\N3C_extract_pcornet_mssql.sql ..\ExtractScripts\N3C_extract_pcornet_redshift.sql -translate redshift
java -jar SqlRender.jar ..\ExtractScripts\N3C_extract_pcornet_mssql.sql ..\ExtractScripts\N3C_extract_pcornet_bigquery.sql -translate bigquery
