

# vocabularyDatabaseSchema is optional and defaults to cdmDatabaseSchema
createCohort <- function(connectionDetails,
                         sqlFilePath,
                         cdmDatabaseSchema,
                         resultsDatabaseSchema,
                         vocabularyDatabaseSchema = cdmDatabaseSchema,
                         ...
                         ) {



  src_sql <- SqlRender::readSql(sqlFilePath)


  sql <- SqlRender::render(sql = src_sql,
                           warnOnMissingParameters = FALSE,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           resultsDatabaseSchema = resultsDatabaseSchema,
                           vocabularyDatabaseSchema = vocabularyDatabaseSchema,
                           ...
                           )

  conn <- DatabaseConnector::connect(connectionDetails)


  result <- DatabaseConnector::executeSql(conn, sql)


  DatabaseConnector::disconnect(conn)

}
