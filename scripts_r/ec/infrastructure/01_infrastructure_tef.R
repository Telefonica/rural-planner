
#Load libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(xlsx)
library(RPostgreSQL)

#DB Connection parameters
config_path <- '~/shared/rural_planner_r/config_files/config_ec'
source(config_path)


file_name <- "Base procesada ESTRUCTURAS corte Junio 2019 Proyección Diciembre 2019 Final 03_07_2019.xlsx"
sheet <- "Estructuras"
skip <- 6

table_infrastructure <- "infrastructure_global_aux"
table_infrastructure_test  <- "test_towers"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_name_io <- "towers.rds"

source('~/shared/rural_planner_r/sql/ec/infrastructure/coverageAreaTest.R')
source('~/shared/rural_planner_r/sql/ec/infrastructure/exportInfrastructure.R')

# Load infrastructure dataset
towers_raw <- read_excel(paste(input_path_infrastructure, file_name, sep = "/"), sheet = sheet, skip = skip)

#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail, tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor, coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)
#source_file, internal_id

#The ID will be that of the row from the data frame
######################################################################################################################


#Select useful columns from raw input
towers_int <- data.frame(towers_raw$LATITUD,
                         towers_raw$LONGITUD,
                         towers_raw$"Mayor altura antena",
                         towers_raw$ASIGNACION,
                         towers_raw$"Codigo BDU",
                         towers_raw$nombre_estructura,
                         towers_raw$"Configuración Proyec Dic 2019",
                         towers_raw$Tipo_de_Estructura,
                         towers_raw$"Altura Estructura",
                         towers_raw$CODIGO_GEOGRAFICO,
                         towers_raw$"VENDOR 2G Proy Dic 2019",
                         towers_raw$"VENDOR 3G Proy Dic 2019",
                         towers_raw$"VENDOR 4G Proy Dic 2019",
                         towers_raw$"FREQ 2G Proy Dic 2019",
                         towers_raw$"FREQ 3G Proy Dic 2019",
                         towers_raw$"FREQ 4G Proy Dic 2019",
                         towers_raw$"TIPO TRANSMISION",
                         towers_raw$"CLAS. GEOG. ATOLL",
                         towers_raw$"Tipo línea eléctrica",
                         stringsAsFactors = F
)

#Change names of the variables we already have
colnames(towers_int) <- c("latitude", 
                          "longitude",
                          "tower_height",
                          "owner",
                          "internal_id",
                          "tower_name",
                          "technologies",
                          "struc_type",
                          "struc_alt",
                          "cod_geo",
                          "vendor_2g",
                          "vendor_3g",
                          "vendor_4g",
                          "freq_2g",
                          "freq_3g",
                          "freq_4g",
                          "transmission_type",
                          "clase_geo",
                          "power"
)

#Fill towers_int with the rest of the fields and reshape where necessary

#Latitude:
towers_int$latitude <- as.numeric(towers_int$latitude)

#Longitude:
towers_int$longitude <- as.numeric(towers_int$longitude)

#Tower height: as integer; for unkown towers it is set to 0
towers_int$tower_height[is.na(towers_int$tower_height)] <- as.integer(0)
towers_int$tower_height[(towers_int$tower_height %% 1) >= 0.50] <- ceiling(towers_int$tower_height[(towers_int$tower_height %% 1) >= 0.50]) 
towers_int$tower_height[(towers_int$tower_height %% 1) < 0.50] <- floor(towers_int$tower_height[(towers_int$tower_height %% 1) < 0.50])
towers_int$tower_height <- as.integer(towers_int$tower_height)


#Owner: as character
towers_int$owner <- as.character(towers_int$owner)


#Location detail: concat codigo greografico, altura de estructura y tipo estructura
towers_int$struc_alt[is.na(towers_int$struc_alt)] <- 0
towers_int$location_detail <- as.character(paste(towers_int$cod_geo, towers_int$struc_alt, towers_int$struc_type, sep = "_"))


#tech_2g, tech_3g, tech_4g: create from the field 'technologies'
towers_int$tech_2g <- FALSE
towers_int$tech_3g <- FALSE
towers_int$tech_4g <- FALSE

towers_int[grepl("2g",towers_int$technologies), "tech_2g"] <- TRUE
towers_int[grepl("3g",towers_int$technologies), "tech_3g"] <- TRUE
towers_int[grepl("4g",towers_int$technologies), "tech_4g"] <- TRUE


#Type: unknown
towers_int$type <- "MACRO"


