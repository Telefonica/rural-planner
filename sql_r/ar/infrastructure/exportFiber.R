exportFiber <- function(schema, table_lines, table_points, third_party_traces, third_party_pops){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table_lines, sep = "")
    dbGetQuery(con,query)
    
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table_points, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,table_lines), 
                 value = data.frame(third_party_traces), row.names = F, append= F)
    
    dbWriteTable(con, 
                 c(schema,table_points), 
                 value = data.frame(third_party_pops), row.names = F, append= F)
    
    
    query <- paste("ALTER TABLE ", schema,".",table_lines, " ADD COLUMN geom GEOGRAPHY ", sep = "")
    dbGetQuery(con,query)
    
    ## AD HOC QA, remove when necessary:
    query <- paste("DELETE FROM ", schema,".",table_lines, " WHERE LENGTH(wkt::text)<=53 ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("DELETE FROM ", schema,".",table_lines, " WHERE wkt LIKE '%LINESTRING Z ()%' ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema,".",table_lines, " SET geom = ST_GeogFromText(wkt) ", sep = "")
    dbGetQuery(con,query)
    
    
    query <- paste("ALTER TABLE ", schema,".",table_lines, " DROP COLUMN wkt ", sep = "")
    dbGetQuery(con,query)
    
    
    query <- paste("ALTER TABLE ", schema,".",table_points, " ADD COLUMN geom GEOGRAPHY ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema,".",table_points, " SET geom =  ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::GEOGRAPHY ", sep = "")
    dbGetQuery(con,query)
    
    
    dbDisconnect(con)
}