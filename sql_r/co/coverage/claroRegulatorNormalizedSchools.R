claroRegulatorNormalizedSchools <- function(schema_prod, table_schools, schema, claro_polygons_table){
    drv <- dbDriver("PostgreSQL")
    con  <-  dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    query <- paste0('SELECT s.school_id,
                    ST_Contains(c.geom_2g,s.geom::geometry) AS tech_2g_regulator,
                    ST_Contains(c.geom_3g,s.geom::geometry) AS tech_3g_regulator,
                    ST_Contains(c.geom_4g,s.geom::geometry) AS tech_4g_regulator
               FROM ',schema,'.',table_schools,' s, ',schema_prod,'.',claro_polygons_table,' c')
    
    claro_regulator_normalized_df <- dbGetQuery(con,query)
    dbDisconnect(con)
    claro_regulator_normalized_df
}