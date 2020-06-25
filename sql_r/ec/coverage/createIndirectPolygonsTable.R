createIndirectPolygonsTable <- function(schema, indirect_polygons_table,infrastructure_table, indirect_coverage_polygons_df){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                       host = host, port = port,
                       user = user, password = pwd)
      
    query <- paste0('TRUNCATE TABLE ',schema,'.', indirect_polygons_table)
    dbGetQuery(con,query)
    
    # Indirect Coverage 2G
    query <- paste0("SELECT (ST_Union(ST_MakeValid(coverage_area_2g))) 
                     FROM ",schema,".", infrastructure_table, "
                     WHERE tech_2g IS TRUE AND coverage_area_2g IS NOT NULL")
    indirect_coverage_polygons_df$geom_2g <- dbGetQuery(con,query)
    
    # Indirect Coverage 3G
    query <- paste0("SELECT (ST_Union(ST_MakeValid(coverage_area_3g))) 
                     FROM ",schema,".", infrastructure_table, "
                     WHERE tech_3g IS TRUE AND coverage_area_3g IS NOT NULL")
    indirect_coverage_polygons_df$geom_3g <- dbGetQuery(con,query)
    
    # Indirect Coverage 4G
    query <- paste0("SELECT (ST_Union(ST_MakeValid(coverage_area_4g))) 
                     FROM ",schema,".", infrastructure_table, "
                     WHERE tech_4g IS TRUE AND coverage_area_4g IS NOT NULL")
    indirect_coverage_polygons_df$geom_4g <- dbGetQuery(con,query)
    
    
    dbWriteTable(con, c(schema,indirect_polygons_table), 
                 value = data.frame(indirect_coverage_polygons_df), row.names = F, append= T)
    
    
    # Change column type to geometry
    query <- paste0("ALTER TABLE ",schema,".",indirect_polygons_table,"
              ALTER COLUMN geom_2g TYPE geometry")
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ",schema,".",indirect_polygons_table,"
              ALTER COLUMN geom_3g TYPE geometry")
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ",schema,".",indirect_polygons_table,"
              ALTER COLUMN geom_4g TYPE geometry")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}