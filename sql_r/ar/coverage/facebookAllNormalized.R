facebookAllNormalized <- function(schema, table_settlements, schema_prod, facebook_competitors_polygons_2g, facebook_competitors_polygons_3g, facebook_competitors_polygons_4g){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
                     
    query <- paste0('SELECT DISTINCT s.settlement_id,
                   ST_Contains(f2.geom,s.geom::geometry) AS competitors_2g_app,
                   ST_Contains(f3.geom,s.geom::geometry) AS competitors_3g_app,
                   ST_Contains(f4.geom,s.geom::geometry) AS competitors_4g_app
              FROM ',schema,'.',table_settlements,' s, ',schema_prod,'.',facebook_competitors_polygons_2g,' f2,',schema_prod,'.', facebook_competitors_polygons_3g, ' f3,', schema_prod,'.', facebook_competitors_polygons_4g, ' f4')
    
    facebook_all_normalized_df <- dbGetQuery(con,query)
    
    dbDisconnect(con)
    facebook_all_normalized_df
    
}