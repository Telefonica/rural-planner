exportSitesPAM <- function(schema_dev, table_dev, pam_int){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    #KA MIGRATION SITES
    
    query <- paste0("DROP TABLE IF EXISTS ", schema_dev,".",table_dev)
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema_dev,table_dev), 
                 value = data.frame(pam_int), row.names = F, append= F, replace= T)
    
    query <- paste("ALTER TABLE ", schema_dev,".",table_dev, " ADD COLUMN geom GEOGRAPHY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema_dev,".",table_dev, " SET geom = ST_SetSRID(ST_MakePoint(longitude::numeric, latitude::numeric), 4326) ", sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}