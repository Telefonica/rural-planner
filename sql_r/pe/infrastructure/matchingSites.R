matchingSites <- function(schema_dev, sites_ka_matching_table, infra_table, table_dev){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("
        
        CREATE TABLE ", schema_dev,".",sites_ka_matching_table, "
        AS (
              SELECT DISTINCT ON(X.tower_id) *,
                CASE WHEN ((X.migration_flag) IS NOT NULL) THEN CONCAT('KA_MIGRATION_', X.migration_flag) 
                ELSE NULL END AS migration_tag
              FROM (
                    ( SELECT DISTINCT ON(A.tower_id) A.*, B.tower_name AS tower_name2, B.latitude AS latitude2,
                        B.longitude AS longitude2,
                        B.internal_id AS internal_id2, B.location_detail AS location_detail2, B.band,
                        B.migration_flag AS migration_flag, B.ipt_perimeter AS ipt_perimeter2, B.geom AS geom2,
                        st_distance(A.geom::geography, B.geom::geography),
                        st_makeline(A.geom::geometry, B.geom::geometry)
                      FROM ( SELECT *
                             FROM ", schema_dev,".",infra_table, " I
                             WHERE I.internal_id IS NOT NULL
                             AND I.source IN ('MACROS', 'OIMR', 'IPT', 'FIBER_PLANNED', 'FEMTOS')
                            ) A
                      INNER JOIN ", schema_dev,".",table_dev, " B
                      ON A.internal_id = B.internal_id
                    )
        
               UNION
        
                    ( SELECT DISTINCT ON(A.tower_id) A.*, B.tower_name AS tower_name2, B.latitude AS latitude2,
                        B.longitude AS longitude2,
                        B.internal_id AS internal_id2, B.location_detail AS location_detail2, B.band,
                        B.migration_flag AS migration_flag, B.ipt_perimeter AS ipt_perimeter2, B.geom AS geom2,
                        st_distance(A.geom::geography, B.geom::geography),
                        st_makeline(A.geom::geometry, B.geom::geometry)
                      FROM ( SELECT *
                             FROM ", schema_dev,".",infra_table, " I
                             WHERE I.source IN ('MACROS', 'OIMR', 'IPT', 'FIBER_PLANNED', 'FEMTOS')
                           ) A
                      INNER JOIN ", schema_dev,".",table_dev, " B
                      ON A.tower_name = B.tower_name
                      WHERE (st_distance(A.geom::geography, B.geom::geography)<4000)
                    )
        
               UNION
        
                    ( SELECT DISTINCT ON(A.tower_id) A.*, B.tower_name AS tower_name2, B.latitude AS latitude2,
                        B.longitude AS longitude2,
                        B.internal_id AS internal_id2, B.location_detail AS location_detail2, B.band,
                        B.migration_flag AS migration_flag, B.ipt_perimeter AS ipt_perimeter2, B.geom AS geom2,
                        st_distance(A.geom::geography, B.geom::geography),
                        st_makeline(A.geom::geometry, B.geom::geometry)
                      FROM ( SELECT *
                             FROM ", schema_dev,".",infra_table, " I
                             WHERE I.source IN ('MACROS', 'OIMR', 'IPT', 'FIBER_PLANNED', 'FEMTOS')
                           ) A
                      INNER JOIN ", schema_dev,".",table_dev, " B
                      ON st_dwithin(A.geom::geography, B.geom::geography, 50)
                      ORDER BY A.tower_id, st_distance(A.geom::geography, B.geom::geography)
                    )
               
                ) X
                ORDER BY X.tower_id, st_distance(X.geom::geography, X.geom2::geography)
        )")
    
    dbGetQuery(con,query)
    
    dbDisconnect(con)


}