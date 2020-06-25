## CREATE UNAGGREGATED ZRD TABLE
createUnaggregatedZRD <- function(schema_dev, table_zrd_unaggregated, table_households, table_admin_division_1, table_admin_division_2){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("DROP TABLE IF EXISTS ", schema_dev,".",table_zrd_unaggregated)
    dbGetQuery(con,query)
    
    query <- paste("CREATE TABLE ",schema_dev, ".", table_zrd_unaggregated," AS 
                   SELECT CONCAT(h.admin_division_1_id,'-ZRD')::TEXT as settlement_id,
                   'ZONA RURAL DISPERSA'::TEXT as settlement_name,
                   h.admin_division_1_id,
                   m.admin_division_1_name,
                   h.admin_division_2_id,
                   m.admin_division_2_name,
                   NULL::INTEGER as population_census,
                   m.norm_factor*d.hab_house as population_corrected,
                   ST_Y(h.geom::geometry) as latitude,
                   ST_X(h.geom::geometry) as longitude, 
                   h.geom as geom
                   FROM ",schema_dev, ".", table_households," h 
                   LEFT JOIN ",schema_dev, ".", table_admin_division_1," m
                   ON h.admin_division_1_id=m.admin_division_1_id
                   LEFT JOIN ",schema_dev, ".", table_admin_division_2," d
                   ON h.admin_division_2_id=d.admin_division_2_id
                   WHERE h.cluster IS NULL
                   ORDER BY h.admin_division_1_id", sep="")
    
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}