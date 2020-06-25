listSchools <- function(schema, table_schools){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 

    query <- paste0('SELECT school_id FROM ',schema,'.',table_schools)
    schools_list <- dbGetQuery(con,query)
    
    dbDisconnect(con)
    
    schools_list
}