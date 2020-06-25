loadOSMAPIData <- function(schema,table_google){

    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    #Get settlements without location
    query <- paste0('SELECT * FROM ',schema,'.',table_google, " where latitude_google is null")
    unlocated_settlements <- dbGetQuery(con, query)
    
    dbDisconnect(con)
    
    unlocated_settlements 

}