
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)


#VARIABLES
#Load auxiliary functions
source('~/shared/rural_planner/functions/coverage_area.R')

#Load femto towers
file_name <- "IPT_Consolidado_Sitios_22.08.18.xlsx"
sheets <- c("SC","MC", "OIMR")
skip <- 1

file_name_2 <- "Perímetro IPT 05.07.19.xlsx"
sheet <- "Detalle por cell id"


output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_io <- "ipt.rds"

source('~/shared/rural_planner/sql/pe/infrastructure/getInternalID.R')
source('~/shared/rural_planner/sql/pe/infrastructure/removeDuplicates.R')
source('~/shared/rural_planner/sql/pe/infrastructure/exportNormalizeIpt.R')

ipt_oimr <- read_excel(paste(input_path_infrastructure,  file_name, sep = "/"), sheet = sheets[3], skip = skip)

ipt_raw <- read_excel(paste(input_path_infrastructure,  file_name_2, sep = "/"), sheet = sheet, skip = skip)

ipt_raw


######################################################################################################################
#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail, tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor, coverage_area,  coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)

#The ID will be that of the row from the data frame
######################################################################################################################


######################################################################################################################

#Select useful columns from raw input
ipt_int <- data.frame(ipt_raw$LONGITUD,
                     ipt_raw$LATITUD,
                     ipt_raw$`TIPO/TECNOLOGIA`,
                     ipt_raw$NOMBRE_NODO,
                     ipt_raw$`PROPIETARIO TORRE`,
                     
                     
                     ipt_raw$PROYECTO,
                     
                     
                     ipt_raw$TX,
                     ipt_raw$ESTADO,
                     
                     ipt_raw$COD_UNICO_SITE...1,
                     ipt_raw$COD_UNICO_IPT...2,
                     ipt_raw$PERIMETRO
                     )

#Change names of the variables we already have
colnames(ipt_int) <- c("latitude", 
                      "longitude",
                      "tower_type",
                      "tower_name",
                      "owner",
                      
                      "initiative",
                      
                      "transport",
                      "status",
                      
                      "internal_id_tdp",
                      "internal_id",
                      "ipt_perimeter"
                      )

ipt_oimr <- ipt_oimr[,c("NOMBRE_NODO",
                        "UBIGEO",
                        "CENTRO_POBLADO",
                        "TIPO",
                        "ESTADO",
                        "PROYECTO",
                        "PERIMETRO")]

names(ipt_oimr) <- c("tower_name",
                     "settlement_id",
                     "location_detail",
                     "tech",
                     "status",
                     "subtype",
                     "ipt_perimeter"
                     )
#INITIAL FILTERING:

#ipt_int <- ipt_int[!(ipt_int$state%in%c("DESACTIVADO","REEMPLAZADA")),]
#ipt_int <- ipt_int[(grepl("OIMR",ipt_int$pilot)),]
#ipt_int <- ipt_int[!(ipt_int$pilot%in%c("LOON PRUEBAS INTERFERENCIAS","POR VALIDAR")),]

######################################################################################################################

######################################################################################################################

#Fill with the rest of the fields and reshape where necessary

## Remove BTS with several entries (one per node)

ipt_int <- ipt_int %>% arrange(internal_id, internal_id_tdp, latitude, longitude, owner, status, ipt_perimeter, tower_name) %>%
     group_by(internal_id, internal_id_tdp, latitude, longitude, owner, status, ipt_perimeter) %>% summarise(tower_type = paste0(unique(tower_type), collapse = ","), initiative = paste0(unique(initiative), collapse = ","), tower_name=last(tower_name), 
            transport = paste0(unique(transport), collapse = ","))

#Latitude: already done
ipt_int$latitude <- as.numeric(gsub("[\xc2\xa0]", "",as.character(ipt_int$latitude)))

#Longitude: double (errors on data)
ipt_int$longitude <- as.numeric(gsub("[\xc2\xa0]", "",as.character(ipt_int$longitude)))

## Add settlement's coordinates to OIMR towers

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd) 

