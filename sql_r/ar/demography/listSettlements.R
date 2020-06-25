listSettlements <- function(schema, table_settlements){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0('SELECT *, right(settlement_id,5) as settlement_id_numeric FROM ',schema,'.',table_settlements)
    #query <- paste0('SELECT *, right(settlement_id,5)::numeric as settlement_id_numeric FROM ',schema,'.',table_settlements)
    settlements <- dbGetQuery(con, query)
    
    dbDisconnect(con)
    settlements

}