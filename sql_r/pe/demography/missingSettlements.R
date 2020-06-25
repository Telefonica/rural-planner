missingSettlements <- function(intermediate_schema, schools_incomplete_settlements_table, settlements_table, schools){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                             host = host, port = port,
                             user = user, password = pwd)
    dbWriteTable(con, c(intermediate_schema,schools_incomplete_settlements_table), value = data.frame(schools), row.names = F, append= T)
    
    query <- paste0('SELECT 
                sch.*,s.settlement_id AS settlement_id_corrected 
                FROM ',intermediate_schema,'.',schools_incomplete_settlements_table,' sch 
                LEFT JOIN ',intermediate_schema,'.',settlements_table,' s 
                ON (sch.settlement_id_6=LEFT(s.settlement_id,6) AND sch.settlement=s.settlement_name) 
                WHERE s.settlement_id IS NOT NULL AND sch.settlement_id IS NULL')
    
    settlement_ids_corrected <- dbGetQuery(con,query)
    dbDisconnect(con)
    settlement_ids_corrected
}