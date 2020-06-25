deleteDuplicates_3 <- function(schema_dev,table_azteca, table_tef){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
                     
    query <- paste0("select distinct on (i1.internal_id)
                        i1.internal_id as internal_id_azteca, 
                        i2.internal_id as internal_id_tef
                        FROM ",schema_dev,".",table_azteca," i1
                        RIGHT JOIN ",schema_dev,".",table_tef," i2
                      on st_dwithin(i1.geom::geography,i2.geom::geography,15)
                      where i1.owner='TELEF?NICA'
    
    ")                
                     
                     
    df_aux <- dbGetQuery(con,query)
                     
    dbDisconnect(con)
    
    df_aux
}