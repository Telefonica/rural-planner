setInsidePolygon <- function(schema,table_settlements_polygons, table_households, admin_div_2_aux){
  invisible(lapply(admin_div_2_aux$admin_division_2_id,function(id){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    query <-paste("UPDATE ",schema, ".", table_households, " 
                  SET inside_polygon = true,
                  closest_settlement = settlement_id
                  FROM ",schema,".", table_settlements_polygons," 
                  WHERE right(",table_settlements_polygons, ".settlement_id,3) ='000' 
                  AND ST_Within(", table_households, ".geom::geometry, ", table_settlements_polygons,".geom)
                  AND ", table_households, ".admin_division_2_id='",id,"'
                  AND ", table_settlements_polygons,".admin_division_2_id='",id, "'",sep = "")
    dbGetQuery(con,query)
    flush.console()
    dbDisconnect(con)
  }))
  
}
