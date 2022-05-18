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

The OMOP Data Exporter is a `R` library designed to build the N3C phenotype and assemble extract files from your OMOP CDM. This R package uses [SQLRender](https://cran.r-project.org/web/packages/SqlRender/index.html) to translate between suppoted RDBMS including: 'Microsoft Sql Server', 'Oracle', 'PostgreSql', 'Amazon RedShift', 'Apache Impala', 'IBM Netezza', 'Google BigQuery', 'Microsoft PDW', and 'SQLite'.


**System Prerequisites**

- A database in [Common Data Model version 5](https://github.com/OHDSI/CommonDataModel) in one of these platforms: SQL Server, Oracle, PostgreSQL, IBM Netezza, Apache Impala, Amazon RedShift, Google BigQuery or Microsoft APS.
- Incorporation of [OMOP Vocabulary release v20200331,v20200403, v20200428, v20200430, v20200512, v20200519](https://github.com/OHDSI/Vocabulary-v5.0/releases) in your local ETL. It is also suggested to follow [OHDSI Community Guidance for Mapping](https://github.com/OHDSI/Covid-19/wiki/Release)
- R version 3.5.0 or newer (version 4 or newer is highly recommended)
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
               ,subdir = "Exporters/RExporter"
               ,INSTALL_opts = "--no-multiarch"
)

# Uncomment to test for missing packages
# setdiff(c("rJava", "DatabaseConnector","SqlRender","zip","N3cOhdsi"), rownames(installed.packages()))

# load package
library(N3cOhdsi)

```
**Troubleshooting note:** If you have an older version of R (prior to version 4), the installation may fail--the remotes package is not tolerant of warning messages, which often come up due to versioning issues. The best way to correct this is to update to the newest version of R. If you are not able to update R, you can force the installation to ignore the warning messages by setting an additional environment variable: R_REMOTES_NO_ERRORS_FROM_WARNINGS = true. 

**Local configuration**

Note: Please scroll to the bottom of this README to see examples of what the MANIFEST configuration should look like.

```r
# -- run config
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sql server",  # options: oracle, postgresql, redshift, sql server, pdw, netezza, bigquery, sqlite
                                                          server = "", # name of the server
                                                          user="", # username to access server
                                                          password = "" #password for that user
                                                          )
cdmDatabaseSchema <- "" # schema for your CDM instance -- e.g. TMC_OMOP.dbo
resultsDatabaseSchema <- "" # schema with write privileges -- e.g. OHDSI.dbo
outputFolder <-  paste0(getwd(), "/output/")  # directory where output will be stored. default provided
phenotypeSqlPath <- "" # full path of phenotype sql file (.../Phenotype_Data_Acquisition/PhenotypeScripts/your_file.sql)
extractSqlPath <- ""  # full path of extract sql file (.../Phenotype_Data_Acquisition/ExtractScripts/your_file.sql)

# FOR NLP SITES ONLY:
nlpSqlPath <- "" # full path of nlp extract sql file (.../Phenotype_Data_Acquisition/NLPExtracts/N3C_extract_nlp_mssql.sql)

# FOR ADT/VISIT_DETAIL SITES ONLY:
adtSqlPath <- "" # full path of ADT extract sql file (.../Phenotype_Data_Acquisition/ADTExtracts/N3C_extract_adt_mssql.sql)

# -- manifest config
siteAbbrev <- "TuftsMC" #-- unique site identifier
siteName   <- ""
contactName <- ""
contactEmail <- ""
cdmName <- "OMOP" #-- source data model. options: "OMOP", "ACT", "PCORNet", "TriNetX"
cdmVersion <- "5.3.1"
vocabularyVersion <- "" #-- will be null for non-OMOP sites, but needs to be passed at null
n3cPhenotypeYN <- "Y"
n3cPhenotypeVersion <- ""
dataLatencyNumDays <- "2"  #-- this integer will be used to calculate UPDATE_DATE dynamically
daysBetweenSubmissions <- "3"  #-- this integer will be used to calculate NEXT_SUBMISSION_DATE dynamically
shiftDateYN <- "X" #-- Replace with either 'Y' or 'N' to indicate if your data is date shifted
maxNumShiftDays <- "NA" #-- If date shifting, replace with max number of days shifted


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
                        resultsDatabaseSchema = resultsDatabaseSchema,
                        outputFolder = outputFolder,
                        siteAbbrev = siteAbbrev,
                        siteName = siteName,
                        contactName = contactName,
                        contactEmail = contactEmail,
                        cdmName = cdmName,
                        cdmVersion = cdmVersion,
                        vocabularyVersion = vocabularyVersion,
                        n3cPhenotypeYN = n3cPhenotypeYN,
                        n3cPhenotypeVersion = n3cPhenotypeVersion,
                        dataLatencyNumDays = dataLatencyNumDays,
                        daysBetweenSubmissions = daysBetweenSubmissions,
                        shiftDateYN = shiftDateYN,
                        maxNumShiftDays = maxNumShiftDays,
                        useAndromeda = FALSE # See troubleshooting note below
                        )
                        
# OPTIONAL EXTENSIONS
#------------------
# For those sites that have opted in for adding in NLP and/or ADT data, you must first run the main extraction code above before executing below as these functions append to tables generated during that process

#(1/2) NLP
# FOR NLP SITES ONLY
# Assumes OHNLP has already been run, reads from NOTE and NOTE_NLP tables, extracts NLP data to pipe delimited files
# references path var 'nlpSqlPath'
N3cOhdsi::runExtraction(connectionDetails = connectionDetails,
                        sqlFilePath = nlpSqlPath,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        resultsDatabaseSchema = resultsDatabaseSchema,
                        outputFolder = outputFolder
)

