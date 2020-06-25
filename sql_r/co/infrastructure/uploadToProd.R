uploadToProd <- function(schema, table, Ps1){
    #Set connection data
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    pgInsert(con, c(schema,table),Ps1)
    
    #We convert all the information from signal power to (-1, -2, -3, -4, -5) in the 'gid' field
    query <- paste("
    ALTER TABLE ", schema,".", table,
    " ALTER gid TYPE varchar"
                   , sep = "")
    dbGetQuery(con, query)
    
    
    query <- paste("
    UPDATE ", schema,".", table,
    " SET gid = CASE WHEN gid = '1' THEN '-1'
                          WHEN gid = '2' THEN '-2'
                          WHEN gid = '3' THEN '-3'
                          WHEN gid = '4' THEN '-4'
                          WHEN gid = '5' THEN '-5' 
                          END"
                   , sep = "")
    dbGetQuery(con, query)
    
    #Create the final normalized table
    query <- paste("
    ALTER TABLE ", schema,".", table,
    " RENAME gid TO signal_strength"
                   , sep = "")
    dbGetQuery(con, query)
    
    dbDisconnect(con)
}