mergeWithSettlements <- function(schema, settlements_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                         host = host, port = port,
                         user = user, password = pwd) 
    
    query <- paste0('SELECT settlement_id FROM ',schema,'.',settlements_table)
    settlements_list <- dbGetQuery(con, query)
    
    dbDisconnect(con)
    settlements_list
}