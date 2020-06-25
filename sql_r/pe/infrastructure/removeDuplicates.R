removeDuplicates <- function(schema,table_duplicates_ipt, ipt){
    
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    dbWriteTable(con, 
                     c(schema,table_duplicates_ipt), 
                     value = data.frame(ipt), row.names = F, append= F)
    
    query <- paste("
        SELECT
        latitude,
        longitude,
        MAX(tower_height) AS tower_height,
        MAX(owner) AS owner,
        MAX(location_detail) AS location_detail,
        MAX(tower_type) AS tower_type,
        bool_or(tech_2g) AS tech_2g,
        bool_or(tech_3g) AS tech_3g,
        bool_or(tech_4g) AS tech_4g,
        MAX(type) AS type,
        MAX(subtype) AS subtype,
        MIN(in_service) AS in_service,
        MAX(vendor) AS vendor,
        MAX(coverage_area_2g)::geometry AS coverage_area_2g,
        MAX(coverage_area_3g)::geometry AS coverage_area_3g,
        MAX(coverage_area_4g)::geometry AS coverage_area_4g,
        bool_or(fiber) AS fiber,
        bool_or(radio) AS radio,
        bool_or(satellite) AS satellite,
        bool_or(satellite_band_in_use) AS satellite_band_in_use,
        MAX(radio_distance_km) AS radio_distance_km,
        MAX(last_mile_bandwidth) AS last_mile_bandwidth,
        source_file,
        source,   
        internal_id,
        MAX(tower_name) AS tower_name,
        ipt_perimeter
        FROM ", schema, ".", table_duplicates_ipt, " 
        GROUP BY latitude, longitude, internal_id,source_file, source,ipt_perimeter
        ", sep = "")
        
    ipt <- dbGetQuery(con,query)
    
    query <- paste("DROP TABLE ",schema, ".", table_duplicates_ipt, sep = "")
    dbGetQuery(con,query)
        
        
    dbDisconnect(con)
    
    ipt

}