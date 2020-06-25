listSettlementsZRD <- function(schema, table_zrd){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 

    query <- paste0('SELECT centroid FROM ',schema,'.',table_zrd)
    settlements_list <- dbGetQuery(con,query)
    
    dbDisconnect(con)
    
    settlements_list
}