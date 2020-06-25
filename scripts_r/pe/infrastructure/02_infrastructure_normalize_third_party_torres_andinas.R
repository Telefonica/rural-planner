
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)


#VARIABLES 
file_name <- "Piura-Tumbes y Cajamarca - DB Red de Acceso - 20190120 - TDP.xlsx"
skip <- 1

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "torres_andinas.rds"


source('~/shared/rural_planner/sql/pe/infrastructure/exportDB_A.R')

#Load gilat nodes
torres_andinas_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), skip = skip)

torres_andinas_raw


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

torres_andinas_int <- data.frame(torres_andinas_raw$"LATITUD",
                     torres_andinas_raw$"LONGITUD",
                     torres_andinas_raw$`Altura DE TORRE`,
                     
                     torres_andinas_raw$`TIPO DE SITE (FINAL)`,
                     torres_andinas_raw$LOCALIDAD,
                     
                     torres_andinas_raw$`Conectividad al NOC`,

                     torres_andinas_raw$`NOMBRE CODIFICADO`,
                     torres_andinas_raw$`NOMBRE CODIFICADO`
      )


#Change names of the variables we already have
colnames(torres_andinas_int) <- c("latitude", 
                      "longitude",
                      "tower_height",
                      
                      "subtype",
                      "location_detail",
                      "status",
                      
                      "internal_id",
                      "tower_name"
)

######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done

#Longitude: already done

#Tower height: as integer
torres_andinas_int$tower_height <- as.integer(as.character(torres_andinas_int$tower_height))

#Owner: all Torres Andinas
torres_andinas_int$owner <- "TORRES ANDINAS"
torres_andinas_int$owner <- as.character(torres_andinas_int$owner)

#Location detail: as character
torres_andinas_int$location_detail <- as.character(torres_andinas_int$location_detail)

#tech_2g, tech_3g, tech_4g: No access in torres andinas (for now)
torres_andinas_int$"tech_2g" <- FALSE
torres_andinas_int$"tech_3g" <- FALSE
torres_andinas_int$"tech_4g" <- FALSE

#Type: ASSUMPTION: We can use all of the nodes for transport. We will not use them for access.
torres_andinas_int$type <- NA
torres_andinas_int$type <- as.character(torres_andinas_int$type)

#Subtype: as character
torres_andinas_int$subtype <- as.character(torres_andinas_int$subtype)

#In Service: IN SERVICE. From june onwards planned.
torres_andinas_int$status <- as.Date(torres_andinas_int$status)
torres_andinas_int$in_service[torres_andinas_int$status<=Sys.Date()] <- "IN SERVICE"
torres_andinas_int$in_service[torres_andinas_int$status>Sys.Date()] <- "PLANNED"

torres_andinas_int$in_service[torres_andinas_int$in_service == "2019-03-29"] <- "IN SERVICE"
torres_andinas_int$in_service[torres_andinas_int$in_service != "IN SERVICE"] <- paste0("PLANNED ",torres_andinas_int$in_service[torres_andinas_int$in_service != "IN SERVICE"])
torres_andinas_int$in_service <- as.character(torres_andinas_int$in_service)

#Vendor: Does not apply
torres_andinas_int$vendor <- NA
torres_andinas_int$vendor <- as.character(torres_andinas_int$vendor)

#Coverage area 2G, 3G and 4G: No info
torres_andinas_int$coverage_area_2g <- NA
torres_andinas_int$coverage_area_2g <- as.character(torres_andinas_int$coverage_area_2g)

torres_andinas_int$coverage_area_3g <- NA
torres_andinas_int$coverage_area_3g <- as.character(torres_andinas_int$coverage_area_3g)

torres_andinas_int$coverage_area_4g <- NA
torres_andinas_int$coverage_area_4g <- as.character(torres_andinas_int$coverage_area_4g)

#fiber, radio, satellite: ALL fiber
torres_andinas_int$fiber <- TRUE
torres_andinas_int$radio <- FALSE
torres_andinas_int$satellite <- FALSE

#satellite band in use: Does not apply
torres_andinas_int$satellite_band_in_use <- NA
torres_andinas_int$satellite_band_in_use <- as.character(torres_andinas_int$satellite_band_in_use)

#radio_distance_km: no info on this
torres_andinas_int$radio_distance_km <- NA
torres_andinas_int$radio_distance_km <- as.numeric(torres_andinas_int$radio_distance_km)

#last_mile_bandwidth: no info on this
torres_andinas_int$last_mile_bandwidth <- NA
torres_andinas_int$last_mile_bandwidth <- as.character(torres_andinas_int$last_mile_bandwidth)

#Tower type:
torres_andinas_int$tower_type <- "INFRASTRUCTURE"

torres_andinas_int[((torres_andinas_int$tech_2g == TRUE)|(torres_andinas_int$tech_3g == TRUE)|(torres_andinas_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

torres_andinas_int[(((torres_andinas_int$fiber == TRUE)|(torres_andinas_int$radio == TRUE)|(torres_andinas_int$satellite == TRUE))&(torres_andinas_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

torres_andinas_int[(((torres_andinas_int$fiber == TRUE)|(torres_andinas_int$radio == TRUE)|(torres_andinas_int$satellite == TRUE))&(torres_andinas_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
torres_andinas_int$source_file <- file_name

#Source:
torres_andinas_int$source <- "TORRES ANDINAS"

#Internal ID:
torres_andinas_int$internal_id <- as.character(torres_andinas_int$internal_id)

#Tower name:
torres_andinas_int$tower_name <- as.character(torres_andinas_int$tower_name)

# IPT perimeter: NO IPT
torres_andinas_int$ipt_perimeter <- NA
torres_andinas_int$ipt_perimeter <- as.character(torres_andinas_int$ipt_perimeter) 


######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
torres_andinas <- torres_andinas_int[,c("latitude",
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
torres_andinas
######################################################################################################################




#Export the normalized output
saveRDS(torres_andinas, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, torres_andinas)

exportDB_A(schema_dev, table_torres_andinas, torres_andinas)


