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

### VARIABLES ###
file_name <- "Red TX Azteca-Anditel.csv"
sheet <- "TD"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "anditel.rds"

source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')


#Load anditel nodes
anditel_raw <- read.csv2(paste(input_path_infrastructure, file_name, sep='/'),header=T, dec=".",fileEncoding="latin1")


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

anditel_int <- data.frame(anditel_raw$Latitude,
                     anditel_raw$Longitude,
                     anditel_raw$"Tower.height",
                     anditel_raw$Altura..m.,
                     anditel_raw$Codigo.Andired,
                     anditel_raw$RED.TX,
                     anditel_raw$Site.name,
                     anditel_raw$Estado.24.05.2018,
                     anditel_raw$NOMBRE.NODO
      )

#Change names of the variables we already have
colnames(anditel_int) <- c("latitude", 
                      "longitude",
                      "tower_height_i",
                      "tower_height_ii",
                      "internal_id",
                      "type",
                      "location_detail",
                      "in_service",
                      "tower_name"
                      )
######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

## AD HOC: Parse null fields to NA

anditel_int[anditel_int=='(en blanco)'] <- NA
anditel_int[anditel_int==''] <- NA
anditel_int <- anditel_int[c(-913),]


#Latitude:

anditel_int$latitude <- gsub("°"," ",anditel_int$latitude)
anditel_int$latitude <- gsub("° "," ",anditel_int$latitude)
anditel_int$latitude <- gsub("'"," ",anditel_int$latitude)
anditel_int$latitude <- gsub('"'," ",anditel_int$latitude)
anditel_int$latitude <- gsub(',',".",anditel_int$latitude)

anditel_int$latitude[!is.na(anditel_int$latitude)] <- anditel_int$latitude[!is.na(anditel_int$latitude)] %>%
 sub(' ', 'd', .) %>%
 sub(' ', '\'', .) %>%
 sub(' ', '"', .) %>%
  char2dms %>%
  as.numeric


anditel_int$latitude <- as.numeric(anditel_int$latitude)

#Longitude:

anditel_int$longitude <- gsub("°"," ",anditel_int$longitude)
anditel_int$longitude <- gsub("° "," ",anditel_int$longitude)
anditel_int$longitude <- gsub("  "," ",anditel_int$longitude)
anditel_int$longitude <- gsub("'"," ",anditel_int$longitude)
anditel_int$longitude <- gsub('"'," ",anditel_int$longitude)
anditel_int$longitude <- gsub(',',".",anditel_int$longitude)

anditel_int$longitude[!is.na(anditel_int$longitude)] <- anditel_int$longitude[!is.na(anditel_int$longitude)] %>%
 sub(' ', 'd', .) %>%
 sub(' ', '\'', .) %>%
 sub(' ', '\"', .) %>%
  char2dms %>%
  as.numeric

anditel_int$longitude <- as.numeric(anditel_int$longitude)

 ## AD-HOC: Correct missing negative signs (longitude in Colombia -70° ~ -80°) and remove unlocated sites

anditel_int$longitude[anditel_int$longitude>0 & !is.na(anditel_int$longitude)] <- -(anditel_int$longitude[anditel_int$longitude>0 & !is.na(anditel_int$longitude)])
anditel_int <- anditel_int[!is.na(anditel_int$latitude),]

#Tower height: as integer
anditel_int$tower_height <- ifelse(!is.na(anditel_int$tower_height_i), as.integer(as.character(anditel_int$tower_height_i)), as.integer(as.character(anditel_int$tower_height_ii)))
anditel_int$tower_height[is.na(anditel_int$tower_height)] <- 30


#Owner: as character
anditel_int$owner <- as.character("ANDITEL")

#Location detail: as character (TX OWNER)
anditel_int$location_detail <- as.character(anditel_int$owner)

#tech_2g, tech_3g, tech_4g: Only Tx
anditel_int$"tech_2g" <- FALSE
anditel_int$"tech_3g" <- FALSE
anditel_int$"tech_4g" <- FALSE

#Type: No information
anditel_int$type <- as.character(anditel_int$type)

#Subtype: No information
anditel_int$subtype <- '-'
anditel_int$subtype <- as.character(anditel_int$subtype)

#In Service: 
anditel_int$in_service <- "IN SERVICE"
anditel_int$in_service[grepl("Se retira de la red",anditel_int$in_service)] <- "OUT OF SERVICE"
anditel_int$in_service[grepl("En operación",anditel_int$in_service)] <- "IN SERVICE"
anditel_int$in_service[grepl("En proceso",anditel_int$in_service)] <- "IN PROCESS"
anditel_int$in_service[grepl("2018",anditel_int$in_service)] <- "PLANNED"
anditel_int$in_service <- as.character(anditel_int$in_service)
#AD-HOC: Remove sites out of service
anditel_int <- anditel_int[!(anditel_int$in_service=='OUT OF SERVICE'),]

#Vendor: Does not apply
anditel_int$vendor <- NA
anditel_int$vendor <- as.character(anditel_int$vendor)

#Coverage area 2G, 3G and 4G: No ACCESS
anditel_int$coverage_area_2g <- NA
anditel_int$coverage_area_2g <- as.character(anditel_int$coverage_area_2g)

anditel_int$coverage_area_3g <- NA
anditel_int$coverage_area_3g <- as.character(anditel_int$coverage_area_3g)

anditel_int$coverage_area_4g <- NA
anditel_int$coverage_area_4g <- as.character(anditel_int$coverage_area_4g)

#fiber, radio, satellite: No info
anditel_int$fiber <- FALSE
anditel_int$fiber[anditel_int$owner=='AZTECA'] <- TRUE
anditel_int$radio <- FALSE
anditel_int$radio[anditel_int$owner=='ANDITEL'] <- TRUE
anditel_int$satellite <- FALSE

#satellite band in use: Does not apply
anditel_int$satellite_band_in_use <- NA
anditel_int$satellite_band_in_use <- as.character(anditel_int$satellite_band_in_use)

#radio_distance_km: Does not apply
anditel_int$radio_distance_km <- NA
anditel_int$radio_distance_km <- as.numeric(anditel_int$radio_distance_km)

#last_mile_bandwidth: Does not apply
anditel_int$last_mile_bandwidth <- NA
anditel_int$last_mile_bandwidth <- as.character(anditel_int$last_mile_bandwidth)

#Tower type: No information for now
anditel_int$tower_type <- "INFRASTRUCTURE"

anditel_int[((anditel_int$tech_2g == TRUE)|(anditel_int$tech_3g == TRUE)|(anditel_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

anditel_int[(((anditel_int$fiber == TRUE)|(anditel_int$radio == TRUE)|(anditel_int$satellite == TRUE))&(anditel_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

anditel_int[(((anditel_int$fiber == TRUE)|(anditel_int$radio == TRUE)|(anditel_int$satellite == TRUE))&(anditel_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
anditel_int$source_file <- file_name

#Source:
anditel_int$source <- "ANDITEL"


#Internal ID:
anditel_int$internal_id <- as.character(anditel_int$internal_id)

#Tower name
anditel_int$tower_name <- NA
anditel_int$tower_name <- as.character(anditel_int$tower_name)

#IPT perimeter : No information for now
anditel_int$ipt_perimeter <- NA
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
anditel <- anditel_int[,c("latitude",
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
anditel
######################################################################################################################



#Export the normalized output
saveRDS(anditel, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, anditel)

#Export to DB
exportDB_Infrastructure(schema_dev, table_anditel, anditel)

