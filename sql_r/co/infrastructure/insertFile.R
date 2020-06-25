insertFile <- function(schema, temp_table, dfSHPs){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd) 
  
  pgInsert(conn = con, name = c(schema,temp_table),data.obj = dfSHPs)
  
  dbDisconnect(con)
}