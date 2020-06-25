uploadDB <- function(schema, red_4g, table_atoll_4g, red_3g, table_atoll_3g, red_2g, table_atoll_2g){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(Postgres(), dbname = dbname, host = host, port = port, 
                      user = user, password = pwd)
    
    query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table_atoll_4g)
    dbGetQuery(con, query)
    
    query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table_atoll_3g)
    dbGetQuery(con, query)
    
    query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table_atoll_2g)
    dbGetQuery(con, query)
    
    st_write(obj = red_4g, dsn = con, Id(schema=schema, table = table_atoll_4g))

    
    st_write(obj = red_3g, dsn = con, Id(schema=schema, table = table_atoll_3g))

    
    st_write(obj = red_2g, dsn = con, Id(schema=schema, table = table_atoll_2g))

    
    # Change SRID 32717 to 4326 in atoll tables
    query <- paste0("ALTER TABLE ", schema, ".", table_atoll_4g, " 
                     ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 4326) 
                     USING ST_Multi(ST_Transform(ST_SetSRID(geom, 32717), 4326));")
    dbGetQuery(con, query)
    
    query <- paste0("ALTER TABLE ", schema, ".", table_atoll_3g, " 
                     ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 4326) 
                     USING ST_Multi(ST_Transform(ST_SetSRID(geom, 32717), 4326));")
    dbGetQuery(con, query)
    
    query <- paste0("ALTER TABLE ", schema, ".", table_atoll_2g, " 
                     ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 4326) 
                     USING ST_Multi(ST_Transform(ST_SetSRID(geom, 32717), 4326));")
    dbGetQuery(con, query)
    
    ## Simplify geometries
    query <- paste0("UPDATE ", schema, ".", table_atoll_4g, " 
                     SET geom= (ST_Simplify(geom,0.001));")
    dbGetQuery(con, query)
    
    query <- paste0("UPDATE ", schema, ".", table_atoll_3g, " 
                     SET geom= (ST_Simplify(geom,0.001));")
    dbGetQuery(con, query)
    
    query <- paste0("UPDATE ", schema, ".", table_atoll_2g, " 
                     SET geom= (ST_Simplify(geom,0.001));")
    dbGetQuery(con, query)
    
    dbDisconnect(con)
}