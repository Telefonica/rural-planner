

#LIBRARIES
library(RPostgreSQL)
library(stringr)
library(rgdal)
library(sf)
library(xml2)
library(pbapply)
library(XML)
library(readxl)
library(dplyr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_br'
source(config_path)


#VARIABLES
kml_file <- "doc.kml"
kmz_radio <- "KMZ_Ativos.kmz" 

file_name_fiber <- "Rede_DWDM_Vivo.xlsx"
file_name_fiber_2 <- "20191101_Mun_Capacidade.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_mw <- "vivo_mw_pops.rds"
file_name_fo <- "vivo_fo_pops.rds"

source('~/shared/rural_planner/sql/exportDB_AddGeom.R')



#Unzip files
lapply(c(kmz_radio), function(x){
  dir.create(paste(input_path_infrastructure,gsub(".kmz","",x),sep="/"))
  unzip(paste(input_path_infrastructure,x,sep='/'),exdir=paste(input_path_infrastructure,gsub(".kmz","",x),sep="/"))})

#read excels

fiber_vivo_raw <- read_excel(paste(input_path_infrastructure, file_name_fiber, sep='/'))
fiber_vivo_raw_a <- fiber_vivo_raw[,c("SiteA",
                                      "UFA",
                                      "FabricanteA",
                                      "ReleaseHWA",
                                      "MunicipioA",
                                      "Status",
                                      "PropriedadeFibra",
                                      "LatitudeA",
                                      "LongitudeA")]
fiber_vivo_raw_b <- fiber_vivo_raw[,c("SiteB",
                                      "UFB",
                                      "FabricanteB",
                                      "ReleaseHWB",
                                      "MunicipioB",
                                      "Status",
                                      "PropriedadeFibra",
                                      "LatitudeB",
                                      "LongitudeB")]

names(fiber_vivo_raw_a) <- c("site",
                             "uf",
                             "vendor",
                             "release_hw",
                             "municipio",
                             "status",
                             "owner",
                             "latitude",
                             "longitude")

names(fiber_vivo_raw_b) <- c("site",
                             "uf",
                             "release_hw",
                             "vendor",
                             "municipio",
                             "status",
                             "owner",
                             "latitude",
                             "longitude")

fiber_vivo_int <- rbind(fiber_vivo_raw_a, fiber_vivo_raw_b)

fiber_vivo_2_raw <- read_excel(paste(input_path_infrastructure, file_name_fiber_2, sep='/'))
fiber_vivo_2_int <- fiber_vivo_2_raw[,c("Código IBGE",
                                        "UF",
                                        "Latitude",
                                        "Longitude",
                                        "Tecnologia (Dez 2019)")]

names(fiber_vivo_2_int) <- c("admin_division_2_id",
                             "uf",
                             "latitude",
                             "longitude",
                             "technology")


## Read KML files

# Initialize variables
vivo_mw_pops <- data.frame()

ns <- "d1"


input_path_radio <- paste(input_path_infrastructure, gsub(".kmz","",kmz_radio), kml_file,sep="/")

xml <- read_xml(input_path_radio)

## POPs

print(Sys.time())

Points_list <- xml_parent(xml_find_all(xml,"//d1:Point"))

if(length(Points_list)>0){
  
  dfpoints <- pblapply(Points_list,function(x){
    
    data.frame( folder = xml_find_first(xml_parent(x),str_c(ns,":name"))%>%xml_text,
                name = xml_find_first(x, str_c(ns, ":", "name")) %>% xml_text, 
                height =xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text
                %>% str_split(",")
                %>% sapply('[',3), 
                coordinates = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text,
                longitude = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text
                %>% str_split(",")
                %>% sapply('[',1),
                latitude = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) %>% xml_text
                %>% str_split(",")
                %>% sapply('[',2),
                wkt = xml_find_first(x, str_c(ns, ":", str_c("Point/", ns, ":coordinates"))) 
                %>% xml_text 
                %>% {gsub(","," ",.)} 
                %>% paste0("POINT Z (",.,")")
    )
    
  }) %>% bind_rows
  
  
  dfpoints_int <- dfpoints[,c("name",
                              "latitude",
                              "longitude")]
  
  dfpoints_int$location_detail <- as.character(NA)
  
  dfpoints_int$internal_id <- dfpoints_int$name
  
  dfpoints_int$source <- ("VIVO MW")
  
  dfpoints_int$source_file <- kmz_radio
  
  dfpoints_int$longitude <- as.numeric(dfpoints_int$longitude)
  
  dfpoints_int$latitude <- as.numeric(dfpoints_int$latitude)
  
  dfpoints_int$tower_height <- as.integer(15)
  
  Encoding(dfpoints_int$location_detail)<-"UTF-8"
  Encoding(dfpoints_int$internal_id)<-"UTF-8"
  Encoding(dfpoints_int$source)<-"UTF-8"
  Encoding(dfpoints_int$source_file)<-"UTF-8"
  
  
  vivo_mw_pops <- dfpoints_int[,c("location_detail",
                                  "internal_id",
                                  "source",
                                  "source_file",
                                  "tower_height",
                                  "longitude",
                                  "latitude"
  )]
}


