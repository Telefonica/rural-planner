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
file_name <- "2018 08 21 Portafolio QMC_Operadores.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "qmc.rds"

source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')

#Load qmc nodes
qmc_raw <- read_excel(paste(input_path_infrastructure, file_name, sep='/'),skip=1)


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

qmc_int <- data.frame(qmc_raw$CODIGO,
                      qmc_raw$'NOMBRE PREDIO',
                      qmc_raw$DIRECCION,
                      qmc_raw$'LATITUD (decimal)',
                      qmc_raw$'LONGITUD (decimal)',
                      qmc_raw$'TIPO DE ESTRUCTURA...10',
                      qmc_raw$'ALTURA TOTAL (mts)'
)

#Change names of the variables we already have
colnames(qmc_int) <- c("internal_id",
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

qmc_int$latitude <- as.numeric(qmc_int$latitude)


#Longitude:

qmc_int$longitude <- as.numeric(qmc_int$longitude)
#AD-HOC correction. Missing negative sign in one tower. Longitude is always negative
qmc_int$longitude[qmc_int$longitude>0] <- -(qmc_int$longitude[qmc_int$longitude>0])


#Tower height: no information for now
qmc_int$tower_height <- as.numeric(qmc_int$tower_height)


#Owner: as character
qmc_int$owner <- as.character("QMC")

#Location detail: as character (TX OWNER). No information
qmc_int$location_detail <- '-'


#tech_2g, tech_3g, tech_4g: No information
qmc_int$"tech_2g" <- FALSE
qmc_int$"tech_3g" <- FALSE
qmc_int$"tech_4g" <- FALSE

#Type: No information
qmc_int$type <- as.character(qmc_int$type)

#Subtype: RAN OWNER. No information
qmc_int$subtype <- '-'
qmc_int$subtype <- as.character(qmc_int$subtype)

#In Service:  No info; all in service
qmc_int$in_service <- "IN SERVICE"


#Vendor: Does not apply
qmc_int$vendor <- NA
qmc_int$vendor <- as.character(qmc_int$vendor)


#Coverage area 2G, 3G and 4G: No ACCESS
qmc_int$coverage_area_2g <- NA
qmc_int$coverage_area_2g <- as.character(qmc_int$coverage_area_2g)

qmc_int$coverage_area_3g <- NA
qmc_int$coverage_area_3g <- as.character(qmc_int$coverage_area_3g)

qmc_int$coverage_area_4g <- NA
qmc_int$coverage_area_4g <- as.character(qmc_int$coverage_area_4g)


#fiber, radio, satellite: No info
qmc_int$fiber <- FALSE
qmc_int$radio <- FALSE
qmc_int$satellite <- FALSE

#satellite band in use: Does not apply
qmc_int$satellite_band_in_use <- NA
qmc_int$satellite_band_in_use <- as.character(qmc_int$satellite_band_in_use)


#radio_distance_km: Does not apply
qmc_int$radio_distance_km <- NA
qmc_int$radio_distance_km <- as.numeric(qmc_int$radio_distance_km)



#last_mile_bandwidth: Does not apply
qmc_int$last_mile_bandwidth <- NA
qmc_int$last_mile_bandwidth <- as.character(qmc_int$last_mile_bandwidth)


#Tower type: No information for now
qmc_int$tower_type <- "INFRASTRUCTURE"

qmc_int[((qmc_int$tech_2g == TRUE)|(qmc_int$tech_3g == TRUE)|(qmc_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

qmc_int[(((qmc_int$fiber == TRUE)|(qmc_int$radio == TRUE)|(qmc_int$satellite == TRUE))&(qmc_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

qmc_int[(((qmc_int$fiber == TRUE)|(qmc_int$radio == TRUE)|(qmc_int$satellite == TRUE))&(qmc_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
qmc_int$source_file <- file_name


#Source:
qmc_int$source <- "QMC"


#Internal ID:
qmc_int$internal_id <- as.character(qmc_int$internal_id)


#Tower name
qmc_int$tower_name <- as.character(qmc_int$tower_name)


#IPT perimeter : No information for now
qmc_int$ipt_perimeter <- NA

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
qmc <- qmc_int[,c("latitude",
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
qmc
######################################################################################################################


qmc <- qmc %>% distinct(latitude, longitude, .keep_all=T)


#Export the normalized output
saveRDS(qmc, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, qmc)

#Export to DB
exportDB_Infrastructure(schema_dev, table_qmc, qmc)
