
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)

#VARIABLES
# Set value to false if we want to assume omnidirectional BTS in the coverage area calculation; else set to TRUE (increases computation time to 5~7 hours)

realShape <- FALSE

#Load macro towers

file_name <- "MatrizGeolocalizacion - 2019-07-02.xlsx"
skip <- 0

ipt_file_name <- "Perímetro IPT 05.07.19.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "macros.rds"

source('~/shared/rural_planner/sql/pe/infrastructure/groupNodes.R')
source('~/shared/rural_planner/sql/pe/infrastructure/exportDB.R')


macros_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), skip = skip)

ipt_ids <- unique(read_excel(paste(input_path_infrastructure,  ipt_file_name, sep = "/"),sheet = "Detalle por cell id")[,1])[[1]]


######################################################################################################################
#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail, tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor, coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)

#The ID will be that of the row from the data frame
######################################################################################################################


######################################################################################################################

#Select useful columns from raw input
macros_int <- data.frame(macros_raw$Latitud,
                     macros_raw$Longitud,
                     macros_raw$AlturaTorre, 
                     macros_raw$TipoZona,
                     macros_raw$Direccion,
                     macros_raw$TipoEstacionBase,
                     
                     macros_raw$Tecnologia,
                     macros_raw$BandaFrecuenia,
                     macros_raw$EstadoServicio,
                     macros_raw$TipoCoubicacion,
                     macros_raw$Azimuth,
                     macros_raw$AmplitudBeam,
                     
                     macros_raw$MedioTX,
                     
                     macros_raw$`CodigoUnicoEStacion`,
                     macros_raw$EtiquetaNodo,
                     macros_raw$NombreEstacion,
                     
                     macros_raw$PropietarioEstacion,
                     macros_raw$VendorNodo
                     )

#Change names of the variables we already have
colnames(macros_int) <- c("latitude", 
                      "longitude",
                      "tower_height",
                      "subtype",
                      "location_detail",
                      "tower_type",
                      
                      "technology",
                      "band_mhz",
                      "status",
                      "ran_sharing",
                      "azimuth",
                      "beamwidth",
                      
                      "transport",
                      
                      "internal_id",
                      "node_id",
                      "site_id",
                      
                      "owner",
                      "vendor"
                      )

macros_int<-macros_int[grepl('En servicio',macros_int$status) | grepl('En proceso',macros_int$status),]



######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: as numeric

macros_int$latitude <- as.numeric(as.character(macros_int$latitude))

#Longitude: as numeric

macros_int$longitude <- as.numeric(as.character(macros_int$longitude))

#Owner:
macros_int$owner <- as.character(macros_int$owner)
macros_int[is.na(macros_int$owner),'owner'] <- "TDP"

#Location detail: as char
macros_int$location_detail <- as.character(macros_int$location_detail)

Encoding(macros_int$location_detail) <- "UTF-8"
macros_int$location_detail <- enc2native(macros_int$location_detail)

#tech_2g, tech_3g, tech_4g:
macros_int$"tech_2g" <- FALSE
macros_int$"tech_3g" <- FALSE
macros_int$"tech_4g" <- FALSE

macros_int[macros_int$technology == "GSM", 'tech_2g'] <- TRUE
macros_int[macros_int$technology == "UMTS", 'tech_3g'] <- TRUE
macros_int[macros_int$technology == "LTE", 'tech_4g'] <- TRUE


#Type:
macros_int$type <- "FEMTO"
macros_int$type[grepl("MACRO",macros_int$tower_type)] <- "MACRO"


#Tower height: as integer
macros_int$tower_height <- as.integer(as.character(macros_int$tower_height))
macros_int$tower_height[is.na(macros_int$tower_height) & macros_int$type=="MACRO"] <- 30
macros_int$tower_height[is.na(macros_int$tower_height) & macros_int$type=="FEMTO"] <- 15

#Subtype: as character 
macros_int$subtype <- as.character(macros_int$subtype)

#In Service: 
macros_int$in_service <- "IN SERVICE"
macros_int[grepl("proceso",macros_int$status), 'in_service'] <- "PLANNED"

#Vendor:
macros_int$vendor <- as.character(macros_int$vendor)


# Coverage radius:
macros_int$coverage_radius <- as.numeric(as.character(macros_int$tower_height))/10
macros_int$coverage_radius[macros_int$coverage_radius<1.5] <- 1.5