rm(Points_list, xml, dfpoints, dfpoints_int)




#Latitude and longitude: already processed
#Tower height:already processed

#Owner:
vivo_mw_pops$owner <- as.character(gsub("_POINTS","",vivo_mw_pops$source))


#tech_2g, tech_3g, tech_4g: does not apply
vivo_mw_pops$"tech_2g" <- FALSE
vivo_mw_pops$"tech_3g" <- FALSE
vivo_mw_pops$"tech_4g" <- FALSE

vivo_mw_pops$coverage_area_2g <- as.character(NA)
vivo_mw_pops$coverage_area_3g <- as.character(NA)
vivo_mw_pops$coverage_area_4g <- as.character(NA)

#Type:
vivo_mw_pops$type <- "MW POP"

#Subtype: as character 
vivo_mw_pops$subtype <- as.character(NA)
Encoding(vivo_mw_pops$subtype) <- "UTF-8"

#Location detail: as char
vivo_mw_pops$location_detail <- as.character(vivo_mw_pops$location_detail)
Encoding(vivo_mw_pops$location_detail) <- "UTF-8"

#In Service: 
vivo_mw_pops$in_service <- "IN SERVICE"

#Vendor: Unknown
vivo_mw_pops$vendor <- NA
vivo_mw_pops$vendor <- as.character(vivo_mw_pops$vendor)


#fiber, radio, satellite: all FO nodes/ traces
vivo_mw_pops$fiber <- FALSE
vivo_mw_pops$radio <- TRUE
vivo_mw_pops$satellite <- FALSE

#satellite band in use:
vivo_mw_pops$satellite_band_in_use <- NA
vivo_mw_pops$satellite_band_in_use <- as.character(vivo_mw_pops$satellite_band_in_use)

#radio_distance_km: no info on this
vivo_mw_pops$radio_distance_km <- NA
vivo_mw_pops$radio_distance_km <- as.numeric(vivo_mw_pops$radio_distance_km)

#last_mile_bandwidth:
vivo_mw_pops$last_mile_bandwidth <- NA
vivo_mw_pops$last_mile_bandwidth <- as.character(vivo_mw_pops$last_mile_bandwidth)

#Tower type:
vivo_mw_pops$tower_type <- "INFRASTRUCTURE"

