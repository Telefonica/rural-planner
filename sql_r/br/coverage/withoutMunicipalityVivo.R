withoutMunicipalityVivo <- function(schema, table_settlements, table_vivo){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd) 
                 
    query <- paste0("SELECT rt.settlement_id,
                      CASE WHEN c2g.internal_id IS NOT NULL THEN TRUE ELSE FALSE END AS tech_2g_regulator,
                      CASE WHEN c3g.internal_id IS NOT NULL THEN TRUE ELSE FALSE END AS tech_3g_regulator,
                      CASE WHEN c4g.internal_id IS NOT NULL THEN TRUE ELSE FALSE END AS tech_4g_regulator
                      FROM (SELECT * FROM ",schema,".",table_settlements,"
                            WHERE admin_division_2_id IS NULL) rt
                      LEFT JOIN LATERAL
                              (SELECT *
                                  FROM ",schema,".",table_vivo,"_2g as buf
                                  WHERE ST_Intersects(st_transform(rt.geom,3857), buf.coverage_area_2g)
                                  ORDER BY ST_MaxDistance(st_transform(rt.geom,3857), buf.coverage_area_2g)
                                  LIMIT 1
                          ) as c2g
                      ON TRUE
                      LEFT JOIN LATERAL
                              (SELECT *
                                  FROM ",schema,".",table_vivo,"_3g as buf
                                  WHERE ST_Intersects(st_transform(rt.geom,3857), buf.coverage_area_3g)
                                  ORDER BY ST_MaxDistance(st_transform(rt.geom,3857), buf.coverage_area_3g)
                                  LIMIT 1
                          ) as c3g
                      ON TRUE
                      LEFT JOIN LATERAL
                              (SELECT *
                                  FROM ",schema,".",table_vivo,"_4g as buf
                                  WHERE ST_Intersects(st_transform(rt.geom,3857), buf.coverage_area_4g)
                                  ORDER BY ST_MaxDistance(st_transform(rt.geom,3857), buf.coverage_area_4g)
                                  LIMIT 1
                          ) as c4g
                      ON TRUE
                      WHERE c2g.internal_id IS NOT NULL")
                      
    aux_df <- dbGetQuery(con,query)
    dbDisconnect(con)
    aux_df
}