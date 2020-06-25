exportSchools <- function(schema, schools_summary_table, schools_summary){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                         host = host, port = port,
                         user = user, password = pwd) 
    
    dbWriteTable(con,c(schema,schools_summary_table), value = data.frame(schools_summary), row.names = F, append= T)
    
    #Parse columns to integer type
    
    names_schools <- names(schools_summary)
    
    for (i in 2:length(names_schools)){
      query <- paste0("ALTER TABLE ",schema,".", schools_summary_table, "
              ALTER COLUMN ",names_schools[i]," TYPE integer") 
      
    dbGetQuery(con,query)
    }
    
    dbDisconnect(con)
}