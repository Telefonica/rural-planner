matchingSettlementsNoGrid <- function(schema_dev, table, no_grid_table, schema, table_settlements){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("CREATE TABLE ", schema_dev, ".", table, " AS (
                    (SELECT DISTINCT ON(id_localidad) *, ST_MakeLine(geom2::geometry,geom::geometry)
    	               FROM (
    		                SELECT DISTINCT ON(B.settlement_id) B.settlement_id, B.settlement_name, B.geom,
                            ST_Distance(B.geom::geography, A.geom2::geography),
    		                    A.id_localidad, A.localidad, A.geom2
    		                FROM (
    			                 SELECT DISTINCT ON(A.id_localidad) A.id_localidad, A.localidad, A.geom2,
                               B.settlement_id, B.settlement_name, B.geom
    			                 FROM ", schema_dev, ".", no_grid_table, " A
    			                 LEFT JOIN ", schema, ".", table_settlements, " B
    			                 ON ((A.id_localidad = B.settlement_id)
    				                   OR ((A.localidad = B.settlement_name) 
    				                       AND (A.id_municipio::text = B.admin_division_1_id)
    				                       AND (A.id_departamento::text = B.admin_division_2_id)))
    			                 WHERE B.settlement_id IS NULL) A --los que no coinciden
    		                   INNER JOIN (
    			                     SELECT *
    			                     FROM ", schema, ".", table_settlements, "
                                   WHERE settlement_id NOT IN (
    				                       SELECT DISTINCT ON(B.settlement_id) B.settlement_id
    				                       FROM ", schema_dev, ".", no_grid_table, " A
    				                       INNER JOIN ", schema, ".", table_settlements, " B
    				                       ON ((A.id_localidad = B.settlement_id)
    					                         OR ((A.localidad = B.settlement_name) 
    					                             AND (A.id_municipio::text = B.admin_division_1_id)
    					                             AND (A.id_departamento::text = B.admin_division_2_id))
                                   )
                               )
    				               ) B
    		                   ON ST_DWithin(B.geom::geography, A.geom2::geography, 5000)
    				
                           ORDER BY B.settlement_id, ST_Distance(B.geom::geography, A.geom2::geography)
                     ) C
                    
                    ORDER BY id_localidad, st_distance)
    
                    UNION
    
                    (SELECT DISTINCT ON(id_localidad) *, ST_MakeLine(geom2::geometry,geom::geometry)
                     FROM (
                         SELECT DISTINCT ON(B.settlement_id) B.settlement_id, B.settlement_name, B.geom,
                             ST_Distance(B.geom::geography, A.geom2::geography),
                             A.id_localidad, A.localidad, A.geom2
                         FROM ", schema_dev, ".", no_grid_table, " A
                         INNER JOIN ", schema, ".", table_settlements, " B
                         ON ((A.id_localidad = B.settlement_id)
                             OR ((A.localidad = B.settlement_name) 
                                 AND (A.id_municipio::text = B.admin_division_1_id)
                                 AND (A.id_departamento::text = B.admin_division_2_id))
                         )
                     ) D)
                    )")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}