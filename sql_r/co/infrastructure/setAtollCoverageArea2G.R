#Set atoll coverage area 2g to those towers as centroids in proyeccines_qw_atoll

setAtollCoverageArea2G <- function(schema_dev, schema, table_atoll, table_global){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                      host = host, port = port,
                      user = user, password = pwd)
    
    query <- paste0("UPDATE ", schema_dev, ".", table_global, " 
                     SET coverage_area_2g = B.coverage_area::geometry  
                     FROM ",schema,".",table_atoll," B 
                     WHERE ", table_global, ".internal_id = B.internal_id
                     AND ", table_global, ".source = B.source")
    dbGetQuery(con,query)
    
    dbDisconnect(con,query)
}