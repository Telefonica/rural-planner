
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(xlsx)
library(RPostgreSQL)


#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)


#VARIABLES

file_name_loc <- "PR_Cajamarca_Localidades_Beneficiarias.xlsx"
file_name_rad <- "PR_Cajamarca_Radioenlaces.xlsx"
file_name_fo <- "Nodos_RT_Cajamarca.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_name <- "advisia.rds"

source('~/shared/rural_planner/sql/pe/infrastructure/exportAdvisia.R')

#VARIABLES
#Load access and transport advisia
advisia_loc_raw <- read_excel(paste(input_path_infrastructure,  file_name_loc, sep = "/"), skip=3)
advisia_rad_raw_1 <- read_excel(paste(input_path_infrastructure,  file_name_rad, sep = "/"),sheet=1, skip=4)
advisia_rad_raw_2 <- read_excel(paste(input_path_infrastructure,  file_name_rad, sep = "/"),sheet=2, skip=4)
advisia_rad_raw_3 <- read_excel(paste(input_path_infrastructure,  file_name_rad, sep = "/"),sheet=3, skip=4)
advisia_fo_raw <- read_excel(paste(input_path_infrastructure,  file_name_fo, sep = "/"), skip=1)



######################################################################################################################
#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail, tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor, coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)
#source_file, internal_id

#The ID will be that of the row from the data frame
######################################################################################################################


#Select useful columns from raw input
advisia_int <- data.frame( advisia_loc_raw$...1, 
                      advisia_loc_raw$`TIPO DE SALTO`,
                      advisia_loc_raw$LATITUD,
                     advisia_loc_raw$LONGITUD,

                     advisia_loc_raw$CodINEI2010,
                     advisia_loc_raw$LOCALIDAD,
                     
                     stringsAsFactors = F
                     
                     )

#Change names of the variables we already have
colnames(advisia_int) <- c( "internal_id",
                            "tx_type",
                            "latitude", 
                            "longitude",
                            "settlement_id",
                            "location_detail"
                            )

advisia_fo_int <- data.frame( advisia_fo_raw$...2,
                              advisia_fo_raw$LATITUD,
                              advisia_fo_raw$LONGITUD,
                              advisia_fo_raw$...6,
                     stringsAsFactors = F
                     
                     )
colnames(advisia_fo_int) <- c("settlement_id",
                              "latitude",
                              "longitude",
                              "location_detail"
                              )
 advisia_heights_1 <- advisia_rad_raw_1[!duplicated(advisia_rad_raw_1$CodINEI...2),c("CodINEI...2","ALTURA DE LA TORRE (m)...10")]
 names(advisia_heights_1) <- c("CodINEI...11","ALTURA DE LA TORRE (m)...19")
 advisia_heights_2 <- advisia_rad_raw_1[!duplicated(advisia_rad_raw_1$CodINEI...11),c("CodINEI...11","ALTURA DE LA TORRE (m)...19")]
 advisia_heights_3 <- advisia_rad_raw_2[!duplicated(advisia_rad_raw_2$CodINEI...11),c("CodINEI...11","ALTURA DE LA TORRE (m)...19")]
 advisia_heights_4 <- advisia_rad_raw_3[!duplicated(advisia_rad_raw_3$CodINEI...11),c("CodINEI...11","ALTURA DE LA TORRE (m)...19")]
 
advisia_heights <- rbind(advisia_heights_1,advisia_heights_2,advisia_heights_3,advisia_heights_4)
advisia_heights <- advisia_heights[!nchar(advisia_heights$CodINEI...11)==6,]
advisia_heights$CodINEI...11 <- str_pad(advisia_heights$CodINEI...11, 10, side="left", pad="0")
names(advisia_heights) <- c("settlement_id", "tower_height")
 
######################################################################################################################

#Latitude:

advisia_int$latitude <- as.numeric(as.character(advisia_int$latitude))

