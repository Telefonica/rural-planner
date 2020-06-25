exportKaMigration <- function(schema_dev, table_dev, ka_int, table_3q_dev, ka_tdp_int){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    #KA MIGRATION SITES
    query <- paste0("DROP TABLE IF EXISTS ", schema_dev,".",table_dev)
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema_dev,table_dev), 
                 value = data.frame(ka_int), row.names = F, append= F, replace= T)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table_dev, " ALTER COLUMN tower_id TYPE INTEGER USING tower_id::INTEGER", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table_dev, " ALTER COLUMN migration_flag TYPE INTEGER USING migration_flag::INTEGER", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table_dev, " ADD COLUMN geom GEOGRAPHY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema_dev,".",table_dev, " SET geom = ST_SetSRID(ST_MakePoint(longitude::numeric, latitude::numeric), 4326) ", sep = "")
    dbGetQuery(con,query)
    
    
    #KA MIGRATION SITES TDP
    query <- paste0("DROP TABLE IF EXISTS ", schema_dev,".",table_3q_dev)
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema_dev,table_3q_dev), 
                 value = data.frame(ka_tdp_int), row.names = F, append= F, replace= T)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table_3q_dev, " ALTER COLUMN tower_id TYPE INTEGER USING tower_id::INTEGER", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table_3q_dev, " ADD COLUMN geom GEOGRAPHY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema_dev,".",table_3q_dev, " SET geom = ST_SetSRID(ST_MakePoint(longitude::numeric, latitude::numeric), 4326) ", sep = "")
    dbGetQuery(con,query)
    
    
    dbDisconnect(con)
}