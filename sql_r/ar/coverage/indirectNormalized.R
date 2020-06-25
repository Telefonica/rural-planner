indirectNormalized <- function(schema, table_settlements, indirect_polygons_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
                     
    query <- paste0("SELECT DISTINCT s.settlement_id,
                   ST_Contains(i.geom_2g,s.geom::geometry) AS tech_2g_indirect,
                   ST_Contains(i.geom_3g,s.geom::geometry) AS tech_3g_indirect,
                   ST_Contains(i.geom_4g,s.geom::geometry) AS tech_4g_indirect,
                    'MOVISTAR' as operator_id
                  FROM ",schema,".",table_settlements," s,", schema,".",indirect_polygons_table ," i
                  WHERE operator='Movistar'
                UNION
                  SELECT DISTINCT s.settlement_id,
                   ST_Contains(i.geom_2g,s.geom::geometry) AS tech_2g_indirect,
                   ST_Contains(i.geom_3g,s.geom::geometry) AS tech_3g_indirect,
                   ST_Contains(i.geom_4g,s.geom::geometry) AS tech_4g_indirect,
                    'CLARO' as operator_id
                  FROM ",schema,".",table_settlements," s,", schema,".",indirect_polygons_table ," i
                  WHERE operator='Claro'
                UNION
                  SELECT DISTINCT s.settlement_id,
                   ST_Contains(i.geom_2g,s.geom::geometry) AS tech_2g_indirect,
                   ST_Contains(i.geom_3g,s.geom::geometry) AS tech_3g_indirect,
                   ST_Contains(i.geom_4g,s.geom::geometry) AS tech_4g_indirect,
                    'PERSONAL' as operator_id
                  FROM ",schema,".",table_settlements," s,", schema,".",indirect_polygons_table ," i
                  WHERE operator='Personal'
              ")
    
    indirect_normalized_df <- dbGetQuery(con,query)
    
    dbDisconnect(con)
    indirect_normalized_df
    
}