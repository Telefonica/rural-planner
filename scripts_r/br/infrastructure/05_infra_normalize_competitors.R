
#LIBRARIES
library(gdalUtils)
library('png')
library(raster)
library("XML")
library(rgdal)
library(rgeos)
library(sf)
library("spex")
library(stringr)
library(tools)
library(readxl)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_br'
source(config_path)

#VARIABLES
batch_path <- "C:/Program Files/QGIS 2.18/bin/gdal_polygonize.py"
unzip_folder <- "unzip"
access_file <- '20190905143137_exportacao_mapa.xlsx'
file_name1 <- "csv_licenciamento_583041be.csv"
file_name2 <- "csv_licenciamento_63b06f17.csv"
file_name3 <- "csv_licenciamento_824d4e7e.csv"
file_name4 <- "csv_licenciamento_9c3bbb26.csv"
file_name5 <- "csv_licenciamento_f462b69f.csv"
file_name6 <- "csv_licenciamento_fdd4fab4.csv"
file_name7 <- "csv_licenciamento_ecb6f784.csv"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "infra_competitors.rds"

source('~/shared/rural_planner/sql/br/infrastructure/05_groupNodes.R')
source('~/shared/rural_planner/sql/exportDB_AddGeom.R')
source('~/shared/rural_planner/functions/readAllFilesCsv.R')


#dir.create(file.path(input_path_infrastructure,unzip_folder))

#Get all files from inside folders
#zip_files <- list.files(input_path_infrastructure,full.names = T,recursive = T,pattern='\\.zip$')

#Unzip files
#lapply(zip_files, function(x){unzip(x,exdir=paste(dirname(x),unzip_folder,sep ="/"))})

#Folder and file names
input_folder <- paste(input_path_infrastructure,unzip_folder,sep ="/")
input_files <- list.files( input_folder,full.names = F,recursive = T,pattern='\\.csv$')


path <- paste(input_path_infrastructure, 'unzip', sep="/")
towers_raw <- readAllFiles(input_files, path) 
csv1_df <- read.csv(paste(input_path_infrastructure,file_name1, sep="/"), fileEncoding = "latin1", stringsAsFactors = F)
csv2_df <- read.csv(paste(input_path_infrastructure,file_name2, sep="/"), fileEncoding = "latin1", stringsAsFactors = F)
csv3_df <- read.csv(paste(input_path_infrastructure,file_name3, sep="/"), fileEncoding = "latin1", stringsAsFactors = F)
csv4_df <- read.csv(paste(input_path_infrastructure,file_name4, sep="/"), fileEncoding = "latin1", stringsAsFactors = F)
csv5_df <- read.csv(paste(input_path_infrastructure,file_name5, sep="/"), fileEncoding = "latin1", stringsAsFactors = F)
csv6_df <- read.csv(paste(input_path_infrastructure,file_name6, sep="/"), fileEncoding = "latin1", stringsAsFactors = F)
csv7_df <- read.csv(paste(input_path_infrastructure,file_name7, sep="/"), fileEncoding = "latin1", stringsAsFactors = F)

towers_raw <- rbind(towers_raw, csv1_df)
towers_raw <- rbind(towers_raw, csv2_df)
towers_raw <- rbind(towers_raw, csv3_df)
towers_raw <- rbind(towers_raw, csv4_df)
towers_raw <- rbind(towers_raw, csv5_df)
towers_raw <- rbind(towers_raw, csv6_df)
towers_raw <- rbind(towers_raw, csv7_df)


towers_int <- data.frame(towers_raw$NomeEntidade,
                         towers_raw$NumEstacao,
                         towers_raw$EnderecoEstacao,
                         towers_raw$AlturaAntena,
                         towers_raw$Latitude,
                         towers_raw$Longitude,
                         stringsAsFactors = F)

names(towers_int) <- c("owner",
                       "internal_id",
                       "location_detail",
                       "tower_height",
                       "lat",
                       "lon")

access_raw <- read_excel(paste(input_folder, access_file, sep = "/"))

access_int <- data.frame(access_raw$estacao,
                         access_raw$operadora,
                         access_raw$t2g,
                         access_raw$t3g,
                         access_raw$t4g,
                         stringsAsFactors = F)

names(access_int) <- c("internal_id",
                       "owner",
                       "tech_2g",
                       "tech_3g",
                       "tech_4g")



## Normalize latitude and longitude
towers_int$lat <- as.character(towers_int$lat)
towers_int$lat[grepl("S|s",towers_int$lat)] <- paste0("-",towers_int$lat[grepl("S|s",towers_int$lat)])

towers_int$latitude_deg <- as.numeric(sapply(strsplit(towers_int$lat,"S|s|N|n"), `[`, 1))
towers_int$latitude_min <- as.numeric(str_sub(towers_int$lat,-6,-5)) 
towers_int$latitude_sec <- as.numeric(str_sub(towers_int$lat,-4,-1))/100 

towers_int$latitude <- towers_int$latitude_deg + towers_int$latitude_min/60 + towers_int$latitude_sec/3600
towers_int$latitude[grepl("-", towers_int$lat)] <- towers_int$latitude_deg[grepl("-", towers_int$lat)] - towers_int$latitude_min[grepl("-", towers_int$lat)]/60 - towers_int$latitude_sec[grepl("-", towers_int$lat)]/3600

towers_int$lon <- as.character(towers_int$lon)
towers_int$lon[grepl("W|w",towers_int$lon)] <- paste0("-",towers_int$lon[grepl("W|w",towers_int$lon)])