#Subtype: concat clase geografica, freq2g, freq3g, freq4g
towers_int$subtype <- as.character(paste(towers_int$clase_geo, "FREQ2G", towers_int$freq_2g, "FREQ3G", towers_int$freq_3g, "FREQ4G", towers_int$freq_4g, sep = "_"))


#In Service: 
towers_int$in_service <- "IN SERVICE"
towers_int$in_service[is.na(towers_int$internal_id)] <- "PLANNED"


#Vendor: concat vendor2g, vendor3g, vendor4g
towers_int[grepl("NOKIA", towers_int$vendor_2g), "vendor_2g"] <- "NOKIA"
towers_int[grepl("SIEMENS", towers_int$vendor_2g), "vendor_2g"] <- "SIEMENS"
towers_int[grepl("ZTE", towers_int$vendor_2g), "vendor_2g"] <- "ZTE"

towers_int[grepl("ZTE", towers_int$vendor_3g), "vendor_3g"] <- "ZTE"
towers_int[grepl("NOKIA", towers_int$vendor_3g), "vendor_3g"] <- "NOKIA"

towers_int[grepl("ZTE", towers_int$vendor_4g), "vendor_4g"] <- "ZTE"
towers_int[grepl("NOKIA", towers_int$vendor_4g), "vendor_4g"] <- "NOKIA"

towers_int$vendor <- as.character(paste("VENDOR2g", towers_int$vendor_2g,"VENDOR3g", towers_int$vendor_3g, "VENDOR4g", towers_int$vendor_4g, sep = "_"))


#Coverage radius: unknown, assume tower_height/10 km for all towers (limits between 1.5 and 5 km)
towers_int$coverage_radius <- towers_int$tower_height/10
towers_int$coverage_radius[towers_int$coverage_radius<1.5] <- 1.5
towers_int$coverage_radius[towers_int$coverage_radius>5] <- 5


#Coverage area 2G, 3G and 4G

#Set connection data
towers_int <- coverageArea(schema_dev, table_infrastructure_test, towers_int)


#fiber, radio, satellite: create from transport fields
towers_int$fiber <- FALSE
towers_int$radio <- FALSE
towers_int$satellite <- FALSE

towers_int[grepl("Fiber-optic",towers_int$transmission_type),'fiber'] <- TRUE
towers_int[grepl("Microwave",towers_int$transmission_type),'radio'] <- TRUE
towers_int[grepl("SATELITAL",towers_int$transmission_type),'satellite'] <- TRUE


#satellite band in use: unknown.
towers_int$satellite_band_in_use <- NA
towers_int$satellite_band_in_use <- as.character(towers_int$satellite_band_in_use)

#radio_distance_km: reshaped as energy
towers_int$energy <- NA
towers_int[grepl("Baja",towers_int$power),'energy'] <- "LOW"
towers_int[grepl("Media",towers_int$power),'energy'] <- "MEDIUM"
towers_int$energy <- as.character(towers_int$energy)


#last_mile_bandwidth: as character
towers_int$last_mile_bandwidth <- NA
towers_int$last_mile_bandwidth <- as.character(towers_int$last_mile_bandwidth)


#Tower type:
towers_int$tower_type <- "INFRASTRUCTURE"

towers_int[((towers_int$tech_2g == TRUE)|(towers_int$tech_3g == TRUE)|(towers_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

towers_int[((towers_int$fiber == TRUE)|(towers_int$radio == TRUE)|(towers_int$satellite == TRUE))&(towers_int$tower_type == "ACCESS"), 'tower_type'] <- "ACCESS AND TRANSPORT"

towers_int[((towers_int$fiber == TRUE)|(towers_int$radio == TRUE)|(towers_int$satellite == TRUE))&(towers_int$tower_type == "INFRASTRUCTURE"), 'tower_type'] <- "TRANSPORT"


#Source file:
towers_int$source_file <- as.character(file_name)


#Source
towers_int$source <- "TEF"


#Internal ID:
towers_int$internal_id <- as.character(towers_int$internal_id)


#Tower name:
towers_int$tower_name <- as.character(towers_int$tower_name)


#IPT perimeter : No information for now
towers_int$ipt_perimeter <- NA
towers_int$ipt_perimeter <- as.character(towers_int$ipt_perimeter)


#Create final normalized data frame in the right order

#Final macro data frame
towers <- towers_int[,c("latitude",
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
                        "energy",
                        "last_mile_bandwidth",
                        
                        "source_file",
                        "source",
                        "internal_id",
                        "tower_name",
                        "ipt_perimeter"
)]

#Export the normalized output
saveRDS(towers, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, towers)

exportInfrastructure(schema_dev, table_infrastructure, towers)

