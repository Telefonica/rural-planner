assignClosestSettlement <- function(schema, table_households, table_settlements, id, idMun){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                    host = host, port = port,
                     user = user, password = pwd)

    query <-paste("UPDATE ", schema, ".", table_households, " A 
                    SET closest_settlement = B.settlement_id 
                    FROM ( SELECT DISTINCT ON (T.household_id)
                            C.settlement_id,
                            T.household_id,
                            ST_Distance(C.geom, T.geom) AS distance
                            FROM ", schema, ".", table_settlements, " C 
                            LEFT JOIN ", schema, ".", table_households, " T ON C.admin_division_1_id = T.admin_division_1_id
                            WHERE T.admin_division_1_id = '",idMun,"'
                            AND T.inside_polygon is null
                            ORDER BY T.household_id, distance) B
                    WHERE A.household_id = B.household_id
                    AND B.distance<3000",sep="")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}