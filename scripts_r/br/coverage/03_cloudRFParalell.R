library(jsonlite)
library(XML)
library(gdalUtils)
library('png')
library(raster)
library(rgeos)
library(sf)
library(readxl)
library(rpostgis)
library(pbapply)
library(httr)
library(parallel)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_br'
source(config_path)

source('~/shared/rural_planner/sql/br/coverage/loadDataCloudRF.R')
# (settlements without 4G)
cells_df <- loadDataCloudRF(schema_dev,table_settlements, table_coverage)


#CREATE INPUT DATA FRAME FOR API
#Create an auxiliary data frame to complete api's information
input_data_raw <- data.frame(cells_df$settlement_id,        
                             cells_df$latitude,     
                             cells_df$longitude,
                             stringsAsFactors = F
                             
)

colnames(input_data_raw) <- c("net",
                              "lat",
                              "lon")
  #Assign 3 azimuths for each one: 90,210,330 and names: settlement_id_1, .._2 y .._3
azimuths <- c(90, 210, 330)

x <- data.frame()
for (i in (1:length(azimuths))){
  aux_df <- input_data_raw
  aux_df$azi <- azimuths[i]
  aux_df$nam <- paste0(aux_df$net, '_', i)
  x <- rbind(x, aux_df)
  rm(aux_df)
}

input_data_raw <-x[order(x$nam),]
rm(x)

#Delete those which were calculated in other iterations

shp_files <- list.files(paste(input_path_cloudrf,output_shp_folder_cloudrf,sep='/'), recursive=T, full.names = F)
input_data_raw <- input_data_raw[!input_data_raw$nam %in% shp_files,]
  
total <- nrow(input_data_raw)

#half of them run in cloudRF
if( total %% 2 == 0) {
  for(i in(1 : (total/2))){
    input_data_raw[i,'url'] <- url_spain
  }

  #Other half of them run in cloudRF UK
  for(i in(((total/2)+1) : total)){
    input_data_raw[i,'url'] <- url_uk
  }
} else {
  for(i in(1: floor(total/2))){
    input_data_raw[i,'url'] <- url_spain
  }

  #Other half of them run in cloudRF UK
  for(i in(ceiling(total/2): total)){
    input_data_raw[i,'url'] <- url_uk
  }
}


if( (total %% 4) == 0){
  #first quarter and third one run by session1
  for(i in(1: (total/4))){
    input_data_raw[i,'uid'] <- api_id_session3
  }

  for(i in(((total/2) + 1 ): (0.75*total))){
    input_data_raw[i,'uid'] <- api_id_session4
  }

  #first quarter and third one run by session2
  for(i in(((total/4) + 1 ) : (total/2))){
    input_data_raw[i,'uid'] <- api_id_session3
  }
  
  for(i in(((0.75*total) + 1) : total)){
    input_data_raw[i,'uid'] <- api_id_session4
  }
  
} else {
  #first quarter and third one run by session1
  for(i in(1: floor(total/4))){
   input_data_raw[i,'uid'] <- api_id_session3
  }
  
  for(i in(ceiling(total/2): floor(0.75*total))){
    input_data_raw[i,'uid'] <- api_id_session4
  }
  
  #first quarter and third one run by session2
  for(i in(ceiling(total/4) : floor(total/2))){
    input_data_raw[i,'uid'] <- api_id_session3
  }
  
  for(i in(ceiling(0.75*total) : total)){
    input_data_raw[i,'uid'] <- api_id_session4
  }
}
input_data_raw$key <- api_key
input_data_raw$lat <- as.numeric(input_data_raw$lat)
input_data_raw$lon <- as.numeric(input_data_raw$lon)
input_data_raw$txh <- as.numeric(50)
input_data_raw$frq <- 700
input_data_raw$rxh <- 1.5
input_data_raw$dis <- 'm'
input_data_raw$txw <- 20  #Potencia
input_data_raw$txg <- 2.14 #Ganancia antena trasmisor
input_data_raw$rxg <- 2.14
input_data_raw$pm <- 3 #hemos probado el 1. funciona el 3.
input_data_raw$pe <- 2  #HACER PRUEBAS CON ESTE. TIENE 3 MODOS: 1,2 Y 3. probar con los tres.
input_data_raw$res <- 30
input_data_raw$rad <- 15
input_data_raw$out <- 2
input_data_raw$rxs <- -103
input_data_raw$ant <- 2794
input_data_raw$bwi <- 10
input_data_raw$ber <- 0
input_data_raw$blu <- -110
input_data_raw$clh <- 0
input_data_raw$cli <- 1 #climate = Equatorial
input_data_raw$cll <- 4
input_data_raw$fbr <- 0  ## Not relevant in specified antenna case
input_data_raw$file <- 'shp' 
input_data_raw$grn <- -95
input_data_raw$hbw <- 0  ## Not relevant in specified antenna case
input_data_raw$ked <- 0
input_data_raw$mod <- 0
input_data_raw$pol <- 'v'
input_data_raw$red <- -80
input_data_raw$ter <- 15
input_data_raw$tlt <- 6 # mean calculated with brasil towers' data = 5.69 -> 6
input_data_raw$vbw <- 0  ## Not relevant in specified antenna case
input_data_raw$col <- 11
input_data_raw$rel <- 90
input_data_raw$engine <- 2
input_data_raw$nf <- -104 #el bandwidth(bwi) = 10. 1mHz = -114 dBm, 10mHz = -104dBm, 20mHz = -101dBm

