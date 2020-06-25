indirectNormalizedZRD <- function(schema_dev, table_settlements, indirect_polygons_table){
  drv <- dbDriver("PostgreSQL")
  con  <-  dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
  
  #We create a table according to the geographic location of each settlement and the coverage area for each technology calculated from the infrastructure   information.
  
  query <- paste0('SELECT s.centroid, 
                   ST_Contains(i.geom_2g,s.geom::geometry) AS tech_2g_indirect,
                   ST_Contains(i.geom_3g,s.geom::geometry) AS tech_3g_indirect,
                   ST_Contains(i.geom_4g,s.geom::geometry) AS tech_4g_indirect
              FROM ',schema_dev,'.',table_settlements,' s, ',schema_dev,'.',indirect_polygons_table,' i')
  
  indirect_normalized_df <- dbGetQuery(con,query)
  dbDisconnect(con)
  indirect_normalized_df
}