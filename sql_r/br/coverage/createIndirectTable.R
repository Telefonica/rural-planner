createIndirectTable <- function(schema, indirect_polygons_table, infrastructure_table, vivo_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                         host = host, port = port,
                         user = user, password = pwd) 
    
    query <- paste0('DROP TABLE IF EXISTS ',schema,'.', indirect_polygons_table)
    dbGetQuery(con,query)
    

    
    query <- paste0("CREATE TABLE ",schema,".", indirect_polygons_table, 
                    " AS (SELECT source AS operator_id,
                        ST_Union(CASE WHEN v2.internal_id is NULL THEN i.coverage_area_2g ELSE NULL END) as coverage_area_2g,
                        ST_Union(CASE WHEN v3.internal_id is NULL THEN i.coverage_area_3g ELSE NULL END) as coverage_area_3g,
                        ST_Union(CASE WHEN v4.internal_id is NULL THEN i.coverage_area_4g ELSE NULL END) as coverage_area_4g
                    FROM ",schema,".", infrastructure_table," i
                    LEFT JOIN ",schema,".", vivo_table,"_2g v2
                    ON i.internal_id=v2.internal_id
                    LEFT JOIN ",schema,".", vivo_table,"_3g v3
                    ON i.internal_id=v3.internal_id
                    LEFT JOIN ",schema,".", vivo_table,"_4g v4
                    ON i.internal_id=v4.internal_id
                    GROUP BY source)")
    dbGetQuery(con,query)
    dbDisconnect(con)

}