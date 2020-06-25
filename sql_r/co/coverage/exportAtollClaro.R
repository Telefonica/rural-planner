exportAtollClaro <- function(schema, table, technologies) {
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste0("DROP TABLE IF EXISTS ", schema,".",table, sep = "")
    dbGetQuery(con,query)
    
    query <-paste0("CREATE TABLE ", schema,".",table," (geom_2g geometry,geom_3g geometry,geom_4g geometry)")
    dbGetQuery(con,query)
    
    query <-paste0("INSERT INTO ", schema,".",table," VALUES (NULL,NULL,NULL)")
    dbGetQuery(con,query)
    
    maxUnion <-10000
    
    for(technology in tolower(technologies)){
      drv <- dbDriver("PostgreSQL")
      con <- dbConnect(drv, dbname = dbname,
                       host = host, port = port,
                       user = user, password = pwd)
      
      query <- paste0("SELECT COUNT(*) FROM ", schema,".",table,"_",technology )
      total <- as.numeric(dbGetQuery(con,query)[1,1])
      if(total>maxUnion){
        query <- paste0("UPDATE ", schema,".",table," A SET geom_",technology," = E.geom FROM
              (SELECT ST_CollectionExtract(ST_Collect(geom),3) AS geom FROM (" )
        
        query <- paste0(query, " SELECT ST_Union(geom) AS geom FROM (
                    SELECT * FROM ", schema,".",table,"_",technology ," ORDER BY geom 
                    LIMIT ",maxUnion,") B")
        offset<-maxUnion
        while(offset < total){
          query<- paste0(query, " UNION 
                    SELECT ST_Union(geom) AS geom FROM (
                    SELECT * FROM ", schema,".",table,"_",technology ," ORDER BY geom 
                    LIMIT ",maxUnion," OFFSET ", offset,") C")
          
          offset <-offset+maxUnion
        }
        query<-paste0(query, ")")
        dbGetQuery(con,query)
        
      }
      else{
        query<-paste0("UPDATE ", schema,".",table," A SET geom_",technology," = B.geom FROM
              (SELECT ST_Union(geom) AS geom FROM ", schema,".",table,"_",technology ,")B")
        dbGetQuery(con,query)
      }
    }
      
 dbDisconnect(con)
      
}