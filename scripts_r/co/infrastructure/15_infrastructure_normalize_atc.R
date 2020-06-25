#Libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(XLConnect)
library(XLConnectJars)
library(sp)
library(dplyr)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)


### VARIABLES ###
file_name_1 <- "Portafolio ATC Colombia - 26 septiembre 2018.xls"
file_name_2 <- "Sitios En Desarrollo - 26 septiembre 2018.xls"


output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "atc.rds"


source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')

#Load atc nodes
atc_raw <- read_excel(paste(input_path_infrastructure, file_name_1, sep='/'),skip=4)
atc_planned_raw <- read_excel(paste(input_path_infrastructure, file_name_2, sep='/'),skip=4)


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

atc_int <- data.frame(atc_raw$LATITUD,
                     atc_raw$LONGITUD,
                     atc_raw$`TOWER HEIGHT`,
                     atc_raw$`BUILDING HEIGHT`,
                     atc_raw$`ASSET CLASS`,
                     atc_raw$`TOWER NUMBER`,
                     atc_raw$`ASSET STATUS`,
                     atc_raw$`ASSET NAME`
      )

#Change names of the variables we already have
colnames(atc_int) <- c("latitude", 
                      "longitude",
                      "tower_height_i",
                      "tower_height_ii",
                      "type",
                      "internal_id",
                      "status",
                      "tower_name"
                      )

atc_planned_int <- data.frame(atc_planned_raw$LATITUD,
                     atc_planned_raw$LONGITUD,
                     atc_planned_raw$`TOWER HEIGHT`,
                     atc_planned_raw$`BUILDING HEIGHT`,
                     atc_planned_raw$`ASSET CLASS`,
                     atc_planned_raw$`TOWER NUMBER`,
                     atc_planned_raw$`ASSET STATUS`,
                     atc_planned_raw$`ASSET NAME`
      )

#Change names of the variables we already have
colnames(atc_planned_int) <- c("latitude", 
                      "longitude",
                      "tower_height_i",
                      "tower_height_ii",
                      "type",
                      "internal_id",
                      "status",
                      "tower_name"
                      )

######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude:

atc_int$latitude <- as.numeric(atc_int$latitude)

atc_planned_int$latitude <- as.numeric(atc_planned_int$latitude)

#Longitude:

atc_int$longitude <- as.numeric(atc_int$longitude)

atc_planned_int$longitude <- as.numeric(atc_planned_int$longitude)

#Tower height: as integer
atc_int$tower_height <- atc_int$tower_height_i + atc_int$tower_height_ii

atc_planned_int$tower_height <- atc_planned_int$tower_height_i + atc_planned_int$tower_height_ii

#Owner: as character
atc_int$owner <- as.character("ATC")

atc_planned_int$owner <- as.character("ATC")

#Location detail: as character (TX OWNER). No information
atc_int$location_detail <- '-'

atc_planned_int$location_detail <- '-'

#tech_2g, tech_3g, tech_4g: No information
atc_int$"tech_2g" <- FALSE
atc_int$"tech_3g" <- FALSE
atc_int$"tech_4g" <- FALSE

atc_planned_int$"tech_2g" <- FALSE
atc_planned_int$"tech_3g" <- FALSE
atc_planned_int$"tech_4g" <- FALSE

#Type: No information
atc_int$type <- as.character(atc_int$type)

atc_planned_int$type <- as.character(atc_planned_int$type)

#Subtype: No information
atc_int$subtype <- '-'
atc_int$subtype <- as.character(atc_int$subtype)

atc_planned_int$subtype <- '-'
atc_planned_int$subtype <- as.character(atc_planned_int$subtype)

#In Service: 
atc_int$in_service <- "IN SERVICE"
atc_int$in_service[grepl("Sublease",atc_int$status)] <- "OUT OF SERVICE"
atc_int$in_service <- as.character(atc_int$in_service)
#AD-HOC: Remove sites out of service
atc_int <- atc_int[!(atc_int$in_service=='OUT OF SERVICE'),]


atc_planned_int$in_service <- "PLANNED"

#Vendor: Does not apply
atc_int$vendor <- NA
atc_int$vendor <- as.character(atc_int$vendor)

atc_planned_int$vendor <- NA
atc_planned_int$vendor <- as.character(atc_planned_int$vendor)

#Coverage area 2G, 3G and 4G: No ACCESS
atc_int$coverage_area_2g <- NA
atc_int$coverage_area_2g <- as.character(atc_int$coverage_area_2g)

