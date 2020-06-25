
#LIBRARIES
library(RPostgreSQL)
library(stringr)
library(rgdal)
library("sf")
library(xml2)
library(tidyverse)
library(dplyr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)


#VARIABLES
input_path <- "~/shared/rural_planner/data/pe/infrastructure/Red claro"

file_name_kmz <-"Interes Telefonica.kmz"

file_name_kml <- "doc.kml"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_name <- "claro_nodes.rds"


source('~/shared/rural_planner/sql/pe/infrastructure/exportClaroSitesFiber.R')
source('~/shared/rural_planner/sql/pe/infrastructure/exportPeClaroFiber.R')

#Extract kmz file to open get .kml file
kml_file <- paste(input_path, file_name_kml, sep='/')

unzip(paste(input_path,file_name_kmz, sep = "/"), exdir = input_path )


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



claro_points_int <- dfpoints[,c("folder",
                                 "name",
                                 "description",
                                 "longitude",
                                 "latitude",
                                 "wkt")]


######################################################################################################################

#Latitude: Extract latitude, longitude 
claro_points_int$latitude <- as.numeric(claro_points_int$latitude)

#Longitude:
claro_points_int$longitude <- as.numeric(claro_points_int$longitude)

#Tower height: as integer, default 30 m
claro_points_int$tower_height <- 0

#Owner:
claro_points_int$owner <- 'CLARO'

#Location detail: as char
claro_points_int$location_detail <- paste(claro_points_int$folder,claro_points_int$name,claro_points_int$description,sep=" - ") 

claro_points_int$location_detail <- gsub(" - NA","",claro_points_int$location_detail)

Encoding(claro_points_int$location_detail) <- "UTF-8"

#tech_2g, tech_3g, tech_4g:
claro_points_int$"tech_2g" <- FALSE
claro_points_int$"tech_3g" <- FALSE
claro_points_int$"tech_4g" <- FALSE

#Type:
claro_points_int$type <- NA
claro_points_int$type <- as.character(claro_points_int$type)

#Subtype: as character 
claro_points_int$subtype <- NA
claro_points_int$subtype <- as.character(claro_points_int$subtype)

#In Service: 
claro_points_int$in_service <- "IN SERVICE"

#Vendor: Unknown
claro_points_int$vendor <- NA
claro_points_int$vendor <- as.character(claro_points_int$vendor)

#Coverage area 2G, 3G and 4G
claro_points_int$coverage_area_2g <- NA
claro_points_int$coverage_area_2g <- as.character(claro_points_int$coverage_area_2g)

claro_points_int$coverage_area_3g <- NA
claro_points_int$coverage_area_3g <- as.character(claro_points_int$coverage_area_3g)

claro_points_int$coverage_area_4g <- NA
claro_points_int$coverage_area_4g <- as.character(claro_points_int$coverage_area_4g)

#fiber, radio, satellite: create from transport field
claro_points_int$fiber <- TRUE
claro_points_int$radio <- FALSE
claro_points_int$satellite <- FALSE

#satellite band in use:
claro_points_int$satellite_band_in_use <- NA
claro_points_int$satellite_band_in_use <- as.character(claro_points_int$satellite_band_in_use)

#radio_distance_km: no info on this
claro_points_int$radio_distance_km <- NA
claro_points_int$radio_distance_km <- as.numeric(claro_points_int$radio_distance_km)

#last_mile_bandwidth:
claro_points_int$last_mile_bandwidth <- NA
claro_points_int$last_mile_bandwidth <- as.character(claro_points_int$last_mile_bandwidth)

#Tower type:
claro_points_int$tower_type <- "INFRASTRUCTURE"

claro_points_int[((claro_points_int$tech_2g == TRUE)|(claro_points_int$tech_3g == TRUE)|(claro_points_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

claro_points_int[(((claro_points_int$fiber == TRUE)|(claro_points_int$radio == TRUE)|(claro_points_int$satellite == TRUE))&(claro_points_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

claro_points_int[(((claro_points_int$fiber == TRUE)|(claro_points_int$radio == TRUE)|(claro_points_int$satellite == TRUE))&(claro_points_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
claro_points_int$source_file <- file_name_kmz

#Source:
claro_points_int$source<- "CLARO FIBER"

#Internal ID:
claro_points_int$internal_id <- claro_points_int$name
claro_points_int$internal_id <- as.character(claro_points_int$internal_id)

#Tower name
claro_points_int$tower_name <- claro_points_int$internal_id

#IPT perimeter
claro_points_int$ipt_perimeter <- NA
claro_points_int$ipt_perimeter <- as.character(claro_points_int$ipt_perimeter)

#Remove sites with duplicated latitude and longitude
claro_points_int <- claro_points_int %>% distinct(latitude, longitude, .keep_all = TRUE)

claro_points <- claro_points_int[,c("latitude",
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
                                      "satellite_band_in_use",
                                      "radio_distance_km",
                                      "last_mile_bandwidth",
                                      
                                      "source_file",
                                      "source",
                                      "internal_id",
                                      "tower_name",
                                      "ipt_perimeter"
                                      )]



#Export the normalized output
saveRDS(claro_points, paste(output_path, file_name, sep = "/"))

test <- readRDS(paste(output_path, file_name, sep = "/"))
identical(test, claro_points)

exportClaroSitesFiber(schema_dev, table_points_claro, claro_points)

claro_lines_int <- dflines[,c("folder",
                                 "name",
                                 "description",
                                 "wkt")]

claro_lines_int$location_detail <- paste(claro_lines_int$folder,claro_lines_int$name,claro_lines_int$description,sep=" - ") 

claro_lines_int$location_detail <- gsub(" - NA","",claro_lines_int$location_detail)

Encoding(claro_lines_int$location_detail)<-"UTF-8"


claro_lines <- claro_lines_int[,c("location_detail",
                                      "wkt"
                                      )]

##Upload to database
exportPeClaroFiber(schema_dev, table_lines_claro, claro_lines)



