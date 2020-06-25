exportAtoll <- function(schema, table, technologies){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <-paste0("CREATE TABLE ", schema,".",table," (geom_2g geometry,geom_3g geometry,geom_4g geometry)")
    dbGetQuery(con,query)
    
    query <-paste0("INSERT INTO ", schema,".",table," VALUES (NULL,NULL,NULL)")
    dbGetQuery(con,query)
    
    
    for(technology in tolower(technologies)){
      query<-paste0("UPDATE ", schema,".",table," A SET geom_",technology," = B.geom FROM
                  (SELECT ST_Union(ST_MakeValid(geom)) AS geom FROM ", schema,".",table,"_",technology ,")B")
      dbGetQuery(con,query)
    }
    
    dbDisconnect(con)

}