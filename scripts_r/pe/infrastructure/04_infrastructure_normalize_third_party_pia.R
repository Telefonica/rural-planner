
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)


#VARIABLES
input_path <- "~/shared/rural_planner/data/pe/infrastructure"
file_name <- "EBCs por Medio de TX - Consolidado 2018_MAR.xlsx"
sheet <- "EnodeB-PIA"
skip <- 0

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "pia.rds"

source('~/shared/rural_planner/sql/pe/infrastructure/exportDB_A.R')


#Load pia nodes
pia_raw <- read_excel(paste(input_path,  file_name, sep = "/"), sheet = sheet, skip = skip)

pia_raw




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

pia_int <- data.frame(pia_raw$'...5',
                     pia_raw$COORDENADAS,
                     pia_raw$'CODIGO UNICO',
                     pia_raw$TORRE
      )

#Change names of the variables we already have
colnames(pia_int) <- c("latitude", 
                      "longitude",
                      "internal_id",
                      "tower_name"
                      )

######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done

#Longitude: already done

#Tower height: ASSUMPTION: 90 meters by default
pia_int$tower_height <- as.integer(90)

#Owner: all pia
pia_int$owner <- "PIA"
pia_int$owner <- as.character(pia_int$owner)

#Location detail: as char
pia_int$location_detail <- as.character(pia_int$tower_name)

#tech_2g, tech_3g, tech_4g: No access in pia (for now)
pia_int$"tech_2g" <- FALSE
pia_int$"tech_3g" <- FALSE
pia_int$"tech_4g" <- FALSE

#Type: ASSUMPTION: pia is only towers with radiolink for now
pia_int$type <- NA
pia_int$type <- as.character(pia_int$type)

#Subtype: does not apply
pia_int$subtype <- NA
pia_int$subtype <- as.character(pia_int$subtype)

#In Service: ALL IN SERVICE. No info on this.
pia_int$in_service <- "IN SERVICE"
pia_int$in_service <- as.character(pia_int$in_service)

#Vendor: Does not apply
pia_int$vendor <- NA
pia_int$vendor <- as.character(pia_int$vendor)

#Coverage area 2G, 3G and 4G: No info
pia_int$coverage_area_2g <- NA
pia_int$coverage_area_2g <- as.character(pia_int$coverage_area_2g)

pia_int$coverage_area_3g <- NA
pia_int$coverage_area_3g <- as.character(pia_int$coverage_area_3g)

pia_int$coverage_area_4g <- NA
pia_int$coverage_area_4g <- as.character(pia_int$coverage_area_4g)

#fiber, radio, satellite: Towers with fiber
pia_int$fiber <- FALSE
pia_int$radio <- TRUE
pia_int$satellite <- FALSE

#satellite band in use: Does not apply
pia_int$satellite_band_in_use <- NA
pia_int$satellite_band_in_use <- as.character(pia_int$satellite_band_in_use)

#radio_distance_km: Does not apply
pia_int$radio_distance_km <- NA
pia_int$radio_distance_km <- as.numeric(pia_int$radio_distance_km)

#last_mile_bandwidth: Does not apply
pia_int$last_mile_bandwidth <- NA
pia_int$last_mile_bandwidth <- as.character(pia_int$last_mile_bandwidth)

#Tower type:
pia_int$tower_type <- "INFRASTRUCTURE"

pia_int[((pia_int$tech_2g == TRUE)|(pia_int$tech_3g == TRUE)|(pia_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

pia_int[(((pia_int$fiber == TRUE)|(pia_int$radio == TRUE)|(pia_int$satellite == TRUE))&(pia_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

pia_int[(((pia_int$fiber == TRUE)|(pia_int$radio == TRUE)|(pia_int$satellite == TRUE))&(pia_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
pia_int$source_file <- file_name

#Source:
pia_int$source <- "PIA"

#Internal ID:
pia_int$internal_id <- as.character(pia_int$internal_id)

#Tower name
pia_int$tower_name <- as.character(pia_int$tower_name)

#IPT perimeter : Does not apply
pia_int$ipt_perimeter <- NA
pia_int$ipt_perimeter <- as.character(pia_int$ipt_perimeter)

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
pia <- pia_int[,c("latitude",
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
pia
######################################################################################################################



#Export the normalized output
saveRDS(pia, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, pia)

exportDB_A(schema_dev, table_pia, pia)

