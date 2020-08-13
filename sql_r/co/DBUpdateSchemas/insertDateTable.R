insertDateTable <- function(schema, table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("INSERT INTO ", schema,".",table, "(date) VALUES ('",Sys.Date(),"')")
    dbGetQuery(con,query)
    
    dbDisconnect(con)

}