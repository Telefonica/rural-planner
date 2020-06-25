exportBasic <- function(schema, table, settlements_basic){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)  
    
    query <- paste("DROP TABLE IF EXISTS ", schema, ".", table)
    dbGetQuery(con,query)
    
    dbWriteTable(con, c(schema,table), 
                 value = data.frame(settlements_basic), 
                 row.names = F, append = T)
    
    query <- paste("ALTER TABLE ", schema,".",table, " ADD COLUMN geom geography", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema, ".", table, " SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326)", sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)

}