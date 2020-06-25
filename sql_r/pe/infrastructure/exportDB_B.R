exportDB_B <- function(schema, table, df){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste("DROP TABLE IF EXISTS ", schema, ".", table, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,table), 
                 value = data.frame(df), row.names = T, append= F)
    
    query <- paste("ALTER TABLE ", schema, ".", table," RENAME \"row.names\" TO tower_id", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table, " ADD COLUMN geom geography", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema, ".", table, " SET geom = ST_SetSRID(ST_MakePoint(longitude::numeric, latitude::numeric),4326)", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema, ".", table," ALTER COLUMN tower_id TYPE INTEGER USING tower_id::INTEGER", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table, " ALTER COLUMN coverage_area_2g TYPE GEOMETRY USING coverage_area_2g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table, " ALTER COLUMN coverage_area_3g TYPE GEOMETRY USING coverage_area_3g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table, " ALTER COLUMN coverage_area_4g TYPE GEOMETRY USING coverage_area_4g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)

}