#Libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(XLConnect)
library(XLConnectJars)
library(dplyr)
library(sp)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)


file_name <- "PTI COL Phoenix 230818.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "pti.rds"

source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')


#Load atp nodes
pti_raw <- read_excel(paste(input_path_infrastructure, file_name, sep='/'),skip=2,col_types = "text")

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

pti_int <- data.frame(pti_raw$`Site Number`,
                      pti_raw$`Site Name`,
                      pti_raw$`Site Type`,
                      pti_raw$`Site Latitude`,
                      pti_raw$`Site Longitude`,
                      pti_raw$`Site Address (Full)`,
                      pti_raw$`Tower AGL (in meters)`,
                      stringsAsFactors=FALSE)


#Change names of the variables we already have
colnames(pti_int) <- c("internal_id",
                       "tower_name",
                       "type",
                       "latitude",
                       "longitude",
                       "location_detail",
                       "tower_height")



######################################################################################################################

######################################################################################################################


#Fill with the rest of the fields and reshape where necessary


#AD-HOC correction. Remove ° in latitude and longitude columns
pti_int$latitude<-gsub("°","",pti_int$latitude)
pti_int$longitude<-gsub("°","",pti_int$longitude)


#Latitude:
pti_int$latitude <- as.numeric(pti_int$latitude)

#Longitude:
pti_int$longitude <- as.numeric(pti_int$longitude)


#Tower height: no information for now
pti_int$tower_height <- round(as.numeric(pti_int$tower_height),digits = 1)
pti_int$tower_height[is.na(pti_int$tower_height)] <- 15



#Owner: as character
pti_int$owner <- as.character("PTI")

#Location detail: as character (TX OWNER). No information
pti_int$location_detail <- '-'


#tech_2g, tech_3g, tech_4g: No information
pti_int$"tech_2g" <- FALSE
pti_int$"tech_3g" <- FALSE
pti_int$"tech_4g" <- FALSE

#Type: as character
pti_int$type <- as.character(pti_int$type)

#Subtype: RAN OWNER. No information
pti_int$subtype <- '-'
pti_int$subtype <- as.character(pti_int$subtype)

#In Service:  No info; all in service
pti_int$in_service <- "IN SERVICE"


#Vendor: Does not apply
pti_int$vendor <- NA
pti_int$vendor <- as.character(pti_int$vendor)


#Coverage area 2G, 3G and 4G: No ACCESS
pti_int$coverage_area_2g <- NA
pti_int$coverage_area_2g <- as.character(pti_int$coverage_area_2g)

pti_int$coverage_area_3g <- NA
pti_int$coverage_area_3g <- as.character(pti_int$coverage_area_3g)

pti_int$coverage_area_4g <- NA
pti_int$coverage_area_4g <- as.character(pti_int$coverage_area_4g)


#fiber, radio, satellite: No info
pti_int$fiber <- FALSE
pti_int$radio <- FALSE
pti_int$satellite <- FALSE

#satellite band in use: Does not apply
pti_int$satellite_band_in_use <- NA
pti_int$satellite_band_in_use <- as.character(pti_int$satellite_band_in_use)


#radio_distance_km: Does not apply
pti_int$radio_distance_km <- NA
pti_int$radio_distance_km <- as.numeric(pti_int$radio_distance_km)



#last_mile_bandwidth: Does not apply
pti_int$last_mile_bandwidth <- NA
pti_int$last_mile_bandwidth <- as.character(pti_int$last_mile_bandwidth)


#Tower type: No information for now
pti_int$tower_type <- "INFRASTRUCTURE"

pti_int[((pti_int$tech_2g == TRUE)|(pti_int$tech_3g == TRUE)|(pti_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

pti_int[(((pti_int$fiber == TRUE)|(pti_int$radio == TRUE)|(pti_int$satellite == TRUE))&(pti_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

pti_int[(((pti_int$fiber == TRUE)|(pti_int$radio == TRUE)|(pti_int$satellite == TRUE))&(pti_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
pti_int$source_file <- file_name


#Source:
pti_int$source <- "PTI"


#Internal ID:
pti_int$internal_id <- as.character(pti_int$internal_id)


#Tower name
pti_int$tower_name <- as.character(pti_int$tower_name)


#IPT perimeter : No information for now
pti_int$ipt_perimeter <- NA

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
pti <- pti_int[,c("latitude",
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

pti
######################################################################################################################

pti <- pti %>% distinct(latitude, longitude, .keep_all=T)


#Export the normalized output
saveRDS(pti, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, pti)

#Export to DB
exportDB_Infrastructure(schema_dev, table_pti, pti)
