indirectPolygonsClaro <- function(schema, indirect_polygons_table, infrastructure_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
                     
    query <- paste0("CREATE TABLE ", schema_dev, ".", indirect_polygons_table, "
     AS (SELECT (ST_Union(ST_MakeValid(coverage_area_2g))) as geom_2g,
                (ST_Union(ST_MakeValid(coverage_area_3g))) as geom_3g,
                (ST_Union(ST_MakeValid(coverage_area_4g))) as geom_4g
                FROM ",schema,".", infrastructure_table, 
                " WHERE in_service='IN SERVICE'
                AND source IN ('CLARO'))")
    dbGetQuery(con, query)

    dbDisconnect(con)
}