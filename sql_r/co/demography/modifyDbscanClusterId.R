#Modify dbscan clusters' id 
modifyDbscanClusterId <- function(schema, table_settlements){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                    host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0("UPDATE ",schema, ".", table_settlements," SET settlement_id = concat, settlement_name = concat FROM
                    (SELECT 
                    settlement_id, 
                    concat(sign_latitude, entero_latitude, 'D', decimal_latitude, '-',sign_longitude, entero_longitude, 'D', decimal_longitude) 
                    FROM (
                          SELECT 
                          CASE WHEN latitude>0 THEN 'N' ELSE 'S' END AS sign_latitude,
                          CASE WHEN longitude>0 THEN 'E' ELSE 'W' END AS sign_longitude,
                          TRIM('-' FROM SPLIT_PART(latitude::text,'.',1)) AS entero_latitude,
                          SUBSTRING(SPLIT_PART(latitude::text,'.',2) FROM 1 FOR 4) AS decimal_latitude,
                          TRIM('-' FROM SPLIT_PART(longitude::text,'.',1)) AS entero_longitude,
                          SUBSTRING(SPLIT_PART(longitude::text,'.',2) FROM 1 FOR 4) AS decimal_longitude,
                          settlement_id
                          FROM ",schema, ".", table_settlements," WHERE settlement_id LIKE '%-%' AND settlement_id NOT LIKE '%ZRD'
                         ) a 
                    )b
                    WHERE ", table_settlements,".settlement_id=b.settlement_id")
     
    dbGetQuery(con,query)
    dbDisconnect(con)

}