#Libraries
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


file_name <- "20180913 Nodos Azteca_OLD.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "azteca.rds"

source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')


#Load anditel nodes
azteca_raw <- read_excel(paste(input_path_infrastructure, file_name, sep='/'), skip=3, sheet='TD')


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

azteca_int <- data.frame(azteca_raw$Latitud,
                         azteca_raw$Longitud,
                         azteca_raw$PROPIETARIO,
                         azteca_raw$NODO,
                         azteca_raw$`TIPO DE NODO`,
                         azteca_raw$`ALTURA_TORRE (mts)`)

#Change names of the variables we already have
colnames(azteca_int) <- c("latitude", 
                      "longitude",
                      "owner",
                      "internal_id",
                      "type",
                      "tower_height"
                      )
######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

## AD HOC: Parse null fields to NA
azteca_int[azteca_int=='NA'] <- NA

#Latitude: Remove 0
azteca_int$latitude <- as.numeric(as.character(azteca_int$latitude))
azteca_int$latitude[azteca_int$latitude==0]<-NA

#Longitude: Remove 0
azteca_int$longitude <- as.numeric(as.character(azteca_int$longitude))
azteca_int$longitude[azteca_int$longitude==0]<-NA

## AD-HOC: Correct missing negative signs (longitude in Colombia -70? ~ -80?) and ndes that are not geolocated

azteca_int$longitude[azteca_int$longitude>0 & !is.na(azteca_int$longitude)] <- -(azteca_int$longitude[azteca_int$longitude>0 & !is.na(azteca_int$longitude)])
azteca_int <- azteca_int[!is.na(azteca_int$latitude),]


#Tower height: remove invalid data (set to minimum height=10m) and convert to integer
azteca_int$tower_height <-  as.character(azteca_int$tower_height)
azteca_int$tower_height[grepl("NUEVO|MÁSTIL FACHADA|NA",azteca_int$tower_height)] <- 10
azteca_int$tower_height <-  as.numeric(azteca_int$tower_height)
azteca_int$tower_height[is.na(azteca_int$tower_height)] <- 15

#Owner: as character
azteca_int$owner <- as.character(azteca_int$owner)

#Location detail: as character (TX OWNER)
azteca_int$location_detail <- "AZTECA"

#tech_2g, tech_3g, tech_4g: Only Tx
azteca_int$"tech_2g" <- FALSE
azteca_int$"tech_3g" <- FALSE
azteca_int$"tech_4g" <- FALSE

#Type: No information
azteca_int$type <- NA
azteca_int$type <- as.character(azteca_int$type)

#Subtype: ACCESS OWNER, NO ACCESS
azteca_int$subtype <- as.character("-")

#In Service: ALL IN SERVICE. No info on this.
azteca_int$in_service <- "IN SERVICE"

#Vendor: Does not apply
azteca_int$vendor <- NA
azteca_int$vendor <- as.character(azteca_int$vendor)

#Coverage area 2G, 3G and 4G: No ACCESS
azteca_int$coverage_area_2g <- NA
azteca_int$coverage_area_2g <- as.character(azteca_int$coverage_area_2g)

azteca_int$coverage_area_3g <- NA
azteca_int$coverage_area_3g <- as.character(azteca_int$coverage_area_3g)

azteca_int$coverage_area_4g <- NA
azteca_int$coverage_area_4g <- as.character(azteca_int$coverage_area_4g)

#fiber, radio, satellite: No info
azteca_int$fiber <- TRUE
azteca_int$radio <- FALSE
azteca_int$satellite <- FALSE

#satellite band in use: Does not apply
azteca_int$satellite_band_in_use <- NA
azteca_int$satellite_band_in_use <- as.character(azteca_int$satellite_band_in_use)

#radio_distance_km: Does not apply
azteca_int$radio_distance_km <- NA
azteca_int$radio_distance_km <- as.numeric(azteca_int$radio_distance_km)

#last_mile_bandwidth: Does not apply
azteca_int$last_mile_bandwidth <- NA
azteca_int$last_mile_bandwidth <- as.character(azteca_int$last_mile_bandwidth)

#Tower type: No information for now
azteca_int$tower_type <- "INFRASTRUCTURE"

azteca_int[((azteca_int$tech_2g == TRUE)|(azteca_int$tech_3g == TRUE)|(azteca_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

azteca_int[(((azteca_int$fiber == TRUE)|(azteca_int$radio == TRUE)|(azteca_int$satellite == TRUE))&(azteca_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

azteca_int[(((azteca_int$fiber == TRUE)|(azteca_int$radio == TRUE)|(azteca_int$satellite == TRUE))&(azteca_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
azteca_int$source_file <- file_name

#Source:
azteca_int$source <- "AZTECA"

#Internal ID:
azteca_int$internal_id <- as.character(azteca_int$internal_id)

#Tower name
azteca_int$tower_name <- NA
azteca_int$tower_name <- as.character(azteca_int$tower_name)

#IPT perimeter : No information for now
azteca_int$ipt_perimeter <- NA
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
azteca <- azteca_int[,c("latitude",
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
azteca
######################################################################################################################



#Export the normalized output
saveRDS(azteca, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, azteca)

#Export to DB
exportDB_Infrastructure(schema_dev, table_azteca, azteca)

