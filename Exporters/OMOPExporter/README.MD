<!-----
NEW: Your output is on the clipboard!

NEW: Check the "Supress top comment" to remove this info from the output.

Conversion time: 0.423 seconds.


Using this Markdown file:

1. Paste this output into your source file.
2. See the notes and action items below regarding this conversion run.
3. Check the rendered output (headings, lists, code blocks, tables) for proper
   formatting and use a linkchecker before you publish this page.

Conversion notes:

* Docs to Markdown version 1.0?23
* Tue May 12 2020 10:08:49 GMT-0700 (PDT)
* Source doc: Untitled document
----->


**OMOP Data Exporter**

The OMOP Data Exporer is a `R` library designed to build the N3C phenotype and assemble extract files from your OMOP CDM. This R package uses [SQLRender](https://cran.r-project.org/web/packages/SqlRender/index.html) to translate between suppoted RDBMS including: 'Microsoft Sql Server', 'Oracle', 'PostgreSql', 'Amazon RedShift', 'Apache Impala', 'IBM Netezza', 'Google BigQuery', 'Microsoft PDW', and 'SQLite'.


**System Prerequisites**

- A database in [Common Data Model version 5](https://github.com/OHDSI/CommonDataModel) in one of these platforms: SQL Server, Oracle, PostgreSQL, IBM Netezza, Apache Impala, Amazon RedShift, Google BigQuery or Microsoft APS.
- Incorporation of [OMOP Vocabulary release v20200331,v20200403, v20200428, v20200430, v20200512, v20200519](https://github.com/OHDSI/Vocabulary-v5.0/releases) in your local ETL. It is also suggested to follow [OHDSI Community Guidance for Mapping](https://github.com/OHDSI/Covid-19/wiki/Release)
- R version 3.5.0 or newer
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)
- [Java](http://java.com)
- JAVA_HOME environment variable set to JDK path
  ```r
    # Check current value: 
    Sys.getenv("JAVA_HOME")
    # Set to new value
    Sys.setenv(JAVA_HOME="~/yourjdkpath")
  ```
- Suggested: 25 GB of free disk space

**Installation**

First, navigate the root of this repository to find the appropriate [phenotype generation](https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/tree/master/PhenotypeScripts) and [data extraction](https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/tree/master/ExtractScripts) scripts that match your common data model and sql dialect. Save these to a convenient location as the file paths are expected as parameters below. 

To utilize the Exporter, in `R` use the following code to install the dependencies:
```r
install.packages("remotes")
library(remotes)

# Uncomment to Verify JAVA_HOME is set to jdk path
# Sys.getenv("JAVA_HOME")

remotes::install_github(repo = "National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition"
               ,ref = "master"
               ,subdir = "Exporters/OMOPExporter"
               ,INSTALL_opts = "--no-multiarch"
)

# Uncomment to test for missing packages
# setdiff(c("rJava", "DatabaseConnector","SqlRender","zip","N3cOhdsi"), rownames(installed.packages()))

# load package
library(N3cOhdsi)

```
**Local configuration**

```r
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sql server",  # options: oracle, postgressql, redshift, sql server, pdw, netezza, bigquery, sqlite
                                                          server = "", # name of the server
                                                          user="", # username to access server
                                                          password = "" #password for that user
                                                          )
cdmDatabaseSchema <- "" # schema for your CDM instance -- e.g. TMC_OMOP.dbo
resultsDatabaseSchema <- "" # schema with write privileges
outputFolder <-  paste0(getwd(), "/output/")  # directory where output will be stored. default provided
cdmName <- "OMOP" # source data model. options: "OMOP", "ACT", "PCORNet", "TriNetX"
siteAbbrev <- "TuftsMC" # unique site identifier

phenotypeSqlPath <- "" # full path of phenotype sql file (.../Phenotype_Data_Acquisition/PhenotypeScripts/N3C_phenotype_x_y.sql)
extractSqlPath   <- "" # full path of extract sql file (.../Phenotype_Data_Acquisition/ExtractScripts/N3C_extract_x_y.sql)

```
**Execution**
```r
# Generate cohort
N3cOhdsi::createCohort(connectionDetails = connectionDetails,
                        sqlFilePath = phenotypeSqlPath,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        resultsDatabaseSchema = resultsDatabaseSchema
                        )

# Extract data to pipe delimited files
N3cOhdsi::runExtraction(connectionDetails = connectionDetails,
                        sqlFilePath = extractSqlPath,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        resultsDatabaseSchema = resultsDatabaseSchema
                        )


# Compress output
zip::zipr(zipfile = paste0(siteAbbrev, "_", cdmName, "_", format(Sys.Date(),"%Y%m%d"),".zip"),
          files = list.files(outputFolder, full.names = TRUE))


```

Note: if you cannot call out to the internet from R, you may download the [TAR here](https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/archive/master.zip). 

When you download this, you'll need to `Upload` the package into your RStudio environment (if in the cloud) or simply find the file pathway (if local RStudio). Once uploaded, you will need to open the `N3cOhdsi.Rprog` and the `Build` tab will show up in the upper right windows (next to Environment, History, Connections, Build). Proceed to `Install and Restart` to build the `N3cOhdsi` library. You may access the file `example_execution.R` to retrieve the code referenced above.

**What will my output look like?**

Once you run the exporter, your files will be output in the following directory structure:

**_Parent Directory_**

![Screenshot of Example Parent Directory](https://imgur.com/68YwCGU.png)

**_Sub-Directory_**

![Screenshot of Example Sub-Directory](https://imgur.com/ubrdNwA.png)

Note that these files are .csv files, but are actually pipe delimited rather than comma delimited. The exporter will take care of delimiters, formatting, headers, and everything else you need to be compliant with our formatting.

**Bug Reports/Enhancement Requests/Contributions**

We would love to hear from you about this script, as we hope to continue to improve and enhance it. We also welcome contributions, if there's a cool feature you've added locally. Please feel free to open an issue or create a pull request as needed!
