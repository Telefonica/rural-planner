matchSettlementsIds <- function(schema, table_settlements){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
                     
    query <- paste0('SELECT DISTINCT ON (settlement_id) settlement_id, settlement_name, admin_division_1_name, admin_division_2_name FROM ',schema,'.',table_settlements) 
    settlements_info <- dbGetQuery(con,query)
    
    dbDisconnect(con)
    settlements_info
    
}