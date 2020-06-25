listSettlements <- function(schema, table_settlements){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)
  
  #List of all settlements registered in the country
  
  query <- paste0('SELECT settlement_id FROM ',schema,'.',table_settlements)
  settlements_list <- dbGetQuery(con,query)
  dbDisconnect(con)
  settlements_list
}