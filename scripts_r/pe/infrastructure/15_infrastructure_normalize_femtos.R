
#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)


#VARIABLES
source('~/shared/rural_planner/functions/coverage_area.R')

macros <- readRDS(paste0(input_path_infrastructure,"/intermediate outputs/macros.rds", sep=""))


#Load femto towers
file_name <- "fuente_femtos_edgardo.xlsx"
sheet <- "RURAL"
skip <- 1

ipt_file_name <- "Perímetro IPT 05.07.19.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "femtos.rds"


source('~/shared/rural_planner/sql/pe/infrastructure/exportDB.R')

femtos_raw <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), sheet = sheet, skip = skip)
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
#femtos_int <- readRDS("C:/Users/csalle/Desktop/IPT/Scripts/Rural Planner AR/infrastructure/femtos_int.rds")
#Select useful columns from raw input
femtos_int <- data.frame(femtos_raw$Latitud,
                     femtos_raw$Longitud,
                     femtos_raw$`Altura torre`, 
                     femtos_raw$Antena,
                     femtos_raw$`Dirección`,
                     
                     femtos_raw$`Tecnología/Banda`,
                     femtos_raw$`FECHA DE PUESTA DE SERVICIO`,
                     femtos_raw$Azimuth,
                     femtos_raw$`Banda de frecuencia`,
                     
                     femtos_raw$`TECNOLOGÍA`,
                     femtos_raw$CONTRATA,
                     
                     femtos_raw$CU,
                     femtos_raw$`Cell Name`,
                     femtos_raw$`BTS NAME`,
                     stringsAsFactors = FALSE
                     )

#Change names of the variables we already have
colnames(femtos_int) <- c("latitude", 
                      "longitude",
                      "tower_height",
                      "subtype",
                      "location_detail",
                      
                      "technology",
                      "status",
                      "azimuth",
                      "satellite_band_in_use",
                      
                      "transport",
                      "transport_owner",
                      
                      "internal_id",
                      "node_id",
                      "site_id"
                      )


# Remove rows without internal id
femtos_int <- femtos_int[!(is.na(femtos_int$internal_id)),]

# AD-HOC: Remove BTS already loaded in macros & in ipt source

femtos_int <- femtos_int[!(femtos_int$internal_id%in%macros$internal_id),]

femtos_int <- femtos_int[!(femtos_int$internal_id%in% ipt_ids),]



rownames(femtos_int) <- 1:nrow(femtos_int)
######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

#Latitude: already done

#Longitude: already done


#Internal ID:
femtos_int$internal_id <- as.character(femtos_int$internal_id)

#Tower height: as integer
femtos_int$tower_height <- as.integer(as.character(femtos_int$tower_height))
femtos_int$tower_height[is.na(femtos_int$tower_height)] <- 15

#Owner:
femtos_int$owner <-  as.character(femtos_int$transport_owner)
femtos_int[is.na(femtos_int$owner),'owner'] <- "TDP"

#Location detail: as char
femtos_int$location_detail <- as.character(femtos_int$location_detail)

# Band MHz:  AD-HOC: all GSM 850 (3G)
femtos_int$band_mhz[!is.na(femtos_int$technology)] <- 850

# Technology:  AD-HOC: all GSM (3G)
femtos_int$technology[!is.na(femtos_int$band_mhz)] <- '3G'

#tech_2g, tech_3g, tech_4g: all 3G
femtos_int$"tech_2g" <- FALSE
femtos_int$"tech_3g" <- TRUE
femtos_int$"tech_4g" <- FALSE

#Type: all femtos
femtos_int$type <- "FEMTO"

#Subtype: as character 
femtos_int$subtype <- as.character(femtos_int$subtype)

#In Service: 
femtos_int$in_service <- "IN SERVICE"
femtos_int[is.na(femtos_int$status), 'in_service'] <- "PLANNED"

#Vendor: Unknown
femtos_int$vendor <- NA
femtos_int$vendor <- as.character(femtos_int$vendor)

# ran sharing: no info on this
femtos_int$ran_sharing <- NA

# Coverage radius: assume 1.5 km for femtos with no info on tower height or with height smaller than 15m
femtos_int$coverage_radius <- as.numeric(as.character(femtos_int$tower_height))/10
femtos_int$coverage_radius[is.na(femtos_int$coverage_radius) | femtos_int$coverage_radius<1.5] <- 1.5

femtos_int$azimuth <- 0

#No info on beamwidth (assume all towers omnidirectional)
femtos_int$beamwidth <- 360

n <- length(femtos_int$latitude)

