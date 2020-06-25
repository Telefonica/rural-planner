loadDataCloudRF <- function(schema,table, table_coverage){
  
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd) 
    
    query <- paste0("SELECT settlement_id,latitude,longitude FROM ", schema,".",table, " A WHERE A.settlement_id in (SELECT settlement_id FROM ", schema,".",table_coverage," WHERE vivo_4g_corrected IS FALSE)")

    aux_df <- dbGetQuery(con,query)
    dbDisconnect(con)
    aux_df
}