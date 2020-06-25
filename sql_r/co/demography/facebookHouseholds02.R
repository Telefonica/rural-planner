facebookHouseholds02 <- function(schema, table_households_raw, table_households){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                    host = host, port = port,
                     user = user, password = pwd)

    ## Create backup table with all households in case we need to check something 
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table_households_raw, sep = "")
    dbGetQuery(con,query)
    
    query <-paste(" create table ",schema,".",table_households_raw,
                  " AS (select * from ",schema,".",table_households, ")",sep = "")
    
    dbGetQuery(con,query)
    
    ## Remove households that are not within Colombia limits
    
    query <-paste(" DELETE FROM ",schema,".",table_households,
                  " WHERE admin_division_2_id is null",sep = "")
                 
    dbGetQuery(con,query)
    
    ## Set a flag for those that are located inside an admin_division_1_id capital polygon (and set as the closest settlement the capital)
    
    query <-paste(" ALTER TABLE ",schema,".",table_households,
                  " ADD column inside_polygon bool",sep = "")
                 
    dbGetQuery(con,query)
    
    query <-paste(" ALTER TABLE ",schema,".",table_households,
                  " ADD column closest_settlement text",sep = "")
                 
    dbGetQuery(con,query)
    
    dbDisconnect(con)

}