advisia_fo_int$latitude <- as.numeric(sub("([[:digit:]]{1,6})$", ".\\1",  as.character(advisia_fo_int$latitude)))

#Longitude:

advisia_int$longitude <- as.numeric(as.character(advisia_int$longitude))

advisia_fo_int$longitude <- as.numeric(sub("([[:digit:]]{2,6})$", ".\\1",  as.character(advisia_fo_int$longitude)))

## AD-HOC: Remove wrong values
advisia_int <- advisia_int[!(advisia_int$latitude==0 & advisia_int$longitude==0),]
advisia_int <- advisia_int[!(advisia_int$latitude==advisia_int$longitude),]

#Tower height: as integer; for unkown advisia it is set to 10

advisia_int <- merge(advisia_int, advisia_heights, by=c("settlement_id"), all.x=T)
advisia_int$tower_height <- as.integer(advisia_int$tower_height)

advisia_int$tower_height[is.na(advisia_int$tower_height) | advisia_int$tower_height<15] <- as.integer(15)

advisia_fo_int$tower_height <- as.integer(15)

#Owner: as character

advisia_int$owner <- as.character("ADVISIA")

advisia_fo_int$owner <- as.character("ADVISIA")

advisia_int$location_detail <- as.character(advisia_int$location_detail)

advisia_fo_int$location_detail <- as.character(advisia_fo_int$location_detail)

#tech_2g, tech_3g, tech_4g: create from the field 'technologies'; for transport no access technologies
advisia_int$tech_2g <- FALSE
advisia_int$tech_3g <- FALSE
advisia_int$tech_4g <- FALSE

advisia_fo_int$tech_2g <- FALSE
advisia_fo_int$tech_3g <- FALSE
advisia_fo_int$tech_4g <- FALSE


#Type: unknown
advisia_int$type <- as.character(NA)
advisia_fo_int$type <- as.character(NA)


#Subtype: AD-HOC : subtype is RAN owner
advisia_int$subtype <- as.character(NA)
advisia_fo_int$subtype <- as.character(NA)

#In Service: All in service
#advisia_int$in_service[grepl("OPERATING",advisia_int$status)] <- "IN SERVICE"
advisia_int$in_service <- "PLANNED"
advisia_fo_int$in_service <- "PLANNED"

#Vendor: as character (UNKNOWN)
advisia_int$vendor <- NA
advisia_int$vendor <- as.character(advisia_int$vendor)

advisia_fo_int$vendor <- NA
advisia_fo_int$vendor <- as.character(advisia_fo_int$vendor)

# Coverage area: NULL
advisia_int$coverage_area_2g <- as.character(NA)
advisia_int$coverage_area_3g <- as.character(NA)
advisia_int$coverage_area_4g <- as.character(NA)

advisia_fo_int$coverage_area_2g <- as.character(NA)
advisia_fo_int$coverage_area_3g <- as.character(NA)
advisia_fo_int$coverage_area_4g <- as.character(NA)

#fiber, radio, satellite: create from transport fields
advisia_int$fiber <- FALSE
advisia_int$radio <- FALSE
advisia_int$satellite <- FALSE


advisia_int[(grepl("SALTO 0",advisia_int$tx_type))&(!is.na(advisia_int$tx_type)),'fiber'] <- TRUE
advisia_int[(grepl("SALTO 1",advisia_int$tx_type))&(!is.na(advisia_int$tx_type)),'radio'] <- TRUE
advisia_int[(grepl("SALTO 2",advisia_int$tx_type))&(!is.na(advisia_int$tx_type)),'radio'] <- TRUE
advisia_int[(grepl("SALTO 3",advisia_int$tx_type))&(!is.na(advisia_int$tx_type)),'radio'] <- TRUE

advisia_fo_int$fiber <- TRUE
advisia_fo_int$radio <- FALSE
advisia_fo_int$satellite <- FALSE

