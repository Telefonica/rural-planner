uploadDBWithIndex <- function(schema,table, df, index, using){
    #Upload to database
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table)
    dbGetQuery(con,query)
    
    pgInsert(conn = con, name = c(schema,table),data.obj = df)
    
    
    #Create spatial index for each table
    query <- paste("CREATE INDEX ", index, " ON ", schema,".",table, " USING ", using, sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
    
    
}
