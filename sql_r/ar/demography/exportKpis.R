exportKpis <- function(schema, output_table, etapa){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0("DROP TABLE IF EXISTS ", schema,".",output_table)
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,output_table), 
                 value = data.frame(etapa), row.names = F, append= F, replace= T)
    
    
    dbDisconnect(con)
}