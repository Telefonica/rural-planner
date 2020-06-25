atollCoverageVivo <- function(schema, table_coverage_vivo, coverage_regulator_vivo, table_coverage_competitors_4g, table_coverage_competitors_3g, table_coverage_competitors){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table_coverage_vivo)
    dbGetQuery(con,query)
    
    pgInsert(conn = con, name = c(schema,table_coverage_vivo), data.obj = coverage_regulator_vivo)
    
    query <- paste0("CREATE TABLE ", schema, ".", table_coverage_vivo, "_temp AS (
                    SELECT CASE WHEN tech='2G' THEN geom ELSE NULL END AS geom_2g, 
                            CASE WHEN tech='3G' THEN geom ELSE NULL END AS geom_3g,
                            CASE WHEN tech LIKE '%4G%' THEN geom ELSE NULL END AS geom_4g
                    FROM (
                    SELECT tech, ST_CollectionExtract(ST_Multi(ST_Collect(geom)),3) as geom 
                    FROM ", schema, ".", table_coverage_vivo, " 
                    GROUP BY tech) a);
                    DROP TABLE IF EXISTS ", schema, ".", table_coverage_vivo,";
                    CREATE TABLE ", schema, ".", table_coverage_vivo," AS (
                    SELECT * FROM ", schema, ".", table_coverage_vivo, "_temp);
                    DROP TABLE ", schema, ".", table_coverage_vivo, "_temp;")
    dbGetQuery(con,query)
    
    query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table_coverage_competitors_4g)
    dbGetQuery(con,query)
    query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table_coverage_competitors_3g)
    dbGetQuery(con,query)
    
    pgInsert(conn = con, name = c(schema,table_coverage_competitors_4g), data.obj = coverage_regulator_competitors_4g)
    pgInsert(conn = con, name = c(schema,table_coverage_competitors_3g), data.obj = coverage_regulator_competitors_3g)
    
    query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table_coverage_competitors)
    dbGetQuery(con,query)
    
    query <- paste0("CREATE TABLE ", schema, ".", table_coverage_competitors, " AS (
                SELECT  NULL::geometry AS geom_2g, 
                        a.geom AS geom_3g,
                        b.geom AS geom_4g,
                        a.operator_id
                FROM (
                SELECT operator_id, ST_CollectionExtract(ST_Multi(ST_Collect(geom)),3) as geom 
                FROM ", schema, ".", table_coverage_competitors_3g, " 
                GROUP BY operator_id) a
                LEFT JOIN (
                SELECT operator_id, ST_CollectionExtract(ST_Multi(ST_Collect(geom)),3) as geom 
                FROM ", schema, ".", table_coverage_competitors_4g, " 
                GROUP BY operator_id) b
                ON a.operator_id=b.operator_id);")
    dbGetQuery(con,query)
    
    query <- paste0("UPDATE ", schema, ".", table_coverage_competitors, " SET geom_4g=ST_Simplify(geom_4g,0.01),     geom_3g=ST_Simplify(geom_3g,0.01)")
    dbGetQuery(con,query)
    
    query <- paste0("DROP TABLE ", schema, ".", table_coverage_competitors_3g)
    dbGetQuery(con,query)
    query <- paste0("DROP TABLE ", schema, ".", table_coverage_competitors_4g)
    dbGetQuery(con,query)
    
    
    dbDisconnect(con)
}