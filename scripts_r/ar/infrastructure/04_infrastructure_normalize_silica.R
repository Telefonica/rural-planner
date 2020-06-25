
#LIBRARIES
library(RPostgreSQL)
library(stringr)
library(rgdal)
library("sf")
library(xml2)
library(tidyverse)


#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_ar'
source(config_path)

#VARIABLES
#Unzip kmz file to open get .kml file
input_path <- "~/shared/rural_planner/data/ar/infrastructure/Red Silica"

file_name_kmz <-"Red Silica Corp - 2018.kmz"

file_name <- "doc.kml"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_name_io <- "silica_nodes.rds"

source('~/shared/rural_planner/sql/ar/infrastructure/exportDB.R')
source('~/shared/rural_planner/sql/ar/infrastructure/uploadDBSilica.R')

kml_file <- paste(input_path, file_name, sep='/')

unzip(paste(input_path_infrastructure,file_name_kmz, sep = "/"), exdir = input_path )



xml <- read_xml(kml_file)

Points_list <- xml_parent(xml_find_all(xml,"//d1:Point"))
ns<-"d1"

dfpoints <- lapply(Points_list,function(x){
  
                    data_frame( folder = xml_find_first(xml_parent(x),str_c(ns,":name"))%>%xml_text,
                                name = xml_find_first(x, str_c(ns, ":", "name")) %>% xml_text, 
                                description = xml_find_first(x, str_c(ns, ":", "description")) %>% xml_text, 
                                coordinates = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text,
                                longitude = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text
                                    %>% str_split(",")
                                    %>% sapply('[',1),
                                latitude = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text
                                    %>% str_split(",")
                                    %>% sapply('[',2),
                                wkt = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) 
                                    %>% xml_text 
                                    %>% {gsub(","," ",.)} 
                                    %>% paste0("POINT Z (",.,")")
                                )
                    
                  }) %>% bind_rows


##### Lineas

Lines_list <- xml_parent(xml_find_all(xml,"//d1:LineString"))

dflines <- lapply(Lines_list,function(x){
                
                  data_frame( folder = xml_find_first(xml_parent(x),str_c(ns,":name"))%>%xml_text,
                              name = xml_find_first(x, str_c(ns, ":", "name")) %>% xml_text,
                              description = xml_find_first(x, str_c(ns, ":", "description")) %>% xml_text, 
                              wkt = xml_find_first(x, str_c(ns, ":", str_c("LineString/", ns, ":coordinates"))) 
                                    %>% xml_text 
                                    %>% str_split("\\s+") 
                                    %>% unlist 
                                    %>% {gsub(","," ",.)} 
                                    %>% paste(collapse=",") 
                                    %>% substr(2,nchar(.)-1) 
                                    %>% paste0("LINESTRING Z (",.,")")
                              )
                  }) %>% bind_rows



silica_points_int <- dfpoints[,c("folder",
                                 "name",
                                 "description",
                                 "longitude",
                                 "latitude",
                                 "wkt")]


######################################################################################################################

#Latitude: Extract latitude, longitude 
silica_points_int$latitude <- as.numeric(silica_points_int$latitude)

#Longitude:
silica_points_int$longitude <- as.numeric(silica_points_int$longitude)

silica_points_int <- silica_points_int[unique(c(silica_points_int$latitude,silica_points_int$longitude)),]

#Tower height: as integer, default 0 m
silica_points_int$tower_height <- 0

#Owner:
silica_points_int$owner <- 'SILICA'

#Location detail: as char
silica_points_int$location_detail <- paste(silica_points_int$folder,silica_points_int$name,silica_points_int$description,sep=" - ") 

silica_points_int$location_detail <- gsub(" - NA","",silica_points_int$location_detail)

Encoding(silica_points_int$location_detail)<-"UTF-8"

#tech_2g, tech_3g, tech_4g:
silica_points_int$"tech_2g" <- FALSE
silica_points_int$"tech_3g" <- FALSE
silica_points_int$"tech_4g" <- FALSE


#Type:
silica_points_int$type <- NA
silica_points_int$type <- as.character(silica_points_int$type)

