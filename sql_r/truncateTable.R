truncateTable <- function(schema, table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 

    query <- paste0('TRUNCATE TABLE ',schema,'.', table)
    dbGetQuery(con,query) 
    
    dbDisconnect(con)
}