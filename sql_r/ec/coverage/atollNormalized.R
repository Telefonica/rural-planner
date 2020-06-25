atollNormalized <- function(schema_dev, table_settlements, atoll_polygons_table){
  drv <- dbDriver("PostgreSQL")
  con  <-  dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
  
  
  #We create a table according to the geographic location of each settlement and the coverage area for each technology calculated from the atoll information.
  query <- paste0('SELECT s.settlement_id, 
               ST_Contains(i.geom_2g,s.geom::geometry) AS tech_2g_app,
               ST_Contains(i.geom_3g,s.geom::geometry) AS tech_3g_app,
               ST_Contains(i.geom_4g,s.geom::geometry) AS tech_4g_app
          FROM ',schema_dev,'.',table_settlements,' s, ',schema_dev,'.',atoll_polygons_table,' i')
  
  atoll_normalized_df <- dbGetQuery(con,query)
  dbDisconnect(con)
  atoll_normalized_df
}