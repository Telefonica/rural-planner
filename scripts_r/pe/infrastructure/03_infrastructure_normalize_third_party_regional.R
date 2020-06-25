
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)


#VARIABLES
file_name <- "Proyectos Regionales  - Ubigeo[1].xlsx"
sheet <- "base"
skip <- 0

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "regional.rds"

source('~/shared/rural_planner/sql/pe/infrastructure/groupNodesByTower.R')
source('~/shared/rural_planner/sql/pe/infrastructure/exportDB_A.R')
    

#Load regional nodes
regional_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), sheet = sheet, skip = skip)

regional_raw


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

regional_int <- data.frame(
                     regional_raw$LATITUD...61,
                     regional_raw$LONGITUD...60,
                     regional_raw$CRUCE,
                     regional_raw$LOCALIDAD,
                     regional_raw$`REGION LICITADA`,
                     
                     regional_raw$FUENTE
      )

#Change names of the variables we already have
colnames(regional_int) <- c("latitude", 
                      "longitude",
                      "internal_id",
                      "location_detail",
                      "owner",
                      
                      "subtype"
                      )

######################################################################################################################

######################################################################################################################

# AD-HOC: For the input used, there are several rows per each tower planned that indicate the settlements it is going to give access to:

#Group all rows belonging to the same tower
    #Set connection data
    regional <- groupNodesByTower(schema_dev, table_regional_test, regional_int)

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done

#Longitude: already done

#Tower height: ASSUMPTION: 15 meters by default
regional$tower_height <-  15
regional$tower_height <- as.integer(as.character(regional$tower_height))

#Owner: all regional: AMAZONAS, ICA, JUNIN, LIMA, MOQUEGUA, PUNO, TACNA
regional$owner <- as.character(regional$owner)
# AD-HOC: Remove accent marks non compatible with UTF-8 encoding
 regional$owner[regional$owner=='JUN?N'] <- 'JUNIN'

#Location detail: as char
regional$location_detail <- as.character(regional$location_detail)

#tech_2g, tech_3g, tech_4g: No access in regional (for now)
regional$"tech_2g" <- FALSE
regional$"tech_3g" <- FALSE
regional$"tech_4g" <- FALSE

#Type: ASSUMPTION: regional projects are only towers with fiber for now
regional$type <- NA
regional$type <- as.character(regional$type)

#Subtype: does not apply
regional_int$subtype <- NA
regional_int$subtype <- as.character(regional_int$subtype)

#In Service: ALL PLANNED. No info on this.
regional$in_service <- "PLANNED"
regional$in_service <- as.character(regional$in_service)

#Vendor: Does not apply
regional$vendor <- NA
regional$vendor <- as.character(regional$vendor)

#Coverage area 2G, 3G and 4G: No info
regional$coverage_area_2g <- NA
regional$coverage_area_2g <- as.character(regional$coverage_area_2g)

regional$coverage_area_3g <- NA
regional$coverage_area_3g <- as.character(regional$coverage_area_3g)

regional$coverage_area_4g <- NA
regional$coverage_area_4g <- as.character(regional$coverage_area_4g)

#fiber, radio, satellite: Towers with fiber
regional$fiber <- TRUE
regional$radio <- FALSE
regional$satellite <- FALSE

#satellite band in use: Does not apply
regional$satellite_band_in_use <- NA
regional$satellite_band_in_use <- as.character(regional$satellite_band_in_use)

#radio_distance_km: Does not apply
regional$radio_distance_km <- NA
regional$radio_distance_km <- as.numeric(regional$radio_distance_km)

#last_mile_bandwidth: Does not apply
regional$last_mile_bandwidth <- NA
regional$last_mile_bandwidth <- as.character(regional$last_mile_bandwidth)

#Tower type:
regional$tower_type <- "INFRASTRUCTURE"

regional[((regional$tech_2g == TRUE)|(regional$tech_3g == TRUE)|(regional$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

regional[(((regional$fiber == TRUE)|(regional$radio == TRUE)|(regional$satellite == TRUE))&(regional$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

regional[(((regional$fiber == TRUE)|(regional$radio == TRUE)|(regional$satellite == TRUE))&(regional$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
regional$source_file <- file_name

# Source:
regional$source <- "REGIONAL"

#Internal ID:
regional$internal_id <- as.character(regional$internal_id)

#Tower name:
regional$tower_name <- as.character(regional$internal_id)

# IPT Perimeter:Does not apply
regional$ipt_perimeter <- NA
regional$ipt_perimeter <- as.character(regional$ipt_perimeter)

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
regional <- regional[,c("latitude",
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
regional
######################################################################################################################



#Export the normalized output
saveRDS(regional, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, regional)

exportDB_A(schema_dev, table_regional, regional)


