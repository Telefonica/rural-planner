adminDivision3 <- function(schema, table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0("SELECT DISTINCT admin_division_3_id, admin_division_3_name FROM ", schema,".",table)
    admin_division_3 <- dbGetQuery(con,query)
    
    dbDisconnect(con)
    admin_division_3
}