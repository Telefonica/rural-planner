correctPopulation <- function(output_schema, output_table, output_table_zrd){
    ## Correct aggregate population from 2018 census to 45.5M
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste("SELECT SUM(population_corrected) FROM ", output_schema, ".", output_table,sep="")
    sum_settlements <- dbGetQuery(con, query)
    
    query <- paste("SELECT SUM(cluster_weight) FROM ", output_schema, ".", output_table_zrd,sep="")
    sum_zrd <- dbGetQuery(con, query)
    
    correction_factor <- 45500000/(as.numeric(sum_settlements$sum)+as.numeric(sum_zrd$sum))
    
    query <- paste("UPDATE ",output_schema, ".", output_table," SET population_corrected=population_corrected*", correction_factor ,";
                   UPDATE ",output_schema, ".", output_table_zrd," SET cluster_weight=cluster_weight*", correction_factor, sep="")
    
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}