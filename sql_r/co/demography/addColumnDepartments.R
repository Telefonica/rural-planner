addColumnDepartments <- function(schema, table_admin_division_2){
    #Upload information to departaments table in database
    
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    
    query <- paste("ALTER TABLE ", schema,".",table_admin_division_2, " ADD COLUMN hab_house numeric", sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)

}