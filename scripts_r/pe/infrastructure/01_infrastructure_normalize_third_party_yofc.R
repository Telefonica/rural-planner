

#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)

#VARIABLE
input_path <- "~/shared/rural_planner/data/pe/infrastructure"
file_name <- "Reg&IPT.xlsx"
skip <- 0

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "yofc.rds"

source('~/shared/rural_planner/sql/pe/infrastructure/exportDB_A.R')

#Load gilat nodes
yofc_raw <- read_excel(paste(input_path,  file_name, sep = "/"), skip = skip)

yofc_raw


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

yofc_int <- data.frame(yofc_raw$Lati,
                       yofc_raw$Longi,
                       yofc_raw$IPT,
                       yofc_raw$Ubig
                       )


#Change names of the variables we already have
colnames(yofc_int) <- c("latitude", 
                      "longitude",
                      "ipt",
                      "location_detail"
                      )

######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done

#Longitude: already done

#Tower height: as integer
yofc_int$tower_height <- 0
yofc_int$tower_height <- as.integer(yofc_int$tower_height)

#Owner: all Torres Andinas
yofc_int$owner <- "YOFC"
yofc_int$owner <- as.character(yofc_int$owner)

#Location detail: as character
yofc_int$location_detail <- as.character(yofc_int$location_detail)

#tech_2g, tech_3g, tech_4g: No access in torres andinas (for now)
yofc_int$"tech_2g" <- FALSE
yofc_int$"tech_3g" <- FALSE
yofc_int$"tech_4g" <- FALSE

#Type: ASSUMPTION: We can use all of the nodes for transport. We will not use them for access.
yofc_int$type <- NA
yofc_int$type <- as.character(yofc_int$type)

#Subtype: as character
yofc_int$subtype <- NA
yofc_int$subtype <- as.character(yofc_int$subtype)

#In Service: IN SERVICE.
yofc_int$in_service <- "PLANNED"

#Vendor: Does not apply
yofc_int$vendor <- NA
yofc_int$vendor <- as.character(yofc_int$vendor)

#Coverage area 2G, 3G and 4G: No info
yofc_int$coverage_area_2g <- NA
yofc_int$coverage_area_2g <- as.character(yofc_int$coverage_area_2g)

yofc_int$coverage_area_3g <- NA
yofc_int$coverage_area_3g <- as.character(yofc_int$coverage_area_3g)

yofc_int$coverage_area_4g <- NA
yofc_int$coverage_area_4g <- as.character(yofc_int$coverage_area_4g)

#fiber, radio, satellite: ALL fiber
yofc_int$fiber <- TRUE
yofc_int$radio <- FALSE
yofc_int$satellite <- FALSE

#satellite band in use: Does not apply
yofc_int$satellite_band_in_use <- NA
yofc_int$satellite_band_in_use <- as.character(yofc_int$satellite_band_in_use)

#radio_distance_km: no info on this
yofc_int$radio_distance_km <- NA
yofc_int$radio_distance_km <- as.numeric(yofc_int$radio_distance_km)

#last_mile_bandwidth: no info on this
yofc_int$last_mile_bandwidth <- NA
yofc_int$last_mile_bandwidth <- as.character(yofc_int$last_mile_bandwidth)


#Tower type:
yofc_int$tower_type <- "INFRASTRUCTURE"

yofc_int[((yofc_int$tech_2g == TRUE)|(yofc_int$tech_3g == TRUE)|(yofc_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

yofc_int[(((yofc_int$fiber == TRUE)|(yofc_int$radio == TRUE)|(yofc_int$satellite == TRUE))&(yofc_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

yofc_int[(((yofc_int$fiber == TRUE)|(yofc_int$radio == TRUE)|(yofc_int$satellite == TRUE))&(yofc_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
yofc_int$source_file <- file_name

#Source:
yofc_int$source <- "YOFC"

#Internal ID:
yofc_int$internal_id <- paste0("YOFC-",yofc_int$location_detail)
yofc_int$internal_id <- as.character(yofc_int$internal_id)

#Tower name:
yofc_int$tower_name <- NA
yofc_int$tower_name <- as.character(yofc_int$tower_name)

# IPT perimeter: NO IPT
yofc_int$ipt_perimeter <- NA
yofc_int$ipt_perimeter <- as.character(yofc_int$ipt_perimeter)


######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
yofc <- yofc_int[,c("latitude",
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
yofc
######################################################################################################################




#Export the normalized output
saveRDS(yofc, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, yofc)

exportDB_A(schema_dev, table_yofc, yofc)