atc_int$coverage_area_3g <- NA
atc_int$coverage_area_3g <- as.character(atc_int$coverage_area_3g)

atc_int$coverage_area_4g <- NA
atc_int$coverage_area_4g <- as.character(atc_int$coverage_area_4g)


atc_planned_int$coverage_area_2g <- NA
atc_planned_int$coverage_area_2g <- as.character(atc_planned_int$coverage_area_2g)

atc_planned_int$coverage_area_3g <- NA
atc_planned_int$coverage_area_3g <- as.character(atc_planned_int$coverage_area_3g)

atc_planned_int$coverage_area_4g <- NA
atc_planned_int$coverage_area_4g <- as.character(atc_planned_int$coverage_area_4g)

#fiber, radio, satellite: No info
atc_int$fiber <- FALSE
atc_int$radio <- FALSE
atc_int$satellite <- FALSE

atc_planned_int$fiber <- FALSE
atc_planned_int$radio <- FALSE
atc_planned_int$satellite <- FALSE

#satellite band in use: Does not apply
atc_int$satellite_band_in_use <- NA
atc_int$satellite_band_in_use <- as.character(atc_int$satellite_band_in_use)

atc_planned_int$satellite_band_in_use <- NA
atc_planned_int$satellite_band_in_use <- as.character(atc_planned_int$satellite_band_in_use)

#radio_distance_km: Does not apply
atc_int$radio_distance_km <- NA
atc_int$radio_distance_km <- as.numeric(atc_int$radio_distance_km)


atc_planned_int$radio_distance_km <- NA
atc_planned_int$radio_distance_km <- as.numeric(atc_planned_int$radio_distance_km)

#last_mile_bandwidth: Does not apply
atc_int$last_mile_bandwidth <- NA
atc_int$last_mile_bandwidth <- as.character(atc_int$last_mile_bandwidth)


atc_planned_int$last_mile_bandwidth <- NA
atc_planned_int$last_mile_bandwidth <- as.character(atc_planned_int$last_mile_bandwidth)

#Tower type: No information for now
atc_int$tower_type <- "INFRASTRUCTURE"

atc_int[((atc_int$tech_2g == TRUE)|(atc_int$tech_3g == TRUE)|(atc_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

atc_int[(((atc_int$fiber == TRUE)|(atc_int$radio == TRUE)|(atc_int$satellite == TRUE))&(atc_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

atc_int[(((atc_int$fiber == TRUE)|(atc_int$radio == TRUE)|(atc_int$satellite == TRUE))&(atc_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"


atc_planned_int$tower_type <- "INFRASTRUCTURE"

atc_planned_int[((atc_planned_int$tech_2g == TRUE)|(atc_planned_int$tech_3g == TRUE)|(atc_planned_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

atc_planned_int[(((atc_planned_int$fiber == TRUE)|(atc_planned_int$radio == TRUE)|(atc_planned_int$satellite == TRUE))&(atc_planned_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

atc_planned_int[(((atc_planned_int$fiber == TRUE)|(atc_planned_int$radio == TRUE)|(atc_planned_int$satellite == TRUE))&(atc_planned_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
atc_int$source_file <- file_name_1

atc_planned_int$source_file <- file_name_2

#Source:
atc_int$source <- "ATC"

atc_planned_int$source <- "ATC"

#Internal ID:
atc_int$internal_id <- as.character(atc_int$internal_id)

atc_planned_int$internal_id <- as.character(atc_planned_int$internal_id)

#Tower name
atc_int$tower_name <- as.character(atc_int$tower_name)

atc_planned_int$tower_name <- as.character(atc_planned_int$tower_name)

#IPT perimeter : No information for now
atc_int$ipt_perimeter <- NA


atc_planned_int$ipt_perimeter <- NA
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
atc <- rbind(atc_int[,c("latitude",
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
                        )],
             atc_planned_int[,c("latitude",
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
                        )])
atc
######################################################################################################################

## Remove duplicates by internal_id

atc <- atc %>% distinct(internal_id, .keep_all=T)

## AD-HOC: Remove sublet and non-commecializable sites

atc <- atc[!(atc$internal_id%in%c('160829','161994','162339','162820')),]



#Export the normalized output
saveRDS(atc, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, atc)

#Export to DB
exportDB_Infrastructure(schema_dev, table_atc, atc)

