#Load libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(XLConnect)
library(XLConnectJars)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)


file_name <- "Atributos_ROAMING_NACIONAL_Maximo 11 de junio de 2019.xlsx"
sheet <- "RAN"

source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')
source('~/shared/rural_planner/sql/addTowerId.R')
source('~/shared/rural_planner/sql/co/infrastructure/coverageArea_test.R')

#Load roaming nodes
roaming_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), sheet= sheet)


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

roaming_int <- data.frame(roaming_raw$`LATITUD POBLADO`,
                     roaming_raw$`LONGITUD POBLADO`,
                     roaming_raw$CINUM,
                     roaming_raw$ESTADO,
                     roaming_raw$OPERADOR
      )

#Change names of the variables we already have
colnames(roaming_int) <- c("latitude", 
                      "longitude",
                      "internal_id",
                      "status",
                      "owner"
                      )
######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude:

roaming_int$latitude <- as.numeric(roaming_int$latitude)

#Longitude: 

roaming_int$longitude <- as.numeric(roaming_int$longitude)

# Remove those that are not geolocated:
roaming_int <- roaming_int[!is.na(roaming_int$latitude),]

#Tower height: assume minimum (10m)
roaming_int$tower_height <- as.integer(10)

#Owner: as character (INFRASTRUCTURE OWNER)
roaming_int$owner <- as.character(roaming_int$owner)
roaming_int$owner[grepl("COMCEL",roaming_int$owner)] <- "CLARO"

#Location detail: TRANSPORT OWNER, do not take into account these towers as transport towers since transport is from competitors only
roaming_int$location_detail <- "-"

#tech_2g, tech_3g, tech_4g: Does not provide Movistar coverage for now
roaming_int$"tech_2g" <- TRUE
roaming_int$"tech_3g" <- TRUE
roaming_int$"tech_4g" <- TRUE

#Type: Does not apply
roaming_int$type <- NA
roaming_int$type <- as.character(roaming_int$type)

#Subtype: RAN OWNER
roaming_int$subtype <- as.character(roaming_int$owner)

#In Service:
roaming_int$in_service <- NA
roaming_int$in_service[grepl("OPERATING", roaming_int$status)] <- "IN SERVICE"
roaming_int$in_service[grepl("DEVELOPMENT", roaming_int$status)] <- "PLANNED"
# Remove those towers that are neither planned nor in service
roaming_int <- roaming_int[!is.na(roaming_int$in_service),]

#Vendor: Does not apply
roaming_int$vendor <- NA
roaming_int$vendor <- as.character(roaming_int$vendor)

#Coverage radius: unknown, assume 1.5km
roaming_int$coverage_radius <- 1.5

#Coverage area 2G, 3G and 4G

roaming_int <- coverageArea_test(schema_dev, table_roaming_test, roaming_int)

#fiber, radio, satellite: No info
roaming_int$fiber <- FALSE
roaming_int$radio <- FALSE
roaming_int$satellite <- FALSE

#satellite band in use: Does not apply
roaming_int$satellite_band_in_use <- NA
roaming_int$satellite_band_in_use <- as.character(roaming_int$satellite_band_in_use)

#radio_distance_km: Does not apply
roaming_int$radio_distance_km <- NA
roaming_int$radio_distance_km <- as.numeric(roaming_int$radio_distance_km)

#last_mile_bandwidth: Does not apply
roaming_int$last_mile_bandwidth <- NA
roaming_int$last_mile_bandwidth <- as.character(roaming_int$last_mile_bandwidth)

#Tower type: No information for now
roaming_int$tower_type <- "INFRASTRUCTURE"

roaming_int[((roaming_int$tech_2g == TRUE)|(roaming_int$tech_3g == TRUE)|(roaming_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

roaming_int[(((roaming_int$fiber == TRUE)|(roaming_int$radio == TRUE)|(roaming_int$satellite == TRUE))&(roaming_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

roaming_int[(((roaming_int$fiber == TRUE)|(roaming_int$radio == TRUE)|(roaming_int$satellite == TRUE))&(roaming_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
roaming_int$source_file <- file_name

#Source:
roaming_int$source <- "ROAMING"

#Internal ID:
roaming_int$internal_id <- as.character(roaming_int$internal_id)

#Tower name
roaming_int$tower_name <- as.character(roaming_int$internal_id)

#IPT perimeter : Does not apply

roaming_int$ipt_perimeter <- NA
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
roaming <- roaming_int[,c("latitude",
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
roaming
######################################################################################################################



#Set connection data
exportDB_Infrastructure(schema_dev, table_roaming, roaming)
addTowerId(schema_dev, table_roaming)

