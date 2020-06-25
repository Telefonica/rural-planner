keepOldIds_1 <- function(schema_dev, table_global, table_old){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
                     
    query <- paste0("UPDATE ", schema_dev, ".", table_global, "
                     SET tower_id = a.tower_id 
                     FROM (SELECT * FROM ", schema_dev,".",table_old,"
                     WHERE source in ('SITES_TEF','AZTECA', 'ATC',
                                      'ATP','UNITI','QMC','PTI','POZOS_PETROLEROS')) a
                     WHERE ", table_global, ".internal_id=a.internal_id AND ", table_global, ".source=a.source")
    dbGetQuery(con,query)
    
    ## THEN ANDITEL BY LAT-LONG (NOT ALL SITES HAVE INTERNAL ID)
    
    
    query <- paste0("UPDATE ", schema_dev, ".", table_global, "
                     SET tower_id = a.tower_id 
                     FROM (SELECT * FROM ", schema_dev,".",table_old," 
                     WHERE source = 'ANDITEL') a 
                     WHERE ", table_global, ".latitude=a.latitude 
                     AND ", table_global, ".longitude=a.longitude")
    dbGetQuery(con,query)
    
    ##THEN REST OF THE TOWERS (NEW SOURCES)
    
    query <- paste0("SELECT MAX(tower_id)
                    FROM ",schema_dev,".",table_old)
    max_id <- dbGetQuery(con,query)
                     
    dbDisconnect(con,query)
    
    max_id
}