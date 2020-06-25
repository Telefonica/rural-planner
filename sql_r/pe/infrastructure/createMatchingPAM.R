createMatchingPAM <- function(schema_dev, intermediate_table, table_dev){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("DROP TABLE IF EXISTS ", schema_dev,".",intermediate_table)
    dbGetQuery(con,query)
    
    query <- paste0("CREATE TABLE ", schema_dev, ".", intermediate_table, "
                     AS TABLE ", schema_dev, ".", table_dev)
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ", schema_dev, ".", intermediate_table, "
                     ADD COLUMN match_tag BOOLEAN")
    dbGetQuery(con,query)
    
    query <- paste0("UPDATE ", schema_dev, ".", intermediate_table, "
                     SET match_tag = FALSE")
    dbGetQuery(con,query)
    
    query <- paste0("UPDATE ", schema_dev, ".", intermediate_table, "
                     SET match_tag = TRUE
                        WHERE ipt_tower
                        IN ( SELECT DISTINCT ON(A.ipt_tower) A.ipt_tower
                             FROM ", schema_dev, ".", intermediate_table, " A
                             INNER JOIN ", schema_dev, ".", infrastructure_table, " B 
                             ON A.ipt_tower = B.tower_name
                             WHERE A.match_tag IS FALSE
                             ORDER BY A.ipt_tower, ST_Distance(A.geom, B.geom))")
    dbGetQuery(con,query)
    
    query <- paste0("UPDATE ", schema_dev, ".", intermediate_table, "
                     SET match_tag = TRUE
                        WHERE ipt_tower
                        IN ( SELECT DISTINCT ON(A.ipt_tower) A.ipt_tower
                             FROM ", schema_dev, ".", intermediate_table, " A
                             INNER JOIN ", schema_dev, ".", infrastructure_table, " B 
                             ON ST_DWithin(A.geom, B.geom, 50)
                             WHERE A.match_tag IS FALSE
                             ORDER BY A.ipt_tower, ST_Distance(A.geom, B.geom))")
    dbGetQuery(con,query)
    
    query <- paste0("UPDATE ", schema_dev, ".", intermediate_table, "
                     SET match_tag = TRUE
                        WHERE ipt_tower
                        IN ( SELECT DISTINCT ON(A.ipt_tower) A.ipt_tower
                             FROM ", schema_dev, ".", intermediate_table, " A
                             INNER JOIN ", schema_dev, ".", infrastructure_table, " B 
                             ON A.ipt_tower LIKE CONCAT('%', B.tower_name, '%')
                             WHERE A.match_tag IS FALSE
                             ORDER BY A.ipt_tower, ST_Distance(A.geom, B.geom))")
    dbGetQuery(con,query)
    
    # All of the pam_sites matching (match_tag = TRUE). 
    # Take into account that ipt_towers can provide access/transport to more than one tower (tower_name match with ipt_tower is not unique) so we have less sites to proyect to infrastructure_global table
    
    
    query <- paste0("DROP TABLE IF EXISTS ", schema_dev,".",infra_match_table)
    dbGetQuery(con,query)
    
    query <- paste0("CREATE TABLE ", schema_dev, ".", infra_match_table, " 
                     AS ( SELECT DISTINCT ON(B.ipt_tower) A.*,
                          CASE WHEN ((A.location_detail) IS NOT NULL) 
                               THEN CONCAT('ENTEL_INTEREST_', A.location_detail) 
                          ELSE 'ENTEL_INTEREST' END AS new_location_detail 
                          FROM ", schema_dev, ".", infrastructure_table, " A
                          LEFT JOIN ", schema_dev, ".", intermediate_table, " B
                          ON B.ipt_tower = A.tower_name
                             OR ST_DWithin(A.geom, B.geom, 50)
                             OR B.ipt_tower LIKE CONCAT('%', B.tower_name, '%')
                          WHERE B.match_tag IS TRUE
                          ORDER BY B.ipt_tower, ST_Distance(A.geom::geography, B.geom::geography))")
    dbGetQuery(con,query)
    
    
    dbDisconnect(con)
}