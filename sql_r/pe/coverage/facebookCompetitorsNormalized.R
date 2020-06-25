facebookCompetitors <- function(schema_2, table_settlements, schema_prod, facebook_competitors_polygons_2g, facebook_competitors_polygons_3g, facebook_competitors_polygons_4g){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0('SELECT s.settlement_id,
                   ST_Contains(f2.geom,s.geom::geometry) AS competitors_2g_app,
                   ST_Contains(f3.geom,s.geom::geometry) AS competitors_3g_app,
                   ST_Contains(f4.geom,s.geom::geometry) AS competitors_4g_app
              FROM ',schema_2,'.',table_settlements,' s, ',schema_prod,'.',facebook_competitors_polygons_2g,' f2, ',schema_prod,'.',facebook_competitors_polygons_3g,' f3, ',schema_prod,'.',facebook_competitors_polygons_4g,' f4')
    
    aux <- dbGetQuery(con,query)
    
    dbDisconnect(con)
    aux
}