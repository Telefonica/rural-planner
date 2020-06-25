insertIndirectPolygons <- function(schema, indirect_polygons_table, infrastructure_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
                     
    query <- paste0("INSERT INTO ",schema,".", indirect_polygons_table, "
                    (SELECT source as operator, (ST_Union(ST_MakeValid(coverage_area_2g))) as geom_2g,
                     (ST_Union(ST_MakeValid(coverage_area_3g))) as geom_3g, (ST_Union(ST_MakeValid(coverage_area_4g))) as geom_4g
                    FROM (SELECT coverage_area_2g, coverage_area_3g, coverage_area_4g,
                                  CASE WHEN source IN ('CLARO','PERSONAL') THEN 'IN SERVICE' else in_service END AS in_service,
                                  CASE WHEN source='CLARO' THEN 'Claro'
                                       WHEN source='PERSONAL' THEN 'Personal'
                                       WHEN source IN ('TASA','TASA_FIXED') THEN 'Movistar' else source END AS source
                        FROM ",schema,".", infrastructure_table, " ) i
                    WHERE in_service IN ('IN SERVICE', 'AVAILABLE') AND source IN ('Claro', 'Personal', 'Movistar')
                    GROUP BY source)")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
    
}