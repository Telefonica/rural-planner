### Indirect coverage ###
#We create a table according to the geographic location of each settlement and the coverage area for each technology calculated from the infrastructure #information.

indirectCoverage <- function(schema,table_settlements, indirect_polygons_table, ope){
  
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd) 
    
    query <- paste0("SELECT s.settlement_id, 
               ST_Contains(i.coverage_area_2g,st_transform(s.geom::geometry,3857)) AS tech_2g_indirect,
               ST_Contains(i.coverage_area_3g,st_transform(s.geom::geometry,3857)) AS tech_3g_indirect,
               ST_Contains(i.coverage_area_4g,st_transform(s.geom::geometry,3857)) AS tech_4g_indirect
          FROM ",schema,".",table_settlements," s, ",schema,".",indirect_polygons_table," i
          WHERE operator_id='", ope,"'")

    aux_df <- dbGetQuery(con,query)
    dbDisconnect(con)
    aux_df
}