#Coverage area 2G, 3G and 4G
macros_int$coverage_area_2g <- NA
macros_int$coverage_area_2g <- as.character(macros_int$coverage_area_2g)

macros_int$coverage_area_3g <- NA
macros_int$coverage_area_3g <- as.character(macros_int$coverage_area_3g)

macros_int$coverage_area_4g <- NA
macros_int$coverage_area_4g <- as.character(macros_int$coverage_area_4g)

if (realShape==TRUE){
      macros_int$azimuth <- as.numeric(as.character(macros_int$azimuth))
    #To solve the problem of empty areas that would actually be covered, we increase the beamwidth by a 200% --> 90º becomes 180º
    macros_int$beamwidth <- as.numeric(as.character(macros_int$beamwidth))*2
    
    n <- length(macros_int$latitude)
    
    for (i in 1:n) {
      if(i%%1000 == 0){
        print(paste(i, n, Sys.time(), sep = "/"))
        }
      if(!is.na(macros_int[i,'latitude']) & ! is.na(macros_int[i,'latitude'])) {
        
        radius <- macros_int[i, 'coverage_radius']
        azimuth <- macros_int[i, 'azimuth']
        beamwidth <- macros_int[i, 'beamwidth']
        
        #If we don't have radius, we assume height/10
        if(is.na(radius)) {
          radius <- macros_int[i, 'tower_height']/10
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
        
        if(macros_int[i, 'tech_2g'] == TRUE) {
          macros_int[i, 'coverage_area_2g'] <- coverage_area(round(macros_int[i,'latitude'], 6), round(macros_int[i,'longitude'], 6), radius, azimuth, beamwidth)
        }
        if(macros_int[i, 'tech_3g'] == TRUE) {
          macros_int[i, 'coverage_area_3g'] <- coverage_area(round(macros_int[i,'latitude'], 6), round(macros_int[i,'longitude'], 6), radius, azimuth, beamwidth)
        }
        if(macros_int[i, 'tech_4g'] == TRUE) {
          macros_int[i, 'coverage_area_4g'] <- coverage_area(round(macros_int[i,'latitude'], 6), round(macros_int[i,'longitude'], 6), radius, azimuth, beamwidth)
        }
        
      }
    }
    
    macros_int_backup = macros_int
}

macros <- groupNodes(schema_dev, table_test_macros, macros_int, realShape)

#fiber, radio, satellite: create from transport field
macros$fiber <- FALSE
macros$radio <- FALSE
macros$satellite <- FALSE

macros[grepl("FIBRA OPTICA", macros$transport), 'fiber'] <- TRUE
macros[grepl("MICROONDAS", macros$transport), 'radio'] <- TRUE
macros[grepl("SATELITAL", macros$transport), 'satellite'] <- TRUE

# Transport owner: no info on this

macros$transport_owner <- NA

#satellite band in use: no info on this
macros$satellite_band_in_use <- NA
macros$satellite_band_in_use <- as.character(macros$satellite_band_in_use)

#radio_distance_km: no info on this
macros$radio_distance_km <- NA
macros$radio_distance_km <- as.numeric(macros$radio_distance_km)

#last_mile_bandwidth: No info on this
macros$last_mile_bandwidth <- NA

#Tower type:
macros$tower_type <- "INFRASTRUCTURE"

macros[((macros$tech_2g == TRUE)|(macros$tech_3g == TRUE)|(macros$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

macros[(((macros$fiber == TRUE)|(macros$radio == TRUE)|(macros$satellite == TRUE))&(macros$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

macros[(((macros$fiber == TRUE)|(macros$radio == TRUE)|(macros$satellite == TRUE))&(macros$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
macros$source_file <- file_name

#Source:

macros$source <- "MACROS"

#Internal ID:
macros$internal_id <- as.character(macros$internal_id)

##AD-HOC QA: (needs to be done here to set ipt perimeter correctly)

 macros[macros$internal_id=='CA00210', 'internal_id'] <- 'CA00230'

#Tower name:
macros$tower_name <- as.character(macros$tower_name)

# IPT Perimeter:
macros$ipt_perimeter <- "NO IPT"
macros[macros$internal_id %in% ipt_ids,'ipt_perimeter'] <- "IPT"

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
macros <- macros[,c("latitude",
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
macros
######################################################################################################################


#Export the normalized output
saveRDS(macros, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, macros)

exportDB(schema_dev, table_macros, macros)

