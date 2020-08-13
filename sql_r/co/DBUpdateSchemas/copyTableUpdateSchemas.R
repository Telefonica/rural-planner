copyTable <- function(schema_aux,schema, table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("CREATE TABLE ", schema_aux,".",table, " AS 
                  (SELECT * FROM ", schema, ".", table, " )")
    dbGetQuery(con,query)
    
    dbDisconnect(con)

}