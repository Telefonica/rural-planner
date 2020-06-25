uploadDBAtoll_cnt <- function(schema_pro, table_pro, schema, table){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)
  
  query <-paste0("DROP TABLE ", schema_pro,".",table_pro)
  dbGetQuery(con,query)
  
  query <-paste0("CREATE TABLE ", schema_pro,".",table_pro," AS 
               (SELECT * FROM ", schema,".",table," )")
  dbGetQuery(con,query)
  
  dbDisconnect(con)
  
}