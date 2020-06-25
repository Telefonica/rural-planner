uploadIntermediateOuputs <- function(schema, temp_table, intermediate_output){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
    
    query<-paste0("DROP TABLE ", schema ,".", temp_table)
    dbGetQuery(con,query)
    
    dbWriteTable(con, c(schema,temp_table), value=intermediate_output)
    
    query<-paste0("ALTER TABLE ", schema ,".", temp_table ," ALTER COLUMN geom TYPE GEOMETRY USING geom::geometry")
    dbGetQuery(con,query)
    
    dbDisconnect(con)

}