towers_int$longitude_deg <- as.numeric(sapply(strsplit(towers_int$lon,"E|e|W|w"), `[`, 1))
towers_int$longitude_min <- as.numeric(str_sub(towers_int$lon,-6,-5)) 
towers_int$longitude_sec <- as.numeric(str_sub(towers_int$lon,-4,-1))/100 

towers_int$longitude <- towers_int$longitude_deg + towers_int$longitude_min/60 + towers_int$longitude_sec/3600
towers_int$longitude[grepl("-", towers_int$lon)] <- towers_int$longitude_deg[grepl("-", towers_int$lon)] - towers_int$longitude_min[grepl("-", towers_int$lon)]/60 - towers_int$longitude_sec[grepl("-", towers_int$lon)]/3600

towers_int <- towers_int[!is.na(towers_int$latitude),]
towers_int <- towers_int[!is.na(towers_int$longitude),]

## Tower height
towers_int$tower_height <- as.numeric(towers_int$tower_height)
towers_int$tower_height[is.na(towers_int$tower_height)] <- 0

# Owner 
towers_int$owner <- as.character(towers_int$owner)

# Location detail 
towers_int$location_detail <- as.character(towers_int$location_detail)

#Source:
towers_int$source <- NA
towers_int$source[towers_int$owner=="TELEFÔNICA BRASIL S.A."] <- "TEF"
towers_int$source[towers_int$owner=="CLARO S.A."] <- "CLARO"
towers_int$source[towers_int$owner=="ALGAR CELULAR S/A"] <- "ALGAR"
towers_int$source[towers_int$owner=="TIM S/A"] <- "TIM"
towers_int$source[towers_int$owner=="OI MÓVEL S.A."] <- "OI"
towers_int$source[towers_int$owner=="NEXTEL TELECOMUNICACOES LTDA"] <- "NEXTEL"
towers_int$source[towers_int$owner=="SERCOMTEL S.A. TELECOMUNICAÇÕES"] <- "SERCOMTEL"
towers_int$source[towers_int$owner=="LIGUE TELECOMUNICAÇÕES LTDA"] <- "LIGUE"


#tech_2g, tech_3g, tech_4g: 2G and 3G not possible to differentiate

towers_int <- merge(towers_int, access_int, by.x=c("internal_id","source"), by.y=c("internal_id","owner"))

towers_int$tech_2g <- as.logical(towers_int$tech_2g)
towers_int$tech_3g <- as.logical(towers_int$tech_3g)
towers_int$tech_4g <- as.logical(towers_int$tech_4g)

#Type: as character
towers_int$type <- NA
towers_int$type <- as.character(towers_int$type)


#Subtype:
towers_int$subtype <- as.character(NA)
towers_int$subtype <- as.character(towers_int$subtype)


#In Service:  No info; all in service
towers_int$in_service <- "IN SERVICE"


#Vendor: Does not apply
towers_int$vendor <- NA
towers_int$vendor <- as.character(towers_int$vendor)


#Coverage area 2G, 3G and 4G: No ACCESS
towers_int$coverage_area_2g <- NA
towers_int$coverage_area_2g <- as.character(towers_int$coverage_area_2g)

towers_int$coverage_area_3g <- NA
towers_int$coverage_area_3g <- as.character(towers_int$coverage_area_3g)

towers_int$coverage_area_4g <- NA
towers_int$coverage_area_4g <- as.character(towers_int$coverage_area_4g)


towers_int$coverage_radius <- as.numeric(towers_int$tower_height)/10
towers_int$coverage_radius[ is.na(towers_int$coverage_radius) | towers_int$coverage_radius<1.5 ] <- 1.5
towers_int$coverage_radius[ towers_int$coverage_radius>5 ] <- 5


#Group all nodes belonging to the same tower

towers <- groupNodes(schema_dev, table_competitors_test, towers_int) 

#fiber, radio, satellite:
towers$fiber <- FALSE
towers$radio <- FALSE
towers$satellite <- FALSE


#satellite band in use: Does not apply
towers$satellite_band_in_use <- NA
towers$satellite_band_in_use <- as.character(towers$satellite_band_in_use)


#radio_distance_km: Does not apply
towers$radio_distance_km <- NA
towers$radio_distance_km <- as.numeric(towers$radio_distance_km)


#last_mile_bandwidth: Does not apply
towers$last_mile_bandwidth <- NA
towers$last_mile_bandwidth <- as.character(towers$last_mile_bandwidth)


#Tower type: 
towers$tower_type <- "INFRASTRUCTURE"

towers[((towers$tech_2g == TRUE)|(towers$tech_3g == TRUE)|(towers$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

towers[(((towers$fiber == TRUE)|(towers$radio == TRUE)|(towers$satellite == TRUE))&(towers$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

towers[(((towers$fiber == TRUE)|(towers$radio == TRUE)|(towers$satellite == TRUE))&(towers$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"


#Source file:
towers$source_file <- input_files[1]

#Internal ID:
towers$internal_id <- as.character(towers$internal_id)


#Tower name
towers$tower_name <- NA
towers$tower_name <- as.character(towers$tower_name)

#Final macro data frame
towers <- towers[,c("latitude",
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
                        "tower_name"
                        )]



#Export the normalized output
saveRDS(towers, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, towers)


exportDB_AddGeom(schema_dev, table_competitors, towers, "geom")


