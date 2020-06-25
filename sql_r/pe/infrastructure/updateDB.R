updateDB <- function(schema, table_global, table_entel){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("UPDATE ", schema, ".", table_global, " I
                     SET location_detail = (SELECT location_detail
                                            FROM ", schema, ".", table_entel, " A
                                            WHERE I.tower_id = A.tower_id)")
    dbGetQuery(con,query)
    
    dbDisconnect(con,query)
}