uploadDBAtoll <- function(table, schema, temp_table, table_clusters, table_towers){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)

    query<-paste0("CREATE TABLE ", schema,".",table," AS (
                    SELECT a.centroid, a.internal_id, a.source, c.geom, ST_Intersection(a.geom,ST_Buffer(c.geom::geography,coverage_radius)) as coverage_area
                        FROM (SELECT centroid, internal_id, source,
                        ST_Union(geom) AS geom FROM ", schema,".",temp_table,"
                                    GROUP BY centroid, internal_id, source) a
                        LEFT JOIN (SELECT centroid, c.geom,
                        CASE WHEN tower_height  IS NULL THEN 9000
                        	WHEN tower_height <45 THEN 4500
                        	WHEN tower_height>90 THEN 9000
                        	ELSE tower_height*100 END AS coverage_radius
                        	FROM ", schema,".",table_clusters," c
                        left join ", schema,".",table_towers," i
                        ON c.centroid=i.tower_id::text ) c
                        ON a.centroid=c.centroid)")
    dbGetQuery(con,query)
    
    query<-paste0("DROP TABLE ", schema ,".", temp_table)
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}