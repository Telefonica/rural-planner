deleteDuplicates_2 <- function(schema_dev,table_azteca, table, a, owner){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("SELECT
                        i1.internal_id as internal_id_azteca,
                        i2.internal_id as internal_id_",a,"
                        FROM ",schema_dev,".",table_azteca," i1
                        RIGHT JOIN ",schema_dev,".",table," i2
                        ON ST_Dwithin(i1.geom::geography,i2.geom::geography,30)
                        where i1.owner='", owner,"'"
    )
    
    df_aux <- dbGetQuery(con,query)
                     
    dbDisconnect(con)
    
    df_aux
}