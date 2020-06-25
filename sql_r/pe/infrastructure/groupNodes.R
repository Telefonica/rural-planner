#Group all nodes belonging to the same tower
groupNodes <- function(schema, table, macros_int, realShape){
  
  if (realShape==TRUE){     
        drv <- dbDriver("PostgreSQL")
        con <- dbConnect(drv, dbname = dbname,
                         host = host, port = port,
                         user = user, password = pwd) 
        dbWriteTable(con, 
                     c(schema,table), 
                     value = data.frame(macros_int), row.names = F, append= F)
        
        query <- paste("
        SELECT
        latitude,
        longitude,
        MAX(tower_height) AS tower_height,
        MAX(subtype) AS subtype,
        MAX(location_detail) AS location_detail,
        MAX(type) AS type,
        string_agg(technology, '+') AS technology,
        string_agg(band_mhz::varchar, '+') AS band_mhz,
        MAX(ran_sharing) AS ran_sharing,
        string_agg(transport, '+') AS transport,
        internal_id,
        MAX(owner) AS owner,
        bool_or(tech_2g) AS tech_2g,
        bool_or(tech_3g) AS tech_3g,
        bool_or(tech_4g) AS tech_4g,
        MIN(in_service) AS in_service,
        MAX(vendor) AS vendor,
        MAX(tower_name) AS tower_name,
        ST_Union(coverage_area_2g) AS coverage_area_2g,
        ST_Union(coverage_area_3g) AS coverage_area_3g,
        ST_Union(coverage_area_4g) AS coverage_area_4g
        FROM (
                SELECT
                latitude,
                longitude,
                MAX(tower_height) AS tower_height,
                MAX(subtype) AS subtype,
                MAX(location_detail) AS location_detail,
                MAX(type) AS type,
                MAX(technology) AS technology,
                MAX(band_mhz) AS band_mhz,
                MAX(ran_sharing) AS ran_sharing,
                MAX(transport) AS transport,
                MAX(node_id) AS node_id,
                MAX(internal_id) AS internal_id,
                MAX(owner) AS owner,
                bool_or(tech_2g) AS tech_2g,
                bool_or(tech_3g) AS tech_3g,
                bool_or(tech_4g) AS tech_4g,
                MIN(in_service) AS in_service,
                MAX(vendor) AS vendor,
                MAX(site_id) AS tower_name,
                CASE WHEN coverage_radius*1000/3 > 3000 THEN ST_Union(ST_Union(coverage_area_2g), ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), 3000)::GEOMETRY) 
                ELSE ST_Union(ST_Union(coverage_area_2g), ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), coverage_radius*1000/3)::GEOMETRY) END AS coverage_area_2g,
                CASE WHEN coverage_radius*1000/3 > 3000 THEN ST_Union(ST_Union(coverage_area_3g), ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), 3000)::GEOMETRY) 
                ELSE ST_Union(ST_Union(coverage_area_3g), ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), coverage_radius*1000/3)::GEOMETRY) END AS coverage_area_3g,
                CASE WHEN coverage_radius*1000/3 > 3000 THEN ST_Union(ST_Union(coverage_area_4g), ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), 3000)::GEOMETRY) 
                ELSE ST_Union(ST_Union(coverage_area_4g), ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), coverage_radius*1000/3)::GEOMETRY) END AS coverage_area_4g
                FROM ",schema, ".", table,"
                GROUP BY latitude, longitude, internal_id, coverage_radius
        ) A
        GROUP BY latitude, longitude, internal_id
        ", sep = "")
        
        macros <- dbGetQuery(con,query)
        
        query <- paste("DROP TABLE ",schema, ".", table, sep = "")
        dbGetQuery(con,query)
        dbDisconnect(con)
    
    } else {
        
        drv <- dbDriver("PostgreSQL")
        con <- dbConnect(drv, dbname = dbname,
                         host = host, port = port,
                         user = user, password = pwd) 
        dbWriteTable(con, 
                     c(schema,table), 
                     value = data.frame(macros_int), row.names = F, append= F)
        
        query <- paste("
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
        string_agg(DISTINCT(transport), '+') AS transport,
        internal_id,
        MAX(owner) AS owner,
        bool_or(tech_2g) AS tech_2g,
        bool_or(tech_3g) AS tech_3g,
        bool_or(tech_4g) AS tech_4g,
        MIN(in_service) AS in_service,
        MAX(vendor) AS vendor,
        MAX(site_id) AS tower_name,
        CASE WHEN bool_or(tech_2g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), coverage_radius*1000) ELSE NULL END AS coverage_area_2g,
        CASE WHEN bool_or(tech_3g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), coverage_radius*1000) ELSE NULL END AS coverage_area_3g,
        CASE WHEN bool_or(tech_4g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), coverage_radius*1000) ELSE NULL END AS coverage_area_4g
        FROM ", schema, ".", table, " 
        GROUP BY latitude, longitude, internal_id, coverage_radius
        ", sep = "")
        
        macros <- dbGetQuery(con,query)
        
        query <- paste("DROP TABLE ",schema, ".", table, sep = "")
        dbGetQuery(con,query)
        dbDisconnect(con)
    
    }
    
    macros
}