updateDBTPVogel <- function(schema,table,vogel_lines_int){

    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,table), 
                 value = data.frame(vogel_lines_int), row.names = F, append= F)
    
    
    query <- paste("ALTER TABLE ", schema,".",table, " ADD COLUMN geom GEOGRAPHY ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema,".",table, " SET geom = ST_GeogFromText(wkt) ", sep = "")
    dbGetQuery(con,query)
    
    
    query <- paste("ALTER TABLE ", schema,".",table, " DROP COLUMN wkt ", sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}