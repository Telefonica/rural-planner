normalizationCompetitors <- function(schema, table_settlements, competitors_polygons_table, municipality, competitor){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd) 

    query <- paste0("SELECT s.settlement_id,
                        NULL::bool AS tech_2g_regulator,
                        ST_Contains(c.geom_3g,s.geom::geometry) AS tech_3g_regulator,
                        ST_Contains(c.geom_4g,s.geom::geometry) AS tech_4g_regulator
                   FROM ",schema,".",table_settlements," s, ",schema,".",competitors_polygons_table," c
                   WHERE operator_id='", competitor,"'
                   AND admin_division_2_id='",municipality,"'")

    aux_df <- dbGetQuery(con,query)

    dbDisconnect(con)
    aux_df
}