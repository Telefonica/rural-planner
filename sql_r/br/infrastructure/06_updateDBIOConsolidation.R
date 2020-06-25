updateDBIOConsolidation <- function(schema, table_lines, table_points, traces, towers){

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
                 value = data.frame(traces), row.names = F, append= F)
    
    dbWriteTable(con, 
                 c(schema,table_points), 
                 value = data.frame(towers), row.names = F, append= F)
    
    
    query <- paste("ALTER TABLE ", schema,".",table_lines, " ADD COLUMN geom GEOGRAPHY ", sep = "")
    dbGetQuery(con,query)
    
    
    query <- paste("UPDATE ", schema,".",table_lines, " SET geom = ST_GeogFromText(wkt) ", sep = "")
    dbGetQuery(con,query)
    
    
    query <- paste("ALTER TABLE ", schema,".",table_lines, " DROP COLUMN wkt ", sep = "")
    dbGetQuery(con,query)
    
    
    query <- paste("ALTER TABLE ", schema,".",table_points, " ADD COLUMN geom GEOGRAPHY ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema,".",table_points, " SET geom =  ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::GEOGRAPHY ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("SELECT * FROM ", schema,".",table_points,
                        " 
                    UNION 
                   SELECT * FROM ", schema,".",table_lines, sep="")
    infra_all <- dbGetQuery(con, query)
    
    
    dbDisconnect(con)
    
    infra_all
    
}