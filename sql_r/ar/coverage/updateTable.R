updateTable <- function(schema, table, technology){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd) 
  
  table_technology <-paste0(table,"_",tolower(technology))

  query<-paste0("UPDATE ", schema ,".", table_technology ," SET geom = ST_Simplify(geom,0.001)")
  dbGetQuery(con,query)

  query<-paste0("UPDATE ", schema ,".", table_technology ," SET geom = ST_Multi(ST_Buffer(geom,0))")
  dbGetQuery(con,query)

  query<-paste0("UPDATE ", schema ,".", table_technology ," SET geom = ST_MakeValid(geom_m)")
  dbGetQuery(con,query)

  dbDisconnect(con)
} 