deleteDuplicates_4 <- function(schema_dev,table_tef, table_atc){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("select distinct on (i1.internal_id)
                        i1.internal_id as internal_id_tef, 
                        i2.internal_id as internal_id_atc
                        FROM ",schema_dev,".",table_tef," i1
                        RIGHT JOIN ",schema_dev,".",table_atc," i2
                      on st_dwithin(i1.geom::geography,i2.geom::geography,30)
                      where i1.owner IN ('ATC', 'TELEFONICA')
    
    ")
    
    df_aux <- dbGetQuery(con,query)
                     
    dbDisconnect(con)
    
    df_aux
}