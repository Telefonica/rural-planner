exportSettlements <- function(output_schema, output_table, output_table_zrd, settlements_output, settlements_zrd_output){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                         host = host, port = port,
                         user = user, password = pwd) 
    
    query <- paste("DROP TABLE IF EXISTS ", output_schema, ".", output_table)
    dbGetQuery(con,query)
    
    query <- paste("DROP TABLE IF EXISTS ", output_schema, ".", output_table_zrd)
    dbGetQuery(con,query)
    
    dbWriteTable(con, c(output_schema,output_table), value = data.frame(settlements_output), row.names = F, append = T)
    dbWriteTable(con, c(output_schema,output_table_zrd), value = data.frame(settlements_zrd_output), row.names = F, append = T)
    
    
    dbDisconnect(con)
}