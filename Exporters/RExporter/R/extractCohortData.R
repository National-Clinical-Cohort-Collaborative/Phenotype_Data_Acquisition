
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
                           outputFolder = paste0(getwd(), "/output/"),
                           useAndromeda = FALSE,
                           ...
                           )
{
  # workaround to avoid scientific notation
  # save current scipen value
  scipen_val <- getOption("scipen")
  # temporarily change scipen setting (restored at end of f())
  options(scipen=999)

  # create output dir if it doesn't already exist
  if (!file.exists(file.path(outputFolder)))
    dir.create(file.path(outputFolder), recursive = TRUE)

  if (!file.exists(paste0(outputFolder,"DATAFILES")))
    dir.create(paste0(outputFolder,"DATAFILES"), recursive = TRUE)

  # load source sql file
  src_sql <- SqlRender::readSql(sqlFilePath)

  # replace parameters with values
  src_sql <- SqlRender::render(sql = src_sql,
                               warnOnMissingParameters = FALSE,
                               cdmDatabaseSchema = cdmDatabaseSchema,
                               resultsDatabaseSchema = resultsDatabaseSchema,
                               ...)


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
    if(fileNm != "MANIFEST.csv" && fileNm != "DATA_COUNTS.csv" && fileNm != "EXTRACT_VALIDATION.csv" && fileNm != "DATA_COUNTS_APPEND.csv"){
      output_path <- paste0(outputFolder, "DATAFILES/")
    }


    if(useAndromeda && fileNm != "EXTRACT_VALIDATION.csv"){

      executeChunkAndromeda(conn = conn,
                             sql = sql,
                             fileName = fileNm,
                             outputFolder = output_path)
    }else{

      num_result_rows <- executeChunk(conn = conn,
                                      sql = sql,
                                      fileName = fileNm,
                                      outputFolder = output_path)

      # throw error if dup PKs found
      if(fileNm == 'EXTRACT_VALIDATION.csv' && num_result_rows > 0){
        stop("Duplicate primary keys. See EXTRACT_VALIDATION.csv")
      }

    }



  }



  # Disconnect from database
  DatabaseConnector::disconnect(conn)

  # restore original scipen value
  options(scipen=scipen_val)

}


executeChunk <- function(conn,
                         sql,
                         fileName,
                         outputFolder){



  result <- DatabaseConnector::querySql(conn, sql)

  # workaround to append row counts from optional tables (VISIT_DETAIL, NOTE, NOTE_NLP) to DATA_COUNTS.csv on separate executions
  if(fileName == "DATA_COUNTS_APPEND.csv"){
    write.table(result, file = paste0(outputFolder, "DATA_COUNTS.csv" ), sep = "|", row.names = FALSE, na="", append = TRUE, col.names = FALSE)
    return(nrow(result))
  }

  # everything but appends to DATA_COUNTS table
  else{
    write.table(result, file = paste0(outputFolder, fileName ), sep = "|", row.names = FALSE, na="")
    return(nrow(result))
  }



}



executeChunkAndromeda <- function(conn,
                                 sql,
                                 fileName,
                                 outputFolder){



  andr <- Andromeda::andromeda()
  DatabaseConnector::querySqlToAndromeda(connection = conn
                                         ,sql = sql
                                         ,andromeda = andr
                                         ,andromedaTableName = "tmp")

  write.table(andr$tmp, file = paste0(outputFolder, fileName ), sep = "|", row.names = FALSE, na="")

  Andromeda::close(andr)


}


