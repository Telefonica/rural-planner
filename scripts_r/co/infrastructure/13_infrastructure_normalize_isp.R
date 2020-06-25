#Libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(XLConnect)
library(XLConnectJars)
library(sp)
library(dplyr)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

### VARIABLES ###
file_name_1 <- "Copia de LISTA COMPLETA ISP.xlsx"
file_name_2 <- "PuntoRED.xlsx"
file_name_3 <- "Ingettel.xlsx"
file_name_4 <- "20190716_Base consolidada ISPs interesados v1.xlsx"
sheet <- "3. Internet para todos"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "isp.rds"

source('~/shared/rural_planner/sql/exportDB_Infrastructure.R')

#Load isp nodes
skip <- 5

isp_raw_1 <- read_excel(paste(input_path_infrastructure, file_name_1, sep='/'),sheet = sheet, skip = skip)

isp_raw_2 <- read_excel(paste(input_path_infrastructure, file_name_2, sep='/'),sheet = sheet, skip = skip)

isp_raw_3 <- read_excel(paste(input_path_infrastructure, file_name_3, sep='/'),sheet = sheet, skip = skip)

skip <- 0
isp_raw_4 <- read_excel(paste(input_path_infrastructure, file_name_4, sep='/'),sheet = sheet)


#Select useful columns from raw input

isp_int <- data.frame(isp_raw_1$EMPRESA,
                      isp_raw_1$Departamento,
                      isp_raw_1$Municipio,
                      isp_raw_1$Latitud,
                      isp_raw_1$Longitud,
                      isp_raw_1$Torre,
                      isp_raw_1$'Tipo de Torre',
                      isp_raw_1$'Altura de Torre en Mts',
                      isp_raw_1$'Tipo de transmision Utilizada',
                      stringsAsFactors = FALSE
                     )

#Change names of the variables we already have
colnames(isp_int) <- c("owner",
                       "admin_divison_2_name",
                       "admin_division_1_name",
                       "latitude",
                       "longitude",
                       "type",
                       "subtype",
                       "tower_height",
                       "tx_type"
                      )

isp_raw_2$owner <- "PuntoRED"
isp_raw_3$owner <- "Ingettel"
isp_int_2 <- rbind(isp_raw_2, isp_raw_3)

#Change names of the variables we already have
colnames(isp_int_2) <- c("admin_divison_2_name",
                       "admin_division_1_name",
                       "latitude",
                       "longitude",
                       "type",
                       "subtype",
                       "tower_height",
                       "tx_type",
                       "owner"
                      )

isp_int <- rbind(isp_int, isp_int_2)

#Select useful columns from raw input 4
isp_int_3 <- data.frame(isp_raw_4$Empresa,
                        isp_raw_4$Departamento,
                        isp_raw_4$Municipio,
                        isp_raw_4$Latitud,
                        isp_raw_4$Longitud,
                        isp_raw_4$Torre,
                        isp_raw_4$'Tipo de Torre',
                        isp_raw_4$'Altura de Torre en Mts',
                        isp_raw_4$'Tipo de transmision Utilizada',
                        stringsAsFactors = FALSE
                       )

#Change names of the variables we already have
colnames(isp_int_3) <- c("owner",
                       "admin_divison_2_name",
                       "admin_division_1_name",
                       "latitude",
                       "longitude",
                       "type",
                       "subtype",
                       "tower_height",
                       "tx_type"
                      )

isp_int <- rbind(isp_int, isp_int_3)


######################################################################################################################
#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail,  tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor, coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)

#The ID will be that of the row from the data frame
######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude:

