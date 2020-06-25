groupNodes_B <- function(schema, table, tasa_int){
drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    dbWriteTable(con, 
                 c(schema,table), 
                 value = data.frame(tasa_int), row.names = F, append= F)
    
    query <- paste("
SELECT latitude,
    longitude,
    MAX(tower_height) AS tower_height,
    MAX(subtype) AS subtype,
    MAX(location_detail) AS location_detail,
    MAX(type) AS type,
    string_agg(DISTINCT(technology), '+') AS technology,
    string_agg(DISTINCT(band_mhz::varchar), '+') AS band_mhz,
    MAX(ran_sharing) AS ran_sharing,
    string_agg(DISTINCT(transport), '+') AS transport,
    tower_name as internal_id,
    MAX(owner) AS owner,
    bool_or(tech_2g) AS tech_2g,
    bool_or(tech_3g) AS tech_3g,
    bool_or(tech_4g) AS tech_4g,
    MAX(in_service) AS in_service,
    MAX(vendor) AS vendor,
    tower_name as tower_name,
    ST_union(coverage_area_2g::geometry) as coverage_area_2g,
    ST_union(coverage_area_3g::geometry) as coverage_area_3g,
    ST_union(coverage_area_4g::geometry) as coverage_area_4g
          FROM (
              SELECT
              latitude,
              longitude,
              MAX(tower_height) AS tower_height,
              MAX(subtype) AS subtype,
              MAX(location_detail) AS location_detail,
              MAX(type) AS type,
              string_agg(DISTINCT(technology), '+') AS technology,
              string_agg(DISTINCT(band_mhz::varchar), '+') AS band_mhz,
              MAX(ran_sharing) AS ran_sharing,
              string_agg(DISTINCT(tx_type), '+') AS transport,
              MAX(owner) AS owner,
              bool_or(tech_2g) AS tech_2g,
              bool_or(tech_3g) AS tech_3g,
              bool_or(tech_4g) AS tech_4g,
              MAX(in_service) AS in_service,
              MAX(vendor) AS vendor,
              internal_id AS tower_name,
              CASE WHEN bool_or(tech_2g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude::float, latitude::float),4326) AS geography), MAX(coverage_radius)*1000) ELSE NULL END AS coverage_area_2g,
              CASE WHEN bool_or(tech_3g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude::float, latitude::float),4326) AS geography), MAX(coverage_radius)*1000) ELSE NULL END AS coverage_area_3g,
              CASE WHEN bool_or(tech_4g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude::float, latitude::float),4326) AS geography), MAX(coverage_radius)*1000) ELSE NULL END AS coverage_area_4g
              FROM ", schema, ".", table, " 
              GROUP BY internal_id, latitude, longitude, technology ) A
GROUP BY A.latitude, A.longitude, A.tower_name
    ", sep = "")
    
    tasa <- dbGetQuery(con,query)
    
    query <- paste("DROP TABLE ",schema, ".", table, sep = "")
    dbGetQuery(con,query)
    dbDisconnect(con)
    
    tasa
}