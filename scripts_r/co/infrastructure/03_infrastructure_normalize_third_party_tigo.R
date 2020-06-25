#Load libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

file_name <- "20191008 Baseline LTE Tigo- Sitios maximo.xls"
sheet <- 1

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "tigo.rds"

#Set connection data
source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')
source('~/shared/rural_planner/sql/co/infrastructure/coverageArea_test.R')


#Load tigo nodes
tigo_raw <- read_excel(paste(input_path_infrastructure, file_name, sep = "/"), sheet = sheet)


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

tigo_int <- data.frame(tigo_raw$LATITUDE,
                       tigo_raw$LONGITUDE,
                       tigo_raw$ALTURA_ESTRUCTURA,
                       tigo_raw$OWNER,
                       tigo_raw$DIRECCION,
                       stringsAsFactors = F
)

#Change names of the variables we already have
colnames(tigo_int) <- c("latitude", 
                        "longitude",
                        "tower_height",
                        "owner",
                        "location_detail"
)
######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#internal_id: AD-HOC: concatenate "ENODEBID" and "CELLID"
tigo_int$internal_id <- paste(tigo_raw$ENODEBID, tigo_raw$CELLID, sep = "-")

#Latitude: AD-HOC: towers with Internal-Id : "1786-101" "1786-102" "1786-103" "1786-1"   "1786-2"   "1786-3"  wrong ('.' missing)
tigo_int$latitude[grepl("1786", tigo_int$internal_id)]<-  as.numeric(4.683394)


#Longitude: "1786-101" "1786-102" "1786-103" "1786-1"   "1786-2"   "1786-3"  wrong ('.' missing)
tigo_int$longitude[grepl("1786", tigo_int$internal_id)]<- -74.051559

#Tower height: as integer, delete NAs, and 
tigo_int$tower_height <- as.integer(tigo_int$tower_height)
tigo_int$tower_height[is.na(tigo_int$tower_height) | tigo_int$tower_height<10] <- as.integer(10)

#Owner: already done

#Location detail:  already done

#type: AD-HOC: "MACRO"
tigo_int$type <- "MACRO"

#Tech_2g,Tech_3g,Tech_4g: AD-HOC: All cells are eNodeB so Tech_4g = TRUE
tigo_int$tech_2g <- FALSE
tigo_int$tech_3g <- FALSE
tigo_int$tech_4g <- TRUE

#Subtype: AD-HOC: concatenate "TIPO_ESTRUCTURA" and "TIPO_COBERTURA"
tigo_int$subtype <- paste(tigo_raw$TIPO_ESTRUCTURA,tigo_raw$TIPO_COBERTURA,sep=" ")

#In_service: AD-HOC: we have the date since they have been on air, all "IN SERVICE"
tigo_int$in_service <- "IN SERVICE"

#vendor: AD-HOC: "OPERADOR"
tigo_int$vendor[grepl("MOVISTAR",tigo_raw$OPERADOR)] <- "MOVISTAR"
tigo_int$vendor[grepl("TIGO",tigo_raw$OPERADOR)]<- "TIGO"

#Coverage radius: unknown, assume tower_height/10 km for all towers (limits between 1.5 and 5 km)
tigo_int$coverage_radius <- tigo_int$tower_height/10
tigo_int$coverage_radius[tigo_int$coverage_radius<1.5] <- 1.5
tigo_int$coverage_radius[tigo_int$coverage_radius>5] <- 5

#Coverage area 2G, 3G and 4G
tigo_int <- coverageArea_test(schema_dev, table_tigo_test, tigo_int)
   
#Fiber, radio, satellite:
tigo_int$fiber[grepl("OPTICAL FIBER", tigo_raw$TIPO_TX) | grepl("FO", tigo_raw$TIPO_TX) ] <- TRUE
tigo_int$radio[grepl("RADIO", tigo_raw$TIPO_TX) | grepl("MW", tigo_raw$TIPO_TX) ] <- TRUE
tigo_int$satellite <- FALSE

#satellite band in use: unknown.
tigo_int$satellite_band_in_use <- NA
tigo_int$satellite_band_in_use <- as.character(tigo_int$satellite_band_in_use)

#radio_distance_km: unknown
tigo_int$radio_distance_km <- NA
tigo_int$radio_distance_km <- as.numeric(tigo_int$radio_distance_km)


#last_mile_bandwidth: as character
tigo_int$last_mile_bandwidth <- NA
tigo_int$last_mile_bandwidth <- as.character(tigo_int$last_mile_bandwidth)

#Tower type: AD-HOC: all have tech_4g
tigo_int$tower_type <- "ACCESS"
tigo_int[(tigo_int$fiber == TRUE)|(tigo_int$radio == TRUE)|(tigo_int$satellite == TRUE), 'tower_type'] <- "ACCESS AND TRANSPORT"

#Source file:
tigo_int$source_file <- file_name

#tower_name: AD-HOC: cellname
tigo_int$tower_name <- tigo_raw$CELL_NAME

#Source:
tigo_int$source <- "TIGO"

#IPT perimeter : Does not apply

tigo_int$ipt_perimeter <- NA

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
tigo <- tigo_int[,c("latitude",
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
tigo
######################################################################################################################



#Export the normalized output
saveRDS(tigo, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, tigo)


exportDB_Infrastructure(schema_dev, table_tigo, tigo)






