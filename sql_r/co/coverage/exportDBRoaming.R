exportDBRoaming <- function(schema, output_roaming_table_name, coverage_roaming){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    #Replace existing old data
    
    query<-paste0('TRUNCATE TABLE ',schema,'.',output_roaming_table_name)
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,output_roaming_table_name), 
                 value = data.frame(coverage_roaming), row.names = F, append= T)
    
    dbDisconnect(con)
}