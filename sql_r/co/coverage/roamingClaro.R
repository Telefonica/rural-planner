roamingClaro <- function(schema, table_settlements, indirect_roaming_polygons_table){
    drv <- dbDriver("PostgreSQL")
    con  <-  dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    query <- paste0('SELECT s.settlement_id,
               ST_Contains(m.geom_2g,s.geom::geometry) AS claro_roaming_2g,
               ST_Contains(m.geom_3g,s.geom::geometry) AS claro_roaming_3g,
               ST_Contains(m.geom_4g,s.geom::geometry) AS claro_roaming_4g
          FROM ',schema,'.',table_settlements,' s, ',schema,'.',indirect_roaming_polygons_table,' m
          WHERE m.operator = \'CLARO\'')
    
    claro_roaming <- dbGetQuery(con,query)
    dbDisconnect(con)
    claro_roaming
}