#Subtype: as character 
silica_points_int$subtype <- NA
silica_points_int$subtype <- as.character(silica_points_int$subtype)

#In Service: 
silica_points_int$in_service <- "AVAILABLE"

#Vendor: Unknown
silica_points_int$vendor <- NA
silica_points_int$vendor <- as.character(silica_points_int$vendor)

#Coverage area 2G, 3G and 4G
silica_points_int$coverage_area_2g <- NA
silica_points_int$coverage_area_2g <- as.character(silica_points_int$coverage_area_2g)

silica_points_int$coverage_area_3g <- NA
silica_points_int$coverage_area_3g <- as.character(silica_points_int$coverage_area_3g)

silica_points_int$coverage_area_4g <- NA
silica_points_int$coverage_area_4g <- as.character(silica_points_int$coverage_area_4g)


#fiber, radio, satellite: create from transport field
silica_points_int$fiber <- TRUE
silica_points_int$radio <- FALSE
silica_points_int$satellite <- FALSE

#satellite band in use:
silica_points_int$satellite_band_in_use <- NA
silica_points_int$satellite_band_in_use <- as.character(silica_points_int$satellite_band_in_use)

#radio_distance_km: no info on this
silica_points_int$radio_distance_km <- NA
silica_points_int$radio_distance_km <- as.numeric(silica_points_int$radio_distance_km)

#last_mile_bandwidth:
silica_points_int$last_mile_bandwidth <- NA
silica_points_int$last_mile_bandwidth <- as.character(silica_points_int$last_mile_bandwidth)

#Tower type:
silica_points_int$tower_type <- "INFRASTRUCTURE"

silica_points_int[((silica_points_int$tech_2g == TRUE)|(silica_points_int$tech_3g == TRUE)|(silica_points_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

silica_points_int[(((silica_points_int$fiber == TRUE)|(silica_points_int$radio == TRUE)|(silica_points_int$satellite == TRUE))&(silica_points_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

silica_points_int[(((silica_points_int$fiber == TRUE)|(silica_points_int$radio == TRUE)|(silica_points_int$satellite == TRUE))&(silica_points_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
silica_points_int$source_file <- file_name_kmz

#Source:
silica_points_int$source<- "SILICA"

#Internal ID:
silica_points_int$internal_id <- NA
silica_points_int$internal_id <- as.character(silica_points_int$internal_id)

silica_points_int$tx_3g <- FALSE
silica_points_int$tx_third_pty <- FALSE


silica_points <- silica_points_int[,c("latitude",
                                      "longitude", 
                                      "tower_height", 
                                      "owner", 
                                      "location_detail",
                                      "tower_type",
                                      
                                      "tech_2g", 
                                      "tech_3g", 
                                      "tech_4g", 
                                      "type", 
                                      "subtype", 
                                      "in_service",
                                      "vendor", 
                                      "coverage_area_2g",
                                      "coverage_area_3g",
                                      "coverage_area_4g",
                                      
                                      "fiber",
                                      "radio",
                                      "satellite",
                                      "tx_3g",
                                      "tx_third_pty",
                                      "satellite_band_in_use",
                                      "radio_distance_km",
                                      "last_mile_bandwidth",
                                      
                                      "source_file",
                                      "source",
                                      "internal_id"
)]

#Export the normalized output
saveRDS(silica_points, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, silica_points)


#EXPORT POINTS

exportDB(schema_dev, table_silica_points, silica_points)

#LINES
silica_lines_int <- dflines[,c("folder",
                                 "name",
                                 "description",
                                 "wkt")]

silica_lines_int$location_detail <- paste(silica_lines_int$folder,silica_lines_int$name,silica_lines_int$description,sep=" - ") 

silica_lines_int$location_detail <- gsub(" - NA","",silica_lines_int$location_detail)

Encoding(silica_lines_int$location_detail)<-"UTF-8"


silica_lines <- silica_lines_int[,c("location_detail",
                                      "wkt"
                                      )]

##Upload to database
uploadDBSilica(schema_dev, table_silica_lines, silica_lines)



