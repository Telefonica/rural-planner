setHabHouse <- function(schema, table_admin_division_2,hab_house_departament) {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
  
  apply(hab_house_departament, 1,function(x){
    query <- paste("UPDATE ", schema,".",table_admin_division_2, " SET hab_house = ",x[2]," WHERE admin_division_2_id = '",x[1], "'",sep = "")
    dbSendQuery(con,query)
  })

  
  dbDisconnect(con)
}