test <- function(schema, table, df){

    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    dbWriteTable(con, 
                 c(schema,table), 
                 value = data.frame(df), row.names = F, append= F)
    
    query <- paste("
    SELECT
    *,
    CASE WHEN (tech_2g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), coverage_radius*1000) ELSE NULL END AS coverage_area_2g,
    CASE WHEN (tech_3g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), coverage_radius*1000) ELSE NULL END AS coverage_area_3g,
    CASE WHEN (tech_4g) is TRUE THEN ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geography), coverage_radius*1000) ELSE NULL END AS coverage_area_4g
    FROM ", schema, ".", table, sep = "")
    
    aux <- dbGetQuery(con,query)
    
    query <- paste("DROP TABLE ",schema, ".", table, sep = "")
    dbGetQuery(con,query)
    dbDisconnect(con)
    aux
}