# (2/2) ADT
# FOR ADT/VISIT_DETAIL SITES ONLY
# Assumes main extraction has already been run and the DATA_COUNTS.csv file generated, extracts visit_detail table and appends row counts to DATA_COUNTS.csv
# references path var 'adtSqlPath'
N3cOhdsi::runExtraction(connectionDetails = connectionDetails,
                        sqlFilePath = adtSqlPath,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        resultsDatabaseSchema = resultsDatabaseSchema,
                        outputFolder = outputFolder
)
#------------------------

# Compress output
zip::zipr(zipfile = paste0(siteAbbrev, "_", cdmName, "_", format(Sys.Date(),"%Y%m%d"),".zip"),
          files = list.files(outputFolder, full.names = TRUE))


```
**Troubleshooting note:** The default settings of the `runExtraction` function pulls data from your database into local memory before saving it disk as delimited files. If you are experiencing RAM limitation issues on your local machine, you can avoid storing the query results in memory by leveraging the Andromeda package (set `useAndromeda=TRUE` parameter in `runExtraction()` ) which instead temporarily stores that data on disk instead of RAM.


Note: if you cannot call out to the internet from R, you may download the [TAR here](https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/archive/master.zip). 

When you download this, you'll need to `Upload` the package into your RStudio environment (if in the cloud) or simply find the file pathway (if local RStudio). Once uploaded, you will need to open the `N3cOhdsi.Rprog` and the `Build` tab will show up in the upper right windows (next to Environment, History, Connections, Build). Proceed to `Install and Restart` to build the `N3cOhdsi` library. You may access the file `example_execution.R` to retrieve the code referenced above.

**What will my output look like?**

Once you run the exporter, your files will be output in the following directory structure:

**_Parent Directory_**

![Screenshot of Example Parent Directory](https://imgur.com/68YwCGU.png)

**_Sub-Directory_**

![Screenshot of Example Sub-Directory](https://imgur.com/ubrdNwA.png)

Note that these files are .csv files, but are actually pipe delimited rather than comma delimited. The exporter will take care of delimiters, formatting, headers, and everything else you need to be compliant with our formatting.

**Configuring the MANIFEST variables**

See the table below for examples of what values are expected in the MANIFEST table. 

<table>
  <tr>
   <td><strong>Field name</strong>
   </td>
   <td><strong>Definition</strong>
   </td>
   <td><strong>Sample value</strong>
   </td>
   <td><strong>Static or changing</strong>
   </td>
  </tr>
  <tr>
   <td>SITE_ABBREV
   </td>
   <td>Unique abbreviation for your site; will be provided by N3C
   </td>
   <td>“Tufts”
   </td>
   <td>Static
   </td>
  </tr>
  <tr>
   <td>SITE_NAME
   </td>
   <td>Full name of your site
   </td>
   <td>“Tufts University”
   </td>
   <td>Static
   </td>
  </tr>
  <tr>
  <tr>
   <td>CONTACT_NAME
   </td>
   <td>Full name of N3C technical contact at your site 
   </td>
   <td>“Jane Doe”
   </td>
   <td>Static
   </td>
  </tr>
  <tr>
   <td>CONTACT_EMAIL
   </td>
   <td>Email address of N3C technical contact at your site
   </td>
   <td>“jane_doe@tufts.edu”
   </td>
   <td>Static
   </td>
  </tr>
  <tr>
   <td>CDM_NAME
   </td>
   <td>Choose one: OMOP | PCORNET | ACT | TRINETX
   </td>
   <td>“OMOP”
   </td>
   <td>Static
   </td>
  </tr>
  <tr>
   <td>CDM_VERSION
   </td>
   <td>Numbered version of your chosen CDM
   </td>
   <td>“5.3.1”
   </td>
   <td>Static
   </td>
  </tr>
  <tr>
   <td>VOCABULARY_VERSION
   </td>
   <td>Only applies to OMOP, insert "N/A" for other models. Version of OMOP vocabulary in use for this data pull.
   </td>
   <td>"v5.0 19-MAY-20"
   </td>
   <td>Will change if you update your vocabulary tables at your site
   </td>
  </tr>
  <tr>
   <td>N3C_PHENOTYPE_YN
   </td>
   <td>Enter Y if you are using the N3C phenotype code to define your cohort; enter N if you are using a local definition
   </td>
   <td>“Y”
   </td>
   <td>Static
   </td>
  </tr>
  <tr>
   <td>N3C_PHENOTYPE_VERSION
   </td>
   <td>If using the N3C phenotype, which numbered version was used for this run? (Enter “NA” if not using the N3C phenotype)
   </td>
   <td>“1.6”
   </td>
   <td>Generally static but may need occasional updating
   </td>
  </tr>
  <tr>
   <td>RUN_DATE
   </td>
   <td>Date the current extract was run.
   </td>
   <td>“2020-05-05”
   </td>
   <td>Changing (use SYSDATE)
   </td>
  </tr>
  <tr>
   <td>UPDATE_DATE
   </td>
   <td>Date for which the data in this extract is current (i.e., the maximum date present in your dataset) 
   </td>
   <td>“2020-05-04”
   </td>
   <td>Changing (use SYSDATE - # days latency at your site)
   </td>
  </tr>
  <tr>
   <td>NEXT_SUBMISSION_DATE
   </td>
   <td>Date on which you will submit your next extract
   </td>
   <td>“2020-05-07”
   </td>
   <td>Changing (use SYSDATE + # days between submissions)
   </td>
  </tr>
</table>

**Bug Reports/Enhancement Requests/Contributions**

We would love to hear from you about this script, as we hope to continue to improve and enhance it. We also welcome contributions, if there's a cool feature you've added locally. Please feel free to open an issue or create a pull request as needed!
