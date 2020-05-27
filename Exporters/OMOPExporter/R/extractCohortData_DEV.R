extractCohortData <- function(connectionDetails,
                              sqlFile,
                              fileName,
                              cdmDatabaseSchema,
                              resultsDatabaseSchema,
                              outputFolder) {

  conn <- DatabaseConnector::connect(connectionDetails)
  
  result <- DatabaseConnector::querySql(conn, sqlFile)
  
  write.table(result, file = paste0(outputFolder, fileName ), sep = "|", row.names = FALSE)
  
  DatabaseConnector::disconnect(conn)
}

#break up the single SQL file into individual statements and output file names
parse_sql <- function(sqlFile) {
  sql <- ""
  output_file_tag <- "OUTPUT_FILE:"
  inrows <- unlist(strsplit(sqlFile, "\n"))
  statements <- list()
  outputs <- list()
  statementnum <- 0
  
  for (i in 1:length(inrows)) {
    sql = paste(sql, inrows[i], sep = "\n")
    if (regexpr("OUTPUT_FILE", inrows[i]) != -1) {
      output_file <- sub("--OUTPUT_FILE: ", "", inrows[i]) 
      }
    if (regexpr(";", inrows[i]) != -1) {
      statementnum <- statementnum + 1
      statements[[statementnum]] = sql
      outputs[[statementnum]] = output_file
      sql <- "" 
      }
  }
  
  mapply(c, outputs, statements)
  
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
  
  
  src_sql <-  SqlRender::loadRenderTranslateSql(sqlFilename = "source_extract_scripts.sql",
                                                packageName = "N3cOhdsi",
                                                dbms = connectionDetails$dbms,
                                                cdmDatabaseSchema = cdmDatabaseSchema,
                                                cohortDatabaseSchema = resultsDatabaseSchema
  )
  
  allSQL <- parse_sql(src_sql) 
  
  #iterate through query list
  for (i in seq(from = 1, to = length(allSQL), by = 2)) {
    fileNm <- allSQL[i]
    sql <- allSQL[i+1]
    
  extractCohortData(connectionDetails,
                      sqlFile = sql,
                      fileName = fileNm,
                      cdmDatabaseSchema,
                      resultsDatabaseSchema,
                      outputFolder = paste0(outputFolder, "DATAFILES/"))

  }
  
}
