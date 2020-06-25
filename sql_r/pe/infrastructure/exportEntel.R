exportEntel <- function(schema_dev, output_table, infrastructure_table, infra_match_table){
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
                     SET location_detail = (SELECT new_location_detail
                                            FROM ", schema_dev, ".", infra_match_table, " A
                                            WHERE I.tower_id = A.tower_id)")
    dbGetQuery(con,query)
    dbDisconnect(con)

}