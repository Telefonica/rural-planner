fillMissingValues <- function(schema, temp_Table_census, tempPopCensus, table_settlements, admin_div_3_aux, settlements_basic){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                        host = host, port = port,
                         user = user, password = pwd)
    dbWriteTable(con, c(schema,temp_Table_census), value = data.frame(tempPopCensus), row.names = F, append = T)
    
    query <- paste0("UPDATE ",schema, ".", table_settlements," A SET population_census = B.population_census
                    FROM 
                    (SELECT * FROM ",schema, ".", temp_Table_census," ) B
                    WHERE A.settlement_id = B.settlement_id")
    dbGetQuery(con,query)
    
    query<-paste0("DROP TABLE ", schema, ".", temp_Table_census)
    dbGetQuery(con,query)
    
    # Fill in admin_division_3
    query <- paste0('SELECT * FROM ',schema,'.',table_settlements)
    settlements_basic <- dbGetQuery(con, query)
    
    settlements_basic$admin_division_3_name <- toupper(admin_div_3_aux$admin_division_3_name[match(settlements_basic$admin_division_2_id,tolower(admin_div_3_aux$admin_division_2_id))])
    
    settlements_basic$admin_division_3_id <- toupper(admin_div_3_aux$admin_division_3_name[match(settlements_basic$admin_division_2_id,tolower(admin_div_3_aux$admin_division_2_id))])
    
    query <- paste("TRUNCATE TABLE ", schema, ".", table_settlements)
    dbGetQuery(con,query)
    
    dbWriteTable(con, c(schema,table_settlements), value = data.frame(settlements_basic), row.names = F, append = T)
    
    dbDisconnect(con)
}