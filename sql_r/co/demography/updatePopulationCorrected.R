updatePopulationCorrected <- function(schema,table_settlements){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                    host = host, port = port,
                     user = user, password = pwd)
                     
  query <- paste0("UPDATE ",schema, ".", table_settlements," SET population_corrected = 0 WHERE population_corrected IS NULL")
  dbGetQuery(con,query)
  
  dbDisconnect(con)

}