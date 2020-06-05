java -jar SqlRender.jar ..\PhenotypeScripts\N3C_phenotype_pcornet_mssql.sql ..\PhenotypeScripts\N3C_phenotype_pcornet_oracle.sql -translate oracle
java -jar SqlRender.jar ..\PhenotypeScripts\N3C_phenotype_pcornet_mssql.sql ..\PhenotypeScripts\N3C_phenotype_pcornet_postgres.sql -translate postgresql
java -jar SqlRender.jar ..\PhenotypeScripts\N3C_phenotype_pcornet_mssql.sql ..\PhenotypeScripts\N3C_phenotype_pcornet_redshift.sql -translate redshift
java -jar SqlRender.jar ..\PhenotypeScripts\N3C_phenotype_pcornet_mssql.sql ..\PhenotypeScripts\N3C_phenotype_pcornet_bigquery.sql -translate bigquery
