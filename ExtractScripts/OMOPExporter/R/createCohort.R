



createCohort <- function(connectionDetails,
                            cdmDatabaseSchema,
                            resultsDatabaseSchema,
                            vocabularyDatabaseSchema,
                            targetCohortTable = "cohort",
                            targetCohortId = 9999

                            ) {


  sql <- SqlRender::loadRenderTranslateSql("generate_cohort.sql",
                                         "N3cOhdsi",
                                         dbms = connectionDetails$dbms,
                                         cdm_database_schema = cdmDatabaseSchema,
                                         target_database_schema = resultsDatabaseSchema,
                                         cohortDatabaseSchema = resultsDatabaseSchema,
                                         vocabulary_database_schema = vocabularyDatabaseSchema,
                                         target_cohort_table = targetCohortTable,
                                         target_cohort_id = targetCohortId
                                         )
  conn <- DatabaseConnector::connect(connectionDetails)


  result <- DatabaseConnector::executeSql(conn, sql)
}
