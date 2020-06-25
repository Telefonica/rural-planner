falsePositive <- function(schema, table_households, false_positive_households){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    ## Remove false positives, takes a long time (1/2 hour aprox)
    query <-paste0(" DELETE FROM ",schema,".",table_households,
                  " WHERE household_id IN (", paste(false_positive_households,collapse=","),")")
    
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}