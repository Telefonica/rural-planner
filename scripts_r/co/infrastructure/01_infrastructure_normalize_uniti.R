#Load libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(XLConnect)
library(XLConnectJars)
library(sp)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

file_name <- "Portafolio Uniti Colombia.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "uniti.rds"

source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')

#Load atp nodes
uniti_raw <- read_excel(paste(input_path_infrastructure, file_name, sep='/'),sheet = "Marketable assets",skip = 5)


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

uniti_int <- data.frame(uniti_raw$`ID Uniti`,
                        uniti_raw$`SITE NAME`,
                        uniti_raw$`STREET , NUMBER`,
                        uniti_raw$Latitude,
                        uniti_raw$Longitude,
                        uniti_raw$`Tower Type`,
                        uniti_raw$`Structure Height (mts)`,
                        stringsAsFactors=FALSE)


#Change names of the variables we already have
colnames(uniti_int) <- c("internal_id",
                       "tower_name",
                       "location_detail",
                       "latitude",
                       "longitude",
                       "type",
                       "tower_height")


######################################################################################################################

######################################################################################################################


#Fill with the rest of the fields and reshape where necessary

#Latitude:
uniti_int$latitude <- as.numeric(uniti_int$latitude)

#Longitude:
uniti_int$longitude <- as.numeric(uniti_int$longitude)


#Tower height: no information for now
uniti_int$tower_height <- as.numeric(uniti_int$tower_height)


#Owner: as character
uniti_int$owner <- as.character("UNITI")

#Location detail: as character (TX OWNER). No information
uniti_int$location_detail <- '-'


#tech_2g, tech_3g, tech_4g: No information
uniti_int$"tech_2g" <- FALSE
uniti_int$"tech_3g" <- FALSE
uniti_int$"tech_4g" <- FALSE

#Type: as character
uniti_int$type <- as.character(uniti_int$type)

#Subtype: RAN OWNER. No information
uniti_int$subtype <- '-'
uniti_int$subtype <- as.character(uniti_int$subtype)

#In Service:  No info; all in service
uniti_int$in_service <- "IN SERVICE"


#Vendor: Does not apply
uniti_int$vendor <- NA
uniti_int$vendor <- as.character(uniti_int$vendor)


#Coverage area 2G, 3G and 4G: No ACCESS
uniti_int$coverage_area_2g <- NA
uniti_int$coverage_area_2g <- as.character(uniti_int$coverage_area_2g)

uniti_int$coverage_area_3g <- NA
uniti_int$coverage_area_3g <- as.character(uniti_int$coverage_area_3g)

uniti_int$coverage_area_4g <- NA
uniti_int$coverage_area_4g <- as.character(uniti_int$coverage_area_4g)


#fiber, radio, satellite: No info
uniti_int$fiber <- FALSE
uniti_int$radio <- FALSE
uniti_int$satellite <- FALSE

#satellite band in use: Does not apply
uniti_int$satellite_band_in_use <- NA
uniti_int$satellite_band_in_use <- as.character(uniti_int$satellite_band_in_use)


#radio_distance_km: Does not apply
uniti_int$radio_distance_km <- NA
uniti_int$radio_distance_km <- as.numeric(uniti_int$radio_distance_km)



#last_mile_bandwidth: Does not apply
uniti_int$last_mile_bandwidth <- NA
uniti_int$last_mile_bandwidth <- as.character(uniti_int$last_mile_bandwidth)


#Tower type: No information for now
uniti_int$tower_type <- "INFRASTRUCTURE"

uniti_int[((uniti_int$tech_2g == TRUE)|(uniti_int$tech_3g == TRUE)|(uniti_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

uniti_int[(((uniti_int$fiber == TRUE)|(uniti_int$radio == TRUE)|(uniti_int$satellite == TRUE))&(uniti_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

uniti_int[(((uniti_int$fiber == TRUE)|(uniti_int$radio == TRUE)|(uniti_int$satellite == TRUE))&(uniti_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
uniti_int$source_file <- file_name


#Source:
uniti_int$source <- "UNITI"


#Internal ID:
uniti_int$internal_id <- as.character(uniti_int$internal_id)


#Tower name
uniti_int$tower_name <- as.character(uniti_int$tower_name)


#IPT perimeter : No information for now
uniti_int$ipt_perimeter <- NA

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
uniti <- uniti_int[,c("latitude",
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

uniti
######################################################################################################################






#Export the normalized output
saveRDS(uniti, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, uniti)

#Export to DB
exportDB_Infrastructure(schema_dev, table_uniti, uniti)
