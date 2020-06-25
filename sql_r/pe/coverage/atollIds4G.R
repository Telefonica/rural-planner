atollIds4G <- function(schema, infrastructure_table, atoll_coverage_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
                     
    query <- paste0("SELECT tower_id FROM (SELECT * FROM ",schema,".", infrastructure_table, 
                " where (source='MACROS' OR source='IPT') AND tech_4g is true ) i
              INNER JOIN ",schema,".", atoll_coverage_table, 
                " c 
              on  ST_Within(i.geom::geometry,c.geom_4g)")
    aux <- dbGetQuery(con, query)

    dbDisconnect(con)
    aux

}