
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_ar'
source(config_path)

#VARIABLES
#Load auxiliary functions
source('~/shared/rural_planner/functions/coverage_area.R')


file_name <- "Sitios_Celda_PERSONAL.xlsx"
sheet <- "Sitios_Personal"
skip <- 0

output_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_name_io <- "personal.rds"

source('~/shared/rural_planner/sql/ar/infrastructure/exportDB.R')
source('~/shared/rural_planner/sql/ar/infrastructure/test.R')

#LOAD INPUTS
personal_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), sheet = sheet, skip = skip)

#We keep only one cell per site
personal_raw <- personal_raw[! duplicated(personal_raw$SITIO),]

personal_raw

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
personal_int <- data.frame(personal_raw$LATITUD,
                     personal_raw$LONGITUD,
                     personal_raw$LOCALIDAD,
                     personal_raw$TECNOLOGIA,
                     personal_raw$SITIO
                     )

#Change names of the variables we already have
colnames(personal_int) <- c("latitude", 
                      "longitude",
                      "location_detail",
                      "technology",
                      "internal_id"
                      )

rownames(personal_int) <- 1:nrow(personal_int)
######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude:
personal_int$latitude <- gsub(",", ".", personal_int$latitude)
personal_int$latitude <- as.numeric(as.character(personal_int$latitude))

#Longitude:
personal_int$longitude <- gsub(",", ".", personal_int$longitude)
personal_int$longitude <- as.numeric(as.character(personal_int$longitude))

#Tower height: as integer
personal_int$tower_height <- 0
personal_int$tower_height <- as.integer(as.character(personal_int$tower_height))

#Owner:
personal_int$owner <- "PERSONAL"

#Location detail: as char
personal_int$location_detail <- as.character(personal_int$location_detail)

#tech_2g, tech_3g, tech_4g:
personal_int$"tech_2g" <- FALSE
personal_int$"tech_3g" <- FALSE
personal_int$"tech_4g" <- FALSE

personal_int[grepl("2G",personal_int$technology), 'tech_2g'] <- TRUE
personal_int[grepl("3G",personal_int$technology), 'tech_3g'] <- TRUE
personal_int[grepl("4G",personal_int$technology), 'tech_4g'] <- TRUE


#Type:
personal_int$type <- NA
personal_int$type <- as.character(personal_int$type)


#Subtype: as character 
personal_int$subtype <- NA
personal_int$subtype <- as.character(personal_int$subtype)

#In Service: 
personal_int$in_service <- NA
personal_int$in_service <- as.character(personal_int$in_service)

#Vendor: Unknown
personal_int$vendor <- NA
personal_int$vendor <- as.character(personal_int$vendor)

#Coverage radius: unknown, assume 3km for all towers
personal_int$coverage_radius <- 3

#Coverage area 2G, 3G and 4G
personal_int <- test(schema_dev, table_personal_test, personal_int)

#fiber, radio, satellite: create from transport field
personal_int$fiber <- FALSE
personal_int$radio <- FALSE
personal_int$satellite <- FALSE

#satellite band in use:
personal_int$satellite_band_in_use <- NA
personal_int$satellite_band_in_use <- as.character(personal_int$satellite_band_in_use)

#radio_distance_km: no info on this
personal_int$radio_distance_km <- NA
personal_int$radio_distance_km <- as.numeric(personal_int$radio_distance_km)

#last_mile_bandwidth:
personal_int$last_mile_bandwidth <- NA
personal_int$last_mile_bandwidth <- as.character(personal_int$last_mile_bandwidth)

#Tower type:
personal_int$tower_type <- "INFRASTRUCTURE"

personal_int[((personal_int$tech_2g == TRUE)|(personal_int$tech_3g == TRUE)|(personal_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

personal_int[(((personal_int$fiber == TRUE)|(personal_int$radio == TRUE)|(personal_int$satellite == TRUE))&(personal_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

personal_int[(((personal_int$fiber == TRUE)|(personal_int$radio == TRUE)|(personal_int$satellite == TRUE))&(personal_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
personal_int$source_file <- file_name

#Source:
personal_int$source <- "PERSONAL"

#Internal ID:
personal_int$internal_id <- as.character(personal_int$internal_id)

personal_int$tx_3g <- FALSE
personal_int$tx_third_pty <- FALSE
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
personal <- personal_int[,c("latitude",
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
personal
######################################################################################################################

  


#Export the normalized output
saveRDS(personal, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, personal)

exportDB(schema_dev, table_personal, personal)
