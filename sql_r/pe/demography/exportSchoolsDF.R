exportSchoolsDF <- function(schema, schools_table, schools_df){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                             host = host, port = port,
                             user = user, password = pwd)
    dbWriteTable(con, c(schema, schools_table), value = data.frame(schools_df), row.names = T, append= T)
    
    query <- paste("ALTER TABLE ", schema, ".", schools_table," RENAME \"row.names\" TO school_internal_id", sep = "")
    
    dbGetQuery(con,query)
    
    #Add geometry
    
    query <- paste0("ALTER TABLE ",schema,".",schools_table," ADD COLUMN geom geometry")
    dbGetQuery(con,query)
    
    query <- paste0("UPDATE ",schema,".",schools_table," SET geom = ST_SetSRID(ST_MakePoint(longitude::float, latitude::float),4326)")
    dbGetQuery(con,query)
    
    
    query <- paste0("CREATE INDEX schools_gix ON ", schema, ".", schools_table, " USING GIST (geom);")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}