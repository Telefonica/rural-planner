createNormalizedCluster <- function(schema, table_settlements, table_households, table_admin_division_1, table_admin_division_2){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                    host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste("INSERT INTO ",schema, ".", table_settlements," 
                   (settlement_id, settlement_name,admin_division_1_id,admin_division_1_name,
                    admin_division_2_id,admin_division_2_name, population_census, population_corrected,
                    latitude,longitude,source,geom,households)
                   SELECT CONCAT(h.admin_division_1_id,'-',cluster) as settlement_id,
                   CONCAT(h.admin_division_1_id,'-',cluster) as settlement_name,
                   h.admin_division_1_id,
                   m.admin_division_1_name,
                   h.admin_division_2_id,
                   m.admin_division_2_name,
                   NULL as population_census,
                   COUNT(h.*)*m.norm_factor*d.hab_house as population_corrected,
                   ST_X(ST_Transform(ST_Centroid(ST_Collect(h.geom::geometry)),4626)) as latitude,
                   ST_Y(ST_Transform( ST_Centroid(ST_Collect(h.geom::geometry)),4626)) as longitude, 
                   'DBSCAN' as source,
                   ST_Centroid(ST_Collect(h.geom::geometry)) as geom,
                   count(h.*) as households
                   FROM ",schema, ".", table_households," h 
                   LEFT JOIN ",schema, ".", table_admin_division_1," m
                   ON h.admin_division_1_id=m.admin_division_1_id
                   LEFT JOIN ",schema, ".", table_admin_division_2," d
                   ON h.admin_division_2_id=d.admin_division_2_id
                   WHERE h.cluster IS NOT NULL
                   GROUP BY h.cluster, h.admin_division_1_id,m.admin_division_1_name, 
                   h.admin_division_2_id, m.admin_division_2_name,m.norm_factor, d.hab_house", sep="")
    
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}