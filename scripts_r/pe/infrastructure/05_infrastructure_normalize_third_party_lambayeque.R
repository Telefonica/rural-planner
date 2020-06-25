
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)

#VARIABLES
file_name <- "Nodos Lambayeque.xlsx"
sheet <- "Hoja1"
skip <- 0


output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "lambayeque.rds"


source('~/shared/rural_planner/sql/pe/infrastructure/exportDB_A.R')

#Load lambayeque nodes
lambayeque_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), sheet = sheet, skip = skip)

lambayeque_raw



######################################################################################################################
#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail,  tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor, coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)

#The ID will be that of the row from the data frame
######################################################################################################################


######################################################################################################################

#Select useful columns from raw input

lambayeque_int <- data.frame(lambayeque_raw$"Latitud",
                     lambayeque_raw$"Longitud",
                     lambayeque_raw$`Altura Torre`,
                     lambayeque_raw$Direccion,
                     
                     lambayeque_raw$`Nombre de Nodo`,
                     lambayeque_raw$`Nombre de Nodo`
      )

#Change names of the variables we already have
colnames(lambayeque_int) <- c("latitude", 
                      "longitude",
                      "tower_height",
                      "location_detail",
                      
                      "internal_id",
                      "tower_name"
                      )

######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done

#Longitude: already done

#Tower height: ASSUMPTION: 30 meters by default and info from email coming from lambayeque
lambayeque_int$tower_height <- as.integer(as.character(lambayeque_int$tower_height))

#Owner: all lambayeque
lambayeque_int$owner <- "LAMBAYEQUE"
lambayeque_int$owner <- as.character(lambayeque_int$owner)

#Location detail: as char
lambayeque_int$location_detail <- as.character(lambayeque_int$location_detail)

#tech_2g, tech_3g, tech_4g: No access in lambayeque (for now)
lambayeque_int$"tech_2g" <- FALSE
lambayeque_int$"tech_3g" <- FALSE
lambayeque_int$"tech_4g" <- FALSE

#Type: ASSUMPTION: lambayeque is only towers with fiber for now
lambayeque_int$type <- NA
lambayeque_int$type <- as.character(lambayeque_int$type)

#Subtype: does not apply
lambayeque_int$subtype <- NA
lambayeque_int$subtype <- as.character(lambayeque_int$subtype)

#In Service: ALL IN SERVICE. No info on this.
lambayeque_int$in_service <- "IN SERVICE"
lambayeque_int$in_service <- as.character(lambayeque_int$in_service)

#Vendor: Does not apply
lambayeque_int$vendor <- NA
lambayeque_int$vendor <- as.character(lambayeque_int$vendor)

#Coverage area 2G, 3G and 4G: No info
lambayeque_int$coverage_area_2g <- NA
lambayeque_int$coverage_area_2g <- as.character(lambayeque_int$coverage_area_2g)

lambayeque_int$coverage_area_3g <- NA
lambayeque_int$coverage_area_3g <- as.character(lambayeque_int$coverage_area_3g)

lambayeque_int$coverage_area_4g <- NA
lambayeque_int$coverage_area_4g <- as.character(lambayeque_int$coverage_area_4g)

#fiber, radio, satellite: Towers with fiber
lambayeque_int$fiber <- FALSE
lambayeque_int$radio <- TRUE
lambayeque_int$satellite <- FALSE

#satellite band in use: Does not apply
lambayeque_int$satellite_band_in_use <- NA
lambayeque_int$satellite_band_in_use <- as.character(lambayeque_int$satellite_band_in_use)

#radio_distance_km: Does not apply
lambayeque_int$radio_distance_km <- NA
lambayeque_int$radio_distance_km <- as.numeric(lambayeque_int$radio_distance_km)

#last_mile_bandwidth: Does not apply
lambayeque_int$last_mile_bandwidth <- NA
lambayeque_int$last_mile_bandwidth <- as.character(lambayeque_int$last_mile_bandwidth)

#Tower type:
lambayeque_int$tower_type <- "INFRASTRUCTURE"

lambayeque_int[((lambayeque_int$tech_2g == TRUE)|(lambayeque_int$tech_3g == TRUE)|(lambayeque_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

lambayeque_int[(((lambayeque_int$fiber == TRUE)|(lambayeque_int$radio == TRUE)|(lambayeque_int$satellite == TRUE))&(lambayeque_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

lambayeque_int[(((lambayeque_int$fiber == TRUE)|(lambayeque_int$radio == TRUE)|(lambayeque_int$satellite == TRUE))&(lambayeque_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
lambayeque_int$source_file <- file_name

# Source:
lambayeque_int$source <- "LAMBAYEQUE"

#Internal ID:
lambayeque_int$internal_id <- as.character(lambayeque_int$internal_id)

#Tower name:
lambayeque_int$tower_name <- as.character(lambayeque_int$tower_name)

#IPT Perimeter: Does not apply
lambayeque_int$ipt_perimeter <- NA
lambayeque_int$ipt_perimeter <- as.character(lambayeque_int$ipt_perimeter)

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
lambayeque <- lambayeque_int[,c("latitude",
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
lambayeque
######################################################################################################################



#Export the normalized output
saveRDS(lambayeque, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, lambayeque)

exportDB_A(schema_dev, table_lambayeque, lambayeque)

