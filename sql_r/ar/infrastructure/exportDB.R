exportDB <- function(schema_dev, table, df){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    
    query <- paste("DROP TABLE IF EXISTS ", schema_dev,".",table, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema_dev,table), 
                 value = data.frame(df), row.names = T, append= F)
    
    query <- paste("ALTER TABLE ", schema_dev, ".", table," RENAME \"row.names\" TO tower_id", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev, ".", table," ALTER COLUMN tower_id TYPE INTEGER USING tower_id::INTEGER", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table, " ALTER COLUMN coverage_area_2g TYPE GEOMETRY USING coverage_area_2g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table, " ALTER COLUMN coverage_area_3g TYPE GEOMETRY USING coverage_area_3g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table, " ALTER COLUMN coverage_area_4g TYPE GEOMETRY USING coverage_area_4g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table, " ADD COLUMN geom GEOGRAPHY ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema_dev,".",table, " SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::GEOGRAPHY ", sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}