exportPartners <- function(schema, table_prod, table_settlements, table_tmp){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0("DROP TABLE IF EXISTS ", schema,".",table_prod)
    dbGetQuery(con,query)
    
    query <- paste0("CREATE TABLE ", schema,".",table_prod, " AS (
                    SELECT  
                    A.settlement_id,
                    A.admin_division_2_id,
                    A.admin_division_1_id,
                    A.settlement_name,
                    A.latitude,
                    A.longitude,
                    B.partners,
                    B.aliado,
                    B.presencia_clarin,
                    A.geom
                    FROM  ", schema,".",table_settlements, " A
                    LEFT JOIN 
                    (SELECT 
                    settlement_id,
                    string_agg(partners,' ; ') as partners,
                    aliado,
                    bool_or(presencia_clarin) as presencia_clarin
                    FROM ", schema,".",table_tmp, " 
                    GROUP BY settlement_id,admin_division_2_id,
                    admin_division_1_id,
                    settlement_name,
                    latitude,
                    longitude,
                    aliado,
                    geom)B
                    ON B.settlement_id = A.settlement_id)")
    dbGetQuery(con,query)
    
    query <- paste0("DROP TABLE IF EXISTS ", schema,".",table_tmp)
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}