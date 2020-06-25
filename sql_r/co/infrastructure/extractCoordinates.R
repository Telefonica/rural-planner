# Upload input to database and join with settlements table to extract coordinates. First we try to match the name to de admin_division_1 name and get the coordinates of the capital, if that's not possible we match with a settlement with the same name. Only matches if there is only one settlement name. There are 3 cases where there is no match because there are several settlements in that admin_division_2_name with the same name

extractCoordinates <- function(schema, table_temp, ufinet_int, table_admin_div_2, table_settlements){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table_temp, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,table_temp), 
                 value = data.frame(ufinet_int), row.names = F, append= F, replace= T)
    
    query <- paste("
    SELECT  E.internal_id,
            E.admin_division_2_name,
            E.admin_division_1_name,
            CASE 
                WHEN capital IS NULL THEN settlement_name 
                ELSE capital 
            END AS settlement_name,
            CASE 
                WHEN lat_capital IS NULL THEN latitude 
                ELSE lat_capital 
            END AS latitude,
            CASE 
                WHEN  long_capital IS NULL THEN longitude 
                ELSE long_capital 
            END AS longitude   
    FROM (
            SELECT  C.*,
                    S.settlement_name AS capital, 
                    S.latitude AS lat_capital,
                    S.longitude AS long_capital, 
                    S2.latitude, 
                    S2.longitude, 
                    S2.settlement_name 
            FROM ", schema,".",table_temp, " C
            LEFT JOIN ", schema,".",table_admin_div_2, " B
            ON C.admin_division_1_id = B.admin_division_1_id
            LEFT JOIN ", schema,".",table_settlements, " S
            ON S.settlement_id = (B.admin_division_1_id || '000') 
            LEFT JOIN (SELECT 
                      A.admin_division_2_name,
                      A.settlement_name, 
                      latitude,
                      longitude,
                      settlement_id 
                      FROM(
                          SELECT  DISTINCT(admin_division_2_name,settlement_name), 
                                  admin_division_2_name, 
                                  settlement_name
                          FROM ", schema,".",table_settlements, " S
                          GROUP BY admin_division_2_name, settlement_name
                          HAVING COUNT(*) =1) A
                          LEFT JOIN ", schema,".",table_settlements, " S2
                          ON S2.settlement_name = A.settlement_name AND S2.admin_division_2_name = A.admin_division_2_name) S2
            ON S2.settlement_name = C.admin_division_1_name AND S2.admin_division_2_name = C.admin_division_2_name
    ) E", sep = "")
    
    ufinet_int <- dbGetQuery(con,query)
    
    dbDisconnect(con)
    ufinet_int
}