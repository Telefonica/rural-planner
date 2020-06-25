
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_ar'
source(config_path)

#VARIABLES
source('~/shared/rural_planner/functions/coverage_area.R')


file_name <- "Sitios_CLARO.xlsx"
sheet <- "DATA"
skip <- 0

output_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_name_io <- "claro.rds"

source('~/shared/rural_planner/sql/ar/infrastructure/test.R')
source('~/shared/rural_planner/sql/ar/infrastructure/exportDB.R')


#LOAD INPUTS
claro_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), sheet = sheet, skip = skip)
claro_raw

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
claro_int <- data.frame(claro_raw$LATITUD,
                     claro_raw$LONGITUD,
                     claro_raw$NOMBRE,
                     claro_raw$TECNOLOGIA,
                     claro_raw$SITIO
                     )

#Change names of the variables we already have
colnames(claro_int) <- c("latitude", 
                      "longitude",
                      "location_detail",
                      "technology",
                      "internal_id"
                      )

rownames(claro_int) <- 1:nrow(claro_int)
######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude:
claro_int$latitude <- as.numeric(as.character(claro_int$latitude))

#Longitude:
claro_int$longitude <- as.numeric(as.character(claro_int$longitude))

#Tower height: as integer
claro_int$tower_height <- NA
claro_int$tower_height <- as.integer(as.character(claro_int$tower_height))
claro_int$tower_height[is.na(claro_int$tower_height)] <- 30

#Owner:
claro_int$owner <- "CLARO"

#Location detail: as char
claro_int$location_detail <- as.character(claro_int$location_detail)

#tech_2g, tech_3g, tech_4g:
claro_int$"tech_2g" <- FALSE
claro_int$"tech_3g" <- FALSE
claro_int$"tech_4g" <- FALSE

claro_int[grepl("2G",claro_int$technology), 'tech_2g'] <- TRUE
claro_int[grepl("3G",claro_int$technology), 'tech_3g'] <- TRUE
claro_int[grepl("4G",claro_int$technology), 'tech_4g'] <- TRUE

#Type:
claro_int$type <- NA
claro_int$type <- as.character(claro_int$type)


#Subtype: as character 
claro_int$subtype <- NA
claro_int$subtype <- as.character(claro_int$subtype)

#In Service: 
claro_int$in_service <- NA
claro_int$in_service <- as.character(claro_int$in_service)

#Vendor: Unknown
claro_int$vendor <- NA
claro_int$vendor <- as.character(claro_int$vendor)

#Coverage radius: unknown, assume 3km for all towers
claro_int$coverage_radius <- 3

#Coverage area 2G, 3G and 4G
claro_int <- test(schema_dev, table_claro_test, claro_int)



#fiber, radio, satellite:
claro_int$fiber <- FALSE
claro_int$radio <- FALSE
claro_int$satellite <- FALSE

#satellite band in use:
claro_int$satellite_band_in_use <- NA
claro_int$satellite_band_in_use <- as.character(claro_int$satellite_band_in_use)

#radio_distance_km: no info on this
claro_int$radio_distance_km <- NA
claro_int$radio_distance_km <- as.numeric(claro_int$radio_distance_km)

#last_mile_bandwidth:
claro_int$last_mile_bandwidth <- NA
claro_int$last_mile_bandwidth <- as.character(claro_int$last_mile_bandwidth)

#Tower type:
claro_int$tower_type <- "INFRASTRUCTURE"

claro_int[((claro_int$tech_2g == TRUE)|(claro_int$tech_3g == TRUE)|(claro_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

claro_int[(((claro_int$fiber == TRUE)|(claro_int$radio == TRUE)|(claro_int$satellite == TRUE))&(claro_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

claro_int[(((claro_int$fiber == TRUE)|(claro_int$radio == TRUE)|(claro_int$satellite == TRUE))&(claro_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
claro_int$source_file <- file_name

#Source:
claro_int$source <- "CLARO"

#Internal ID:
claro_int$internal_id <- as.character(claro_int$internal_id)

claro_int$tx_3g <- FALSE
claro_int$tx_third_pty <- FALSE
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
claro <- claro_int[,c("latitude",
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
claro
######################################################################################################################

  

#Export the normalized output
saveRDS(claro, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, claro)

#EXPORT TO DB
exportDB(schema_dev, table_claro, claro)
