deleteDuplicates_5 <- function(schema_dev,table_tef, table_atp){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    query <- paste0("select i1.internal_id as internal_id_tef, 
                        i2.internal_id as internal_id_atp
                        FROM ",schema_dev,".",table_tef," i1
                        RIGHT JOIN ",schema_dev,".",table_atp," i2
                      on st_dwithin(i1.geom::geography,i2.geom::geography,30)
                      where i1.owner LIKE '%ATP%'
    
    ")
             
    df_aux <- dbGetQuery(con,query)
                     
    dbDisconnect(con)
    
    df_aux
}