vivo_mw_pops[((vivo_mw_pops$tech_2g == TRUE)|(vivo_mw_pops$tech_3g == TRUE)|(vivo_mw_pops$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

vivo_mw_pops[(((vivo_mw_pops$fiber == TRUE)|(vivo_mw_pops$radio == TRUE)|(vivo_mw_pops$satellite == TRUE))&(vivo_mw_pops$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

vivo_mw_pops[(((vivo_mw_pops$fiber == TRUE)|(vivo_mw_pops$radio == TRUE)|(vivo_mw_pops$satellite == TRUE))&(vivo_mw_pops$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
vivo_mw_pops$source_file <- as.character(vivo_mw_pops$source_file)

#Source:
vivo_mw_pops$source<-  as.character(vivo_mw_pops$source)

#Internal ID:
vivo_mw_pops$internal_id <- as.character(vivo_mw_pops$internal_id)


#Tower_name:
vivo_mw_pops$tower_name <- as.character(vivo_mw_pops$internal_id)
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
vivo_mw_pops <- vivo_mw_pops[,c("latitude",
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
######################################################################################################################


## Latitude and longitude: already processed
fiber_vivo_int$latitude <- as.numeric(fiber_vivo_int$latitude)
fiber_vivo_2_int$latitude <- as.numeric(fiber_vivo_2_int$latitude)


fiber_vivo_int$longitude <- as.numeric(fiber_vivo_int$longitude)
fiber_vivo_2_int$longitude <- as.numeric(fiber_vivo_2_int$longitude)

#Tower height:already processed
fiber_vivo_int$tower_height <- as.integer(15)
fiber_vivo_2_int$tower_height <- as.integer(15)


#Owner:
fiber_vivo_int$owner <- as.character(fiber_vivo_int$owner)
fiber_vivo_2_int$owner <- as.character("VIVO")


#tech_2g, tech_3g, tech_4g: does not apply
fiber_vivo_int$"tech_2g" <- FALSE
fiber_vivo_int$"tech_3g" <- FALSE
fiber_vivo_int$"tech_4g" <- FALSE

fiber_vivo_2_int$"tech_2g" <- FALSE
fiber_vivo_2_int$"tech_3g" <- FALSE
fiber_vivo_2_int$"tech_4g" <- FALSE

fiber_vivo_int$coverage_area_2g <- as.character(NA)
fiber_vivo_int$coverage_area_3g <- as.character(NA)
fiber_vivo_int$coverage_area_4g <- as.character(NA)

fiber_vivo_2_int$coverage_area_2g <- as.character(NA)
fiber_vivo_2_int$coverage_area_3g <- as.character(NA)
fiber_vivo_2_int$coverage_area_4g <- as.character(NA)

#Type:
fiber_vivo_int$type <- "FO POP"
fiber_vivo_2_int$type <- "FO POP"

#Subtype: as character 
fiber_vivo_int$subtype <- as.character(NA)
fiber_vivo_int$subtype[(fiber_vivo_int$release_hw=="OLA" | is.na(fiber_vivo_int$release_hw))] <- "UNPRIORITIZED"
fiber_vivo_2_int$subtype <- as.character(NA)
fiber_vivo_2_int$subtype[(fiber_vivo_2_int$technology=="Capacidade")] <- "UNPRIORITIZED"

#Location detail: as char
fiber_vivo_int$location_detail <- as.character(fiber_vivo_int$municipio)
Encoding(fiber_vivo_int$location_detail) <- "UTF-8"
fiber_vivo_2_int$location_detail <- paste(fiber_vivo_2_int$uf, as.character(fiber_vivo_2_int$admin_division_2_id))
Encoding(fiber_vivo_2_int$location_detail) <- "UTF-8"

#In Service: 
fiber_vivo_int$in_service <- "IN SERVICE"
fiber_vivo_int$in_service[fiber_vivo_int$status=="Planejado"] <- "PLANNED"
fiber_vivo_2_int$in_service <- "IN SERVICE"

#Vendor: 
fiber_vivo_int$vendor <- as.character(fiber_vivo_int$vendor)
fiber_vivo_2_int$vendor <- NA
fiber_vivo_2_int$vendor <- as.character(fiber_vivo_2_int$vendor)



#fiber, radio, satellite: all FO nodes/ traces
fiber_vivo_int$fiber <- TRUE
fiber_vivo_int$radio <- FALSE
fiber_vivo_int$satellite <- FALSE
fiber_vivo_2_int$fiber <- TRUE
fiber_vivo_2_int$radio <- FALSE
fiber_vivo_2_int$satellite <- FALSE

#satellite band in use:
fiber_vivo_int$satellite_band_in_use <- NA
fiber_vivo_int$satellite_band_in_use <- as.character(fiber_vivo_int$satellite_band_in_use)

fiber_vivo_2_int$satellite_band_in_use <- NA
fiber_vivo_2_int$satellite_band_in_use <- as.character(fiber_vivo_2_int$satellite_band_in_use)

#radio_distance_km: no info on this
fiber_vivo_int$radio_distance_km <- NA
fiber_vivo_int$radio_distance_km <- as.numeric(fiber_vivo_int$radio_distance_km)

fiber_vivo_2_int$radio_distance_km <- NA
fiber_vivo_2_int$radio_distance_km <- as.numeric(fiber_vivo_2_int$radio_distance_km)

#last_mile_bandwidth:
fiber_vivo_int$last_mile_bandwidth <- NA
fiber_vivo_int$last_mile_bandwidth <- as.character(fiber_vivo_int$last_mile_bandwidth)

fiber_vivo_2_int$last_mile_bandwidth <- NA
fiber_vivo_2_int$last_mile_bandwidth <- as.character(fiber_vivo_2_int$last_mile_bandwidth)

#Tower type:
fiber_vivo_int$tower_type <- "INFRASTRUCTURE"

fiber_vivo_int[((fiber_vivo_int$tech_2g == TRUE)|(fiber_vivo_int$tech_3g == TRUE)|(fiber_vivo_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

fiber_vivo_int[(((fiber_vivo_int$fiber == TRUE)|(fiber_vivo_int$radio == TRUE)|(fiber_vivo_int$satellite == TRUE))&(fiber_vivo_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

fiber_vivo_int[(((fiber_vivo_int$fiber == TRUE)|(fiber_vivo_int$radio == TRUE)|(fiber_vivo_int$satellite == TRUE))&(fiber_vivo_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

fiber_vivo_2_int$tower_type <- "INFRASTRUCTURE"

fiber_vivo_2_int[((fiber_vivo_2_int$tech_2g == TRUE)|(fiber_vivo_2_int$tech_3g == TRUE)|(fiber_vivo_2_int$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

fiber_vivo_2_int[(((fiber_vivo_2_int$fiber == TRUE)|(fiber_vivo_2_int$radio == TRUE)|(fiber_vivo_2_int$satellite == TRUE))&(fiber_vivo_2_int$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

fiber_vivo_2_int[(((fiber_vivo_2_int$fiber == TRUE)|(fiber_vivo_2_int$radio == TRUE)|(fiber_vivo_2_int$satellite == TRUE))&(fiber_vivo_2_int$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
fiber_vivo_int$source_file <- as.character(file_name_fiber)
fiber_vivo_2_int$source_file <- as.character(file_name_fiber_2)

#Source:
fiber_vivo_int$source<-  as.character("FO VIVO")
fiber_vivo_int$source[fiber_vivo_int$subtype=="UNPRIORITIZED"] <- as.character("FO VIVO UNPRIORITIZED")
fiber_vivo_2_int$source<-  as.character("FO 3RD PARTY")

#Internal ID:
fiber_vivo_int$internal_id <- paste(fiber_vivo_int$uf, fiber_vivo_int$site, sep="")
fiber_vivo_2_int$internal_id <- paste(fiber_vivo_2_int$uf, fiber_vivo_2_int$admin_division_2_id, sep="")


#Tower_name:
fiber_vivo_int$tower_name <- as.character(fiber_vivo_int$internal_id)
fiber_vivo_2_int$tower_name <- as.character(fiber_vivo_2_int$internal_id)
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
fiber_vivo_int <- fiber_vivo_int[,c("latitude",
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

fiber_vivo_2_int <- fiber_vivo_2_int[,c("latitude",
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

fiber_vivo <- rbind(fiber_vivo_2_int, fiber_vivo_int)
######################################################################################################################

#Export the normalized output


saveRDS(vivo_mw_pops, paste(output_path, file_name_mw, sep = "/"))
saveRDS(fiber_vivo, paste(output_path, file_name_fo, sep = "/"))

test_mw <- readRDS(paste(output_path, file_name_mw, sep = "/"))
identical(test_mw, vivo_mw_pops)

test_fo <- readRDS(paste(output_path, file_name_fo, sep = "/"))
identical(test_fo, fiber_vivo)


##Upload to database (intermediate output)
exportDB_AddGeom(schema_dev, table_radio, vivo_mw_pops, "geom")
exportDB_AddGeom(schema_dev, table_fiber, fiber_vivo, "geom")

