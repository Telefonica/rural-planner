flagFalsePoisitive <- function(schema, table_admin_division_1, admin_division_1_id){   
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                    host = host, port = port,
                     user = user, password = pwd) 
    
    
    query <- paste("ALTER TABLE ",schema, ".", table_admin_division_1," ADD COLUMN false_positive boolean", sep="")
    dbGetQuery(con, query)
    
    query <-paste0(" UPDATE ",schema,".",table_admin_division_1,
                  " SET false_positive = true WHERE admin_division_1_id IN ('",paste(admin_division_1_id,collapse="','"),"')")
    dbGetQuery(con, query)
    dbDisconnect(con)
}