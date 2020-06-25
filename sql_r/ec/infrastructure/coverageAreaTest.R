coverageArea <- function(schema, table, towers_int){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)
  
  query <- paste("DROP TABLE IF EXISTS ", schema,".",table, sep = "")
  dbGetQuery(con,query)
  
  dbWriteTable(con,
               c(schema,table),
               value = data.frame(towers_int), row.names = F, append= F)
  
  # query <- paste0("ALTER TABLE ",schema,".",table,"
  #                  ALTER COLUMN latitude TYPE DOUBLE PRECISION USING latitude::DOUBLE PRECISION;
  #                  ALTER TABLE ",schema,".",table," 
  #                  ALTER COLUMN longitude TYPE DOUBLE PRECISION USING longitude::DOUBLE PRECISION;")
  # dbGetQuery(con,query)
  
  query <- paste("SELECT *,
                CASE WHEN (tech_2g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(
ST_MakePoint(longitude, latitude),4326) AS geography), coverage_radius*1000)
                ELSE NULL END AS coverage_area_2g,
                CASE WHEN (tech_3g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), coverage_radius*1000)
                ELSE NULL END AS coverage_area_3g,
                CASE WHEN (tech_4g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), coverage_radius*1000)
                ELSE NULL END AS coverage_area_4g
                FROM ", schema, ".", table, sep = "")
  
  towers_int <- dbGetQuery(con,query)
  
  query <- paste("DROP TABLE ",schema, ".", table, sep = "")
  dbGetQuery(con,query)
  dbDisconnect(con)
  towers_int
  
}