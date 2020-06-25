indirectPolygons <- function(schema_dev, indirect_polygons_table, infrastructure_table){
    drv <- dbDriver("PostgreSQL")
    con  <-  dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    query <- paste0("CREATE TABLE ", schema_dev, ".", indirect_polygons_table, "
     AS (SELECT (ST_Union(ST_MakeValid(CASE WHEN tech_2g IS TRUE THEN coverage_area_2g ELSE NULL END))) as geom_2g,
                (ST_Union(ST_MakeValid(CASE WHEN tech_3g IS TRUE THEN coverage_area_3g ELSE NULL END))) as geom_3g,
                (ST_Union(ST_MakeValid(CASE WHEN tech_4g IS TRUE THEN coverage_area_4g ELSE NULL END))) as geom_4g
                 FROM ",schema_dev,".", infrastructure_table, 
                " WHERE source NOT IN ('CLARO'))")
    dbGetQuery(con, query)
    dbDisconnect(con)
  }