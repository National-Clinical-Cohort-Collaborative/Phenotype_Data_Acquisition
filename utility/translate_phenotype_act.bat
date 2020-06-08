java -jar SqlRender.jar ..\PhenotypeScripts\N3C_phenotype_act_mssql.sql ..\PhenotypeScripts\N3C_phenotype_act_oracle.sql -translate oracle
java -jar SqlRender.jar ..\PhenotypeScripts\N3C_phenotype_act_mssql.sql ..\PhenotypeScripts\N3C_phenotype_act_postgres.sql -translate postgresql
java -jar SqlRender.jar ..\PhenotypeScripts\N3C_phenotype_act_mssql.sql ..\PhenotypeScripts\N3C_phenotype_act_redshift.sql -translate redshift
java -jar SqlRender.jar ..\PhenotypeScripts\N3C_phenotype_act_mssql.sql ..\PhenotypeScripts\N3C_phenotype_act_bigquery.sql -translate bigquery
