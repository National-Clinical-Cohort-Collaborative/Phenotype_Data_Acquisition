

extractCohortData <- function(connectionDetails,
                              sqlFile,
                              fileName,
                              cdmDatabaseSchema,
                              resultsDatabaseSchema,
                              outputFolder) {


  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = sqlFile,
                                           packageName = "N3cOhdsi",
                                           dbms = connectionDetails$dbms,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           cohortDatabaseSchema = resultsDatabaseSchema
  )
  conn <- DatabaseConnector::connect(connectionDetails)

  result <- DatabaseConnector::querySql(conn, sql)

  write.table(result, file = paste0(outputFolder, fileName ))

  DatabaseConnector::disconnect(conn)
}


runExtraction  <- function(connectionDetails,
                           cdmDatabaseSchema,
                           resultsDatabaseSchema,
                           outputFolder = paste0(getwd(), "/output/"))
{

  # create output dir if it doesn't already exist
  if (!file.exists(file.path(outputFolder)))
    dir.create(file.path(outputFolder), recursive = TRUE)

  if (!file.exists(paste0(outputFolder,"DATAFILES")))
    dir.create(paste0(outputFolder,"DATAFILES"), recursive = TRUE)

  # person
  extractCohortData(connectionDetails,
                    sqlFile = "extract_person.sql",
                    fileName = "person.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))

  # obs period
  extractCohortData(connectionDetails,
                    sqlFile = "extract_observation_period.sql",
                    fileName = "observation_period.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))

  # visit_occurrence
  extractCohortData(connectionDetails,
                    sqlFile = "extract_visit_occurrence.sql",
                    fileName = "visit_occurrence.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))

  # condition_occurrence
  extractCohortData(connectionDetails,
                    sqlFile = "extract_condition_occurrence.sql",
                    fileName = "condition_occurrence.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))


  # drug_exposure
  extractCohortData(connectionDetails,
                    sqlFile = "extract_drug_exposure.sql",
                    fileName = "drug_exposure.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))


  # procedure_occurrence
  extractCohortData(connectionDetails,
                    sqlFile = "extract_procedure_occurrence.sql",
                    fileName = "procedure_occurrence.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))


  # measurement
  extractCohortData(connectionDetails,
                    sqlFile = "extract_measurement.sql",
                    fileName = "measurement.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))

  # observation
  extractCohortData(connectionDetails,
                    sqlFile = "extract_observation.sql",
                    fileName = "observation.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))


  # location
  extractCohortData(connectionDetails,
                    sqlFile = "extract_location.sql",
                    fileName = "location.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))

  # care_site
  extractCohortData(connectionDetails,
                    sqlFile = "extract_care_site.sql",
                    fileName = "care_site.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))


  # provider
  extractCohortData(connectionDetails,
                    sqlFile = "extract_provider.sql",
                    fileName = "provider.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))

  # drug_era
  extractCohortData(connectionDetails,
                    sqlFile = "extract_drug_era.sql",
                    fileName = "drug_era.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))


  # dose_era
  extractCohortData(connectionDetails,
                    sqlFile = "extract_dose_era.sql",
                    fileName = "dose_era.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))


  # condition_era
  extractCohortData(connectionDetails,
                    sqlFile = "extract_condition_era.sql",
                    fileName = "condition_era.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder = paste0(outputFolder, "DATAFILES/"))


  # data_counts
  extractCohortData(connectionDetails,
                    sqlFile = "extract_data_counts.sql",
                    fileName = "data_counts.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder)


  # manifest
  extractCohortData(connectionDetails,
                    sqlFile = "extract_manifest.sql",
                    fileName = "manifest.csv",
                    cdmDatabaseSchema,
                    resultsDatabaseSchema,
                    outputFolder)

}




