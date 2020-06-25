indirectCoverageSchools <- function(schema, table_schools, indirect_polygons_table){
    drv <- dbDriver("PostgreSQL")
    con  <-  dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    query <- paste0('SELECT s.school_id,
                   ST_Contains(i.geom_2g,s.geom::geometry) AS tech_2g_indirect,
                   ST_Contains(i.geom_3g,s.geom::geometry) AS tech_3g_indirect,
                   ST_Contains(i.geom_4g,s.geom::geometry) AS tech_4g_indirect
              FROM ',schema,'.',table_schools,' s, ',schema,'.',indirect_polygons_table,' i')
    
    indirect_normalized_df <- dbGetQuery(con,query)
    dbDisconnect(con)
    indirect_normalized_df
}