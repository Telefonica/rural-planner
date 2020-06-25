#Libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(xlsx)
library(RPostgreSQL)


#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)


### VARIABLES ###
file_name <- "20191009Infraestructura ColTel.xls"
sheet <- 1

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "towers.rds"

source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')
source('~/shared/rural_planner/sql/co/infrastructure/coverageArea_test.R')


#Load access and transport towers
towers_raw <- read_excel(paste(input_path_infrastructure, file_name, sep = "/"), sheet = sheet)



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
                         towers_raw$ALT_ESTRUCTURAS,
                         towers_raw$PROPI_ESTRUCTURAS,
                         towers_raw$TIPO_OPERACION,
                         towers_raw$TIPO_INMUEBLE,

                         towers_raw$TIPO_TX,
                         towers_raw$OPERACION_MOVIL,
                         towers_raw$STATUS,

                         towers_raw$DIRECCION,
                         towers_raw$LOCATION,
                         towers_raw$NOMBRE_EMPLAZAMIENTO,
                         stringsAsFactors = F
                        )

#Change names of the variables we already have
colnames(towers_int) <- c("latitude", 
                          "longitude",
                          "tower_height",
                          "owner",
                          "type",
                          "ran_type",

                          "transport",
                          "technologies",
                          "status",
                      
                          "location_detail" ,
                          "internal_id",
                          "tower_name"
                         )



#Latitude:
towers_int$latitude <- as.numeric(as.character(towers_int$latitude))


#Longitude:
towers_int$longitude <- as.numeric(as.character(towers_int$longitude))
towers_int$longitude[towers_int$longitude>0 & !is.na(towers_int$longitude>0)] <- -(towers_int$longitude[towers_int$longitude>0 & !is.na(towers_int$longitude>0)])

## AD-HOC: Remove wrong values (NAs and 0s)
towers_int <- towers_int[!(towers_int$latitude==0 & towers_int$longitude==0),]
towers_int <- towers_int[!(is.na(towers_int$latitude) | is.na(towers_int$longitude)),]



#Tower height: as integer; for unkown towers it is set to 10
towers_int$tower_height <- as.integer(towers_int$tower_height)
towers_int$tower_height[is.na(towers_int$tower_height) | towers_int$tower_height<10] <- as.integer(10)


#Owner: as character
towers_int$owner <- as.character(towers_int$owner)
towers_int$owner[is.na(towers_int$owner)] <- "TELEFONICA"
towers_int$owner[towers_int$owner=="N/A"] <- "TELEFONICA"


#tech_2g, tech_3g, tech_4g: create from the field 'technologies'; for transport no access technologies
towers_int$tech_2g <- FALSE
towers_int$tech_3g <- FALSE
towers_int$tech_4g <- FALSE

towers_int[grepl("GSM",towers_int$technologies), "tech_2g"] <- TRUE
towers_int[grepl("UMTS",towers_int$technologies), "tech_3g"] <- TRUE
towers_int[grepl("LTE",towers_int$technologies), "tech_4g"] <- TRUE

#Type: AD-HOC: delete NA´s
towers_int$type <- as.character(towers_int$type)

#Subtype: AD-HOC : subtype is RAN owner
towers_int$subtype <- as.character("MOVISTAR")
towers_int$subtype[(towers_int$ran_type=='TIGO RAN SHARING')] <- "TIGO"

#In Service: 
towers_int$in_service[grepl("OPERATING",towers_int$status)] <- "IN SERVICE"
towers_int$in_service[grepl("NOT READY",towers_int$status)] <- "PLANNED"


#Vendor: as character (UNKNOWN)
towers_int$vendor <- NA
towers_int$vendor <- as.character(towers_int$vendor)


#Coverage radius: unknown, assume tower_height/10 km for all towers (limits between 1.5 and 5 km)
towers_int$coverage_radius <- towers_int$tower_height/10
towers_int$coverage_radius[towers_int$coverage_radius<1.5] <- 1.5
towers_int$coverage_radius[towers_int$coverage_radius>5] <- 5

#Coverage area 2G, 3G and 4G. AD-HOC
towers_int <- coverageArea_test(schema_dev, table_tef_test, towers_int)


#fiber, radio, satellite: create from transport fields
towers_int$fiber <- FALSE
towers_int$radio <- FALSE
towers_int$satellite <- FALSE

towers_int[(grepl("FIBRA",towers_int$transport))&(!is.na(towers_int$transport)),'fiber'] <- TRUE
towers_int[(grepl("RADIO",towers_int$transport))&(!is.na(towers_int$transport)),'radio'] <- TRUE
towers_int[(grepl("REPETIDORRF",towers_int$type))&(!is.na(towers_int$type)),'radio'] <- TRUE
towers_int[(grepl("SATELIT",towers_int$transport))&(!is.na(towers_int$transport)),'satellite'] <- TRUE


towers_int <- towers_int[!grepl('COBRE',towers_int$transport),]


#satellite band in use: unknown.
towers_int$satellite_band_in_use <- NA
towers_int$satellite_band_in_use <- as.character(towers_int$satellite_band_in_use)

#radio_distance_km: unknown
towers_int$radio_distance_km <- NA
towers_int$radio_distance_km <- as.numeric(towers_int$radio_distance_km)


#last_mile_bandwidth: as character
towers_int$last_mile_bandwidth <- NA
towers_int$last_mile_bandwidth <- as.character(towers_int$last_mile_bandwidth)

#Tower type:
towers_int$tower_type <- "INFRASTRUCTURE"

towers_int[((towers_int$tech_2g == TRUE)|(towers_int$tech_3g == TRUE)|(towers_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

towers_int[((towers_int$fiber == TRUE)|(towers_int$radio == TRUE)|(towers_int$satellite == TRUE))&(towers_int$tower_type == "ACCESS"), 'tower_type'] <- "ACCESS AND TRANSPORT"

towers_int[((towers_int$fiber == TRUE)|(towers_int$radio == TRUE)|(towers_int$satellite == TRUE))&(towers_int$tower_type == "INFRASTRUCTURE"), 'tower_type'] <- "TRANSPORT"


#AD-HOC: Towers that only have Tx don't have RAN owner
towers_int$subtype[!(grepl("ACCESS", towers_int$tower_type))] <- '-'

#Source file:
towers_int$source_file <- file_name


#Source
towers_int$source <- "SITES_TEF"

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
                        "radio_distance_km",
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



#Export to DB
exportDB_Infrastructure(schema_dev, table_tef, towers)

dbDisconnect(con)

