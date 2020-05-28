
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
                           sqlFilePath,
                           cdmDatabaseSchema,
                           resultsDatabaseSchema,
                           outputFolder = paste0(getwd(), "/output/")
                           )
{

  # create output dir if it doesn't already exist
  if (!file.exists(file.path(outputFolder)))
    dir.create(file.path(outputFolder), recursive = TRUE)

  if (!file.exists(paste0(outputFolder,"DATAFILES")))
    dir.create(paste0(outputFolder,"DATAFILES"), recursive = TRUE)

  # load source sql file
  src_sql <- SqlRender::readSql(sqlFilePath)

  # replace parameters with values
  src_sql <- SqlRender::render(sql = src_sql,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           resultsDatabaseSchema = resultsDatabaseSchema)


  # split script into chunks (to produce separate output files)
  allSQL <- parse_sql(src_sql)


  # establish database connection
  conn <- DatabaseConnector::connect(connectionDetails)

  #iterate through query list
  for (i in seq(from = 1, to = length(allSQL), by = 2)) {
    fileNm <- allSQL[i]

    # check for and remove return from file name
    fileNm <- gsub(pattern = "\r", x = fileNm, replacement = "")

    sql <- allSQL[i+1]

    # TODO: replace this hacky approach to writing these two tables to the root output folder
    output_path <- outputFolder
    if(fileNm != "MANIFEST.csv" && fileNm != "DATA_COUNTS.csv"){
      output_path <- paste0(outputFolder, "DATAFILES/")
    }

    executeChunk(conn = conn,
                 sql = sql,
                 fileName = fileNm,
                 outputFolder = output_path)

  }



  # Disconnect from database
  DatabaseConnector::disconnect(conn)

}


executeChunk <- function(conn,
                         sql,
                         fileName,
                         outputFolder){



  result <- DatabaseConnector::querySql(conn, sql)

  write.table(result, file = paste0(outputFolder, fileName ), sep = "|", row.names = FALSE)



}
