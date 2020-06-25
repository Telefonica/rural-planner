#Update table rural_planner_dev.settlements_dev 
updateSettlementsDev <- function(settlements, schema, table){

  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
  
  query <- paste0("DROP TABLE IF EXISTS ", schema,".",table)
  dbGetQuery(con,query)
  
  dbWriteTable(con, 
               c(schema,table), 
               value = data.frame(settlements), row.names = F, append= T)
  
  
  query <- paste("ALTER TABLE ", schema,".",table, " ADD COLUMN geom geography", sep = "")
  dbGetQuery(con,query)
  
  query <- paste("UPDATE ", schema, ".", table, " SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326)", sep = "")
  dbGetQuery(con,query)
  
  
  query <- paste0("CREATE INDEX settlement_id_ix ON ", schema, ".", table, " (settlement_id)")
  dbGetQuery(con,query)

  
  query <- paste0("CREATE INDEX settlement_id_gix ON ", schema, ".", table, " USING GIST(geom)")
  dbGetQuery(con,query)
  
  dbDisconnect(con)
}