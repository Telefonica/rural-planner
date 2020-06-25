#Export and separate towers, access and transport
export_separate_towers <- function(schema, schema_dev, table_old, table_global, intermediate_table, towers){   
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste("SELECT * from information_schema.tables where table_schema = ", schema_dev," and table_name=", table_global, sep = "")
    exists_backup <- dbGetQuery(con,query)
    
    #Upload old towers, add ID as integer and add geom field and change the coverage areas types to geom
    query <- paste("DROP TABLE IF EXISTS ", schema_dev,".",table_old, sep = "")
    dbGetQuery(con,query)
    
    if (nrow(exists_backup)>0){
        query <- paste0("CREATE TABLE ",schema_dev,".",table_old," AS SELECT  * FROM ", schema,".",table_global)
        dbGetQuery(con,query)}
    
    dbWriteTable(con, c(schema_dev, intermediate_table), 
                 value = data.frame(towers), 
                 row.names = F, replace = T)
    
    query <- paste("ALTER TABLE ", schema_dev,".",intermediate_table, " ALTER COLUMN tower_id TYPE INTEGER USING tower_id::INTEGER", sep = "")
    dbGetQuery(con,query)
    
    #Upload towers, add ID as integer and add geom field and change the coverage areas types to geom
    query <- paste("DROP TABLE IF EXISTS ", schema_dev,".",table_global, sep = "")
    dbGetQuery(con,query)
    
    
    query <- paste0("CREATE TABLE ",schema_dev,".",table_global," AS SELECT DISTINCT ON (latitude, longitude, source, internal_id) * FROM ", schema_dev,".",intermediate_table)
    dbGetQuery(con,query)
    
    query <- paste0("DROP TABLE IF EXISTS ", schema_dev,".",intermediate_table)
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table_global, " ALTER COLUMN tower_id TYPE INTEGER USING tower_id::INTEGER", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table_global, " ALTER COLUMN coverage_area_2g TYPE GEOMETRY USING coverage_area_2g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table_global, " ALTER COLUMN coverage_area_3g TYPE GEOMETRY USING coverage_area_3g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table_global, " ALTER COLUMN coverage_area_4g TYPE GEOMETRY USING coverage_area_4g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table_global, " ADD COLUMN geom geography", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema_dev, ".", table_global, " SET geom = ST_SetSRID(ST_MakePoint(longitude::numeric, latitude::numeric),4326) WHERE latitude<>0 AND longitude<>0", sep = "")
    dbGetQuery(con,query)
    
    ## AD-HOC: do not take into account the coverage area that would give the infrastructure that is "PLANNED" (not "IN SERVICE")
    
    query <- paste("UPDATE ", schema_dev, ".", table_global, " SET coverage_area_2g = NULL WHERE in_service <> 'IN SERVICE'", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema_dev, ".", table_global, " SET coverage_area_3g = NULL WHERE in_service <> 'IN SERVICE'", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema_dev, ".", table_global, " SET coverage_area_4g = NULL WHERE in_service <> 'IN SERVICE'", sep = "")
    dbGetQuery(con,query)
    
    
    dbDisconnect(con)
    
}
