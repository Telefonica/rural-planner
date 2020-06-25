
#LIBRARIES
library(RPostgreSQL)
library(stringr)
library(rgdal)
library("sf")
library(xml2)
library(tidyverse)


#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)


#VARIABLES


input_path <- "~/shared/rural_planner/data/pe/infrastructure/fiber planned"

file_name_kmz <-"Fibra óptica 2018 - 2019.kmz"

file_name <- "doc.kml"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "fiber_planned.rds"

source('~/shared/rural_planner/sql/pe/infrastructure/exportDB.R')

#Unzip kmz file to open get .kml file
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





fiber_points_int <- dfpoints[,c("folder",
                                 "name",
                                 "description",
                                 "longitude",
                                 "latitude",
                                 "wkt")]


######################################################################################################################

#Latitude: Extract latitude, longitude 
fiber_points_int$latitude <- as.numeric(fiber_points_int$latitude)

#Longitude:
fiber_points_int$longitude <- as.numeric(fiber_points_int$longitude)

fiber_points_int <- fiber_points_int[unique(c(fiber_points_int$latitude,fiber_points_int$longitude)),]

#Tower height: as integer, default 30 m
fiber_points_int$tower_height <- 0

#Owner:
fiber_points_int$owner <- 'TDP'

#Location detail: as char
fiber_points_int$location_detail <- paste(fiber_points_int$name,fiber_points_int$description,sep=" - ") 

fiber_points_int$location_detail <- gsub(" - NA","",fiber_points_int$location_detail)

Encoding(fiber_points_int$location_detail) <- "UTF-8"

#tech_2g, tech_3g, tech_4g:
fiber_points_int$"tech_2g" <- FALSE
fiber_points_int$"tech_3g" <- FALSE
fiber_points_int$"tech_4g" <- FALSE


#Type:
fiber_points_int$type <- NA
fiber_points_int$type <- as.character(fiber_points_int$type)

#Subtype: as character 
fiber_points_int$subtype <- NA
fiber_points_int$subtype <- as.character(fiber_points_int$subtype)

#In Service: 
fiber_points_int$in_service <- "PLANNED"

#Vendor: Unknown
fiber_points_int$vendor <- NA
fiber_points_int$vendor <- as.character(fiber_points_int$vendor)

#Coverage area 2G, 3G and 4G
fiber_points_int$coverage_area_2g <- NA
fiber_points_int$coverage_area_2g <- as.character(fiber_points_int$coverage_area_2g)

fiber_points_int$coverage_area_3g <- NA
fiber_points_int$coverage_area_3g <- as.character(fiber_points_int$coverage_area_3g)

fiber_points_int$coverage_area_4g <- NA
fiber_points_int$coverage_area_4g <- as.character(fiber_points_int$coverage_area_4g)


#fiber, radio, satellite: create from transport field
fiber_points_int$fiber <- TRUE
fiber_points_int$radio <- FALSE
fiber_points_int$satellite <- FALSE

#satellite band in use:
fiber_points_int$satellite_band_in_use <- NA
fiber_points_int$satellite_band_in_use <- as.character(fiber_points_int$satellite_band_in_use)

#radio_distance_km: no info on this
fiber_points_int$radio_distance_km <- NA
fiber_points_int$radio_distance_km <- as.numeric(fiber_points_int$radio_distance_km)

#last_mile_bandwidth:
fiber_points_int$last_mile_bandwidth <- NA
fiber_points_int$last_mile_bandwidth <- as.character(fiber_points_int$last_mile_bandwidth)

#Tower type:
fiber_points_int$tower_type <- "INFRASTRUCTURE"

fiber_points_int[((fiber_points_int$tech_2g == TRUE)|(fiber_points_int$tech_3g == TRUE)|(fiber_points_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

fiber_points_int[(((fiber_points_int$fiber == TRUE)|(fiber_points_int$radio == TRUE)|(fiber_points_int$satellite == TRUE))&(fiber_points_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

fiber_points_int[(((fiber_points_int$fiber == TRUE)|(fiber_points_int$radio == TRUE)|(fiber_points_int$satellite == TRUE))&(fiber_points_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
fiber_points_int$source_file <- file_name_kmz

#Source:
fiber_points_int$source<- "FIBER_PLANNED"

#Internal ID:
fiber_points_int$internal_id <- NA
fiber_points_int$internal_id <- as.character(fiber_points_int$internal_id)

## IPT Perimeter: doest not apply
fiber_points_int$ipt_perimeter <- "NO IPT"
fiber_points_int$ipt_perimeter <- as.character(fiber_points_int$ipt_perimeter)

## Tower name
fiber_points_int$tower_name <- fiber_points_int$internal_id
fiber_points_int$tower_name <- as.character(fiber_points_int$tower_name)


fiber_points <- fiber_points_int[,c("latitude",
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
saveRDS(fiber_points, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, fiber_points)

#Upload points to database structured as infrastructure  
exportDB(schema_dev, table_points, fiber_points)




