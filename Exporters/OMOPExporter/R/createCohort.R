

# vocabularyDatabaseSchema is optional and defaults to cdmDatabaseSchema
createCohort <- function(connectionDetails,
                            sqlFilePath,
                            cdmDatabaseSchema,
                            resultsDatabaseSchema,
                            vocabularyDatabaseSchema = cdmDatabaseSchema
                            ) {



  src_sql <- SqlRender::readSql(sqlFilePath)


  sql <- SqlRender::render(sql = src_sql,
                           cdm_database_schema = cdmDatabaseSchema,
                           target_database_schema = resultsDatabaseSchema,
                           cohortDatabaseSchema = resultsDatabaseSchema,
                           vocabulary_database_schema = vocabularyDatabaseSchema)

  conn <- DatabaseConnector::connect(connectionDetails)


  result <- DatabaseConnector::executeSql(conn, sql)


  DatabaseConnector::disconnect(conn)

}
