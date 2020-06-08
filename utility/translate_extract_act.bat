java -jar SqlRender.jar ..\ExtractScripts\N3C_extract_act_mssql.sql ..\ExtractScripts\N3C_extract_act_oracle.sql -translate oracle
java -jar SqlRender.jar ..\ExtractScripts\N3C_extract_act_mssql.sql ..\ExtractScripts\N3C_extract_act_postgres.sql -translate postgresql
java -jar SqlRender.jar ..\ExtractScripts\N3C_extract_act_mssql.sql ..\ExtractScripts\N3C_extract_act_redshift.sql -translate redshift
java -jar SqlRender.jar ..\ExtractScripts\N3C_extract_act_mssql.sql ..\ExtractScripts\N3C_extract_act_bigquery.sql -translate bigquery
