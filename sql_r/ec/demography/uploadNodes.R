uploadNodes <- function(schema, tables, objects){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)
  
  # Create latitude and longitude fields and recalculate geom as geography
  
  for(i in 1:length(tables)){
    
    pgInsert(conn = con, name = c(schema, tables[i]), data.obj = objects[[i]])
    
    query <- paste0("ALTER TABLE ", schema, ".", tables[i], " ADD COLUMN latitude FLOAT")
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ", schema, ".", tables[i], " ADD COLUMN longitude FLOAT")
    dbGetQuery(con, query)
    
    query <- paste0("ALTER TABLE ", schema, ".", tables[i], " ALTER COLUMN geom TYPE Geometry(Point,4326)
          USING ST_Transform(geom, 4326)")
    dbGetQuery(con,query)
    
    query <- paste0("UPDATE ", schema, ".", tables[i], " SET latitude = ST_Y(geom)")
    dbGetQuery(con, query)
    
    query <- paste0("UPDATE ", schema, ".", tables[i], " SET longitude = ST_X(geom)")
    dbGetQuery(con, query)
    
    query <- paste0("ALTER TABLE ", schema, ".", tables[i], " ALTER COLUMN geom TYPE GEOGRAPHY USING geom::GEOGRAPHY")
    dbGetQuery(con, query)
    
  }    
  
  dbDisconnect(con)
}