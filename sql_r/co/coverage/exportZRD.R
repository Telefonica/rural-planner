exportZRD <- function(schema, output_table_name, coverage){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    #Replace existing old data
    query<-paste0('TRUNCATE TABLE ',schema,'.',output_table_name)
    dbGetQuery(con,query)
    dbWriteTable(con, 
                 c(schema,output_table_name), 
                 value = data.frame(coverage), row.names = F, append= T)
    
    #Parse columns to logical (only run if creating df for 1st time)
    
    names_coverage <- names(coverage)
    
    for (i in 2:length(names_coverage)){
      query <- paste0("ALTER TABLE ",schema,".",output_table_name,
              " ALTER COLUMN ",names_coverage[i]," TYPE boolean USING ",names_coverage[i],"::boolean")
      dbGetQuery(con,query)
    }
    
    dbDisconnect(con)
}
