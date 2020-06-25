uploadGoogleData <- function(schema,table_google,settlements_basic_google){

    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query<-paste("DROP TABLE IF EXISTS ", schema, ".", table_google,sep="")
    dbGetQuery(con,query)
    
    #Run only first time to create table
    dbWriteTable(con, c(schema,table_google), value = data.frame(settlements_basic_google), row.names = F, append = F)
    
    #Get settlements without location
    query <- paste0('SELECT * FROM ',schema,'.',table_google, " WHERE latitude IS NULL")
    unlocated_settlements <- dbGetQuery(con, query)
    
    dbDisconnect(con)
    
    unlocated_settlements 

}