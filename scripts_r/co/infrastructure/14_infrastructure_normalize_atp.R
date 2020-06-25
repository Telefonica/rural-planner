### LIBRARIES ###
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(XLConnect)
library(XLConnectJars)
library(sp)
library(dplyr)

### CONFIG ###
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

### VARIABLES ###
file_name <- "Portafolio_ATP_TTUU_2018.xlsx"
output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "atp.rds"

source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')

#Load atp nodes
atp_raw <- read_excel(paste(input_path_infrastructure, file_name, sep='/'),skip=9)


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

atp_int <- data.frame(atp_raw$Latitutude,
                     atp_raw$Longitude,
                     atp_raw$`Andy ID`,
                     atp_raw$`Site Name`,
                     atp_raw$`Tower type`,
                     atp_raw$`Height (m)`
      )

#Change names of the variables we already have
colnames(atp_int) <- c("latitude", 
                      "longitude",
                      "internal_id",
                      "tower_name",
                      "type",
                      "tower_height"
                      )


######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude:

atp_int$latitude <- as.numeric(atp_int$latitude)


#Longitude:

atp_int$longitude <- as.numeric(atp_int$longitude)


#Tower height: no information for now
atp_int$tower_height <- round(as.numeric(atp_int$tower_height))


#Owner: as character
atp_int$owner <- as.character("ATP")

#Location detail: as character (TX OWNER). No information
atp_int$location_detail <- '-'


#tech_2g, tech_3g, tech_4g: No information
atp_int$"tech_2g" <- FALSE
atp_int$"tech_3g" <- FALSE
atp_int$"tech_4g" <- FALSE

#Type: No information
atp_int$type <- as.character(atp_int$type)

#Subtype: RAN OWNER. No information
atp_int$subtype <- '-'
atp_int$subtype <- as.character(atp_int$subtype)

#In Service:  No info; all in service
atp_int$in_service <- "IN SERVICE"


#Vendor: Does not apply
atp_int$vendor <- NA
atp_int$vendor <- as.character(atp_int$vendor)


#Coverage area 2G, 3G and 4G: No ACCESS
atp_int$coverage_area_2g <- NA
atp_int$coverage_area_2g <- as.character(atp_int$coverage_area_2g)

atp_int$coverage_area_3g <- NA
atp_int$coverage_area_3g <- as.character(atp_int$coverage_area_3g)

atp_int$coverage_area_4g <- NA
atp_int$coverage_area_4g <- as.character(atp_int$coverage_area_4g)


#fiber, radio, satellite: No info
atp_int$fiber <- FALSE
atp_int$radio <- FALSE
atp_int$satellite <- FALSE

#satellite band in use: Does not apply
atp_int$satellite_band_in_use <- NA
atp_int$satellite_band_in_use <- as.character(atp_int$satellite_band_in_use)


#radio_distance_km: Does not apply
atp_int$radio_distance_km <- NA
atp_int$radio_distance_km <- as.numeric(atp_int$radio_distance_km)



#last_mile_bandwidth: Does not apply
atp_int$last_mile_bandwidth <- NA
atp_int$last_mile_bandwidth <- as.character(atp_int$last_mile_bandwidth)


#Tower type: No information for now
atp_int$tower_type <- "INFRASTRUCTURE"

atp_int[((atp_int$tech_2g == TRUE)|(atp_int$tech_3g == TRUE)|(atp_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

atp_int[(((atp_int$fiber == TRUE)|(atp_int$radio == TRUE)|(atp_int$satellite == TRUE))&(atp_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

atp_int[(((atp_int$fiber == TRUE)|(atp_int$radio == TRUE)|(atp_int$satellite == TRUE))&(atp_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
atp_int$source_file <- file_name


#Source:
atp_int$source <- "ATP"


#Internal ID:
atp_int$internal_id <- as.character(atp_int$internal_id)


#Tower name
atp_int$tower_name <- as.character(atp_int$tower_name)


#IPT perimeter : No information for now
atp_int$ipt_perimeter <- NA

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
atp <- atp_int[,c("latitude",
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
atp
######################################################################################################################
## Remove duplicates by internal_id

atp <- atp %>% distinct(internal_id, .keep_all=T)



#Export the normalized output
saveRDS(atp, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, atp)

#Export to db
exportDB_Infrastructure(schema_dev, table_atp, atp)
