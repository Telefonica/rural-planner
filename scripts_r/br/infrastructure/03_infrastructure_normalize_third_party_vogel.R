
#LIBRARIES
library(RPostgreSQL)
library(stringr)
library(rgdal)
library("sf")
library(xml2)
library(pbapply)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_br'
source(config_path)

#VARIABLES
#Unzip kmz file to open get .kml file
kml_file <-"KMZ VOGEL 2018.kml"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_lines <- "vogel_lines.rds"

source('~/shared/rural_planner/sql/br/infrastructure/03_updateDBTPVogel.R')

## Read KML file
xml <- read_xml(paste(input_path_infrastructure,kml_file, sep="/"))

ns<-"d1"

Lines_list <- xml_parent(xml_find_all(xml,"//d1:LineString"))

dflines <- pblapply(Lines_list,function(x){
                  data_frame( folder = xml_find_first(xml_parent(x),str_c(ns,":name"))%>%xml_text,
                              name = xml_find_first(x, str_c(ns, ":", "name")) %>% xml_text,
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


vogel_lines_int <- dflines[,c("folder",
                                 "name",
                                 "wkt")]

vogel_lines_int$name[vogel_lines_int$name=="Objetos Salvos do MapInfo"] <- NA

vogel_lines_int$location_detail <- paste(vogel_lines_int$folder,vogel_lines_int$name,sep=" - ") 

vogel_lines_int$location_detail <- gsub(" - NA","",vogel_lines_int$location_detail)

Encoding(vogel_lines_int$location_detail)<-"UTF-8"


vogel_lines <- vogel_lines_int[,c("location_detail",
                                      "wkt"
                                      )]


## Latitude and longitude: does not apply
vogel_lines$latitude <- as.numeric(0)

#Longitude:
vogel_lines$longitude <- as.numeric(0)

#Tower height: unknown, assumed 0m
vogel_lines$tower_height <- as.integer(0)

#Owner:
vogel_lines$owner <- as.character("VOGEL")


#tech_2g, tech_3g, tech_4g: does not apply
vogel_lines$"tech_2g" <- FALSE
vogel_lines$"tech_3g" <- FALSE
vogel_lines$"tech_4g" <- FALSE

vogel_lines$coverage_area_2g <- as.character(NA)
vogel_lines$coverage_area_3g <- as.character(NA)
vogel_lines$coverage_area_4g <- as.character(NA)

#Type:
vogel_lines$type <- "FO TRACE"

#Subtype: as character 
vogel_lines$subtype <- as.character(NA)
Encoding(vogel_lines$subtype) <- "UTF-8"

#Location detail: as char
vogel_lines$location_detail <- as.character(vogel_lines$location_detail)
Encoding(vogel_lines$location_detail) <- "UTF-8"

#In Service: 
vogel_lines$in_service <- "IN SERVICE"

#Vendor: Unknown
vogel_lines$vendor <- NA
vogel_lines$vendor <- as.character(vogel_lines$vendor)
    
#fiber, radio, satellite: all FO nodes/ traces
vogel_lines$fiber <- TRUE
vogel_lines$radio <- FALSE
vogel_lines$satellite <- FALSE

#satellite band in use:
vogel_lines$satellite_band_in_use <- NA
vogel_lines$satellite_band_in_use <- as.character(vogel_lines$satellite_band_in_use)

#radio_distance_km: no info on this
vogel_lines$radio_distance_km <- NA
vogel_lines$radio_distance_km <- as.numeric(vogel_lines$radio_distance_km)

#last_mile_bandwidth:
vogel_lines$last_mile_bandwidth <- NA
vogel_lines$last_mile_bandwidth <- as.character(vogel_lines$last_mile_bandwidth)

#Tower type:
vogel_lines$tower_type <- "INFRASTRUCTURE"

vogel_lines[((vogel_lines$tech_2g == TRUE)|(vogel_lines$tech_3g == TRUE)|(vogel_lines$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

vogel_lines[(((vogel_lines$fiber == TRUE)|(vogel_lines$radio == TRUE)|(vogel_lines$satellite == TRUE))&(vogel_lines$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

vogel_lines[(((vogel_lines$fiber == TRUE)|(vogel_lines$radio == TRUE)|(vogel_lines$satellite == TRUE))&(vogel_lines$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
vogel_lines$source_file <- as.character(kml_file)

#Source:
vogel_lines$source<-  as.character("VOGEL_LINES")

#Internal ID:
vogel_lines$internal_id <- as.character(vogel_lines$location_detail)

#Tower_name:
vogel_lines$tower_name <- as.character(vogel_lines$location_detail)
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
vogel_lines <- vogel_lines[,c("latitude",
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
                        
                        "wkt"
                        )]
######################################################################################################################

#Export the normalized output
saveRDS(vogel_lines, paste(output_path, file_name_lines, sep = "/"))

test_lines <- readRDS(paste(output_path, file_name_lines, sep = "/"))
identical(test_lines, vogel_lines)

#EXPORT
updateDBTPVogel(schema_dev, table_lines_vogel, vogel_lines)

