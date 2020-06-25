fbCompetitorsZRD <- function(schema_dev, schema, table_zrd, facebook_competitors_polygons_2g, facebook_competitors_polygons_3g, facebook_competitors_polygons_4g){
    drv <- dbDriver("PostgreSQL")
    con  <-  dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    query <- paste0('SELECT s.centroid,
                   ST_Contains(f2.geom,s.geom_centroid::geometry) AS competitors_2g_app,
                   ST_Contains(f3.geom,s.geom_centroid::geometry) AS competitors_3g_app,
                   ST_Contains(f4.geom,s.geom_centroid::geometry) AS competitors_4g_app
              FROM ',schema,'.',table_zrd,' s, ',schema_prod,'.',facebook_competitors_polygons_2g,' f2, ',schema_prod,'.',facebook_competitors_polygons_3g,' f3, ',schema_prod,'.',facebook_competitors_polygons_4g,' f4')
    
    facebook_competitors_normalized_df <- dbGetQuery(con,query)
    dbDisconnect(con)
    facebook_competitors_normalized_df
}