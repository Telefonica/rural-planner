regulatorNormalized <- function(schema, table_settlements, table_atoll){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
                     
    query <- paste0("SELECT DISTINCT s.settlement_id,
                   ST_Contains(a.geom_2g,s.geom::geometry) AS tech_2g_regulator,
                   ST_Contains(a.geom_3g,s.geom::geometry) AS tech_3g_regulator,
                   ST_Contains(a.geom_4g,s.geom::geometry) AS tech_4g_regulator,
                    'MOVISTAR' as operator_id
                  FROM ",schema,".",table_settlements," s,", schema,".",table_atoll ," a
              ")
    
    regulator_normalized_df <- dbGetQuery(con,query)
    
    dbDisconnect(con)
    regulator_normalized_df
    
}