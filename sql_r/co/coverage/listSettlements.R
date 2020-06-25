listSettlements <- function(schema_dev, table_settlements){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 

    query <- paste0('SELECT settlement_id FROM ',schema_dev,'.',table_settlements)
    settlements_list <- dbGetQuery(con,query)
    
    dbDisconnect(con)
    
    settlements_list
}