
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)

#VARIABLES
file_name <- "torres_ehas.xlsx"
sheet <- "torres_ehas_def"
skip <- 0

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "ehas.rds"


source('~/shared/rural_planner/sql/pe/infrastructure/exportDB_A.R')

#Load ehas nodes
ehas_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), sheet = sheet, skip = skip)

ehas_raw


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

ehas_int <- data.frame(ehas_raw$"Y",
                     ehas_raw$"X",
                     ehas_raw$"Name",
                     ehas_raw$"Name",
                     ehas_raw$"Name"
                    )

#Change names of the variables we already have
colnames(ehas_int) <- c("latitude", 
                      "longitude",
                      "location_detail",
                      
                      "internal_id",
                      "tower_name"
                      )

######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done

#Longitude: already done

#Tower height: ASSUMPTION: 30 meters by default and info from email coming from EHAS
ehas_int$tower_height <- 30
ehas_int[ehas_int$location_detail == 'C.S. Balsapuerto','tower_height'] <- 45
ehas_int[ehas_int$location_detail == 'C.S. Jeberos','tower_height'] <- 12
ehas_int[ehas_int$location_detail == 'P.S. Bellavista','tower_height'] <- 12
ehas_int[ehas_int$location_detail == 'PS Buena Vista','tower_height'] <- 12
ehas_int$tower_height <- as.integer(as.character(ehas_int$tower_height))

#Owner: all ehas
ehas_int$owner <- "EHAS"
ehas_int$owner <- as.character(ehas_int$owner)

#Location detail: as char
ehas_int$location_detail <- as.character(ehas_int$location_detail)

#tech_2g, tech_3g, tech_4g: No access in ehas (for now)
ehas_int$"tech_2g" <- FALSE
ehas_int$"tech_3g" <- FALSE
ehas_int$"tech_4g" <- FALSE

#Type: ASSUMPTION: EHAS is only towers with radios for now
ehas_int$type <- NA
ehas_int$type <- as.character(ehas_int$type)

#Subtype: does not apply
ehas_int$subtype <- NA
ehas_int$subtype <- as.character(ehas_int$subtype)

#In Service: ALL IN SERVICE. No info on this.
ehas_int$in_service <- "IN SERVICE"
ehas_int$in_service <- as.character(ehas_int$in_service)

#Vendor: Does not apply
ehas_int$vendor <- NA
ehas_int$vendor <- as.character(ehas_int$vendor)

#Coverage area 2G, 3G and 4G: No info
ehas_int$coverage_area_2g <- NA
ehas_int$coverage_area_2g <- as.character(ehas_int$coverage_area_2g)

ehas_int$coverage_area_3g <- NA
ehas_int$coverage_area_3g <- as.character(ehas_int$coverage_area_3g)

ehas_int$coverage_area_4g <- NA
ehas_int$coverage_area_4g <- as.character(ehas_int$coverage_area_4g)

#fiber, radio, satellite: Towers with radiolinks
ehas_int$fiber <- FALSE
ehas_int$radio <- TRUE
ehas_int$satellite <- FALSE

#satellite band in use: Does not apply
ehas_int$satellite_band_in_use <- NA
ehas_int$satellite_band_in_use <- as.character(ehas_int$satellite_band_in_use)

#radio_distance_km: Does not apply
ehas_int$radio_distance_km <- NA
ehas_int$radio_distance_km <- as.numeric(ehas_int$radio_distance_km)

#last_mile_bandwidth: Does not apply
ehas_int$last_mile_bandwidth <- NA
ehas_int$last_mile_bandwidth <- as.character(ehas_int$last_mile_bandwidth)

#Tower type:
ehas_int$tower_type <- "INFRASTRUCTURE"

ehas_int[((ehas_int$tech_2g == TRUE)|(ehas_int$tech_3g == TRUE)|(ehas_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

ehas_int[(((ehas_int$fiber == TRUE)|(ehas_int$radio == TRUE)|(ehas_int$satellite == TRUE))&(ehas_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

ehas_int[(((ehas_int$fiber == TRUE)|(ehas_int$radio == TRUE)|(ehas_int$satellite == TRUE))&(ehas_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
ehas_int$source_file <- file_name

# Source
ehas_int$source <- "EHAS"

#Internal ID:
ehas_int$internal_id <- as.character(ehas_int$internal_id)

# Tower name
ehas_int$tower_name <- as.character(ehas_int$tower_name)

# IPT perimeter: Does not apply
ehas_int$ipt_perimeter <- NA
ehas_int$ipt_perimeter <- as.character(ehas_int$ipt_perimeter)

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
ehas <- ehas_int[,c("latitude",
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
ehas
######################################################################################################################


#Export the normalized output
saveRDS(ehas, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, ehas)

#Set connection data
exportDB_A(schema_dev, table_ehas, ehas)

