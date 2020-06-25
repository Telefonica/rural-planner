
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)


#VARIABLES
file_name <- "Actualización de Coordenadas 02-2018.xlsx"
sheet <- "Actualizacion 07-02-18"
skip <- 0


output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "gilat.rds"

source('~/shared/rural_planner/sql/pe/infrastructure/exportDB_A.R')


#Load gilat nodes
gilat_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), sheet = sheet, skip = skip)

gilat_raw


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

gilat_int <- data.frame(gilat_raw$"LATITUD",
                     gilat_raw$"LONGITUD",
                     gilat_raw$"ALTURA DE TORRE\r\n(m)",
                     
                     gilat_raw$`TIPO DE NODO`,
                     gilat_raw$"BACKBONE",
                     gilat_raw$PROYECTO,
                     
                     gilat_raw$`CODIGO NODO`
      )

#Change names of the variables we already have
colnames(gilat_int) <- c("latitude", 
                      "longitude",
                      "tower_height",
                      
                      "node_type",
                      "transport",
                      "subtype",
                      
                      "internal_id"
                      )

#Filter those without info of transport
gilat_int <- gilat_int[!is.na(gilat_int$transport),]
rownames(gilat_int) <- 1:nrow(gilat_int)

######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done

#Longitude: already done

#Tower height: as integer
gilat_int$tower_height <- as.integer(as.character(gilat_int$tower_height))

#Owner: all Gilat
gilat_int$owner <- "GILAT"
gilat_int$owner <- as.character(gilat_int$owner)

#Location detail: as char
gilat_int$location_detail <- NA
gilat_int$location_detail <- as.character(gilat_int$location_detail)

#tech_2g, tech_3g, tech_4g: No access in gilat (for now)
gilat_int$"tech_2g" <- FALSE
gilat_int$"tech_3g" <- FALSE
gilat_int$"tech_4g" <- FALSE

#Type: ASSUMPTION: We can use all of the nodes for transport. We will not use them for access.
gilat_int$type <- NA
gilat_int$type <- as.character(gilat_int$type)

#Subtype: as character from the project
gilat_int$subtype <- as.character(gilat_int$subtype)

#In Service: ALL IN SERVICE. No info on this.
gilat_int$in_service <- "IN SERVICE"
gilat_int$in_service <- as.character(gilat_int$in_service)

#Vendor: Does not apply
gilat_int$vendor <- NA
gilat_int$vendor <- as.character(gilat_int$vendor)

#Coverage area 2G, 3G and 4G: No info
gilat_int$coverage_area_2g <- NA
gilat_int$coverage_area_2g <- as.character(gilat_int$coverage_area_2g)

gilat_int$coverage_area_3g <- NA
gilat_int$coverage_area_3g <- as.character(gilat_int$coverage_area_3g)

gilat_int$coverage_area_4g <- NA
gilat_int$coverage_area_4g <- as.character(gilat_int$coverage_area_4g)

#fiber, radio, satellite: We take it from the transport column. For access nodes, we take directly this field formatted. For transport nodes we assign Fiber to the Core nodes and we take the 'FUNCI?N' column to assign radio or fiber
gilat_int$fiber <- FALSE
gilat_int$radio <- FALSE
gilat_int$satellite <- FALSE

gilat_int[grepl("Fibra", gilat_int$transport), 'fiber'] <- TRUE

gilat_int[grepl("Radio", gilat_int$transport), 'radio'] <- TRUE

#satellite band in use: Does not apply
gilat_int$satellite_band_in_use <- NA
gilat_int$satellite_band_in_use <- as.character(gilat_int$satellite_band_in_use)

#radio_distance_km: no info on this
gilat_int$radio_distance_km <- NA
gilat_int$radio_distance_km <- as.numeric(gilat_int$radio_distance_km)

#last_mile_bandwidth: no info on this
gilat_int$last_mile_bandwidth <- NA
gilat_int$last_mile_bandwidth <- as.character(gilat_int$last_mile_bandwidth)

#Tower type:
gilat_int$tower_type <- "INFRASTRUCTURE"

gilat_int[((gilat_int$tech_2g == TRUE)|(gilat_int$tech_3g == TRUE)|(gilat_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

gilat_int[(((gilat_int$fiber == TRUE)|(gilat_int$radio == TRUE)|(gilat_int$satellite == TRUE))&(gilat_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

gilat_int[(((gilat_int$fiber == TRUE)|(gilat_int$radio == TRUE)|(gilat_int$satellite == TRUE))&(gilat_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
gilat_int$source_file <- file_name

#Source:
gilat_int$source <- "GILAT"

#Internal ID:
gilat_int$internal_id <- as.character(gilat_int$internal_id)

#Tower name: No info on this
gilat_int$tower_name <- gilat_int$internal_id

# IPT perimeter: Does not apply
gilat_int$ipt_perimeter <- NA
gilat_int$ipt_perimeter <- as.character(gilat_int$ipt_perimeter)

#Ad-hoc operation for Gilat: there are repeated nodes where one has Fiber only and the other one has fiber and radio. These are hybrid nodes. They are the nodes with ID repeated but with a " - RT" at the end. This operation removes these duplicates
# gilat_int <- gilat_int[order(gilat_int$internal_id, decreasing = TRUE),]
# gilat_int <- gilat_int[!duplicated(substr(gilat_int$internal_id, 1, 7)),]
# gilat_int <- gilat_int[order(gilat_int$internal_id, decreasing = FALSE),]



######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
gilat <- gilat_int[,c("latitude",
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
gilat
######################################################################################################################




#Export the normalized output
saveRDS(gilat, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, gilat)

exportDB_A(schema_dev, table_gilat, gilat)

