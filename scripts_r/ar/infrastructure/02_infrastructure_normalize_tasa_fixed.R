
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_ar'
source(config_path)

#VARIABLES
file_name <- "Sitios TASA.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_name_io <- "tasa_fixed.rds"


source('~/shared/rural_planner/sql/ar/infrastructure/exportDBtasaFixed.R')

#LOAD INPUTS
tasa_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"),sheet = "BASE")


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
tasa_int <- data.frame(tasa_raw$latitud,
                       tasa_raw$longitud,
                       tasa_raw$Domicilio,
                       tasa_raw$`TIPO ESTRUCTURA`,
                       tasa_raw$ALTURA,
                       tasa_raw$`RB MOVIL`,
                       tasa_raw$`EN VENTA O DESMONTE`,
                       tasa_raw$Nombre,
                       tasa_raw$`COD. EMP.`,
                       stringsAsFactors = F)

#Change names of the variables we already have
colnames(tasa_int) <- c("latitude", 
                      "longitude",
                      "location_detail",
                      "type",
                      "tower_height",
                      "subtype",
                      "in_service",
                      "tower_name",
                      "internal_id"
                      )


######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary
#Latitude:
tasa_int$latitude <- gsub(",",".", tasa_int$latitude)
tasa_int$latitude <- gsub(" ","", tasa_int$latitude)
tasa_int$latitude <- gsub("\xc2\xa0","", tasa_int$latitude)
tasa_int$latitude[!(grepl(".",tasa_int$latitude, fixed=T))] <- paste0(substring(tasa_int$latitude[!(grepl(".",tasa_int$latitude, fixed=T))],1,3), ".",substring(tasa_int$latitude[!(grepl(".",tasa_int$latitude, fixed=T))],4) )
tasa_int$latitude <- as.numeric(tasa_int$latitude)

#Longitude:
tasa_int$longitude <- gsub("°","", tasa_int$longitude)
tasa_int$longitude <- gsub(",",".", tasa_int$longitude)
tasa_int$longitude <- gsub(" ","", tasa_int$longitude)
tasa_int$longitude <- gsub("\xc2\xa0","", tasa_int$longitude)
tasa_int$longitude[!(grepl(".",tasa_int$longitude, fixed=T))] <- paste0(substring(tasa_int$longitude[!(grepl(".",tasa_int$longitude, fixed=T))],1,3), ".",substring(tasa_int$longitude[!(grepl(".",tasa_int$longitude, fixed=T))],4) )
tasa_int$longitude <- as.numeric(tasa_int$longitude)

#Tower height: as integer, default 30 m
tasa_int$tower_height <- as.integer(tasa_int$tower_height)
tasa_int$tower_height[is.na(tasa_int$tower_height)] <- 0

#Owner:
tasa_int$owner <- as.character(NA)
tasa_int$owner[is.na(tasa_int$owner)]<-'TASA'


#tech_2g, tech_3g, tech_4g:
tasa_int$"tech_2g" <- FALSE
tasa_int$"tech_3g" <- FALSE
tasa_int$"tech_4g" <- FALSE

tasa_int$coverage_area_2g <- as.character(NA)
tasa_int$coverage_area_3g <- as.character(NA)
tasa_int$coverage_area_4g <- as.character(NA)

#Type:
tasa_int$type <- as.character(tasa_int$type)

#Subtype: as character 
tasa_int$subtype <- as.character(tasa_int$subtype)
Encoding(tasa_int$subtype) <- "UTF-8"

#Location detail: as char
tasa_int$location_detail <- as.character(tasa_int$location_detail)
Encoding(tasa_int$location_detail) <- "UTF-8"

#In Service: 
tasa_int$in_service <- "IN SERVICE"

#Vendor: Unknown
tasa_int$vendor <- NA
tasa_int$vendor <- as.character(tasa_int$vendor)

#fiber, radio, satellite: create from transport field
tasa_int$fiber <- FALSE
tasa_int$radio <- FALSE
tasa_int$satellite <- FALSE

#satellite band in use:
tasa_int$satellite_band_in_use <- NA
tasa_int$satellite_band_in_use <- as.character(tasa_int$satellite_band_in_use)

#radio_distance_km: no info on this
tasa_int$radio_distance_km <- NA
tasa_int$radio_distance_km <- as.numeric(tasa_int$radio_distance_km)

#last_mile_bandwidth:
tasa_int$last_mile_bandwidth <- NA
tasa_int$last_mile_bandwidth <- as.character(tasa_int$last_mile_bandwidth)

#Tower type:
tasa_int$tower_type <- "INFRASTRUCTURE"

tasa_int[((tasa_int$tech_2g == TRUE)|(tasa_int$tech_3g == TRUE)|(tasa_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

tasa_int[(((tasa_int$fiber == TRUE)|(tasa_int$radio == TRUE)|(tasa_int$satellite == TRUE))&(tasa_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

tasa_int[(((tasa_int$fiber == TRUE)|(tasa_int$radio == TRUE)|(tasa_int$satellite == TRUE))&(tasa_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
tasa_int$source_file <- file_name

#Source:
tasa_int$source<- "TASA_FIXED"

#Internal ID:
tasa_int$internal_id <- as.character(tasa_int$internal_id)

tasa_int$tx_3g <- FALSE
tasa_int$tx_third_pty <- FALSE
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
tasa_fixed <- tasa_int[,c("latitude",
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
#tasa_fixed
######################################################################################################################

#EXPORT TO DB

#Export the normalized output
saveRDS(tasa_fixed, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, tasa_fixed)

#Set connection data
exportDBtasaFixed(schema_dev, table_tasa_fixed, tasa_fixed)