for (i in 1:n) {
  if(i%%1000 == 0){
    print(paste(i, n, Sys.time(), sep = "/"))
    }
  if(!is.na(femtos_int[i,'latitude']) & ! is.na(femtos_int[i,'latitude'])) {
    
    radius <- as.numeric(femtos_int[i, 'coverage_radius'])
    azimuth <- as.numeric(femtos_int[i, 'azimuth'])
    beamwidth <- as.numeric(femtos_int[i, 'beamwidth'])
    
    #If we don't have radius, we assume height/10
    if(is.na(radius)) {
      radius <- macros_int[i, 'tower_height']/10
    }
    #If we didn't have height either, we assume 1.5 km
    if(is.na(radius)) {
      radius <- 1.5
    }
    if(is.na(azimuth)) {
      azimuth <- 0
    }
    if(is.na(beamwidth) | beamwidth==0) {
      beamwidth <- 360
    }
    
    if(femtos_int[i, 'tech_2g'] == TRUE) {
      femtos_int[i, 'coverage_area_2g'] <- coverage_area(round(femtos_int[i,'latitude'], 6), round(femtos_int[i,'longitude'], 6), radius, azimuth, beamwidth)
    } else { femtos_int$coverage_area_2g[i] <- as.character(NA) }
    if(femtos_int[i, 'tech_3g'] == TRUE) {
      femtos_int[i, 'coverage_area_3g'] <- coverage_area(round(femtos_int[i,'latitude'], 6), round(femtos_int[i,'longitude'], 6), radius, azimuth, beamwidth)
    } else {  femtos_int$coverage_area_3g[i] <- as.character(NA)}
    if(femtos_int[i, 'tech_4g'] == TRUE) {
      femtos_int[i, 'coverage_area_4g'] <- coverage_area(round(femtos_int[i,'latitude'], 6), round(femtos_int[i,'longitude'], 6), radius, azimuth, beamwidth)
    } else { femtos_int$coverage_area_4g[i] <-  as.character(NA)}
    
}
}

femtos_int_backup = femtos_int


#fiber, radio, satellite: create from transport field
femtos_int$fiber <- FALSE
femtos_int$radio <- FALSE
femtos_int$satellite <- FALSE

femtos_int[grepl("FO", femtos_int$transport), 'fiber'] <- TRUE
femtos_int[grepl("RADIO", femtos_int$transport), 'radio'] <- TRUE
femtos_int[grepl("SATELITAL", femtos_int$transport), 'satellite'] <- TRUE

#satellite band in use: keep the current one 
femtos_int$satellite_band_in_use <- as.character(femtos_int$satellite_band_in_use)

#radio_distance_km: no info on this
femtos_int$radio_distance_km <- NA
femtos_int$radio_distance_km <- as.numeric(femtos_int$radio_distance_km)

#last_mile_bandwidth: 0.2 Mbps for VSAT and 0.4 Mbps for SCPC
femtos_int$last_mile_bandwidth <- NA
femtos_int[grepl("SPSC", femtos_int$transport), 'last_mile_bandwidth'] <- '0.4 Mbps'
femtos_int[grepl("VSAT", femtos_int$transport), 'last_mile_bandwidth'] <- '0.2 Mbps'
femtos_int$last_mile_bandwidth <- as.character(femtos_int$last_mile_bandwidth)

#Tower type:
femtos_int$tower_type <- "INFRASTRUCTURE"

femtos_int[((femtos_int$tech_2g == TRUE)|(femtos_int$tech_3g == TRUE)|(femtos_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

femtos_int[(((femtos_int$fiber == TRUE)|(femtos_int$radio == TRUE)|(femtos_int$satellite == TRUE))&(femtos_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

femtos_int[(((femtos_int$fiber == TRUE)|(femtos_int$radio == TRUE)|(femtos_int$satellite == TRUE))&(femtos_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
femtos_int$source_file <- file_name

#Source:
femtos_int$source <- "FEMTOS"

#Tower name:
femtos_int$tower_name <- as.character(femtos_int$site_id)

# IPT Perimeter:
femtos_int$ipt_perimeter <- "NO IPT"
femtos_int[femtos_int$internal_id%in%ipt_ids,'ipt_perimeter'] <- "IPT"

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
femtos <- femtos_int[,c("latitude",
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
femtos
######################################################################################################################
femtos <- femtos[!duplicated(femtos$internal_id),]


#Export the normalized output
saveRDS(femtos, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, femtos)

#Set connection data
exportDB(schema_dev, table_femtos, femtos)

