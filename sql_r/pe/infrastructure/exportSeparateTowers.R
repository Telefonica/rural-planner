exportSeparateTowers <- function(schema, table_old, table_global, towers){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    
    
    #Upload old towers, add ID as integer and add geom field and change the coverage areas types to geom
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table_old, sep = "")
    dbGetQuery(con,query)
    
    query <- paste0("CREATE TABLE ",schema,".",table_old," AS SELECT  * FROM ", schema,".",table_global)
    dbGetQuery(con,query)
    
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table_global, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, c(schema,table_global), value = data.frame(towers), row.names = T, append= T)
    query <- paste("ALTER TABLE ", schema,".",table_global, " RENAME \"row.names\" TO tower_id", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ADD COLUMN geom geography", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema,".",table_global, " SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ALTER COLUMN tower_id TYPE INTEGER USING tower_id::INTEGER", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ALTER COLUMN coverage_area_2g TYPE GEOMETRY USING coverage_area_2g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ALTER COLUMN coverage_area_3g TYPE GEOMETRY USING coverage_area_3g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ALTER COLUMN coverage_area_4g TYPE GEOMETRY USING coverage_area_4g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    
    ## AD-HOC: where latitude and longitude are zero, it means it is a moving BTS in a boat (the geometry is not created); and correct longitudes from several towers
    
    query <- paste("UPDATE ", schema, ".", table_global, " SET longitude = -longitude WHERE longitude > 0", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema, ".", table_global, " SET latitude = -latitude WHERE latitude > 0", sep = "")
    dbGetQuery(con,query)
    
    ## AD-HOC: do not take into account the coverage area that would give the infrastructure that is "PLANNED" (not "IN SERVICE")
    
    query <- paste("UPDATE ", schema, ".", table_global, " SET coverage_area_2g = NULL WHERE in_service <> 'IN SERVICE'", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema, ".", table_global, " SET coverage_area_3g = NULL WHERE in_service <> 'IN SERVICE'", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema, ".", table_global, " SET coverage_area_4g = NULL WHERE in_service <> 'IN SERVICE'", sep = "")
    dbGetQuery(con,query)
    
    
    ## AD_HOC: REMOVE PIA DUPLICATES
    
    query <- paste0("DELETE FROM ",schema,".",table_global," * WHERE internal_id IN (
                    select internal_id from ",schema, ".", table_global,"
                        group by internal_id
                        having count(internal_id)>1
                    ) AND source='PIA'" )
    
    dbGetQuery(con,query)
    
    ## AD-HOC: Change coordinates
    
    query <- paste0("UPDATE ",schema,".",table_global," SET latitude=longitude, longitude=latitude WHERE 
                    latitude<-70" )
    dbGetQuery(con,query)
    
    
    query <- paste0("UPDATE ",schema,".",table_global," SET longitude= -77.0261119  WHERE 
                    internal_id='LI06091'" )
    dbGetQuery(con,query)
    
    
    query <- paste0("UPDATE ",schema,".",table_global," SET longitude= -73.9593063  WHERE 
                    internal_id='JU00497'" )
    dbGetQuery(con,query)
    
    
    query <- paste0("UPDATE ",schema,".",table_global," SET latitude= -latitude  WHERE 
                    internal_id IN ('AR00508', 'AR00505')" )
    #dbGetQuery(con,query)
    
    
    query <- paste("UPDATE ", schema, ".", table_global, " SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326) WHERE latitude<>0 and longitude<>0", sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con,query)
}