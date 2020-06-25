createIntermediateTables <- function(schema_dev, table_census_pop, table_households_pop, table_geo_sec, table_geo_loc, table_geo_secdis){
  
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
  
    query <- paste0("CREATE TABLE ", schema_dev, ".", table_census_pop, "_sec as (SELECT canton_id, parroquia_id, sector_id, SUM('TOTPER') as population, count(*) as households FROM ", schema_dev, ".", table_census_pop, "
  GROUP BY canton_id, parroquia_id, sector_id);")
    
    
    query <- paste0("CREATE TABLE ", schema_dev, ".", table_census_pop, "_man as (SELECT canton_id, parroquia_id, sector_id, manzana_id, SUM('TOTPER') as population, count(*) as households FROM ", schema_dev, ".", table_census_pop, "
  GROUP BY canton_id, parroquia_id, sector_id, manzana_id);")
    
    
    query <- paste0("CREATE TABLE ", schema_dev, ".", table_households_pop, " AS
  (SELECT canton_id, parroquia_id, sector_id,  
  RPAD(sector_id, 14, '0') as manzana_id, population, 'URBAN' as type,
  ST_Union(geom) as geom_area, ST_Centroid(ST_Union(geom)) as geom
  FROM ", schema_dev, ".", table_census_pop, "_sec a
  LEFT JOIN ", schema_dev, ".", table_geo_sec, " b
  on a.sector_id=b.dpa_sector
  where b.dpa_sector IS NOT NULL
  GROUP BY canton_id, parroquia_id, sector_id, population 
  UNION ALL
  SELECT canton_id, parroquia_id, sector_id, manzana_id, population, 
  'RURAL' as type,
  ST_Union(c.geom) as geom_area, b.geom as geom
  FROM ", schema_dev, ".", table_census_pop, "_man a
  LEFT JOIN ", schema_dev, ".", table_geo_loc, " b
  on a.manzana_id=b.dpa_locali
  LEFT JOIN ", schema_dev, ".", table_geo_secdis, " c
  on a.sector_id=c.dpa_secdis
  where dpa_locali IS NOT NULL
  GROUP BY canton_id, parroquia_id, sector_id, manzana_id, population, b.geom)")
    dbGetQuery(con,query)
    
  dbDisconnect(con)
}