updateDBVivo <- function(schema,table,vivo){  
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)
                   
  
  query <- paste("DROP TABLE IF EXISTS ", schema,".",table, sep = "")
  dbGetQuery(con,query)
  
  dbWriteTable(con, 
               c(schema,table), 
               value = data.frame(vivo), row.names = T, append= F)
  
  query <- paste("ALTER TABLE ", schema, ".", table," RENAME \"row.names\" TO tower_id", sep = "")
  dbGetQuery(con,query)
  
  query <- paste("ALTER TABLE ", schema, ".", table," ALTER COLUMN tower_id TYPE INTEGER USING tower_id::INTEGER", sep = "")
  dbGetQuery(con,query)
  
  query <- paste("ALTER TABLE ", schema,".",table, " ALTER COLUMN coverage_area_2g TYPE GEOMETRY USING coverage_area_2g::GEOMETRY", sep = "")
  dbGetQuery(con,query)
  
  query <- paste("ALTER TABLE ", schema,".",table, " ALTER COLUMN coverage_area_3g TYPE GEOMETRY USING coverage_area_3g::GEOMETRY", sep = "")
  dbGetQuery(con,query)
  
  query <- paste("ALTER TABLE ", schema,".",table, " ALTER COLUMN coverage_area_4g TYPE GEOMETRY USING coverage_area_4g::GEOMETRY", sep = "")
  dbGetQuery(con,query)
  
  query <- paste("ALTER TABLE ", schema,".",table, " ADD COLUMN geom GEOGRAPHY ", sep = "")
  dbGetQuery(con,query)
  
  query <- paste("UPDATE ", schema,".",table, " SET geom = ST_SetSRID(ST_MakePoint(longitude::float, latitude::float), 4326)::GEOGRAPHY ", sep = "")
  dbGetQuery(con,query)
  
  dbDisconnect(con)
}