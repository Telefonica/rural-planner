      
updateDBGoogle <- function(schema, table_google, latitude, longitude, id){     
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
      
      query <- paste("UPDATE ", schema, ".", table_google, " SET latitude_google = ", latitude ," , longitude_google = ", longitude," , source = 'OSM API' WHERE settlement_id = '",id,"'", sep = "")
      dbGetQuery(con,query)
      dbDisconnect(con)
      
}