isp_int$latitude[isp_int$latitude=='N/A'] <- NA
# Remove NAs
isp_int <- isp_int[!is.na(isp_int$latitude),]
#Process DMS coordinates:
isp_int$latitude[grepl("N|S", isp_int$latitude)] <- gsub(",",".",isp_int$latitude[grepl("N|S", isp_int$latitude)])
isp_int$latitude[grepl("\"", isp_int$latitude)] <- gsub(" ","",isp_int$latitude[grepl("\"", isp_int$latitude)])
isp_int$latitude[grepl("\'\'", isp_int$latitude)] <- gsub(" ","",isp_int$latitude[grepl("\'\'", isp_int$latitude)])
isp_int$latitude[grepl("\"(N|S)", isp_int$latitude)] <- gsub(" ","",isp_int$latitude[grepl("\"(N|S)", isp_int$latitude)])
isp_int$latitude[grepl("\"(N|S)", isp_int$latitude)] <- as.character(as.numeric(char2dms(gsub("N","",isp_int$latitude[grepl("\"(N|S)", isp_int$latitude)]), chd = "°", chm = "'", chs = "\"")))
isp_int$latitude[grepl("\'\'(N|S)", isp_int$latitude)] <- as.character(as.numeric(char2dms(gsub("N","",isp_int$latitude[grepl("\'\'(N|S)", isp_int$latitude)]), chd = "°", chm = "'", chs = "\'\'")))
isp_int$latitude[grepl("N|S", isp_int$latitude)] <- sub(" ","°",isp_int$latitude[grepl("N|S", isp_int$latitude)])
isp_int$latitude[grepl("N|S", isp_int$latitude)] <- as.character(as.numeric(char2dms(isp_int$latitude[grepl("N|S", isp_int$latitude)], chd = "°", chm = " ", chs = "N")))
isp_int$latitude[grepl("°", isp_int$latitude)] <- gsub("°","",isp_int$latitude[grepl("°", isp_int$latitude)])
isp_int$latitude[!(grepl(".", isp_int$latitude, fixed = T))] <- paste0(substring(isp_int$latitude[!(grepl(".", isp_int$latitude, fixed = T))],1,1), ".", substring(isp_int$latitude[!(grepl(".", isp_int$latitude, fixed = T))], 2) )

isp_int$latitude <- as.numeric(isp_int$latitude) 

#Longitude:

isp_int$longitude[isp_int$longitude=='N/A'] <- NA

isp_int <- isp_int[!is.na(isp_int$longitude),]
#Process DMS coordinates:
isp_int$longitude[grepl("N", isp_int$longitude)] <- gsub("N","O",isp_int$longitude[grepl("N", isp_int$longitude)])
isp_int$longitude[grepl("O|W", isp_int$longitude)] <- gsub(",",".",isp_int$longitude[grepl("O|W", isp_int$longitude)])
isp_int$longitude[grepl("O|W", isp_int$longitude)] <- paste0("-",isp_int$longitude[grepl("O|W", isp_int$longitude)])
isp_int$longitude[grepl("\"", isp_int$longitude)] <- gsub(" ","",isp_int$longitude[grepl("\"", isp_int$longitude)])
isp_int$longitude[grepl("\'\'", isp_int$longitude)] <- gsub(" ","",isp_int$longitude[grepl("\'\'", isp_int$longitude)])
isp_int$longitude[grepl("\"(O|W)", isp_int$longitude)] <- gsub(" ","",isp_int$longitude[grepl("\"(O|W)", isp_int$longitude)])
isp_int$longitude[grepl("\"O", isp_int$longitude)] <- as.character(as.numeric(char2dms(gsub("O","",isp_int$longitude[grepl("\"O", isp_int$longitude)]), chd = "°", chm = "'", chs = "\"")))
isp_int$longitude[grepl("\"W", isp_int$longitude)] <- as.character(as.numeric(char2dms(gsub("W","",isp_int$longitude[grepl("\"W", isp_int$longitude)]), chd = "°", chm = "'", chs = "\"")))
isp_int$longitude[grepl("\'\'O", isp_int$longitude)] <- as.character(as.numeric(char2dms(gsub("O","",isp_int$longitude[grepl("\'\'O", isp_int$longitude)]), chd = "°", chm = "'", chs = "\'\'")))
isp_int$longitude[grepl("W", isp_int$longitude)] <- sub(" ","°",isp_int$longitude[grepl("W", isp_int$longitude)])
isp_int$longitude[grepl("W", isp_int$longitude)] <- as.character(as.numeric(char2dms(isp_int$longitude[grepl("W", isp_int$longitude)], chd = "°", chm = " ", chs = "W")))
isp_int$longitude[grepl("°", isp_int$longitude)] <- gsub("°","",isp_int$longitude[grepl("°", isp_int$longitude)])
isp_int$longitude[!(grepl(".", isp_int$longitude, fixed = T))] <- paste0(substring(isp_int$longitude[!(grepl(".", isp_int$longitude, fixed = T))],1,3), ".", substring(isp_int$longitude[!(grepl(".", isp_int$longitude, fixed = T))], 4) )

