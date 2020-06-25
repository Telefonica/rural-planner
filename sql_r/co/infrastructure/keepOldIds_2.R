keepOldIds_2 <- function(schema_dev, table_global){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    
    query <- paste0("UPDATE ", schema_dev, ".", table_global, "
                     SET tower_id = a.tower_id 
                     FROM (SELECT (ROW_NUMBER() OVER (ORDER BY source, latitude,longitude))+",max_id$max," as tower_id,
                              latitude, longitude, source, internal_id
                           FROM ", schema_dev, ".", table_global, "
                           WHERE tower_id IS NULL) a 
                     WHERE ", table_global, ".tower_id IS NULL
                        AND ", table_global, ".latitude= a.latitude
                        AND ", table_global, ".longitude=a.longitude
                        AND ", table_global, ".source=a.source
                        AND ", table_global, ".internal_id=a.internal_id")
    dbGetQuery(con,query)
                     
    dbDisconnect(con,query)
    max_id_2
}