query <- paste0("SELECT settlement_id, latitude, longitude FROM ", schema_dev, ".", table_settlements, " WHERE 
settlement_id IN ('",paste(ipt_oimr$settlement_id, collapse="' , '"),"')")

missing_coordinates_oimr <- dbGetQuery(con, query)

dbDisconnect(con)

ipt_oimr <- merge(ipt_oimr,missing_coordinates_oimr, by.x='settlement_id', by.y='settlement_id')


#AD-HOC: Remove unlocated BTS
ipt_int<- ipt_int[!is.na(ipt_int$latitude),]
ipt_int<- ipt_int[!is.na(ipt_int$longitude),]


#Tower height: as integer
ipt_int$tower_height <- as.numeric(15)

ipt_oimr$tower_height <- as.numeric(15)

#Owner: all Movistar
ipt_int$owner <- "MOVISTAR"

ipt_oimr$owner <- "MAYUTEL"

#Location detail: does not apply
ipt_int$location_detail <- NA

ipt_oimr$location_detail <- as.character(ipt_oimr$location_detail)

# Tower name: as character

ipt_int$tower_name <- as.character(ipt_int$tower_name)

ipt_oimr$tower_name <- as.character(ipt_oimr$tower_name)

#tech_2g, tech_3g, tech_4g: 4G in new source
ipt_int$"tech_2g" <- FALSE
ipt_int$"tech_3g" <- FALSE
ipt_int$"tech_4g" <- FALSE

ipt_int[grepl("2G", ipt_int$tower_type), 'tech_2g'] <- TRUE
ipt_int[grepl("3G", ipt_int$tower_type), 'tech_3g'] <- TRUE
ipt_int[grepl("4G", ipt_int$tower_type), 'tech_4g'] <- TRUE

ipt_oimr$"tech_2g" <- FALSE
ipt_oimr$"tech_3g" <- FALSE
ipt_oimr$"tech_4g" <- FALSE


ipt_oimr[grepl("4G", ipt_oimr$tech), 'tech_4g'] <- TRUE
ipt_oimr[grepl("3G", ipt_oimr$tech), 'tech_3g'] <- TRUE
ipt_oimr[ipt_oimr$tech=="OIMR", 'tech_2g'] <- TRUE

#Type: we take it from BTS Type
ipt_int$type <- "FEMTO"

ipt_int[grepl("SMALL", ipt_int$tower_type),'type'] <- "FEMTO"
ipt_int[grepl("MACRO", ipt_int$tower_type),'type'] <- "MACRO"

ipt_oimr$type <- "FEMTO"


#Subtype: as character from the initiative
ipt_int$subtype <- as.character(ipt_int$initiative)

ipt_oimr$subtype <- as.character(ipt_oimr$subtype)

#In Service: 
ipt_int$in_service <- NA
ipt_int[grepl("SERVICIO", as.character(ipt_int$status)),'in_service'] <- "IN SERVICE"
ipt_int[grepl("PENDIENTE", as.character(ipt_int$status)),'in_service'] <- "PLANNED"

ipt_int <- ipt_int[!is.na(ipt_int$in_service),]

ipt_oimr$in_service <- NA
ipt_oimr[grepl("SERVICIO", as.character(ipt_oimr$status)),'in_service'] <- "IN SERVICE"
ipt_oimr[grepl("PENDIENTE", as.character(ipt_oimr$status)),'in_service'] <- "PLANNED"

ipt_oimr <- ipt_oimr[!is.na(ipt_oimr$in_service),]

#Vendor: We take it from BTS
ipt_int$vendor <- as.character(NA)

ipt_oimr$vendor <- as.character(NA)

#Coverage area 2G, 3G and 4G: we do not have info on shape so we assume a 3 km radius for all ipt and technologies
ipt_int$coverage_area_2g <- NA
ipt_int$coverage_area_2g <- as.character(ipt_int$coverage_area_2g)

ipt_int$coverage_area_3g <- NA
ipt_int$coverage_area_3g <- as.character(ipt_int$coverage_area_3g)

ipt_int$coverage_area_4g <- NA
ipt_int$coverage_area_4g <- as.character(ipt_int$coverage_area_4g)

for (i in 1:length(ipt_int$latitude)) {
  if(!is.na(ipt_int[i,'latitude'])) {
    radius <- 1.5
    if(ipt_int[i, 'type'] == "MACRO") {radius <- 3}
    ipt_int[i, 'coverage_area_2g'] <- coverage_area(round(ipt_int[i,'latitude'], 6), round(ipt_int[i,'longitude'], 6), radius, 0, 360)
  }
}

#In this case, they are all the same, so we do not re-calculate. We select the circle for the towers giving a certain service, and then we delete from the towers without 2G the coverage area calculated for this technology.
ipt_int[ipt_int$tech_3g == TRUE, 'coverage_area_3g'] <- ipt_int[ipt_int$tech_3g == TRUE, 'coverage_area_2g']
ipt_int[ipt_int$tech_4g == TRUE, 'coverage_area_4g'] <- ipt_int[ipt_int$tech_4g == TRUE, 'coverage_area_2g']
ipt_int[ipt_int$tech_2g == FALSE, 'coverage_area_2g'] <- NA

ipt_oimr$coverage_area_2g <- NA
ipt_oimr$coverage_area_2g <- as.character(ipt_oimr$coverage_area_2g)

ipt_oimr$coverage_area_3g <- NA
ipt_oimr$coverage_area_3g <- as.character(ipt_oimr$coverage_area_3g)

ipt_oimr$coverage_area_4g <- NA
ipt_oimr$coverage_area_4g <- as.character(ipt_oimr$coverage_area_4g)

ipt_oimr$longitude <- as.numeric(ipt_oimr$longitude)
ipt_oimr$latitude <- as.numeric(ipt_oimr$latitude)

for (i in 1:length(ipt_oimr$latitude)) {
  if(!is.na(ipt_oimr[i,'latitude'])) {
    radius <- 1.5
    if(ipt_oimr[i, 'type'] == "MACRO") {radius <- 3}
    ipt_oimr[i, 'coverage_area_2g'] <- coverage_area(round(ipt_oimr[i,'latitude'], 6), round(ipt_oimr[i,'longitude'], 6), radius, 0, 360)
  }
}

ipt_oimr[ipt_oimr$tech_3g == TRUE, 'coverage_area_3g'] <- ipt_oimr[ipt_oimr$tech_3g == TRUE, 'coverage_area_2g']
ipt_oimr[ipt_oimr$tech_4g == TRUE, 'coverage_area_4g'] <- ipt_oimr[ipt_oimr$tech_4g == TRUE, 'coverage_area_2g']
ipt_oimr[ipt_oimr$tech_2g == FALSE, 'coverage_area_2g'] <- NA


#fiber, radio, satellite: create from transport field
ipt_int$fiber <- FALSE
ipt_int$radio <- FALSE
ipt_int$satellite <- FALSE

ipt_int[(grepl("FIBRA", ipt_int$transport)), 'fiber'] <- TRUE
ipt_int[(grepl("MICROONDAS", ipt_int$transport)), 'radio'] <- TRUE
ipt_int[grepl("SATELITAL", ipt_int$transport), 'satellite'] <- TRUE

ipt_oimr$fiber <- FALSE
ipt_oimr$radio <- TRUE
ipt_oimr$satellite <- TRUE


#satellite band in use: keep the current one and set NA where there is 'No SAT'
ipt_int$satellite_band_in_use <- NA

ipt_oimr$satellite_band_in_use <- NA

#radio_distance_km: no info on this
ipt_int$radio_distance_km <- NA
ipt_int$radio_distance_km <- as.numeric(ipt_int$radio_distance_km)

ipt_oimr$radio_distance_km <- NA

#last_mile_bandwidth: no info on this
ipt_int$last_mile_bandwidth <- NA
ipt_int$last_mile_bandwidth <- as.character(ipt_int$last_mile_bandwidth)

ipt_oimr$last_mile_bandwidth <- NA


#Tower type:
ipt_int$tower_type <- "INFRASTRUCTURE"

ipt_int[((ipt_int$tech_2g == TRUE)|(ipt_int$tech_3g == TRUE)|(ipt_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

ipt_int[(((ipt_int$fiber == TRUE)|(ipt_int$radio == TRUE)|(ipt_int$satellite == TRUE))&(ipt_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

ipt_int[(((ipt_int$fiber == TRUE)|(ipt_int$radio == TRUE)|(ipt_int$satellite == TRUE))&(ipt_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"


ipt_oimr$tower_type <- "INFRASTRUCTURE"

ipt_oimr[((ipt_oimr$tech_2g == TRUE)|(ipt_oimr$tech_3g == TRUE)|(ipt_oimr$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

ipt_oimr[(((ipt_oimr$fiber == TRUE)|(ipt_oimr$radio == TRUE)|(ipt_oimr$satellite == TRUE))&(ipt_oimr$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

ipt_oimr[(((ipt_oimr$fiber == TRUE)|(ipt_oimr$radio == TRUE)|(ipt_oimr$satellite == TRUE))&(ipt_oimr$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
ipt_int$source_file <- file_name_2

ipt_oimr$source_file <- file_name

#Source:
ipt_int$source <- "IPT"

ipt_oimr$source <- "OIMR"

#Internal ID:
ipt_int$internal_id <- as.character(ipt_int$internal_id)

ipt_oimr$internal_id <- ipt_oimr$tower_name
ipt_oimr$internal_id_tdp <- ipt_oimr$tower_name

#IPT perimeter:
ipt_int$ipt_perimeter <- as.character(ipt_int$ipt_perimeter)
ipt_int$ipt_perimeter[grepl("NEW", ipt_int$ipt_perimeter)] <- "IPT"

ipt_oimr$ipt_perimeter <- as.character(ipt_oimr$ipt_perimeter)


######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frames

ipt <- ipt_int[,c("latitude",
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
                        "internal_id_tdp",
                        "tower_name",
                        "ipt_perimeter"
                        )]

ipt_oimr <- ipt_oimr[,c("latitude",
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
                        "internal_id_tdp",
                        "tower_name",
                        "ipt_perimeter"
                        )]


ipt <- rbind(ipt,ipt_oimr)
######################################################################################################################
ipt



##Remove those towers that are already in the macros source file and remove duplicates
macros_ids <- getInternalID(schema_dev, table_macros)

ipt <- ipt[!(ipt$internal_id_tdp%in%macros_ids$internal_id),]

ipt <- removeDuplicates(schema_dev,table_duplicates_ipt, ipt)



#Export the normalized output
saveRDS(ipt, paste(output_path, file_name_io, sep = "/"))

test <- readRDS(paste(output_path, file_name_io, sep = "/"))
identical(test, ipt)

#Set connection data
exportNormalizeIpt(schema_dev, table_ipt, ipt)
