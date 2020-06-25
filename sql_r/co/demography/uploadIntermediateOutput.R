uploadIntermediateOutput <- function(schema, table_settlements, settlements_basic, table_admin_division_1, table_settlements_polygons){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)  
    
    query <- paste0("DROP TABLE ", schema, ".", table_settlements)
    dbGetQuery(con,query)
    
    dbWriteTable(con, c(schema,table_settlements), value = data.frame(settlements_basic), row.names = F, append = T)
    
    query <- paste("ALTER TABLE ", schema,".",table_settlements, " ADD COLUMN geom geography", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_settlements, " ALTER COLUMN latitude type numeric USING latitude::numeric", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_settlements, " ALTER COLUMN longitude type numeric USING longitude::numeric", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema, ".", table_settlements, " SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326)", sep = "")
    dbGetQuery(con,query)
    
    ## Remove those settlements that were located outside its admin_division_1 limits. This removes incorrect results of Google and OSM APIs
    
    query <- paste("UPDATE ", schema,".",table_settlements, " SET latitude = NULL,longitude = NULL, geom = NULL, source = NULL
                   WHERE settlement_id IN (SELECT settlement_id FROM ",schema, ".", table_settlements," s
                   LEFT JOIN ",schema,".",table_admin_division_1," m
                   ON s.admin_division_1_id = m.admin_division_1_id 
                   WHERE NOT ST_Within(s.geom::geometry,m.geom::geometry))", sep = "")
    dbGetQuery(con,query)
    
    ## Remove settlements with duplicated latitude and longitude
    
    query <- paste("UPDATE ", schema,".",table_settlements, " SET latitude = NULL,longitude = NULL, geom = NULL, source = NULL
                   WHERE (latitude,longitude) in ( 
                   SELECT latitude, longitude from ",schema, ".", table_settlements," 
                   GROUP BY  (latitude,longitude),latitude,longitude 
                   HAVING count(*) >1)", sep = "")
    dbGetQuery(con,query)
    
    ## Add 8 new locations from the source of settlements' polygons from DANE
    
    query <- paste("UPDATE ", schema,".",table_settlements, " A SET latitude=C.latitude, longitude=C.longitude, geom = C.geom, source = C.source  
                   FROM (SELECT settlement_id, 
                          ST_X (ST_Transform(ST_PointOnSurface(geom), 4326)) as longitude, 
                          ST_Y (ST_Transform (ST_PointOnSurface(geom), 4326)) as latitude, 
                          ST_PointOnSurface(geom) as geom,
                          'settlements_polygons' as source
                          FROM ",schema, ".", table_settlements_polygons," WHERE settlement_id IN
                          ( SELECT settlement_id FROM ",schema,".",table_settlements," WHERE latitude IS NULL )) C
                          WHERE A.settlement_id = C.settlement_id", sep = "")
    dbGetQuery(con,query)
    
    ## REMOVE UNLOCATED SETTLEMENTS
    query <-paste(" DELETE FROM ",schema,".",table_settlements,
                  " WHERE (latitude IS NULL or longitude IS NULL)",sep = "")
                 
    dbGetQuery(con,query)
    
    ## Modify population_corrected data type
    query <-paste(" ALTER TABLE ",schema,".",table_settlements,
                  " ALTER COLUMN population_corrected type float USING NULL",sep = "")
                 
    dbGetQuery(con,query)
    
    dbDisconnect(con)

}