officialSettlements <- function(schema, table_census){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)
  
  query <- paste0('SELECT settlement_id, admin_division_2_name,
                          admin_division_1_name, settlement_name FROM ',schema,'.',table_census)
  official_settlements <- dbGetQuery(con,query)
  
  dbDisconnect(con)
  official_settlements
  
  
}