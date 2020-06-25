### Create separate tables for ZRD and settlements (small areas)

separateZRD_Settlements <- function(schema, schema_dev, table_zrd, table, table_prod){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
 
  query <- paste("DROP TABLE IF EXISTS ", schema_dev,".",table_zrd, sep = "")
  dbGetQuery(con,query) 
 
  query <- paste0("CREATE TABLE ", schema_dev, ".", table_zrd, " AS (
                      SELECT * FROM ",schema_dev, ".", table, " WHERE settlement_id IN (
                  SELECT cd_geocodi FROM ", schema, ".", table_census, " 
                      WHERE ST_Area(geom::geography)>=50000000))")
  dbGetQuery(con,query)
  
  
  query <- paste0("CREATE TABLE ", schema_dev, ".", table_prod, " AS (
                      SELECT * FROM ",schema_dev, ".", table, " WHERE settlement_id NOT IN (
                  SELECT settlement_id FROM ", schema_dev, ".", table_zrd, "))")
  dbGetQuery(con,query)
  
  
  query <- paste("DROP TABLE IF EXISTS ", schema_dev,".",table, sep = "")
  dbGetQuery(con,query)
  
  dbDisconnect(con)
}