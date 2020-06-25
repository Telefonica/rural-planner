exportKaBeams <- function(schema_dev, table, schema){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    #We convert all the information from signal power to (-1, -2, -3, -4, -5) in the 'description' field
    query <- paste("
    UPDATE ", schema_dev,".", table,
    " SET \"Name\" = CASE WHEN \"Name\" = '-1' THEN '-1'
                          WHEN \"Name\" = '-2' THEN '-2'
                          WHEN \"Name\" = '-3' THEN '-3'
                          WHEN \"Name\" = '-4' THEN '-4'
                          WHEN \"Name\" = '-5' THEN '-5' 
                          WHEN description = '65' THEN '-1' 
                          WHEN description = '64' THEN '-2'
                          WHEN description = '63' THEN '-3' 
                          WHEN description = '62' THEN '-4'
                          WHEN description = '61' THEN '-5' 
                          END"
                   , sep = "")
    dbGetQuery(con, query)
    
    #Create the final normalized table
    query <- paste("
    CREATE TABLE ", schema,".", table,
    " AS 
    SELECT  \"Name\" AS signal_strength,
    geom
    FROM ", schema_dev, ".", table,
     sep = "")
    dbGetQuery(con, query)
    dbDisconnect(con)

}