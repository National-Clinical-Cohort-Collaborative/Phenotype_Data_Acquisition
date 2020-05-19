
library(DatabaseConnector)
library(SqlRender)
library(OhdsiSharing)

library(N3cOhdsi)

con_details <- DatabaseConnector::createConnectionDetails(dbms = "sql server",
                                             user = "",
                                             password = "",
                                             server = ""
                                             )

cdmDatabaseSchema <- "" #
resultsDatabaseSchema <- "" # schema with write privileges
vocabularyDatabaseSchema <- ""
targetCohortTable <- "cohort"
targetCohortId <- 999 # TODO: remove?
outputFolder <-  paste0(getwd(), "/output/")

# Generate cohort
N3cOhdsi::createCohort(connectionDetails = con_details,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        resultsDatabaseSchema = resultsDatabaseSchema,
                        vocabularyDatabaseSchema = cdmDatabaseSchema,
                        targetCohortTable = targetCohortTable,
                        targetCohortId = targetCohortId
                        )

# Extract data to pipe delimited files
N3cOhdsi::runExtraction(connectionDetails = con_details,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        resultsDatabaseSchema = resultsDatabaseSchema,
                        outputFolder = outputFolder
                        )


# Compress into single file
OhdsiSharing::compressFolder(outputFolder, paste0("Tufts_OMOP_52_", Sys.Date(),".zip") )


