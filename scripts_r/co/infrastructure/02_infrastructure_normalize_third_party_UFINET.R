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

file_name <- "Cobertura Ufinet Colombia.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "ufinet.rds"

source('~/shared/rural_planner/sql/co/infrastructure/extractCoordinates.R')
source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')


#Load anditel nodes
ufinet_raw <- read_excel(paste(input_path_infrastructure, file_name, sep='/'), sheet='Colombia-Presencia de Red (2)')

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

ufinet_int <- data.frame(ufinet_raw$`#`,
                         ufinet_raw$Departamento,
                         ufinet_raw$`Municipio/Ciudad`,
                         ufinet_raw$`Cod Dane`)

#Change names of the variables we already have
colnames(ufinet_int) <- c("internal_id",
                          "admin_division_2_name", 
                          "admin_division_1_name",
                          "admin_division_1_id")

######################################################################################################################


#Normalize characters to match with settlements_name
ufinet_int$admin_division_2_name <- toupper(ufinet_int$admin_division_2_name)
ufinet_int$admin_division_2_name <- chartr("ÁÉÍÓÚ","AEIOU",ufinet_int$admin_division_2_name)

ufinet_int$admin_division_1_name <- toupper(ufinet_int$admin_division_1_name)
ufinet_int$admin_division_1_name <- chartr("ÁÉÍÓÚ","AEIOU",ufinet_int$admin_division_1_name)


# Upload input to database and join with settlements table to extract coordinates. First we try to match the name to de admin_division_1 name and get the coordinates of the capital, if that's not possible we match with a settlement with the same name. Only matches if there is only one settlement name. There are 3 cases where there is no match because there are several settlements in that admin_division_2_name with the same name

ufinet_int <- extractCoordinates(schema_dev, table_ufinet_temp, ufinet_int, table_admin_div_2, table_settlements)

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: as numeric
ufinet_int$latitude <- as.numeric(ufinet_int$latitude)

#Longitude: 
ufinet_int$longitude <- as.numeric(ufinet_int$longitude)


#Tower height: remove invalid data (set to minimum height=10m) and convert to integer
ufinet_int$tower_height <- 0

#Owner: as character
ufinet_int$owner <- NA
ufinet_int$owner <- as.character(ufinet_int$owner)

#Location detail: as character (TX OWNER)
ufinet_int$location_detail <- "UFINET"

#tech_2g, tech_3g, tech_4g: Only Tx
ufinet_int$"tech_2g" <- FALSE
ufinet_int$"tech_3g" <- FALSE
ufinet_int$"tech_4g" <- FALSE

#Type: No information
ufinet_int$type <- NA
ufinet_int$type <- as.character(ufinet_int$type)

#Subtype: ACCESS OWNER, NO ACCESS
ufinet_int$subtype <- NA
ufinet_int$subtype <- as.character(ufinet_int$subtype)

#In Service: ALL IN SERVICE. No info on this.
ufinet_int$in_service <- "IN SERVICE"

#Vendor: Does not apply
ufinet_int$vendor <- NA
ufinet_int$vendor <- as.character(ufinet_int$vendor)

#Coverage area 2G, 3G and 4G: No ACCESS
ufinet_int$coverage_area_2g <- NA
ufinet_int$coverage_area_2g <- as.character(ufinet_int$coverage_area_2g)

ufinet_int$coverage_area_3g <- NA
ufinet_int$coverage_area_3g <- as.character(ufinet_int$coverage_area_3g)

ufinet_int$coverage_area_4g <- NA
ufinet_int$coverage_area_4g <- as.character(ufinet_int$coverage_area_4g)

#fiber, radio, satellite: No info
ufinet_int$fiber <- TRUE
ufinet_int$radio <- FALSE
ufinet_int$satellite <- FALSE

#satellite band in use: Does not apply
ufinet_int$satellite_band_in_use <- NA
ufinet_int$satellite_band_in_use <- as.character(ufinet_int$satellite_band_in_use)

#radio_distance_km: Does not apply
ufinet_int$radio_distance_km <- NA
ufinet_int$radio_distance_km <- as.numeric(ufinet_int$radio_distance_km)

#last_mile_bandwidth: Does not apply
ufinet_int$last_mile_bandwidth <- NA
ufinet_int$last_mile_bandwidth <- as.character(ufinet_int$last_mile_bandwidth)

#Tower type: No information for now
ufinet_int$tower_type <- "INFRASTRUCTURE"

ufinet_int[((ufinet_int$tech_2g == TRUE)|(ufinet_int$tech_3g == TRUE)|(ufinet_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

ufinet_int[(((ufinet_int$fiber == TRUE)|(ufinet_int$radio == TRUE)|(ufinet_int$satellite == TRUE))&(ufinet_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

ufinet_int[(((ufinet_int$fiber == TRUE)|(ufinet_int$radio == TRUE)|(ufinet_int$satellite == TRUE))&(ufinet_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
ufinet_int$source_file <- file_name

#Source:
ufinet_int$source <- "UFINET"

#Internal ID:
ufinet_int$internal_id <- as.character(ufinet_int$internal_id)

#Tower name
ufinet_int$tower_name <- NA
ufinet_int$tower_name <- as.character(ufinet_int$tower_name)

#IPT perimeter : No information for now
ufinet_int$ipt_perimeter <- NA
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
ufinet <- ufinet_int[,c("latitude",
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
ufinet
######################################################################################################################



#Export the normalized output
saveRDS(ufinet, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, ufinet)

#Export to DB
exportDB_Infrastructure(schema_dev, table_ufinet, ufinet)


