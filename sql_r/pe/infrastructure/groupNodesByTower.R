groupNodesByTower <- function(schema, table, regional_int){
        drv <- dbDriver("PostgreSQL")
        con <- dbConnect(drv, dbname = dbname,
                         host = host, port = port,
                         user = user, password = pwd) 
        
        dbWriteTable(con, 
                     c(schema,table), 
                     value = data.frame(regional_int), row.names = F, append= F)
        
        query <- paste("
        SELECT
        latitude,
        longitude,
        MAX(internal_id) AS internal_id,
        MAX(owner) AS owner,
        string_agg(DISTINCT(location_detail), ' , ') AS location_detail,
        string_agg(DISTINCT(subtype), ' + ') AS subtype
        FROM ",schema, ".", table,"
                GROUP BY latitude, longitude", sep = "")
        
        regional <- dbGetQuery(con,query)
        
        query <- paste("DROP TABLE ",schema, ".", table, sep = "")
        dbGetQuery(con,query)
        dbDisconnect(con)
        
        regional
}