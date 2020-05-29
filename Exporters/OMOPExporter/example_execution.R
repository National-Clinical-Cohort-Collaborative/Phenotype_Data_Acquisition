install.packages("devtools")
library(devtools)
install_github("ohdsi/DatabaseConnector", ref = "v2.4.1")
install_github("ohdsi/OhdsiSharing", ref = "v0.1.3")
install.packages("SqlRender", ref = "v1.6.6")

library(DatabaseConnector)
library(SqlRender)
library(OhdsiSharing)
library(N3cOhdsi)

# --- Local configuration ---

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sql server",  # options: oracle, postgressql, redshift, sql server, pdw, netezza, bigquery, sqlite
                                                          server = "", # name of the server
                                                          user="", # username to access server
                                                          password = "" #password for that user
                                                          )
cdmDatabaseSchema <- "" # schema for your CDM instance -- e.g. TMC_OMOP.dbo
resultsDatabaseSchema <- "" # schema with write privileges

outputFolder <-  paste0(getwd(), "/output/")  # directory where output will be stored. default provided

cdmName <- "OMOP"
siteAbbrev <- "TuftsMC" # unique site identifier


phenotypeSqlPath <- "" # full path of phenotype sql file

extractSqlPath <- ""  # full path of extract sql file


# --- Execution ---


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


# Compress into single file
OhdsiSharing::compressFolder(outputFolder, paste0(siteAbbrev, "_", cdmName, "_", format(Sys.Date(),"%Y%m%d"),".zip") )


