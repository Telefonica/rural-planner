uploadDBSilica <- function(schema, table_lines, silica_lines){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table_lines, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,table_lines), 
                 value = data.frame(silica_lines), row.names = F, append= F)
    
    query <- paste("ALTER TABLE ", schema,".",table_lines, " ADD COLUMN geom GEOGRAPHY ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema,".",table_lines, " SET geom = ST_GeogFromText(wkt) ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_lines, " DROP COLUMN wkt ", sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}