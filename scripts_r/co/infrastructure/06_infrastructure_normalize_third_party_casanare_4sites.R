#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(XLConnect)
library(XLConnectJars)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

### VARIABLES ###
file_name_main <- "Casanare_4sites.xlsx"
sheet <- 1
skip <- 0

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "casanare.rds"


source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')


#Load Claro infrastructure info
casanare_raw <- read_excel(paste(input_path_infrastructure, file_name_main, sep = "/"), sheet = sheet, skip = skip)

######################################################################################################################
#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail, tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor, coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)

#The ID will be that of the row from the data frame
######################################################################################################################


######################################################################################################################

#Select useful columns from casanare's 4 sites raw input

casanare_int <- data.frame(casanare_raw$'Locación',
                           casanare_raw$Latitud,
                           casanare_raw$Longitud,
                           casanare_raw$Torre,
                           stringsAsFactors = FALSE
)


#Change names of the variables we already have from casanare's 4 sites raw

colnames(casanare_int) <- c("location_detail",
                       "latitude",
                       "longitude",
                       "tower_height"
)


######################################################################################################################

######################################################################################################################

#Fill casanare_int with the rest of the fields and reshape where necessary

#Location_detail to upper case
casanare_int$location_detail <- toupper(casanare_int$location_detail)


#Longitude:

casanare_int$longitude <- as.numeric(casanare_int$longitude)

#Latitude:

casanare_int$latitude <- as.numeric(casanare_int$latitude)

#Tower height:


casanare_int$tower_height <- as.numeric(casanare_int$tower_height)


#Tower name
casanare_int$tower_name <- casanare_int$location_detail

#Owner to upper case
casanare_int$owner <- NA
casanare_int$owner <- as.character(casanare_int$owner)

#Tech 2G, 3G, 4G: no info
casanare_int$tech_2g <- FALSE
casanare_int$tech_3g <- FALSE
casanare_int$tech_4g <- FALSE

#Type to upper case
casanare_int$type <- NA
casanare_int$type <- as.character(casanare_int$type)

#Subtype
casanare_int$subtype <- NA
casanare_int$subtype <- as.character(casanare_int$subtype)

#In Service: ALL IN SERVICE. No info on this.
casanare_int$in_service <- "IN SERVICE"
casanare_int$in_service <- as.character(casanare_int$in_service)

#Vendor: Does not apply
casanare_int$vendor <- NA
casanare_int$vendor <- as.character(casanare_int$vendor)

#Coverage area 2G, 3G and 4G: no info
casanare_int$coverage_radius <- as.numeric(as.character(casanare_int$tower_height))/10

casanare_int$coverage_area_2g <- NA
casanare_int$coverage_area_2g <- as.character(casanare_int$coverage_area_2g)

casanare_int$coverage_area_3g <- NA
casanare_int$coverage_area_3g <- as.character(casanare_int$coverage_area_3g)

casanare_int$coverage_area_4g <- NA
casanare_int$coverage_area_4g <- as.character(casanare_int$coverage_area_4g)

#fiber, radio, satellite: No info
casanare_int$fiber <- FALSE
casanare_int$radio <- FALSE
casanare_int$satellite <- FALSE

#satellite band in use: Does not apply
casanare_int$satellite_band_in_use <- NA
casanare_int$satellite_band_in_use <- as.character(casanare_int$satellite_band_in_use)

#radio_distance_km: Does not apply
casanare_int$radio_distance_km <- NA
casanare_int$radio_distance_km <- as.numeric(casanare_int$radio_distance_km)

#last_mile_bandwidth: Does not apply
casanare_int$last_mile_bandwidth <- NA
casanare_int$last_mile_bandwidth <- as.character(casanare_int$last_mile_bandwidth)

#Tower type: No information for now
casanare_int$tower_type <- "INFRASTRUCTURE"

#casanare_int[((casanare_int$tech_2g == TRUE)|(casanare_int$tech_3g == TRUE)|(casanare_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

#casanare_int[(((casanare_int$fiber == TRUE)|(casanare_int$radio == TRUE)|(casanare_int$satellite == TRUE))&(casanare_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

#casanare_int[(((casanare_int$fiber == TRUE)|(casanare_int$radio == TRUE)|(casanare_int$satellite == TRUE))&(casanare_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
casanare_int$source_file <- file_name_main

#Source:
casanare_int$source <- "POZOS_PETROLEROS"

#Internal ID:
casanare_int$internal_id <- NA
casanare_int$internal_id <- as.character(casanare_int$location_detail)

#IPT perimeter : Does not apply
casanare_int$ipt_perimeter <- NA


######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
casanare <- casanare_int[,c("latitude",
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


#Export the normalized output
saveRDS(casanare, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <-  readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, casanare)

#Export to DB
exportDB_Infrastructure(schema_dev, table_casanare, casanare)

