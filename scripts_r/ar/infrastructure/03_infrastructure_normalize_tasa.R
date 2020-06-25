
#LIBRARIES
library(readxl)
library(xlsx)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_ar'
source(config_path)

#VARIABLES
source('~/shared/rural_planner/functions/coverage_area.R')

# Set value to false if we want to assume omnidirectional BTS in the coverage area calculation; else set to TRUE (increases computation time to 5~7 hours)
realShape <- FALSE

file_name_main <- "sectores-export-13062019_164708.xlsx"
skip <- 0

file_name <- "Propietarios_Sitios.xlsx"
sheet <- "Propietarios - Sitios"

file_name_2 <- "Propietarios_Sitios_Planificados.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_name_io <- "tasa_ipt.rds"

source('~/shared/rural_planner/sql/ar/infrastructure/groupNodes_A.R')
source('~/shared/rural_planner/sql/ar/infrastructure/groupNodes_B.R')
source('~/shared/rural_planner/sql/ar/infrastructure/exportDBTasa.R')

#LOAD INPUTS
text_vec <- as.vector(rep_len("text",113))

tasa_raw <- read_excel(paste(input_path_infrastructure,  file_name_main, sep = "/"), col_types = text_vec)

#Load owners file
owners_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), sheet=sheet, skip = skip)

names(owners_raw) <- c("site_id",
                       "1",
                       "2",
                       "3",
                       "owner_raw",
                       "4")

#Load owners planned file
owners_planned_raw <- read_excel(paste(input_path_infrastructure,  file_name_2, sep = "/"), skip = skip)

names(owners_planned_raw) <- c("site_id",
                       "1",
                       "2",
                       "3",
                       "4",
                       "5",
                       "owner_raw")

owners <- rbind(owners_raw[,c(1,5)], owners_planned_raw[,c(1,7)])


######################################################################################################################
#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail, tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor, coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)

#The ID will be that of the row from the data frame
######################################################################################################################


######################################################################################################################
#tasa_int <- readRDS("C:/Users/csalle/Desktop/IPT/Scripts/Rural Planner AR/infrastructure/tasa_int.rds")
#Select useful columns from raw input

tasa_int <- data.frame(tasa_raw$Latitud,
                     tasa_raw$Longitud,
                     tasa_raw$"Tipo Nodo",
                     tasa_raw$"Tipo Inst. Sector",
                     
                     tasa_raw$Tipo,
                     tasa_raw$"Tecnología",
                     tasa_raw$"Banda [MHz]",
                     tasa_raw$Estado,
                     tasa_raw$"Radio de Cobertura",
                     
                     tasa_raw$Sitio,
                     tasa_raw$Sector,
                     
                     
                     tasa_raw$"Altura (1)", 
                     tasa_raw$"Azimut (1)",
                     tasa_raw$"Apertura Horizontal (1)",
                     tasa_raw$"Tipo de RAN-Sharing",
                     tasa_raw$"Operadores",
                     
                     tasa_raw$Tx
                     )

#Change names of the variables we already have
colnames(tasa_int) <- c("latitude", 
                      "longitude",
                      "subtype",
                      "location_detail",
                      
                      "tower_type",
                      "technology",
                      "band_mhz",
                      "status",
                      "coverage_radius",
                      
                      "internal_id",
                      "node_id",
                      
                      "tower_height",
                      "azimuth",
                      "beamwidth",
                      "ran_sharing",
                      "ran_sharing_owner",
                      
                      "tx_type"
                      )

tasa_int$internal_id <- as.character(tasa_int$internal_id)
tasa_int$node_id <- as.character(tasa_int$node_id)

tasa_int <- merge(tasa_int,owners,by.x="internal_id", by.y="site_id", all.x=T)

######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done

tasa_int$latitude <- as.numeric(as.character(tasa_int$latitude))

#Longitude: already done

tasa_int$longitude <- as.numeric(as.character(tasa_int$longitude))

#Tower height: as integer
tasa_int$tower_height <- as.integer(as.character(tasa_int$tower_height))
tasa_int$tower_height[is.na(tasa_int$tower_height)] <- 0
tasa_int$tower_height[(tasa_int$tower_height<=0)] <- 0

#Owner:
tasa_int$owner <- as.character(tasa_int$owner_raw)


#Location detail: as char; TX OWNER
tasa_int$location_detail <- as.character(tasa_int$location_detail)

