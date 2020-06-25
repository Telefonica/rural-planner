createIndirectRoamingTable <- function(schema_dev, indirect_roaming_polygons_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    query <- paste0("CREATE TABLE ", schema_dev, ".", indirect_roaming_polygons_table, " AS
                    SELECT owner as operator,
                            (ST_Union(ST_MakeValid(coverage_area_2g))) as geom_2g,
                            (ST_Union(ST_MakeValid(coverage_area_3g))) as geom_3g,
                            (ST_Union(ST_MakeValid(coverage_area_4g))) as geom_4g
                FROM ",schema_dev,".", infrastructure_roaming_table, 
                    " WHERE owner IN ('CLARO','TIGO')
                GROUP BY owner")
    dbGetQuery(con, query)
    
    dbDisconnect(con)
}