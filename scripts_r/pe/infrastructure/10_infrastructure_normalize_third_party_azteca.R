#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)


#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)


#VARIABLES
file_name <- "AZTECA - Base de Datos Nodos F1-F6.xlsx"
sheet <- "Consolidado"
skip <- 0

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "azteca.rds"

source('~/shared/rural_planner/sql/pe/infrastructure/exportDB_A.R')

#Load azteca nodes
azteca_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), sheet = sheet, skip = skip)

azteca_raw

######################################################################################################################
#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail,  tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor,coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)

#The ID will be that of the row from the data frame
######################################################################################################################


######################################################################################################################

#Select useful columns from raw input
azteca_int <- data.frame(azteca_raw$Y,
                     azteca_raw$X,
                     azteca_raw$`DIRECCION CONTRATO`,
                     
                     azteca_raw$TIPO,
                     
                     azteca_raw$ITEM,
                     azteca_raw$ITEM
                     )

#Change names of the variables we already have
colnames(azteca_int) <- c("latitude", 
                      "longitude",
                      "location_detail",
                      "subtype",
                      
                      "internal_id",
                      "tower_name"
                      )
######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done

#Longitude: already done

#Tower height: we do not have this info for now
azteca_int$tower_height <- 0
azteca_int$tower_height <- as.integer(as.character(azteca_int$tower_height))

#Owner: all Azteca
azteca_int$owner <- "AZTECA"

#Location detail: as char
azteca_int$location_detail <- as.character(azteca_int$location_detail)

#tech_2g, tech_3g, tech_4g: No access in Azteca
azteca_int$"tech_2g" <- FALSE
azteca_int$"tech_3g" <- FALSE
azteca_int$"tech_4g" <- FALSE

#Type: all transport only
azteca_int$type <- NA
azteca_int$type <- as.character(azteca_int$type)

#Subtype: as character from contract address
azteca_int$subtype <- as.character(azteca_int$subtype)

#In Service: ALL IN SERVICE. No info on this.
azteca_int$in_service <- "IN SERVICE"

#Vendor: Does not apply
azteca_int$vendor <- NA
azteca_int$vendor <- as.character(azteca_int$vendor)

#Coverage area 2G, 3G and 4G: No info
azteca_int$coverage_area_2g <- NA
azteca_int$coverage_area_2g <- as.character(azteca_int$coverage_area_2g)

azteca_int$coverage_area_3g <- NA
azteca_int$coverage_area_3g <- as.character(azteca_int$coverage_area_3g)

azteca_int$coverage_area_4g <- NA
azteca_int$coverage_area_4g <- as.character(azteca_int$coverage_area_4g)

#fiber, radio, satellite: Azteca has Fiber Only
azteca_int$fiber <- TRUE
azteca_int$radio <- FALSE
azteca_int$satellite <- FALSE

#satellite band in use: Does not apply
azteca_int$satellite_band_in_use <- NA
azteca_int$satellite_band_in_use <- as.character(azteca_int$satellite_band_in_use)

#radio_distance_km: no info on this
azteca_int$radio_distance_km <- NA
azteca_int$radio_distance_km <- as.numeric(azteca_int$radio_distance_km)

#last_mile_bandwidth: no info on this
azteca_int$last_mile_bandwidth <- NA
azteca_int$last_mile_bandwidth <- as.character(azteca_int$last_mile_bandwidth)


#Tower type:
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

#Tower name: 
azteca_int$tower_name <- as.character(azteca_int$tower_name)

# IPT Perimeter: Does not apply
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

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, azteca)

exportDB_A(schema_dev, table_azteca, azteca)

