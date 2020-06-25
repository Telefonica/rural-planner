facebookNormalized <- function(schema_dev, schema, table_settlements, facebook_polygons_tf_table_2g, facebook_polygons_tf_table_3g, facebook_polygons_tf_table_4g){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0('SELECT s.settlement_id,
                   ST_Contains(f2.geom,s.geom::geometry) AS tech_2g_app,
                   ST_Contains(f3.geom,s.geom::geometry) AS tech_3g_app,
                   ST_Contains(f4.geom,s.geom::geometry) AS tech_4g_app
              FROM ',schema_dev,'.',table_settlements,' s, ',schema ,'.',facebook_polygons_tf_table_2g,' f2, ',schema,'.',facebook_polygons_tf_table_3g,' f3,',schema,'.',facebook_polygons_tf_table_4g,' f4')
    
    facebook_normalized_df <- dbGetQuery(con,query)
    dbDisconnect(con)
    facebook_normalized_df

}