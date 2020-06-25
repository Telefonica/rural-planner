insertCensusShp <- function(schema_dev, tables, objects){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
  for(i in 1:length(tables)){
    pgInsert(conn = con, name = c(schema_dev, tables[i]), data.obj = objects[[i]])
  }
  dbDisconnect(con)
}