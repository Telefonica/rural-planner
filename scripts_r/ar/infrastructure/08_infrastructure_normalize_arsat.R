
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_ar'
source(config_path)

#VARIABLES
file_name <- "ARSAT_PuntosdeconexionalPlanFederaldeInternet_ENSERVICIO.csv"
file_name_2 <- "ARSAT_PuntosdeconexionalPlanFederaldeInternet_ENSERVICIO.xlsx"
file_name_3 <- "ARSAT_FuturospuntosdeconexionalPlanFederaldeInternet_PLANIFICADO.xlsx"
file_name_4 <- "arsat_missing.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_name_io <- "arsat.rds"

source('~/shared/rural_planner/sql/ar/infrastructure/exportDB.R')


#Load arsat infra
arsat_raw <- read.csv(paste(input_path_infrastructure,  file_name, sep = "/"))

arsat_old_1 <- read_excel(paste(input_path_infrastructure,  file_name_2, sep = "/"))
arsat_old_2 <- read_excel(paste(input_path_infrastructure,  file_name_3, sep = "/"))
arsat_old_3 <- read_excel(paste(input_path_infrastructure,  file_name_4, sep = "/"))

arsat_locations <- rbind(arsat_old_1[,c("ID Sitio",
                                         "Latitud",
                                         "Longitud")], 
                         arsat_old_2[,c("ID Sitio",
                                         "Latitud",
                                         "Longitud")], 
                         arsat_old_3[,c("Id Sitio",
                                         "Latitud",
                                         "Longitud")] %>% rename("ID Sitio" = "Id Sitio")
                         )

arsat_raw <- merge(arsat_raw, arsat_locations, by.x="ID.Sitio", by.y="ID Sitio", all.x=T)

arsat_raw




######################################################################################################################
#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail, tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor, coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)

#The ID will be that of the row from the data frame
######################################################################################################################


######################################################################################################################

#Select useful columns from raw input
arsat_int <- data.frame(arsat_raw$Latitud,
                        arsat_raw$Longitud,
                      arsat_raw$ID.Sitio,
                     arsat_raw$Traza,
                     arsat_raw$Sub.Traza,
 
                     arsat_raw$Estado
                     )

#Change names of the variables we already have
colnames(arsat_int) <- c("latitude",
                         "longitude",
                        "internal_id", 
                      "location_detail",
                      "location_detail_2",
                      
                      "status"
                      )

rownames(arsat_int) <- 1:nrow(arsat_int)
######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude:
arsat_int$latitude <- as.numeric(as.character(arsat_int$latitude))

#Longitude:
arsat_int$longitude <- as.numeric(as.character(arsat_int$longitude))

#Tower height: as integer
arsat_int$tower_height <- 0
arsat_int$tower_height <- as.integer(as.character(arsat_int$tower_height))

#Owner:
arsat_int$owner <- "ARSAT"

#Location detail: as char
arsat_int$location_detail <- as.character(arsat_int$location_detail)

#tech_2g, tech_3g, tech_4g:
arsat_int$"tech_2g" <- FALSE
arsat_int$"tech_3g" <- FALSE
arsat_int$"tech_4g" <- FALSE

#Type:
arsat_int$type <- NA
arsat_int$type <- as.character(arsat_int$type)


#Subtype: as character 
arsat_int$subtype <- NA
arsat_int$subtype <- as.character(arsat_int$subtype)

#In Service: 
arsat_int$in_service <- "IN SERVICE"
arsat_int[arsat_int$status == "EN PLANIFICACION", 'in_service'] <- "PLANNED"

#Vendor: Unknown
arsat_int$vendor <- NA
arsat_int$vendor <- as.character(arsat_int$vendor)

#Coverage area 2G, 3G and 4G
arsat_int$coverage_area_2g <- NA
arsat_int$coverage_area_2g <- as.character(arsat_int$coverage_area_2g)

arsat_int$coverage_area_3g <- NA
arsat_int$coverage_area_3g <- as.character(arsat_int$coverage_area_3g)

arsat_int$coverage_area_4g <- NA
arsat_int$coverage_area_4g <- as.character(arsat_int$coverage_area_4g)


#fiber, radio, satellite: ALL FIBER NODES
arsat_int$fiber <- TRUE
arsat_int$radio <- FALSE
arsat_int$satellite <- FALSE

arsat_int$tx_3g <- FALSE
arsat_int$tx_third_pty <- FALSE

#satellite band in use:
arsat_int$satellite_band_in_use <- NA
arsat_int$satellite_band_in_use <- as.character(arsat_int$satellite_band_in_use)

#radio_distance_km: no info on this
arsat_int$radio_distance_km <- NA
arsat_int$radio_distance_km <- as.numeric(arsat_int$radio_distance_km)

#last_mile_bandwidth:
arsat_int$last_mile_bandwidth <- NA
arsat_int$last_mile_bandwidth <- as.character(arsat_int$last_mile_bandwidth)

#Tower type:
arsat_int$tower_type <- "INFRASTRUCTURE"

arsat_int[((arsat_int$tech_2g == TRUE)|(arsat_int$tech_3g == TRUE)|(arsat_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

arsat_int[(((arsat_int$fiber == TRUE)|(arsat_int$radio == TRUE)|(arsat_int$satellite == TRUE))&(arsat_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

arsat_int[(((arsat_int$fiber == TRUE)|(arsat_int$radio == TRUE)|(arsat_int$satellite == TRUE))&(arsat_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
arsat_int$source_file <- file_name

#Source:
arsat_int$source <- "ARSAT"

#Internal ID:
arsat_int$internal_id <- as.character(arsat_int$internal_id)
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
arsat <- arsat_int[,c("latitude",
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
arsat
######################################################################################################################

  

#Export the normalized output
saveRDS(arsat, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, arsat)

exportDB(schema_dev, table_arsat, arsat)
