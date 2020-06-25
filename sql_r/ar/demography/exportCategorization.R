exportCategorization <- function(schema, output_table, categorization){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste("DROP TABLE IF EXISTS ", schema, ".", output_table)
    dbGetQuery(con,query)
    
    dbWriteTable(con,c(schema,output_table), 
                 value = data.frame(categorization), row.names = F, append= T)
    
    dbDisconnect(con)
}