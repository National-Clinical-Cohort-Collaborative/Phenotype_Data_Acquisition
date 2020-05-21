install.packages("devtools")
library(devtools)
install_github("ohdsi/DatabaseConnector", ref = "v2.4.1")
install_github("ohdsi/OhdsiSharing", ref = "v0.1.3")
install.packages("SqlRender", ref = "v1.6.6")

library(DatabaseConnector)
library(SqlRender)
library(OhdsiSharing)
library(N3cOhdsi)

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "redshift",  # options: oracle, postgressql, redshift, sql server, pdw, netezza, bigquery, sqlite
                                                          server = "", # name of the server
                                                          user="", # username to access server
                                                          password = "" #password for that user)
cdmDatabaseSchema <- "" # schema for your CDM instance -- e.g. full_201911_omop_v5
resultsDatabaseSchema <- "study_reference" # schema with write privileges
vocabularyDatabaseSchema <- "" #schema where your Vocabulary tables are stored
targetCohortTable <- "n3c_cohort" #name of your cohortTable
outputFolder <-  paste0(getwd(), "/output/")


# Generate cohort
N3cOhdsi::createCohort(connectionDetails = connectionDetails,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        resultsDatabaseSchema = resultsDatabaseSchema,
                        vocabularyDatabaseSchema = cdmDatabaseSchema,
                        targetCohortTable = targetCohortTable
                        )

# Extract data to pipe delimited files
N3cOhdsi::runExtraction(connectionDetails = connectionDetails,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        resultsDatabaseSchema = resultsDatabaseSchema,
                        outputFolder = outputFolder
                        )


# Compress into single file
OhdsiSharing::compressFolder(outputFolder, paste0("YourInstitution_OMOP_SiteNumber_", Sys.Date(),".zip") )


