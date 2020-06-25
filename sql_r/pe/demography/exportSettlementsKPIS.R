exportSettlementsKPIS <- function(schema, table_kpis, settlements_kpis){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0("DROP TABLE ", schema,".",table_kpis, " CASCADE")
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,table_kpis), 
                 value = data.frame(settlements_kpis), row.names = F, append= T)
    
    dbDisconnect(con)
}