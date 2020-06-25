dropTable <- function(dev_schema, table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("DROP TABLE IF EXISTS ", dev_schema, ".", table)
    dbGetQuery(con,query)
    
    dbDisconnect(con)

}