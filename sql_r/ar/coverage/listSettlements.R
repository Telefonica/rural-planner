listSettlements <- function(schema, table_settlements){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    query <- paste0('SELECT DISTINCT settlement_id FROM ',schema,'.',table_settlements) 
    settlements_list <- dbGetQuery(con,query)
    dbDisconnect(con)
    settlements_list
}