addTowerId <- function(schema, table){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
  
  query <- paste("ALTER TABLE ", schema,".",table, " ADD COLUMN tower_id INTEGER ", sep = "")
  dbGetQuery(con,query)
  
  query <- paste("ALTER TABLE ", schema, ".", table," ALTER COLUMN tower_id TYPE INTEGER USING tower_id::INTEGER", sep = "")
  dbGetQuery(con,query)
  
  dbDisconnect(con)
}