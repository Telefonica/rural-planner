#Function that calculates the geom of the area coverage from a (lat, long), a radius, an azimuth and a width.

#Load libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)


#DB Connection parameters
config_path <- '~/shared/rural_planner_peru/config_files/.config_pe'
source(config_path)


coverage_area <- function(latitude, longitude, radius, azimuth = 0, width = 360) {
  radians <- function(deg) {as.double(deg)*pi/180}
  degrees <- function(rad) {as.double(rad)*180/pi}
  
  if(width >= 360) {
    #Set connection data
    schema <- 'rural_planner_dev'
    table  <- 'temp_coverage_area'
    table_2 <- 'temp_coverage_area_2'
    
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
       
    query <- paste("
    SELECT
    ST_Buffer(CAST(ST_SetSRID(ST_MakePoint(",longitude,",", latitude,"),4326) AS geography), ",radius*1000,") AS geom
    ", sep = "")
    
    cov_area <- dbGetQuery(con, query)
    output_cov_area <- cov_area$geom
    
    dbDisconnect(con)
    
    return(output_cov_area)
    
  }
  
  else {
    points <- data.frame(latitude, longitude)
    
    R <- 6378.1 #Earth radius
    
    n <- as.integer(width) #One point per degree
    
    azimuth <- radians(azimuth)
    width <- radians(width)
    latitude <- radians(latitude)
    longitude <- radians(longitude)
    
    alpha_0 <- azimuth - width/2
    alpha_1 <- azimuth + width/2
    alpha <- alpha_0
    
    for (i in 1:(n + 1)) {
      alpha = alpha_0 + (i-1)/as.double(n)*(alpha_1 - alpha_0)
      
      lat1 <- asin(sin(latitude)*cos(radius/R) + cos(latitude)*sin(radius/R)*cos(alpha))
      lon1 <- longitude + atan2(sin(alpha)*sin(radius/R)*cos(latitude), cos(radius/R) - sin(latitude)*sin(lat1))
      
      new_point <- data.frame(degrees(lat1), degrees(lon1))
      colnames(new_point) <- c("latitude", "longitude")
      
      points <- rbind(points, new_point)
    }
    
    last_point <- data.frame(degrees(latitude), degrees(longitude))
    colnames(last_point) <- c("latitude", "longitude")
    
    points <- rbind(points, last_point)
    
    #Set connection data
    schema <- 'rural_planner_dev'
    table  <- 'temp_coverage_area'
    table_2 <- 'temp_coverage_area_2'
    
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    dbWriteTable(con, c(schema,table), value = data.frame(points), row.names = F, append= T)
    
    query <- paste("
                   CREATE TABLE ", schema, ".", table_2,"
                   AS
                   SELECT ST_MakePolygon(geom)::text AS geom
                   FROM (
                   SELECT ST_MakeLine(geom) AS geom
                   FROM (
                   SELECT ST_SetSRID(ST_MakePoint(longitude, latitude),4326) AS geom
                   FROM ", schema,".",table,"
                   ) A
                   ) B ", sep = "")
    
    dbGetQuery(con, query)
    
    query <- paste("
                   SELECT *
                   FROM ", schema,".",table_2, sep = "")
    
    cov_area <- dbGetQuery(con, query)
    output_cov_area <- cov_area$geom
    
    dbGetQuery(con, paste("DROP TABLE ", schema,".",table))
    dbGetQuery(con, paste("DROP TABLE ", schema,".",table_2))
    
    dbDisconnect(con)
    
    return(output_cov_area)
  }
}