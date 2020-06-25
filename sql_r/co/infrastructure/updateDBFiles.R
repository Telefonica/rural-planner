updateDBFiles <- function(schema, temp_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
    
    query<-paste0("UPDATE ", schema ,".", temp_table ," SET geom = ST_Simplify(geom,0.001)")
    dbGetQuery(con,query)
    
    query<-paste0("UPDATE ", schema ,".", temp_table ," SET geom = ST_Multi(ST_Buffer(geom,0))")
    dbGetQuery(con,query)
    
    query<-paste0("UPDATE ", schema ,".", temp_table ," SET geom = ST_CollectionExtract(ST_MakeValid(geom),3)")
    dbGetQuery(con,query)
    
    query <- paste0("SELECT * FROM ", schema, ".", temp_table)
    intermediate_output <- dbGetQuery(con, query)
    
    dbDisconnect(con)
    intermediate_output
}