isp_int$longitude[grepl("O", isp_int$longitude)] <- sub(" ","°",isp_int$longitude[grepl("O", isp_int$longitude)])
isp_int$longitude[grepl("O", isp_int$longitude)] <- sub(" O","O",isp_int$longitude[grepl("O", isp_int$longitude)])
isp_int$longitude[grepl("O", isp_int$longitude)] <- as.character(as.numeric(char2dms(isp_int$longitude[grepl("O", isp_int$longitude)], chd = "°", chm = " ", chs = "O")))

isp_int$longitude <- as.numeric(isp_int$longitude) 


#Tower height:
isp_int$tower_height[is.na(isp_int$tower_height)] <- 0
isp_int$tower_height <- as.integer(isp_int$tower_height)

#Owner: as character
isp_int$owner <- as.character(toupper(isp_int$owner))


#Location detail:
#Admin division concat as location detail
isp_int$admin_division_1_name <- as.character(toupper(isp_int$admin_division_1_name))
isp_int$admin_divison_2_name <- as.character(toupper(isp_int$admin_divison_2_name)) 

isp_int$location_detail <- as.character(paste(isp_int$admin_divison_2_name, isp_int$admin_division_1_name, sep = ", "))


#tech_2g, tech_3g, tech_4g: No information
isp_int$"tech_2g" <- FALSE
isp_int$"tech_3g" <- FALSE
isp_int$"tech_4g" <- FALSE


#Type: as character
isp_int$type <- as.character(isp_int$type)


#Subtype:
isp_int$subtype <- as.character(isp_int$subtype)


#In Service:  No info; all in service
isp_int$in_service <- "IN SERVICE"


#Vendor: Does not apply
isp_int$vendor <- NA
isp_int$vendor <- as.character(isp_int$vendor)


#Coverage area 2G, 3G and 4G: No ACCESS
isp_int$coverage_area_2g <- NA
isp_int$coverage_area_2g <- as.character(isp_int$coverage_area_2g)

isp_int$coverage_area_3g <- NA
isp_int$coverage_area_3g <- as.character(isp_int$coverage_area_3g)

isp_int$coverage_area_4g <- NA
isp_int$coverage_area_4g <- as.character(isp_int$coverage_area_4g)


#fiber, radio, satellite:
isp_int$fiber <- FALSE
isp_int$radio <- FALSE
isp_int$satellite <- FALSE

isp_int[grepl("MICROONDAS", isp_int$tx_type), "radio"] <- TRUE
isp_int[grepl("FIBRA", isp_int$tx_type), "fiber"] <- TRUE


#satellite band in use: Does not apply
isp_int$satellite_band_in_use <- NA
isp_int$satellite_band_in_use <- as.character(isp_int$satellite_band_in_use)


#radio_distance_km: Does not apply
isp_int$radio_distance_km <- NA
isp_int$radio_distance_km <- as.numeric(isp_int$radio_distance_km)


#last_mile_bandwidth: Does not apply
isp_int$last_mile_bandwidth <- NA
isp_int$last_mile_bandwidth <- as.character(isp_int$last_mile_bandwidth)


#Tower type: 
isp_int$tower_type <- "INFRASTRUCTURE"

isp_int[((isp_int$tech_2g == TRUE)|(isp_int$tech_3g == TRUE)|(isp_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

isp_int[(((isp_int$fiber == TRUE)|(isp_int$radio == TRUE)|(isp_int$satellite == TRUE))&(isp_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

isp_int[(((isp_int$fiber == TRUE)|(isp_int$radio == TRUE)|(isp_int$satellite == TRUE))&(isp_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"


#Source file:
isp_int$source_file <- file_name_4


#Source:
isp_int$source <- "ISP"


#Internal ID:
isp_int$internal_id <- NA
isp_int$internal_id <- as.character(isp_int$internal_id)


#Tower name
isp_int$tower_name <- NA
isp_int$tower_name <- as.character(isp_int$tower_name)


#IPT perimeter : No information for now
isp_int$ipt_perimeter <- NA
isp_int$ipt_perimeter <- as.character(isp_int$ipt_perimeter)

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
isp <- isp_int[,c("latitude",
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
saveRDS(isp, paste(output_path, file_name_io, sep = "/"))

#If this test returns true then the export has been successful
test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, isp)

#Export to DB
exportDB_Infrastructure(schema_dev, table_isp, isp)
