java -jar SqlRender.jar ..\PhenotypeScripts\N3C_phenotype_omop_mssql.sql ..\PhenotypeScripts\N3C_phenotype_omop_oracle.sql -translate oracle
java -jar SqlRender.jar ..\PhenotypeScripts\N3C_phenotype_omop_mssql.sql ..\PhenotypeScripts\N3C_phenotype_omop_postgres.sql -translate postgresql
java -jar SqlRender.jar ..\PhenotypeScripts\N3C_phenotype_omop_mssql.sql ..\PhenotypeScripts\N3C_phenotype_omop_redshift.sql -translate redshift
java -jar SqlRender.jar ..\PhenotypeScripts\N3C_phenotype_omop_mssql.sql ..\PhenotypeScripts\N3C_phenotype_omop_bigquery.sql -translate bigquery -oracle_temp_schema @tempDatabaseSchema
