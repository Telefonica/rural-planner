dropTableCascade <- function(schema, table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table, " CASCADE")
    dbGetQuery(con,query)
    
    dbDisconnect(con)

}