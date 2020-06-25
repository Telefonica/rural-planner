deleteUnassignedHouseholds <- function(schema, table_households, admin_division_1_id){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                    host = host, port = port,
                     user = user, password = pwd) 
    
    query <-paste0("DELETE FROM ",schema,".",table_households,
                  " WHERE cluster is null and closest_settlement is null and 
                  admin_division_1_id IN ('",paste(admin_division_1_id,collapse="','"),"')")
    dbGetQuery(con, query)
    dbDisconnect(con)
}