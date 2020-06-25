uploadCensusData <- function(schema_dev, table_census_pop, table_projections, table_geo_loc, table_geo_sec, table_geo_secdis, census_pop, projections_pop, census_loc, census_sec, census_secdis){
  
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
  
  dbWriteTable(con, c(schema_dev, table_census_pop), value = data.frame(census_pop), row.names=F, append=F)
  
  dbWriteTable(con, c(schema_dev, table_projections), value = data.frame(projections_pop), row.names=F, append=F )
  
  pgInsert(conn = con, name = c(schema_dev, table_geo_loc), data.obj = census_loc)
  
  pgInsert(conn = con, name = c(schema_dev, table_geo_sec), data.obj = census_sec)
  
  pgInsert(conn = con, name = c(schema_dev, table_geo_secdis), data.obj = census_secdis)
  
  # Make some format modifications to uploaded tables
  
  query <- paste0('ALTER TABLE ', schema_dev, '.', table_census_pop, ' ADD COLUMN manzana_id VARCHAR;
                    ALTER TABLE ', schema_dev, '.', table_census_pop, ' ADD COLUMN sector_id VARCHAR;
                    ALTER TABLE ', schema_dev, '.', table_census_pop, ' ADD COLUMN parroquia_id VARCHAR;
                    ALTER TABLE ', schema_dev, '.', table_census_pop, ' ADD COLUMN canton_id VARCHAR;
                    ALTER TABLE ', schema_dev, '.', table_census_pop, ' ADD COLUMN provincia_id VARCHAR;')
  dbGetQuery(con, query)
  
  query <- paste0("UPDATE ", schema_dev, ".", table_census_pop, " SET manzana_id=CONCAT(LPAD('I01'::text,2,'0'),LPAD('I02'::text,2,'0'),LPAD('I03'::text,2,'0'),LPAD('I04'::text,3,'0'),LPAD('I05'::text,3,'0'),LPAD('I06'::text,2,'0')),sector_id=CONCAT(LPAD('I01'::text,2,'0'),LPAD('I02'::text,2,'0'),LPAD('I03'::text,2,'0'),LPAD('I04'::text,3,'0'),LPAD('I05'::text,3,'0')),parroquia_id=CONCAT(LPAD('I01'::text,2,'0'),LPAD('I02'::text,2,'0'),LPAD('I03'::text,2,'0')),canton_id=CONCAT(LPAD('I01'::text,2,'0'),LPAD('I02'::text,2,'0')), provincia_id=LPAD('I01'::text,2,'0')")
  dbGetQuery(con, query)
  
  query <- paste0("ALTER TABLE ", schema_dev, ".", table_geo_loc, " 
                ALTER COLUMN geom TYPE geometry(POINT, 4326)
                USING ST_Transform(geom,4326);")
  dbGetQuery(con, query)
  
  query <- paste0("ALTER TABLE ", schema_dev, ".", table_geo_loc, " 
                ALTER COLUMN geom TYPE geography;")
  dbGetQuery(con, query)
  
  query <- paste0("ALTER TABLE ", schema_dev, ".", table_geo_sec, " 
                ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 4326)
                USING ST_Transform(geom,4326);")
  dbGetQuery(con, query)
  
  query <- paste0("ALTER TABLE ", schema_dev, ".", table_geo_secdis, " 
                ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 4326)
                USING ST_Transform(geom,4326);")
  dbGetQuery(con, query)
  
  query <- paste0('UPDATE ', schema_dev, '.', table_census_pop, ' SET \'TOTPER\'=0 WHERE \'TOTPER\' IS NULL')
  dbGetQuery(con, query)
  
  dbDisconnect(con)
}