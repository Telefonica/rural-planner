completeSettlements <- function(schema, table_settlements, table_households, table_admin_division_1, table_admin_division_2){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                    host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste("UPDATE ", schema, ".", table_settlements, " SET population_corrected = c.population_corrected,
                   households = c.households
                   FROM (SELECT s.settlement_id,
                   count(h.*) as households,
                   CASE WHEN RIGHT(s.settlement_id,3)='000' THEN population_census
                   ELSE s.households*m.norm_factor*d.hab_house END as population_corrected
                   FROM  ",schema, ".", table_settlements," s 
                   LEFT JOIN ",schema, ".", table_households," h
                   ON s.settlement_id=h.closest_settlement
                   LEFT JOIN ",schema, ".", table_admin_division_1," m
                   ON h.admin_division_1_id=m.admin_division_1_id
                   LEFT JOIN ",schema, ".", table_admin_division_2," d
                   ON h.admin_division_2_id=d.admin_division_2_id
                   GROUP BY s.settlement_id, s.population_census, m.norm_factor, d.hab_house,households) c 
                   WHERE ", table_settlements, ".settlement_id=c.settlement_id", sep = "")
    
    dbGetQuery(con,query)
    dbDisconnect(con)

}