deleteTables <- function(intermediate_schema, schools_incomplete_settlements_table, schools_by_category_indirect_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    # Drop auxiliary tables
    
    query <- paste0('TRUNCATE TABLE ',intermediate_schema,'.',schools_incomplete_settlements_table)
    
    dbGetQuery(con,query)
    
    query <- paste0('TRUNCATE TABLE ',intermediate_schema,'.',schools_by_category_indirect_table)
     
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}