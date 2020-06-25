exportDBFacebook <- function(table_names,schema, df_tables){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    for(i in (1:length(table_names))){
      dbWriteTable(con, 
                 c(schema,table_names[i]), 
                 value = data.frame(df_tables[[i]]), row.names = F, append= F, replace = T)
    }
    
    for(i in (1:length(table_names))){
      
      query <- paste("ALTER TABLE ", schema,".",table_names[i], " ALTER COLUMN geom TYPE GEOMETRY
                      USING geom::GEOMETRY", sep = "")
      dbGetQuery(con,query)
      
    }
    
    dbDisconnect(con)


}