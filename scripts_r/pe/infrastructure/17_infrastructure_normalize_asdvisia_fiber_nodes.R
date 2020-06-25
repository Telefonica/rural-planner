
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(rgdal)
library(gdalUtils)
library(postGIStools)
library(maptools)
library(raster)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)

#VARIABLES
output_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_name <- "Nodos_RT_Cajamarca.xlsx"
sheet <- 1

file_name_io <- "cajamarca_fiber_nodes.rds"

source('~/shared/rural_planner/sql/pe/infrastructure/exportAsdvisiaFiber.R')

file.exists(paste(input_path_infrastructure, file_name, sep = "/"))
nodes_raw <- read_excel(paste(input_path_infrastructure, file_name, sep = "/"), sheet = sheet)

nombres<- names(nodes_raw)[1:10]
for(i in 11:13){
  nombres<- c(nombres,as.character(nodes_raw[1,i]))
}
names(nodes_raw)<- nombres

nodes_raw <- nodes_raw[-1,]

#Select useful columns from ka_raw input
nodes_int <- data.frame(nodes_raw$LATITUD,
                        nodes_raw$LONGITUD,
                        nodes_raw$CodINEI2010,
                        nodes_raw$LOCALIDAD,
                        nodes_raw$'TIPO DE NODO ÓPTICO (PROYECTO REGIONAL)',
                        nodes_raw$'NODOS ÓPTICOS CON DIVERSIDAD DE RUTAS FISICAS',
                        nodes_raw$'DATA DE UBICACIÓN',
                        stringsAsFactors = FALSE)

#Change names of the variables we already have
colnames(nodes_int) <- c("latitude",
                         "longitude",
                         "cod_inei",
                         "localidad",
                         "type",
                         "subtype",
                         "source")


#Correct wrong coordinates
stringi::stri_sub(nodes_int$longitude, 4, 3) <- "."
stringi::stri_sub(nodes_int$latitude, 3, 2) <- "."

#Latitude:
nodes_int$latitude <- as.numeric(nodes_int$latitude)

#Longitude:
nodes_int$longitude <- as.numeric(nodes_int$longitude)

#Tower height:
nodes_int$tower_height <- 0

#Owner:
nodes_int$owner <- NA
nodes_int$owner <- as.character(nodes_int$owner) 

#Location detail: as char
nodes_int$location_detail <- paste(nodes_int$cod_inei,nodes_int$localidad,sep=" - ") 

Encoding(nodes_int$location_detail) <- "UTF-8"

#tech_2g, tech_3g, tech_4g:
nodes_int$"tech_2g" <- FALSE
nodes_int$"tech_3g" <- FALSE
nodes_int$"tech_4g" <- FALSE

#Type:
nodes_int$type <- as.character(nodes_int$type)

#Subtype
nodes_int[grepl("NO", nodes_int$subtype), "subtype"] <- ""
nodes_int[grepl("SI", nodes_int$subtype), "subtype"] <- "NODO OPTICO CON DIVERSIDAD DE RUTAS FISICAS"

#In Service: 
nodes_int$in_service <- "PLANNED"

#Vendor: Unknown
nodes_int$vendor <- NA
nodes_int$vendor <- as.character(nodes_int$vendor)

#Coverage area 2G, 3G and 4G
nodes_int$coverage_area_2g <- NA
nodes_int$coverage_area_2g <- as.character(nodes_int$coverage_area_2g)

nodes_int$coverage_area_3g <- NA
nodes_int$coverage_area_3g <- as.character(nodes_int$coverage_area_3g)

nodes_int$coverage_area_4g <- NA
nodes_int$coverage_area_4g <- as.character(nodes_int$coverage_area_4g)


#fiber, radio, satellite: create from transport field
nodes_int$fiber <- TRUE
nodes_int$radio <- FALSE
nodes_int$satellite <- FALSE

#satellite band in use:
nodes_int$satellite_band_in_use <- NA
nodes_int$satellite_band_in_use <- as.character(nodes_int$satellite_band_in_use)

#radio_distance_km: no info on this
nodes_int$radio_distance_km <- NA
nodes_int$radio_distance_km <- as.numeric(nodes_int$radio_distance_km)

#last_mile_bandwidth:
nodes_int$last_mile_bandwidth <- NA
nodes_int$last_mile_bandwidth <- as.character(nodes_int$last_mile_bandwidth)

#Tower type:
nodes_int$tower_type <- "INFRASTRUCTURE"

nodes_int[((nodes_int$tech_2g == TRUE)|(nodes_int$tech_3g == TRUE)|(nodes_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

nodes_int[(((nodes_int$fiber == TRUE)|(nodes_int$radio == TRUE)|(nodes_int$satellite == TRUE))&(nodes_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

nodes_int[(((nodes_int$fiber == TRUE)|(nodes_int$radio == TRUE)|(nodes_int$satellite == TRUE))&(nodes_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file
nodes_int$source_file <- file_name

#Source:
#nodes_int$source<- "FIBER_PLANNED"
nodes_int$source <- as.character(nodes_int$source)

#Internal ID:
nodes_int$internal_id <- NA
nodes_int$internal_id <- as.character(nodes_int$internal_id)

## IPT Perimeter: doest not apply
nodes_int$ipt_perimeter <- "NO IPT"
nodes_int$ipt_perimeter <- as.character(nodes_int$ipt_perimeter)

## Tower name
nodes_int$tower_name <- nodes_int$internal_id
nodes_int$tower_name <- as.character(nodes_int$tower_name)


nodes <- nodes_int[,c("latitude",
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


#Export the normalized output
saveRDS(nodes, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, nodes)

exportAsdvisiaFiber(schema_dev, table_asdvisia_fiber, nodes)

