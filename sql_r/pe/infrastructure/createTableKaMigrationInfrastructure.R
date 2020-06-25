createTableKaMigrationInfrastructure <- function(schema_dev, output_table, infrastructure_table, intermediate_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("DROP TABLE IF EXISTS ", schema_dev,".",output_table)
    dbGetQuery(con,query)
    
    query <- paste0("CREATE TABLE ", schema_dev, ".", output_table, "
                     AS TABLE ", schema_dev, ".", infrastructure_table)
    dbGetQuery(con,query)
    
    query <- paste0("UPDATE ", schema_dev, ".", output_table, " I
                     SET satellite_band_in_use = 
                                 (SELECT migration_tag FROM ", schema_dev, ".", infrastructure_table, " A
                                  LEFT JOIN ", schema_dev, ".", intermediate_table, " B
                                  ON A.tower_id = B.tower_id
                                  WHERE I.tower_id = A.tower_id)")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}