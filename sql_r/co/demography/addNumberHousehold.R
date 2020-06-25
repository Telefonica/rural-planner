addNumberHousehold <- function(schema, table_settlements, table_households){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                    host = host, port = port,
                     user = user, password = pwd) 
    
    ## ADD columns: population_cabecera and households_cabecera, population_resto and households_resto
    
    query <- paste("ALTER TABLE ",schema, ".", table_settlements," ADD COLUMN households numeric", sep="")
    dbGetQuery(con, query)
    
    
    query <- paste("UPDATE ",schema, ".", table_settlements," A SET households = c.households FROM
                   (SELECT count(*) as households,
                   closest_settlement as settlement_id 
                   FROM ",schema, ".", table_households," 
                   GROUP BY closest_settlement) c
                   WHERE c.settlement_id = A.settlement_id", sep="")
    
    dbGetQuery(con,query)
    dbDisconnect(con)

}