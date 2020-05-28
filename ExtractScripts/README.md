**Looking for the OMOP Scripts?**

Due to the way the OMOP exporter works, the OMOP SQL scripts are stored in a different directory from the rest of the data model scripts (for now). You can find the both the phenotype and the extract scripts for OMOP [here](https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/tree/master/Exporters/OMOPExporter/inst/sql/sql_server). (Note--this _only_ applies to OMOP.)

We encourage you to use the R-based OMOP exporter. If you choose not to use it, or if you would prefer to use our Python exporter with the OMOP scripts, you will still need to navigate to the directory linked above to get the latest-and-greatest versions of the OMOP scripts. The OMOP scripts that you'll find there are written for MS SQL Server. If you have a different RDBMS: if you use the OMOP Exporter, it will automatically translate the OMOP scripts into other SQL dialects on the fly. If you do not use the exporter, you may need to do the translation manually, or ask us for help!

We are looking into reorganizing this repository in the near future to make this more intuitive. For now, if you have any trouble identifying the right scripts to use, please put in an Issue for us. Thanks!
