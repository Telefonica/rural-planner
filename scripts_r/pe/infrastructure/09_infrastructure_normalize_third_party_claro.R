
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)

file_name <- "Claro Formato 6 - REDES DE ACCESO INALAMBRICO_2017_2Q_MODIF_12-09.xlsx"
skip <- 13
sheet <- "6A - Estaciones Base"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "claro.rds"

source('~/shared/rural_planner/sql/pe/infrastructure/coverageAreaClaro.R')
source('~/shared/rural_planner/sql/pe/infrastructure/exportDB_B.R')

#Load gilat nodes
claro_raw <- read_xlsx(paste(input_path_infrastructure,  file_name, sep = "/"), skip = skip,sheet = sheet,col_types = "text" )

claro_raw


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

claro_int <- data.frame(claro_raw$Latitud,
                       claro_raw$Longitud,
                       claro_raw[,16],
                       claro_raw[,19],
                       claro_raw[,22],
                       claro_raw$`Empresa Propietaria de la Infraestructura`,
                       claro_raw[,40],
                       claro_raw$`Nombre de la Estación`,
                       claro_raw[,3],
                       stringsAsFactors = F
                       )



#Change names of the variables we already have
colnames(claro_int) <- c("latitude", 
                      "longitude",
                      "2g",
                      "3g",
                      "4g",
                      "owner",
                      "tower_height",
                      "tower_name",
                      "internal_id")
                    

######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done
claro_int$latitude <- as.numeric(claro_int$latitude)

#Longitude: already done
claro_int$longitude <- as.numeric(claro_int$longitude)

#Tower height: as integer, if empty 15 m
claro_int$tower_height <- as.numeric(claro_int$tower_height)
claro_int$tower_height[is.na(claro_int$tower_height)] <- 15

#Owner: 
claro_int$owner <- as.character(claro_int$owner)

#Location detail: as character
claro_int$location_detail <- NA
claro_int$location_detail <- as.character(claro_int$location_detail)

#tech_2g, tech_3g, tech_4g: No access in torres andinas (for now)
claro_int$"tech_2g" <- !is.na(claro_int$`2g`)
claro_int$"tech_3g" <- !is.na(claro_int$`3g`)
claro_int$"tech_4g" <- !is.na(claro_int$`4g`)

#Type: 
claro_int$type <- NA
claro_int$type <- as.character(claro_int$type)

#Subtype: as character
claro_int$subtype <- NA
claro_int$subtype <- as.character(claro_int$subtype)

#In Service: IN SERVICE. From june onwards planned.
claro_int$in_service <- "IN SERVICE"

#Vendor: Does not apply
claro_int$vendor <- NA
claro_int$vendor <- as.character(claro_int$vendor)

#Coverage area 2G, 3G and 4G: 
claro_int$coverage_radius <- claro_int$tower_height/10
claro_int$coverage_radius[claro_int$coverage_radius<1.5] <- 1.5
claro_int$coverage_radius[claro_int$coverage_radius>15] <- 15

#Coverage area 2G, 3G and 4G
#Set connection data
claro_int <- coverageAreaClaro(schema_dev, table_test_claro, claro_int)
   
#fiber, radio, satellite: No info
claro_int$fiber <- FALSE
claro_int$radio <- FALSE
claro_int$satellite <- FALSE

#satellite band in use: Does not apply
claro_int$satellite_band_in_use <- NA
claro_int$satellite_band_in_use <- as.character(claro_int$satellite_band_in_use)

#radio_distance_km: no info on this
claro_int$radio_distance_km <- NA
claro_int$radio_distance_km <- as.numeric(claro_int$radio_distance_km)

#last_mile_bandwidth: no info on this
claro_int$last_mile_bandwidth <- NA
claro_int$last_mile_bandwidth <- as.character(claro_int$last_mile_bandwidth)


#Tower type:
claro_int$tower_type <- "INFRASTRUCTURE"

claro_int[((claro_int$tech_2g == TRUE)|(claro_int$tech_3g == TRUE)|(claro_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

claro_int[(((claro_int$fiber == TRUE)|(claro_int$radio == TRUE)|(claro_int$satellite == TRUE))&(claro_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

claro_int[(((claro_int$fiber == TRUE)|(claro_int$radio == TRUE)|(claro_int$satellite == TRUE))&(claro_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
claro_int$source_file <- file_name

#Source:
claro_int$source <- "CLARO"

#Internal ID:
claro_int$internal_id <- as.character(claro_int$internal_id)

#Tower name:
claro_int$tower_name <- as.character(claro_int$tower_name)

# IPT perimeter: NO IPT

claro_int$ipt_perimeter <- NA
claro_int$ipt_perimeter <- as.character(claro_int$ipt_perimeter)


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
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, claro)

#Set connection data
exportDB_B(schema_dev, table_claro, claro)

