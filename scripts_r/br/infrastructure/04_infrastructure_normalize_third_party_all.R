
#LIBRARIES
library(RPostgreSQL)
library(stringr)
library(rgdal)
library(sf)
library(xml2)
library(tidyverse)
library(pbapply)
library(XML)
library(readxl)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_br'
source(config_path)


#VARIABLES
map_filenames <- "map_filenames.xlsx"

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")

file_name_nodes <- "third_party_nodes.rds"
file_name_lines <- "third_party_lines.rds"

source('~/shared/rural_planner/sql/br/infrastructure/04_updateDBTPAll.R')


#Unzip kmz file to open get .kml file
map_files <- read_excel(paste(input_path_infrastructure,map_filenames, sep="/"))

# Unzip files
lapply(map_files$file_name, function(x){
  dir.create(paste(input_path_infrastructure,gsub(".kmz","",x),sep="/"))
  unzip(paste(input_path_infrastructure,x,sep='/'),exdir=paste(input_path_infrastructure,gsub(".kmz","",x),sep="/"))})


## Read KML files

# Initialize variables
third_party_traces <- data.frame()
third_party_pops <- data.frame()

ns <- "d1"

for (i in (1:nrow(map_files))){
  kml_file <- gsub(".kmz", "/doc.kml", map_files$file_name[i])
  xml <- read_xml(paste(input_path_infrastructure, kml_file,sep="/"), encoding = "ISO-8859-1")

  #Traces
  
  print(Sys.time())
  
  Lines_list <- xml_parent(xml_find_all(xml,"//d1:LineString"))
  
  if(length(Lines_list)>0){
     dflines <- pblapply(Lines_list,function(x){
                    data_frame( pre_folder = xml_find_first(xml_parent(xml_parent(xml_parent(x))),str_c(ns,":name"))%>%xml_text,
                                folder = xml_find_first(xml_parent(xml_parent(x)),str_c(ns,":name"))%>%xml_text,
                                name =                     xml_find_first(xml_parent(x),str_c(ns,":name"))%>%xml_text,
                                wkt = xml_find_first(x, str_c(ns, ":", str_c("LineString/", ns, ":coordinates"))) 
                                      %>% xml_text 
                                      %>% str_split("\\s+") 
                                      %>% unlist 
                                      %>% {gsub(","," ",.)} 
                                      %>% paste(collapse=",") 
                                      %>% substr(2,nchar(.)-1) 
                                      %>% paste0("LINESTRING Z (",.,")")
                                )
                    }) %>% bind_rows
  
  dflines_int <- dflines[,c("pre_folder",
                              "folder",
                                 "name",
                                 "wkt")]
  
  dflines_int$location_detail <- paste(dflines_int$pre_folder, dflines_int$folder, dflines_int$name,sep=" - ", na.rm=T) 
  
  dflines_int$internal_id <- dflines_int$name
  
  dflines_int$source <- paste0(map_files$source[i],"_LINES")
  
  dflines_int$source_file <- map_files$file_name[i]
  
  Encoding(dflines_int$location_detail)<-"UTF-8"
  Encoding(dflines_int$internal_id)<-"UTF-8"
  Encoding(dflines_int$source)<-"UTF-8"
  Encoding(dflines_int$source_file)<-"UTF-8"
  
  
  dflines_int <- dflines_int[,c("location_detail",
                                        "wkt",
                                        "internal_id",
                                        "source",
                                        "source_file"
                                        )]
  
  third_party_traces <- rbind(third_party_traces,dflines_int)
  
  assign(paste("dflines",tolower(map_files$source[i]),sep="_"), dflines_int)
  
  }
  
 
  print(paste(map_files$file_name[i]," trace processed.", sep=""))
  
  #POPs
  
  print(Sys.time())
  
  Points_list <- xml_parent(xml_find_all(xml,"//d1:Point"))
  
  if(length(Points_list)>0){
    
  dfpoints <- pblapply(Points_list,function(x){
    
                      data_frame( folder = xml_find_first(xml_parent(x),str_c(ns,":name"))%>%xml_text,
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
  
  
  dfpoints_int <- dfpoints[,c("folder",
                                 "name",
                                 "latitude",
                              "longitude",
                              "height")]
  
  dfpoints_int$location_detail <- paste(dfpoints_int$folder, dfpoints_int$name, na.rm=T,sep=" - ") 
  
  dfpoints_int$internal_id <- dfpoints_int$name
  
  dfpoints_int$source <- paste0(map_files$source[i],"_POINTS")
  
  dfpoints_int$source_file <- map_files$file_name[i]
  
  dfpoints_int$longitude <- as.numeric(dfpoints_int$longitude)
  
  dfpoints_int$latitude <- as.numeric(dfpoints_int$latitude)
  
  dfpoints_int$tower_height <- as.integer(dfpoints_int$height)
  
  Encoding(dfpoints_int$location_detail)<-"UTF-8"
  Encoding(dfpoints_int$internal_id)<-"UTF-8"
  Encoding(dfpoints_int$source)<-"UTF-8"
  Encoding(dfpoints_int$source_file)<-"UTF-8"
  
  
  dfpoints_int <- dfpoints_int[,c("location_detail",
                                        "internal_id",
                                        "source",
                                        "source_file",
                                        "tower_height",
                                        "longitude",
                                        "latitude"
                                        )]
  
  third_party_pops <- rbind(third_party_pops,dfpoints_int)
  
  assign(paste("dfpoints",tolower(map_files$source[i]),sep="_"), dfpoints_int)
  }
  
  print(paste(Sys.time(),"/",map_files$file_name[i]," pops processed.", sep=""))
  
  
  rm(Points_list,Lines_list, xml, dfpoints, dflines, dflines_int, dfpoints_int)
}


## Latitude and longitude: does not apply
third_party_traces$latitude <- as.numeric(0)

#Longitude:
third_party_traces$longitude <- as.numeric(0)

#Tower height: unknown, assumed 0m
third_party_traces$tower_height <- as.integer(0)

#Owner:
third_party_traces$owner <- as.character(gsub("_LINES","",third_party_traces$source))


#tech_2g, tech_3g, tech_4g: does not apply
third_party_traces$"tech_2g" <- FALSE
third_party_traces$"tech_3g" <- FALSE
third_party_traces$"tech_4g" <- FALSE

third_party_traces$coverage_area_2g <- as.character(NA)
third_party_traces$coverage_area_3g <- as.character(NA)
third_party_traces$coverage_area_4g <- as.character(NA)

#Type:
third_party_traces$type <- "FO TRACE"

#Subtype: as character 
third_party_traces$subtype <- as.character(NA)
Encoding(third_party_traces$subtype) <- "UTF-8"

#Location detail: as char
third_party_traces$location_detail <- as.character(third_party_traces$location_detail)
Encoding(third_party_traces$location_detail) <- "UTF-8"

#In Service: 
third_party_traces$in_service <- "IN SERVICE"

#Vendor: Unknown
third_party_traces$vendor <- NA
third_party_traces$vendor <- as.character(third_party_traces$vendor)


    
#fiber, radio, satellite: all FO nodes/ traces
third_party_traces$fiber <- TRUE
third_party_traces$radio <- FALSE
third_party_traces$satellite <- FALSE

#satellite band in use:
third_party_traces$satellite_band_in_use <- NA
third_party_traces$satellite_band_in_use <- as.character(third_party_traces$satellite_band_in_use)

#radio_distance_km: no info on this
third_party_traces$radio_distance_km <- NA
third_party_traces$radio_distance_km <- as.numeric(third_party_traces$radio_distance_km)

#last_mile_bandwidth:
third_party_traces$last_mile_bandwidth <- NA
third_party_traces$last_mile_bandwidth <- as.character(third_party_traces$last_mile_bandwidth)

#Tower type:
third_party_traces$tower_type <- "INFRASTRUCTURE"

third_party_traces[((third_party_traces$tech_2g == TRUE)|(third_party_traces$tech_3g == TRUE)|(third_party_traces$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

third_party_traces[(((third_party_traces$fiber == TRUE)|(third_party_traces$radio == TRUE)|(third_party_traces$satellite == TRUE))&(third_party_traces$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

third_party_traces[(((third_party_traces$fiber == TRUE)|(third_party_traces$radio == TRUE)|(third_party_traces$satellite == TRUE))&(third_party_traces$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
third_party_traces$source_file <- as.character(third_party_traces$source_file)

#Source:
third_party_traces$source<-  as.character(third_party_traces$source)

#Internal ID:
third_party_traces$internal_id <- as.character(third_party_traces$internal_id)


#Tower_name:
third_party_traces$tower_name <- as.character(third_party_traces$internal_id)
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
third_party_traces <- third_party_traces[,c("latitude",
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
                        
                        "wkt"
                        )]
######################################################################################################################


## Latitude and longitude: already processed

#Tower height:Correct heights to 0 where defined as altitude
third_party_pops$tower_height[third_party_pops$source%in%c('SOUTHTECH_POINTS','LEVEL_3_POINTS','INTERNEXA_POINTS','MASTERCABO_POINTS','G8_POINTS')] <- as.integer(0)

#Owner:
third_party_pops$owner <- as.character(gsub("_POINTS","",third_party_pops$source))

#tech_2g, tech_3g, tech_4g: does not apply
third_party_pops$"tech_2g" <- FALSE
third_party_pops$"tech_3g" <- FALSE
third_party_pops$"tech_4g" <- FALSE

third_party_pops$coverage_area_2g <- as.character(NA)
third_party_pops$coverage_area_3g <- as.character(NA)
third_party_pops$coverage_area_4g <- as.character(NA)

#Type:
third_party_pops$type <- "FO POP"

#Subtype: as character 
third_party_pops$subtype <- as.character(NA)
Encoding(third_party_pops$subtype) <- "UTF-8"

#Location detail: as char
third_party_pops$location_detail <- as.character(third_party_pops$location_detail)
Encoding(third_party_pops$location_detail) <- "UTF-8"

#In Service: 
third_party_pops$in_service <- "IN SERVICE"

#Vendor: Unknown
third_party_pops$vendor <- NA
third_party_pops$vendor <- as.character(third_party_pops$vendor)

#fiber, radio, satellite: all FO nodes/ traces
third_party_pops$fiber <- TRUE
third_party_pops$radio <- FALSE
third_party_pops$satellite <- FALSE

#satellite band in use:
third_party_pops$satellite_band_in_use <- NA
third_party_pops$satellite_band_in_use <- as.character(third_party_pops$satellite_band_in_use)

#radio_distance_km: no info on this
third_party_pops$radio_distance_km <- NA
third_party_pops$radio_distance_km <- as.numeric(third_party_pops$radio_distance_km)

#last_mile_bandwidth:
third_party_pops$last_mile_bandwidth <- NA
third_party_pops$last_mile_bandwidth <- as.character(third_party_pops$last_mile_bandwidth)

#Tower type:
third_party_pops$tower_type <- "INFRASTRUCTURE"

third_party_pops[((third_party_pops$tech_2g == TRUE)|(third_party_pops$tech_3g == TRUE)|(third_party_pops$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

third_party_pops[(((third_party_pops$fiber == TRUE)|(third_party_pops$radio == TRUE)|(third_party_pops$satellite == TRUE))&(third_party_pops$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

third_party_pops[(((third_party_pops$fiber == TRUE)|(third_party_pops$radio == TRUE)|(third_party_pops$satellite == TRUE))&(third_party_pops$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#Source file:
third_party_pops$source_file <- as.character(third_party_pops$source_file)

#Source:
third_party_pops$source<-  as.character(third_party_pops$source)

#Internal ID:
third_party_pops$internal_id <- as.character(third_party_pops$internal_id)


#Tower_name:
third_party_pops$tower_name <- as.character(third_party_pops$internal_id)
######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
third_party_pops <- third_party_pops[,c("latitude",
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


#Export the normalized output
saveRDS(third_party_pops, paste(output_path, file_name_nodes, sep = "/"))
saveRDS(third_party_traces, paste(output_path, file_name_lines, sep = "/"))

test <- readRDS(paste(output_path, file_name_nodes, sep = "/"))
identical(test, third_party_pops)

test_lines <- readRDS(paste(output_path, file_name_lines, sep = "/"))
identical(test_lines, third_party_traces)

#HAY UN AD-HOC EN EL FICHERO, MIRAR SI ALGO SALE MAL
updateDBTPAll(schema_dev, table_lines_all, table_points_all, third_party_traces, third_party_pops)
