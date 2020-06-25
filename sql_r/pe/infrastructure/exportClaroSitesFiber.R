exportClaroSitesFiber <- function(schema, table_points, claro_points){
    #Upload points to database structured as infrastructure  
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table_points, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,table_points), 
                 value = data.frame(claro_points), row.names = T, append= F)
    
    query <- paste("ALTER TABLE ", schema, ".", table_points," RENAME \"row.names\" TO tower_id", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema, ".", table_points," ALTER COLUMN tower_id TYPE INTEGER USING tower_id::INTEGER", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_points, " ALTER COLUMN coverage_area_2g TYPE GEOMETRY USING coverage_area_2g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_points, " ALTER COLUMN coverage_area_3g TYPE GEOMETRY USING coverage_area_3g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_points, " ALTER COLUMN coverage_area_4g TYPE GEOMETRY USING coverage_area_4g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_points, " ADD COLUMN geom GEOMETRY ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema,".",table_points, " SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::GEOMETRY ", sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)


}