#tech_2g, tech_3g, tech_4g:
tasa_int$"tech_2g" <- FALSE
tasa_int$"tech_3g" <- FALSE
tasa_int$"tech_4g" <- FALSE

tasa_int[tasa_int$technology == "2G", 'tech_2g'] <- TRUE
tasa_int[tasa_int$technology == "3G", 'tech_3g'] <- TRUE
tasa_int[tasa_int$technology == "4G", 'tech_4g'] <- TRUE


#Type:
tasa_int$type <- NA

tasa_int[grepl("Macro", tasa_int$tower_type), 'type'] <- "MACRO"

tasa_int[grepl("Micro", tasa_int$tower_type), 'type'] <- "FEMTO"


#Subtype: as character ; RAN SHARING OWNER/TYPE
tasa_int$subtype <- NA
tasa_int$subtype[grepl("Anfitrión",tasa_int$ran_sharing)] <- paste("Host",tasa_int$ran_sharing_owner[grepl("Anfitrión",tasa_int$ran_sharing)], sep=' ') 
tasa_int$subtype[grepl("Huesped",tasa_int$ran_sharing)] <- paste("Guest",tasa_int$ran_sharing_owner[grepl("Huesped",tasa_int$ran_sharing)], sep=' ') 

#In Service: 
tasa_int$in_service <- NA
tasa_int$in_service[tasa_int$status=="Baja"] <- 0
tasa_int$in_service[tasa_int$status=="Des-definido"] <- 1
tasa_int$in_service[tasa_int$status=="Liberado"] <- 2
tasa_int$in_service[tasa_int$status=="Integrado"] <- 3
tasa_int$in_service[grepl("Planificado",tasa_int$status)] <- 4
tasa_int$in_service[tasa_int$status=="Pruebas LTE"] <- 5
tasa_int$in_service[tasa_int$status=="Swap"] <- 6
tasa_int$in_service[grepl("Comercial",tasa_int$status)] <- 7

#Vendor: Unknown
tasa_int$vendor <- NA
tasa_int$vendor <- as.character(tasa_int$vendor)

#Coverage area 2G, 3G and 4G
tasa_int$coverage_area_2g <- NA
tasa_int$coverage_area_2g <- as.character(tasa_int$coverage_area_2g)

tasa_int$coverage_area_3g <- NA
tasa_int$coverage_area_3g <- as.character(tasa_int$coverage_area_3g)

tasa_int$coverage_area_4g <- NA
tasa_int$coverage_area_4g <- as.character(tasa_int$coverage_area_4g)

tasa_int$coverage_radius <- 5

tasa_int$azimuth <- as.numeric(as.character(tasa_int$azimuth))
#To solve the problem of empty areas that would actually be covered, we increase the beamwidth by a 200% --> 90? becomes 180?
tasa_int$beamwidth <- as.numeric(as.character(tasa_int$beamwidth))*2

if (realShape==TRUE){
      tasa_int$azimuth <- as.numeric(as.character(tasa_int$azimuth))
    #To solve the problem of empty areas that would actually be covered, we increase the beamwidth by a 200% --> 90º becomes 180º
    tasa_int$beamwidth <- as.numeric(as.character(tasa_int$beamwidth))*2
    
    n <- length(tasa_int$latitude)
    
    for (i in 1:n) {
      if(i%%1000 == 0){
        print(paste(i, n, Sys.time(), sep = "/"))
        }
      if(!is.na(tasa_int[i,'latitude']) & ! is.na(tasa_int[i,'latitude'])) {
        
        radius <- tasa_int[i, 'coverage_radius']
        azimuth <- tasa_int[i, 'azimuth']
        beamwidth <- tasa_int[i, 'beamwidth']
        
        #If we don't have radius, we assume height/10
        if(is.na(radius)) {
          radius <- tasa_int[i, 'tower_height']/10
        }
        #If we didn't have height either, we assume 1.5 km
        if(is.na(radius)) {
          radius <- 3
        }
        if(is.na(azimuth)) {
          azimuth <- 0
        }
        if(is.na(beamwidth) | beamwidth==0) {
          beamwidth <- 360
        }
        
        if(tasa_int[i, 'tech_2g'] == TRUE) {
          tasa_int[i, 'coverage_area_2g'] <- coverage_area(round(tasa_int[i,'latitude'], 6), round(tasa_int[i,'longitude'], 6), radius, azimuth, beamwidth)
        }
        if(tasa_int[i, 'tech_3g'] == TRUE) {
          tasa_int[i, 'coverage_area_3g'] <- coverage_area(round(tasa_int[i,'latitude'], 6), round(tasa_int[i,'longitude'], 6), radius, azimuth, beamwidth)
        }
        if(tasa_int[i, 'tech_4g'] == TRUE) {
          tasa_int[i, 'coverage_area_4g'] <- coverage_area(round(tasa_int[i,'latitude'], 6), round(tasa_int[i,'longitude'], 6), radius, azimuth, beamwidth)
        }
        
      }
    }
    
    tasa_int_backup = tasa_int
    
    #Group all nodes belonging to the same tower
    tasa <- groupNodes_A(schema_dev, table_tasa_test, tasa_int)

} else {
  #Group all nodes belonging to the same tower

    tasa <- groupNodes_B(schema_dev, table_tasa_test, tasa_int)

}


