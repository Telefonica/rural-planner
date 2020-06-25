exportConsolidation <- function(schema, table_global, towers, global_view){
    #Export and separate towers, access and transport
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    #Upload towers, add ID as integer and add geom field and change the coverage areas types to geom
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table_global," CASCADE", sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,table_global), 
                 value = data.frame(towers), row.names = T, append= F)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " RENAME \"row.names\" TO tower_id", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ALTER COLUMN tower_id TYPE INTEGER USING tower_id::INTEGER", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ALTER COLUMN coverage_area_2g TYPE GEOMETRY USING coverage_area_2g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ALTER COLUMN coverage_area_3g TYPE GEOMETRY USING coverage_area_3g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ALTER COLUMN coverage_area_4g TYPE GEOMETRY USING coverage_area_4g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    # AD-HOC
    query <- paste("UPDATE ", schema, ".", table_global, " SET latitude = -latitude where internal_id in ('A11-S197')", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema, ".", table_global, " SET longitude = -longitude where internal_id in ('ARSL4768','ARSL4769')", sep = "")
    dbGetQuery(con,query)
    
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ADD COLUMN geom geography", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema, ".", table_global, " SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326) where latitude<>0 and longitude<>0", sep = "")
    dbGetQuery(con,query)
    
    # AD-HOC
    query <- paste("UPDATE ", schema, ".", table_global, " SET geom = NULL where internal_id in ('AA001','IA030','IA121','CU688')", sep = "")
    dbGetQuery(con,query)
    
    
    query <- paste("UPDATE ", schema, ".", table_global, " SET subtype = replace(subtype,'á','a')", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("
    CREATE VIEW  ", schema, ".", global_view,
    " AS SELECT
    tower_id,
    latitude,
    longitude,
    tower_height,
    owner,
    location_detail,
    tower_type,
    tech_2g,
    tech_3g,
    tech_4g,
    type,
    subtype,
    in_service,
    vendor,
    coverage_area_2g,
    coverage_area_3g,
    coverage_area_4g,
    fiber,
    radio,
    satellite,
    satellite_band_in_use,
    radio_distance_km,
    last_mile_bandwidth,
    source_file,
    internal_id,
    geom
    FROM ", schema, ".", table_global, sep = "")
    
    
    dbGetQuery(con, query)
    
    dbDisconnect(con)
}