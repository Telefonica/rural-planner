
#Load libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(XLConnect)
library(XLConnectJars)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

### VARIABLES ###
file_name_main <- "Claro.xlsx"
sheet <- 1
skip <- 0

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "claro.rds"

source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')
source('~/shared/rural_planner/sql/addTowerId.R')



#Load Claro infrastructure info
claro_raw <- read_excel(paste(input_path_infrastructure, file_name_main, sep = "/"), sheet = sheet, skip = skip)


######################################################################################################################
#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail, tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor, coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)

#The ID will be that of the row from the data frame
######################################################################################################################


######################################################################################################################

#Select useful columns from Claro raw input

claro_int <- data.frame(claro_raw$'Latitud Decimal WGS-84',
                        claro_raw$'Longitud  Decimal WGS-84',
                        claro_raw$Nombre,
                        claro_raw$'Cabecera Municipal',
                        claro_raw$'Altura Estructura Total (Edificio + Estructura)',
                        claro_raw$'Propietario de la estructura de Elevaci¢n',
                        claro_raw$'Tipo de Estructura (TORRE, TORRETA, MONOPOLO, MASTIL, EDIFICIO, VALLA, POSTE, TORRE RIENDADA, INDOOR, SERCHA, ED. + Estructura, TORRE de ENERGIA)',
                        claro_raw$'Tipo TXn (Fibra, Radio, ..)',
                        claro_raw$'Cositing (TIGO, CLARO, AVANTEL, ETC, OTRO)',
                        stringsAsFactors = FALSE
      )

#Change names of the variables we already have from claro raw

colnames(claro_int) <- c("latitude",
                         "longitude",
                         "tower_name",
                         "municipio",
                         "tower_height",
                         "owner",
                         "type",
                         "tx_type",
                         "subtype"
                       )


######################################################################################################################

######################################################################################################################

#Fill claro_int with the rest of the fields and reshape where necessary

#Longitude: already done

#Latitude: already done

#Tower_name: already done

#Tower height: as integer
claro_int$tower_height <- as.integer(claro_int$tower_height)

#Owner to upper case
claro_int$owner <- toupper(claro_int$owner)

#Location_detail: no info
claro_int$location_detail <- NA
claro_int$location_detail <- as.character(claro_int$location_detail)

#Tech 2G, 3G, 4G: no info
claro_int$tech_2g <- FALSE
claro_int$tech_3g <- FALSE
claro_int$tech_4g <- FALSE

#Type to upper case
claro_int$type <- toupper(claro_int$type)

#Subtype
claro_int$subtype <- toupper(claro_int$subtype)

claro_int[grepl("NA", claro_int$subtype) | grepl("NO", claro_int$subtype), 'subtype'] <- "CLARO"

#In Service: ALL IN SERVICE. No info on this.
claro_int$in_service <- "IN SERVICE"
claro_int$in_service <- as.character(claro_int$in_service)

#Vendor: Does not apply
claro_int$vendor <- NA
claro_int$vendor <- as.character(claro_int$vendor)

#Coverage area 2G, 3G and 4G: No info
claro_int$coverage_area_2g <- NA
claro_int$coverage_area_2g <- as.character(claro_int$coverage_area_2g)

claro_int$coverage_area_3g <- NA
claro_int$coverage_area_3g <- as.character(claro_int$coverage_area_3g)

claro_int$coverage_area_4g <- NA
claro_int$coverage_area_4g <- as.character(claro_int$coverage_area_4g)

#fiber, radio, satellite: No info
claro_int$fiber <- FALSE
claro_int$radio <- FALSE
claro_int$satellite <- FALSE

#satellite band in use: Does not apply
claro_int$satellite_band_in_use <- NA
claro_int$satellite_band_in_use <- as.character(claro_int$satellite_band_in_use)

#radio_distance_km: Does not apply
claro_int$radio_distance_km <- NA
claro_int$radio_distance_km <- as.numeric(claro_int$radio_distance_km)

#last_mile_bandwidth: Does not apply
claro_int$last_mile_bandwidth <- NA
claro_int$last_mile_bandwidth <- as.character(claro_int$last_mile_bandwidth)

#Tower type: No information for now
claro_int$tower_type <- "INFRASTRUCTURE"

#claro_int[((claro_int$tech_2g == TRUE)|(claro_int$tech_3g == TRUE)|(claro_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

#claro_int[(((claro_int$fiber == TRUE)|(claro_int$radio == TRUE)|(claro_int$satellite == TRUE))&(claro_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

#claro_int[(((claro_int$fiber == TRUE)|(claro_int$radio == TRUE)|(claro_int$satellite == TRUE))&(claro_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
claro_int$source_file <- file_name_main

#Source:
claro_int$source <- "CLARO"

#Internal ID:
claro_int$internal_id <- as.character(claro_int$tower_name)

#IPT perimeter : Does not apply
claro_int$ipt_perimeter <- NA


######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
claro <- claro_int[,c("latitude",
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

######################################################################################################################



#Export the normalized output
saveRDS(claro, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <-  readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, claro)

#Export to DB
exportDB_Infrastructure(schema_dev, table_claro, claro)
addTowerId(schema_dev, table_claro)


