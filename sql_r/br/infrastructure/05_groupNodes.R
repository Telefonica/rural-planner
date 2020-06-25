#Group all nodes belonging to the same tower

groupNodes <- function(schema, table, towers_int) {

    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,table), 
                 value = data.frame(towers_int), row.names = F, append= F)
    
    query <- paste("
                  SELECT
                  internal_id,
                  MAX(location_detail) as location_detail,
                  latitude,
                  longitude,
                  MAX(tower_height) AS tower_height,
                  MAX(subtype) AS subtype,
                  MAX(location_detail) AS location_detail,
                  MAX(type) AS type,
                  MAX(owner) AS owner,
                  bool_or(tech_2g) AS tech_2g,
                  bool_or(tech_3g) AS tech_3g,
                  bool_or(tech_4g) AS tech_4g,
                  MAX(in_service) AS in_service,
                  MAX(vendor) AS vendor,
                  source,
                  CASE WHEN bool_or(tech_2g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude::float, latitude::float),4326) AS geography), MAX(coverage_radius)*1000) ELSE NULL END AS coverage_area_2g,
                  CASE WHEN bool_or(tech_3g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude::float, latitude::float),4326) AS geography), MAX(coverage_radius)*1000) ELSE NULL END AS coverage_area_3g,
                  CASE WHEN bool_or(tech_4g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude::float, latitude::float),4326) AS geography), MAX(coverage_radius)*1000) ELSE NULL END AS coverage_area_4g
                  FROM ", schema, ".", table, " 
                  GROUP BY latitude, longitude, internal_id, source
        ", sep = "")
    
    towers <- dbGetQuery(con,query)
    
    query <- paste("DROP TABLE ",schema, ".", table, sep = "")
    dbGetQuery(con,query)
    dbDisconnect(con)

    towers
}