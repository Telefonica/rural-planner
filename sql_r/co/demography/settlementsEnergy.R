settlementsEnergy <- function(dev_schema,output_schema, output_table, settlements_table, intermediate_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("DROP TABLE IF EXISTS ", dev_schema, ".", output_table)
    dbGetQuery(con,query)
    
    query <- paste0("CREATE TABLE ", dev_schema, ".", output_table, " AS
                     SELECT * FROM ", output_schema, ".", settlements_table)
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ", dev_schema, ".", output_table, " ADD COLUMN defficient_energy BOOLEAN")
    dbGetQuery(con,query)
    
    query <- paste0("UPDATE ", dev_schema, ".", output_table, " SET defficient_energy = FALSE")
    dbGetQuery(con,query)
    
    query <- paste0("UPDATE ", dev_schema, ".", output_table, "
                     SET defficient_energy = TRUE
                        WHERE settlement_id
                        IN ( SELECT settlement_id 
                             FROM ", dev_schema, ".", intermediate_table, ")")
    dbGetQuery(con,query)
    
    dbDisconnect(con)

}