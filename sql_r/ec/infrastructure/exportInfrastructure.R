exportInfrastructure <- function(schema, table, towers){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,table), 
                 value = data.frame(towers), row.names = T, append= F, replace=F)
    
    query <- paste0("ALTER TABLE ", schema, ".", table," RENAME \"row.names\" TO tower_id")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table, " ALTER COLUMN coverage_area_2g TYPE GEOMETRY USING coverage_area_2g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table, " ALTER COLUMN coverage_area_2g TYPE GEOMETRY USING coverage_area_2g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table, " ALTER COLUMN coverage_area_3g TYPE GEOMETRY USING coverage_area_3g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table, " ALTER COLUMN coverage_area_4g TYPE GEOMETRY USING coverage_area_4g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table, " ADD COLUMN geom geography", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema, ".", table, " SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326)", sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}