#FINAL INPUT(columns ordered)

input_data <- input_data_raw[, c("uid",
                                 "key",
                                 "lat",
                                 "lon",
                                 "txh",
                                 "frq",
                                 "rxh",
                                 "dis",
                                 "txw",
                                 "txg",
                                 "rxg",
                                 "pm",
                                 "pe",
                                 "res",
                                 "rad",
                                 "out",
                                 "rxs",
                                 "ant",
                                 "azi",
                                 "bwi",
                                 "ber",
                                 "blu",
                                 "clh",
                                 "cli",
                                 "cll",
                                 "fbr" ,
                                 "file",
                                 "grn",
                                 "hbw",
                                 "ked",
                                 "mod",
                                 "nam",
                                 "net",
                                 "pol",
                                 "red",
                                 "ter",
                                 "tlt",
                                 "vbw",
                                 "col",
                                 "rel",
                                 "engine",
                                 "nf",
                                 "url")] 

###########################################
#READ DATA FROM CLOUDRF AREA COVERAGE API#
source('~/shared/rural_planner/functions/br/coverage/makeRequest.R')

#create cluster with 4 nodes
clus <- makeCluster(4)
#each cluster request with diferents cloudrf sessions
parLapply(cl = clus, X=1:nrow(input_data), input_data, fun = makeRequest, MoreArgs = c(input_path = input_path_cloudrf, out_shp_folder = output_shp_folder_cloudrf), chunk.size = floor(nrow(input_data)/4))

###########################################
######### UNZIP SHP FOLDERS ###############

#Get the name of those folders
shp_files_zip <- list.files(paste(input_path_cloudrf,output_shp_folder_cloudrf,sep='/'), recursive=T, full.names = F)
#Create new folder
dir.create(paste(input_path_cloudrf,shp_folder_unzip,sep="/"))
#Unzip folders
lapply(shp_files_zip, function(f){unzip(paste(input_path_cloudrf,output_shp_folder_cloudrf,f,sep='/'),exdir=paste(input_path_cloudrf,shp_folder_unzip,strsplit(f,".shp"),sep="/"))})

####################################################
######### DATABASE: INSERT SHP FILES ###############

shp_files <- list.files(paste(input_path_cloudrf,shp_folder_unzip,sep='/'),pattern="\\.shp$" , recursive=T, full.names = F)

source('~/shared/rural_planner/sql/br/coverage/updateDBCloudRF.R')
updateDBCloudRF(schema_dev, table_final_cloudrf, shp_files)







