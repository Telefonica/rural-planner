deleteTablesKaMigration <- function(dev_schema, intermediate_table, table_dev, table_3q_dev){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("DROP TABLE IF EXISTS ", dev_schema, ".", intermediate_table)
    dbGetQuery(con,query)
    
    query <- paste0("DROP TABLE IF EXISTS ", dev_schema, ".", table_dev)
    dbGetQuery(con,query)
    
    query <- paste0("DROP TABLE IF EXISTS ", dev_schema, ".", table_3q_dev)
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}