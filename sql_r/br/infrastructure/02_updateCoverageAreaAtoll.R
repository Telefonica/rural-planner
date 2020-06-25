#Update coverage area with atoll

updateCoverageAreaAtoll <- function(schema_dev, table, atoll_table_2g, atoll_table_3g, atoll_table_4g, atoll_table_all, vivo_int){

    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 

    
    query <- paste("DROP TABLE IF EXISTS ", schema_dev,".",atoll_table_all, sep = "")
    dbGetQuery(con,query) 
    
    query <- paste0('CREATE TABLE ',schema_dev, '.', atoll_table_all, '
                    AS 
                    (SELECT z.internal_id, ST_Union(coverage_area_2g) as coverage_area_2g,
                     ST_Union(coverage_area_3g) as coverage_area_3g,  ST_Union(coverage_area_4g) as coverage_area_4g
                    FROM (SELECT CASE WHEN CONCAT(b."UF",(RIGHT(LEFT(b."ERB",-1),-1))) IS NOT NULL and CONCAT(b."UF",(RIGHT(LEFT(b."ERB",-1),-1)))<>\'\' THEN CONCAT(b."UF",(RIGHT(LEFT(b."ERB",-1),-1)))
                                    WHEN CONCAT(c.uf,(RIGHT(LEFT(c.erb,-1),-1))) IS NOT NULL and CONCAT(c.uf,(RIGHT(LEFT(c.erb,-1),-1)))<>\'\' THEN CONCAT(c.uf,(RIGHT(LEFT(c.erb,-1),-1)))
                                    WHEN CONCAT(d."UF",(RIGHT(LEFT(d."ERB",-1),-1))) IS NOT NULL and CONCAT(d."UF",(RIGHT(LEFT(d."ERB",-1),-1)))<>\'\' THEN CONCAT(d."UF",(RIGHT(LEFT(d."ERB",-1),-1)))
                                    ELSE NULL END AS internal_id,
                              ST_Buffer(ST_Union(b.geom),0) as coverage_area_2g,
                              ST_Buffer(ST_Union(c.geom),0) as coverage_area_3g,
                              ST_Buffer(ST_Union(d.geom),0) as coverage_area_4g
                              FROM ', schema_dev, '.',  atoll_table_2g, ' b 
                              FULL JOIN ', schema_dev, '.',  atoll_table_3g, ' c
                              ON b."UF"=c.uf AND b."ERB"=c.erb
                              FULL JOIN ', schema_dev, '.',  atoll_table_4g, ' d
                              ON b."UF"=d."UF" AND b."ERB"=d."ERB"
                              GROUP BY b."UF", b."ERB", c.uf, c.erb, d."UF", d."ERB"
                    ) z
                    group by internal_id)')
    
    dbGetQuery(con,query)
    
    query <- paste0('ALTER TABLE ',schema_dev, '.', atoll_table_all, '
                      ALTER COLUMN coverage_area_2g SET DATA TYPE geometry;
                    ALTER TABLE ',schema_dev, '.', atoll_table_all, '
                      ALTER COLUMN coverage_area_3g SET DATA TYPE geometry;
                    ALTER TABLE ',schema_dev, '.', atoll_table_all, '
                      ALTER COLUMN coverage_area_4g  SET DATA TYPE geometry')
    dbGetQuery(con,query)
    
    query <- paste0('ALTER TABLE ',schema_dev, '.', atoll_table_all, '
                      ALTER COLUMN coverage_area_2g SET DATA TYPE geometry(MultiPolygon) USING ST_Multi(coverage_area_2g);
                    ALTER TABLE ',schema_dev, '.', atoll_table_all, '
                      ALTER COLUMN coverage_area_3g SET DATA TYPE geometry(MultiPolygon) USING ST_Multi(coverage_area_3g);
                    ALTER TABLE ',schema_dev, '.', atoll_table_all, '
                      ALTER COLUMN coverage_area_4g  SET DATA TYPE geometry(MultiPolygon) USING ST_Multi(coverage_area_4g)')
    dbGetQuery(con,query)
    
    
    
    
    query <- paste0('ALTER TABLE ',schema_dev, '.', atoll_table_all, '
                      ALTER COLUMN coverage_area_2g TYPE geometry(MULTIPOLYGON, 4326)
                        USING ST_SetSRID(coverage_area_2g,4326);
                    ALTER TABLE ',schema_dev, '.', atoll_table_all, '
                      ALTER COLUMN coverage_area_3g TYPE geometry(MULTIPOLYGON, 4326)
                        USING ST_SetSRID(coverage_area_3g,4326);
                    ALTER TABLE ',schema_dev, '.', atoll_table_all, '
                      ALTER COLUMN coverage_area_4g TYPE geometry(MULTIPOLYGON, 4326)
                        USING ST_SetSRID(coverage_area_4g,4326);')
    dbGetQuery(con,query)
    
    
    #Group all nodes belonging to the same tower
    
    query <- paste("DROP TABLE IF EXISTS ", schema_dev,".",table, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema_dev,table), 
                 value = data.frame(vivo_int), row.names = F, append= F)
    
    query <- paste("
                  SELECT
                  A.internal_id,
                  latitude,
                  longitude,
                  MAX(tower_height) AS tower_height,
                  MAX(subtype) AS subtype,
                  MAX(location_detail) AS location_detail,
                  MAX(type) AS type,
                  string_agg(DISTINCT(tx_type), '+') AS transport,
                  MAX(owner) AS owner,
                  bool_or(tech_2g) AS tech_2g,
                  bool_or(tech_3g) AS tech_3g,
                  bool_or(tech_4g) AS tech_4g,
                  bool_or(fiber) AS fiber,
                  bool_or(radio) AS radio,
                  bool_or(satellite) AS satellite,
                  MAX(in_service) AS in_service,
                  MAX(vendor) AS vendor,
                  MAX(location_detail) AS tower_name,
                  NULL::GEOMETRY AS coverage_area_2g,
                  NULL::GEOMETRY AS coverage_area_3g,
                  NULL::GEOMETRY AS coverage_area_4g
                  FROM ", schema_dev, ".", table, " A
                  LEFT JOIN ", schema_dev, ".", atoll_table_all," B
                  ON A.internal_id=B.internal_id
                  WHERE A.internal_id IS NOT NULL
                  GROUP BY latitude, longitude, A.internal_id
        ", sep = "")
    
    vivo <- dbGetQuery(con,query)
    
    query <- paste("DROP TABLE ",schema_dev, ".", table, sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
    
    vivo
}
