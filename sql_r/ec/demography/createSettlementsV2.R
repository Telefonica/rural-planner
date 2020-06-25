createSettlementsV2 <- function(schema_dev, table_settlements_v2, table_settlements, table_projections){
  
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
  
  query <- paste0('CREATE TABLE ', schema_dev, '.', table_settlements_v2,' as (
                    SELECT settlement_id,
                    settlement_name,
                    a.admin_division_1_id,
                    admin_division_1_name,
                    admin_division_2_id,
                    admin_division_2_name,
                    admin_division_3_id,
                    admin_division_3_name,
                    population_census,
                    population_corrected*norm_factor AS population_corrected,
                    latitude,
                    longitude,
                    geom
                    FROM ', schema_dev, '.', table_settlements,'  a
                    LEFT JOIN (SELECT a.admin_division_1_id, 
                                      CASE WHEN sum(a.population_corrected)=0 THEN 0 
                                      ELSE (b.pop_2019/sum(a.population_corrected)) END as norm_factor
                    FROM ', schema_dev, '.', table_settlements,' a
                    LEFT JOIN ', schema_dev, '.', table_projections, ' b
                    ON a.admin_division_1_id=b.admin_division_1_id
                    GROUP BY a.admin_division_1_id, b.admin_division_1_id, b.pop_2019) b
                    ON a.admin_division_1_id=b.admin_division_1_id
                    WHERE a.population_corrected>0)')
  dbGetQuery(con,query)
  
  dbDisconnect(con)
}