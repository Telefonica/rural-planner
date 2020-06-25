deleteDuplicates_1 <- function(schema_dev,table_tef, table_tigo){
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd)
                 
query <- paste0("SELECT DISTINCT ON (t1.latitude, t1.longitude)
             t2.latitude, t2.longitude FROM ",schema_dev,".",table_tef," t1
            LEFT JOIN ",schema_dev,".",table_tigo," t2
            ON ST_DWithin(t1.geom::geography, t2.geom::geography,10) 
            WHERE t1.subtype='TIGO' AND t2.source IS NOT NULL")
            
df_aux <- dbGetQuery(con,query)
                 
dbDisconnect(con)

df_aux
}