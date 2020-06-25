exportDB_AddGeom <- function(schema,table,df,column){

    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, c(schema,table), value = data.frame(df), row.names = F, replace= T)
    
    
    query <- paste("ALTER TABLE ", schema,".",table, " ADD COLUMN ", column," geography", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema, ".", table, " SET ",column," = ST_SetSRID(ST_MakePoint(longitude, latitude),4326)", sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}