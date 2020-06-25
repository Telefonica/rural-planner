settlementsKPIS <- function(schema, table, old_schema, old_kpis_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0("SELECT s1.settlement_id, s1.admin_division_3_id, s2.orography, s2.classification
                        FROM ", schema,".",table," s1 LEFT JOIN ", old_schema,".",old_kpis_table," s2 
                        on s1.settlement_id=s2.settlement_id")
    settlements_kpis <- dbGetQuery(con,query)
    
    dbDisconnect(con)

}