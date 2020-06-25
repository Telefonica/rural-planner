movistarRegulatorNormalized <- function(schema_dev, table_settlements, schema, movistar_polygons_table){
    drv <- dbDriver("PostgreSQL")
    con  <-  dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    query <- paste0('SELECT s.settlement_id,
                   ST_Contains(m.geom_2g,s.geom::geometry) AS tech_2g_regulator,
                   ST_Contains(m.geom_3g,s.geom::geometry) AS tech_3g_regulator,
                   ST_Contains(m.geom_4g,s.geom::geometry) AS tech_4g_regulator
              FROM ', schema_dev,'.',table_settlements,' s, ',schema,'.',movistar_polygons_table,' m')
    
    movistar_regulator_normalized_df <- dbGetQuery(con,query)
    dbDisconnect(con)
    movistar_regulator_normalized_df
}