createTableDate <- function(schema, table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("CREATE TABLE ", schema, ".", table," (date text)")
    dbGetQuery(con,query)
    
    dbDisconnect(con)

}