#satellite band in use: unknown.
advisia_int$satellite_band_in_use <- NA
advisia_fo_int$satellite_band_in_use <- NA

#radio_distance_km: unknown

advisia_int$radio_distance_km <- NA
advisia_int$radio_distance_km <- as.numeric(advisia_int$radio_distance_km)

advisia_fo_int$radio_distance_km <- NA
advisia_fo_int$radio_distance_km <- as.numeric(advisia_fo_int$radio_distance_km)

#last_mile_bandwidth: as character
advisia_int$last_mile_bandwidth <- NA
advisia_int$last_mile_bandwidth <- as.character(advisia_int$last_mile_bandwidth)

advisia_fo_int$last_mile_bandwidth <- NA
advisia_fo_int$last_mile_bandwidth <- as.character(advisia_fo_int$last_mile_bandwidth)

#Tower type:
advisia_int$tower_type <- "INFRASTRUCTURE"

advisia_int[((advisia_int$tech_2g == TRUE)|(advisia_int$tech_3g == TRUE)|(advisia_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

advisia_int[((advisia_int$fiber == TRUE)|(advisia_int$radio == TRUE)|(advisia_int$satellite == TRUE))&(advisia_int$tower_type == "ACCESS"), 'tower_type'] <- "ACCESS AND TRANSPORT"

advisia_int[((advisia_int$fiber == TRUE)|(advisia_int$radio == TRUE)|(advisia_int$satellite == TRUE))&(advisia_int$tower_type == "INFRASTRUCTURE"), 'tower_type'] <- "TRANSPORT"


advisia_fo_int$tower_type <- "INFRASTRUCTURE"

advisia_fo_int[((advisia_fo_int$tech_2g == TRUE)|(advisia_fo_int$tech_3g == TRUE)|(advisia_fo_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

advisia_fo_int[((advisia_fo_int$fiber == TRUE)|(advisia_fo_int$radio == TRUE)|(advisia_fo_int$satellite == TRUE))&(advisia_fo_int$tower_type == "ACCESS"), 'tower_type'] <- "ACCESS AND TRANSPORT"

advisia_fo_int[((advisia_fo_int$fiber == TRUE)|(advisia_fo_int$radio == TRUE)|(advisia_fo_int$satellite == TRUE))&(advisia_fo_int$tower_type == "INFRASTRUCTURE"), 'tower_type'] <- "TRANSPORT"


#Source file:
advisia_int$source_file <- file_name_loc

advisia_fo_int$source_file <- file_name_fo


#Source
advisia_int$source <- "ADVISIA"

advisia_fo_int$source <- "ADVISIA"


#Internal ID:
advisia_int$internal_id <- as.character(advisia_int$internal_id)

advisia_fo_int$internal_id <- str_pad(advisia_fo_int$settlement_id, 10, side="left", pad="0")

#TOWER NAME:

advisia_int$tower_name <- as.character(advisia_int$settlement_id)
advisia_fo_int$tower_name <- str_pad(advisia_fo_int$settlement_id, 10, side="left", pad="0")

#IPT perimeter : No information for now

advisia_int$ipt_perimeter <- NA

advisia_fo_int$ipt_perimeter <- NA

## AD-HOC: Merge FO sites that are not in selected locations
advisia_fo_int <- advisia_fo_int[!(advisia_fo_int$tower_name%in%advisia_int$tower_name),]


######################################################################################################################

######################################################################################################################


#Create final normalized data frame in the right order

#Final macro data frame
advisia <- advisia_int[,c("latitude",
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

advisia_fo <- advisia_fo_int[,c("latitude",
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

advisia <- rbind(advisia, advisia_fo)
######################################################################################################################



#Export the normalized output
saveRDS(advisia, paste(output_path, file_name, sep = "/"))

test <- readRDS(paste(output_path, file_name, sep = "/"))
identical(test, advisia)




exportAdvisia(schema_dev, table_advisia, advisia)
