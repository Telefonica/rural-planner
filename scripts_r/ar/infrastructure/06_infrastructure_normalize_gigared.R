

#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_ar'
source(config_path)

#LIBRARIES
source('~/shared/rural_planner/functions/coverage_area.R')

#Load femto gigared
file_name <- "Sitios_Gigared.xlsx"
sheet <- "GIGARED"
skip <- 1

output_path <-paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_name_io <- "gigared.rds"

source('~/shared/rural_planner/sql/ar/infrastructure/exportDB.R')

#LOAD INPUTS
gigared_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), sheet = sheet, skip = skip)

gigared_raw


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
gigared_int <- data.frame(gigared_raw$Latitud,
                     gigared_raw$Longitud,
                     gigared_raw$TIPO,
 
                     gigared_raw$REGION,
                     
                     gigared_raw$LOCALIDAD,
                     stringsAsFactors = FALSE
                     )

#Change names of the variables we already have
colnames(gigared_int) <- c("latitude", 
                      "longitude",
                      "status",
                      
                      "location_detail",
                      
                      "internal_id"
                      )

rownames(gigared_int) <- 1:nrow(gigared_int)
######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done

#Longitude: already done

#Tower height: as integer
gigared_int$tower_height <- 0
gigared_int$tower_height <- as.integer(as.character(gigared_int$tower_height))

#Owner:
gigared_int$owner <- "GIGARED"

#Location detail: as char
gigared_int$location_detail <- as.character(gigared_int$location_detail)

#tech_2g, tech_3g, tech_4g:
gigared_int$"tech_2g" <- FALSE
gigared_int$"tech_3g" <- FALSE
gigared_int$"tech_4g" <- FALSE

#Type:
gigared_int$type <- NA
gigared_int$type <- as.character(gigared_int$type)


#Subtype: as character 
gigared_int$subtype <- NA
gigared_int$subtype <- as.character(gigared_int$subtype)

#In Service: 
gigared_int$in_service <- "AVAILABLE"
gigared_int[grepl("SERVICIO",gigared_int$status), 'in_service'] <- "IN SERVICE"

#Vendor: Unknown
gigared_int$vendor <- NA
gigared_int$vendor <- as.character(gigared_int$vendor)

#Coverage area 2G, 3G and 4G
gigared_int$coverage_area_2g <- NA
gigared_int$coverage_area_2g <- as.character(gigared_int$coverage_area_2g)

gigared_int$coverage_area_3g <- NA
gigared_int$coverage_area_3g <- as.character(gigared_int$coverage_area_3g)

gigared_int$coverage_area_4g <- NA
gigared_int$coverage_area_4g <- as.character(gigared_int$coverage_area_4g)


#fiber, radio, satellite: create from transport field
gigared_int$fiber <- TRUE
gigared_int$radio <- FALSE
gigared_int$satellite <- FALSE

#satellite band in use:
gigared_int$satellite_band_in_use <- NA
gigared_int$satellite_band_in_use <- as.character(gigared_int$satellite_band_in_use)

#radio_distance_km: no info on this
gigared_int$radio_distance_km <- NA
gigared_int$radio_distance_km <- as.numeric(gigared_int$radio_distance_km)

#last_mile_bandwidth: 0.2 Mbps for VSAT and 0.4 Mbps for SCPC
gigared_int$last_mile_bandwidth <- NA
gigared_int$last_mile_bandwidth <- as.character(gigared_int$last_mile_bandwidth)

#Tower type:
gigared_int$tower_type <- "INFRASTRUCTURE"

gigared_int[((gigared_int$tech_2g == TRUE)|(gigared_int$tech_3g == TRUE)|(gigared_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

gigared_int[(((gigared_int$fiber == TRUE)|(gigared_int$radio == TRUE)|(gigared_int$satellite == TRUE))&(gigared_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

gigared_int[(((gigared_int$fiber == TRUE)|(gigared_int$radio == TRUE)|(gigared_int$satellite == TRUE))&(gigared_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
gigared_int$source_file <- file_name

#Source file:
gigared_int$source <- "GIGARED"

#Internal ID:
gigared_int$internal_id <- as.character(gigared_int$internal_id)

gigared_int$tx_3g <- FALSE
gigared_int$tx_third_pty <- FALSE
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
gigared <- gigared_int[,c("latitude",
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
gigared
######################################################################################################################

  

#Export the normalized output
saveRDS(gigared, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, gigared)

exportDB(schema_dev, table_gigared, gigared)