tasa[tasa$in_service%in%c(7,6,5), 'in_service'] <- "IN SERVICE"
tasa[tasa$in_service%in%c(3,4), 'in_service'] <- "PLANNED"
tasa[tasa$in_service%in%c(0,1,2), 'in_service'] <- NA

#fiber, radio, satellite: create from transport field
tasa$fiber <- FALSE
tasa$radio <- FALSE
tasa$satellite <- FALSE
tasa$tx_3g <- FALSE
tasa$tx_third_pty <- FALSE

tasa[grepl("FO", tasa$transport), 'fiber'] <- TRUE
tasa[grepl("RE", tasa$transport), 'radio'] <- TRUE
tasa[grepl("SAT", tasa$transport) | grepl("Sat", tasa$transport), 'satellite'] <- TRUE
tasa[grepl("Tx", tasa$transport), 'tx_third_pty'] <- TRUE
tasa$tx_3g[(tasa$tech_3g==TRUE) | (tasa$tech_4g==TRUE)] <- TRUE

# Specific cases
tasa$fiber[(tasa$transport == "FO Claro")] <- FALSE
tasa$tx_third_pty[(tasa$transport == "FO Claro")] <- TRUE
tasa$tx_third_pty[(tasa$transport == "Renta")] <- TRUE
tasa$tx_third_pty[(tasa$transport == "Renta Cotesma")] <- TRUE
tasa$tx_third_pty[(tasa$transport == "HDSL + Tx Terceros")] <- FALSE

tasa$tx_3g[(tasa$radio==TRUE) | (tasa$fiber==TRUE) | (tasa$tx_third_pty==TRUE)] <- FALSE

#satellite band in use: keep the current one and set NA where there is 'No SAT'
tasa$satellite_band_in_use <- NA
tasa$satellite_band_in_use <- as.character(tasa$satellite_band_in_use)

#radio_distance_km: no info on this
tasa$radio_distance_km <- NA
tasa$radio_distance_km <- as.numeric(tasa$radio_distance_km)

#last_mile_bandwidth: 0.2 Mbps for VSAT and 0.4 Mbps for SCPC
tasa$last_mile_bandwidth <- NA

#Tower type:
tasa$tower_type <- "INFRASTRUCTURE"

tasa[((tasa$tech_2g == TRUE)|(tasa$tech_3g == TRUE)|(tasa$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

tasa[(((tasa$fiber == TRUE)|(tasa$radio == TRUE)|(tasa$satellite == TRUE)|(tasa$tx_3g == TRUE)|(tasa$tx_third_pty == TRUE))&(tasa$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

tasa[(((tasa$fiber == TRUE)|(tasa$radio == TRUE)|(tasa$satellite == TRUE)|(tasa$tx_3g == TRUE)|(tasa$tx_third_pty == TRUE))&(tasa$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
tasa$source_file <- file_name_main

#Source:
tasa$source <- "TASA"

#Internal ID:
tasa$internal_id <- as.character(tasa$internal_id)

######################################################################################################################

tasa <- tasa[!is.na(tasa$in_service),]
tasa <- tasa[!is.na(tasa$latitude),]
tasa <- tasa[!is.na(tasa$longitude),]


######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
tasa <- tasa[,c("latitude",
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
                        "tx_3g",
                        "tx_third_pty",
                        "satellite_band_in_use",
                        "radio_distance_km",
                        "last_mile_bandwidth",
                        
                        "source_file",
                        "source",
                        "internal_id"
                        )]
tasa
######################################################################################################################



#Export the normalized output
saveRDS(tasa, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, tasa)

exportDBTasa(schema_dev, table_tasa, tasa)

