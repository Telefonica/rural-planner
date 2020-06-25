claroRegulatorNormalizedZRD <- function(schema_prod, table_zrd, schema, claro_polygons_table){
    drv <- dbDriver("PostgreSQL")
    con  <-  dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    query <- paste0('SELECT s.centroid,
                    ST_Contains(c.geom_2g,s.geom_centroid::geometry) AS tech_2g_regulator,
                    ST_Contains(c.geom_3g,s.geom_centroid::geometry) AS tech_3g_regulator,
                    ST_Contains(c.geom_4g,s.geom_centroid::geometry) AS tech_4g_regulator
               FROM ',schema,'.',table_zrd,' s, ',schema_prod,'.',claro_polygons_table,' c')
    
    claro_regulator_normalized_df <- dbGetQuery(con,query)
    dbDisconnect(con)
    claro_regulator_normalized_df
}