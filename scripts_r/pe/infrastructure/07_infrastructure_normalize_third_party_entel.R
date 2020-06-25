
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(xml2)
library(pbapply)
library(tidyverse)
library(dplyr)


#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)


#VARIABLES
file_name <- "Celdas competencia.kmz"

unzip_path <- "~/shared/rural_planner/data/pe/infrastructure/entel"

file_name_kml <-"doc.kml"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "entel.rds"


source('~/shared/rural_planner/sql/pe/infrastructure/exportDB_B.R')


#Unzip KMZ file
kml_file <- paste(unzip_path, file_name_kml, sep='/')

unzip(paste(input_path_infrastructure,file_name, sep = "/"), exdir = unzip_path )


######################################################################################################################
#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail,  tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor, coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)

#The ID will be that of the row from the data frame
######################################################################################################################


xml <- read_xml(kml_file)

Points_list <- xml_find_all(xml, "//*[d1:name='Entel 2017 - 2T']/d1:Placemark")

ns<-"d1"

entel_int1 <- pblapply(Points_list[1:2000],function(x){
  
                    data_frame(name = xml_find_first(x, str_c(ns, ":", "name")) %>% xml_text, 
                                description = xml_find_first(x, str_c(ns, ":", "description")) %>% xml_text, 
                                coordinates = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text,
                                longitude = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text
                                    %>% str_split(",")
                                    %>% sapply('[',1),
                                latitude = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text
                                    %>% str_split(",")
                                    %>% sapply('[',2)
                                )
                  }) %>% bind_rows

entel_int2 <- pblapply(Points_list[2001:4552],function(x){
  
                    data_frame(name = xml_find_first(x, str_c(ns, ":", "name")) %>% xml_text, 
                                description = xml_find_first(x, str_c(ns, ":", "description")) %>% xml_text, 
                                coordinates = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text,
                                longitude = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text
                                    %>% str_split(",")
                                    %>% sapply('[',1),
                                latitude = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text
                                    %>% str_split(",")
                                    %>% sapply('[',2)
                                )
                  }) %>% bind_rows

entel_int <- rbind(entel_int1,entel_int2)
rm(entel_int1,entel_int2)

######################################################################################################################

#Select useful columns from raw input





#Change names of the variables we already have
colnames(entel_int) <- c("tower_name", 
                      "location_detail",
                      "coordinates",
                      "longitude",
                      "latitude")
                    

######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done
entel_int$latitude <- as.numeric(entel_int$latitude)

#Longitude: already done
entel_int$longitude <- as.numeric(entel_int$longitude)

#Tower height: as integer, if empty 15 m
entel_int$tower_height <- 15

#Owner: 
entel_int$owner <- "ENTEL"

#Location detail: as character
entel_int$location_detail <- as.character(entel_int$location_detail)

#tech_2g, tech_3g, tech_4g: no info
entel_int$"tech_2g" <- F
entel_int$"tech_3g" <- F
entel_int$"tech_4g" <- F

#Type: 
entel_int$type <- NA
entel_int$type <- as.character(entel_int$type)

#Subtype: as character
entel_int$subtype <- NA
entel_int$subtype <- as.character(entel_int$subtype)

#In Service: IN SERVICE. From june onwards planned.
entel_int$in_service <- "IN SERVICE"

#Vendor: Does not apply
entel_int$vendor <- NA
entel_int$vendor <- as.character(entel_int$vendor)

#Coverage area 2G, 3G and 4G
entel_int$coverage_area_2g <- NA
entel_int$coverage_area_2g <- as.character(entel_int$coverage_area_2g)

entel_int$coverage_area_3g <- NA
entel_int$coverage_area_3g <- as.character(entel_int$coverage_area_3g)

entel_int$coverage_area_4g <- NA
entel_int$coverage_area_4g <- as.character(entel_int$coverage_area_4g)

#fiber, radio, satellite: No info
entel_int$fiber <- FALSE
entel_int$radio <- FALSE
entel_int$satellite <- FALSE

#satellite band in use: Does not apply
entel_int$satellite_band_in_use <- NA
entel_int$satellite_band_in_use <- as.character(entel_int$satellite_band_in_use)

#radio_distance_km: no info on this
entel_int$radio_distance_km <- NA
entel_int$radio_distance_km <- as.numeric(entel_int$radio_distance_km)

#last_mile_bandwidth: no info on this
entel_int$last_mile_bandwidth <- NA
entel_int$last_mile_bandwidth <- as.character(entel_int$last_mile_bandwidth)

#Tower type:
entel_int$tower_type <- "INFRASTRUCTURE"

entel_int[((entel_int$tech_2g == TRUE)|(entel_int$tech_3g == TRUE)|(entel_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

entel_int[(((entel_int$fiber == TRUE)|(entel_int$radio == TRUE)|(entel_int$satellite == TRUE))&(entel_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

entel_int[(((entel_int$fiber == TRUE)|(entel_int$radio == TRUE)|(entel_int$satellite == TRUE))&(entel_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
entel_int$source_file <- file_name

#Source:
entel_int$source <- "ENTEL"

#Internal ID:
entel_int$internal_id <- entel_int$location_detail 
entel_int$internal_id <- as.character(entel_int$internal_id)

#Tower name:
entel_int$tower_name <- as.character(entel_int$tower_name)

# IPT perimeter: NO IPT
entel_int$ipt_perimeter <- NA
entel_int$ipt_perimeter <- as.character(entel_int$ipt_perimeter)

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
entel <- entel_int[,c("latitude",
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

######################################################################################################################


#Remove duplicates
entel <- entel %>% distinct(latitude,longitude, .keep_all=T)


#Export the normalized output
saveRDS(entel, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, entel)

exportDB_B(schema_dev, table_entel, entel)

