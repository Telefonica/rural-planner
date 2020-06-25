createAtollPolygonsTable <- function(schema, atoll_polygons_table, table_atoll_2g, table_atoll_3g, table_atoll_4g){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)
    # Clean previous data
    query <- paste0('DROP TABLE IF EXISTS ',schema,'.', atoll_polygons_table)
    dbGetQuery(con,query)
    
    # Atoll Coverage
    query <- paste0("CREATE TABLE ",schema,".", atoll_polygons_table, " AS (
    SELECT a.geom as geom_2g, b.geom as geom_3g, c.geom as geom_4g
    FROM ",schema,".", table_atoll_2g," a,", schema,".", table_atoll_3g," b,", schema,".", table_atoll_4g," c)")
    dbGetQuery(con, query)
    
    dbDisconnect(con)

}