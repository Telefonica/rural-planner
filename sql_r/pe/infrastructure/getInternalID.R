getInternalID <- function(schema, table_macros){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0('SELECT internal_id FROM ',schema,'.', table_macros)
    macros_ids <- dbGetQuery(con,query)
    
    dbDisconnect(con)
    macros_ids
}