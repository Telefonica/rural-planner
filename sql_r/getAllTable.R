getAllTable <- function(schema, table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste("SELECT * FROM ",schema, ".", table,sep ="")
    aux<- dbGetQuery(con,query)
    
    dbDisconnect(con)
    aux

}