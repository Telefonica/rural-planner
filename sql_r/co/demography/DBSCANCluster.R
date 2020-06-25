DBSCANCluster <- function(schema, table_households){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                    host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste("ALTER TABLE ",schema, ".", table_households," ADD COLUMN cluster numeric", sep="")
    dbGetQuery(con, query)
    
    query <-paste(" UPDATE ", schema, ".", table_households, " 
                    SET cluster= cid
                       FROM (
                        SELECT household_id, admin_division_1_id, 
                        ST_ClusterDBSCAN(ST_Transform(geom::geometry,26986), eps:= 200, minpoints := 15) OVER () as cid
                        FROM ", schema, ".", table_households, "
                        WHERE ", table_households, ".closest_settlement IS NULL
                      )A
                    WHERE A.household_id=", table_households, ".household_id
                     ", sep= "")
    
    
    dbGetQuery(con,query)
    dbDisconnect(con)
}