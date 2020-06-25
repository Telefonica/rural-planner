
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(scales)
library(readxl)
library(RCurl)
library(RJSONIO)
library(plyr)
library(osmdata)
library(rgdal)
 

### config ###
#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)


#Excels
source_name_1<-"Localidades DANE 12326 Loc.xlsx"
source_name_2<-"col_bnd_admin5_dane_2012.csv"
source_name_3<-"C_digos_de_la_divisi_n_Pol_tico_Administrativa_de_Colombia.csv"
source_name_4<-'Informacion Geografica de Centros Poblados y Coberturas Simuladas.xlsx'
source_name_5<-'20180608 Censo CP 2005.xlsx'
source_name_6<-'DIVIPOLA_20180630.xlsx'
source_name_7<- 'geografia a mano colombia.xlsx'
source_hab_house<-'Hab_house_departament.xlsx'
households_file <- 'CO-Population_Data-2018-05-23.csv'
source_admin_div_3<-"Regionales.xlsx"
file_false_households <- 'false_households.xlsx'
file_falsos_positivos_municipios <- 'falsos positivos municipios.xlsx'

#shp files
shp_municipality_name <- "MGN_MPIO_POLITICO.shp"
shp_departament_name <- "MGN_DPTO_POLITICO.shp"
shp_settlement_name <- "MGN_URB_AREA_CENSAL.shp"

#Auxiliary functions
source('~/shared/rural_planner/sql/getAllTable.R')
source('~/shared/rural_planner/sql/uploadDBWithIndex.R')
source('~/shared/rural_planner/sql/co/demography/uploadGoogleData.R')
source('~/shared/rural_planner/sql/co/demography/updateDBGoogle.R')
source('~/shared/rural_planner/sql/co/demography/loadUnlocatedSettlements.R')
source('~/shared/rural_planner/sql/co/demography/addColumnDepartments.R')
source('~/shared/rural_planner/sql/co/demography/uploadIntermediateOutput.R')
source('~/shared/rural_planner/sql/co/demography/facebookHouseholds.R')
source('~/shared/rural_planner/sql/co/demography/facebookHouseholds02.R')
source('~/shared/rural_planner/sql/co/demography/assignClosestSettlement.R')
source('~/shared/rural_planner/sql/co/demography/falsePositive.R')
source('~/shared/rural_planner/sql/co/demography/DBSCANCluster.R')
source('~/shared/rural_planner/sql/co/demography/deleteUnassignedHouseholds.R')
source('~/shared/rural_planner/sql/co/demography/flagFalsePoisitive.R')
source('~/shared/rural_planner/sql/co/demography/addColumns.R')
source('~/shared/rural_planner/sql/co/demography/addNumberHousehold.R')
source('~/shared/rural_planner/sql/co/demography/completeSettlements.R')
source('~/shared/rural_planner/sql/co/demography/createNormalizedCluster.R')
source('~/shared/rural_planner/sql/co/demography/createNormalizedZRD.R')
source('~/shared/rural_planner/sql/co/demography/updateHousehold.R')
source('~/shared/rural_planner/sql/co/demography/fillMissingValues.R')
source('~/shared/rural_planner/sql/co/demography/modifyDbscanClusterId.R')
source('~/shared/rural_planner/sql/co/demography/updatePopulationCorrected.R')
source('~/shared/rural_planner/sql/co/demography/exportSettlements.R')
source('~/shared/rural_planner/sql/co/demography/createUnaggregatedZRD.R')
source('~/shared/rural_planner/sql/co/demography/correctPopulation.R')


source('~/shared/rural_planner/functions/co/demography/mergeDataFrames.R')
source('~/shared/rural_planner/functions/co/demography/functions_google.R')
source('~/shared/rural_planner/functions/co/demography/setHabHouse.R')
source('~/shared/rural_planner/functions/co/demography/setInsidePolygon.R')
source('~/shared/rural_planner/functions/co/demography/setAdminDivision1.R')

#Load and collect data that we have

file_name_1 <- paste(input_path_demography, source_name_1, sep = "/")
file_name_2 <- paste(input_path_demography, source_name_2, sep = "/")
file_name_3 <- paste(input_path_demography, source_name_3, sep = "/")
file_name_4 <- paste(input_path_demography, source_name_4, sep = "/")
file_name_5 <- paste(input_path_demography, source_name_5, sep = "/")
file_name_6 <- paste(input_path_demography, source_name_6, sep = "/")

settlements_raw_1 <- read_excel(file_name_1)

#We select the fields that we will use

names(settlements_raw_1) <- c('settlement_id', 
                              'admin_division_2_name', 
                              'admin_division_1_name',
                              'settlement_name', 
                              'classification')

settlements_raw_1$settlement_id<-str_pad(as.character(settlements_raw_1$settlement_id),8,"left",pad="0")
settlements_raw_1$latitude <- NA
settlements_raw_1$longitude <- NA
settlements_raw_1$source <- source_name_1


settlements_raw_2 <- read.csv2(file_name_2)

settlements_raw_2 <- settlements_raw_2[,c(9,6,8,11:13,2)]

names(settlements_raw_2) <-  c('settlement_name',
                                     'settlement_id',  
                                     'type', 
                                     'area', 
                                     'latitude',
                                     'longitude',
                                     'geom')

settlements_raw_2$settlement_id<-str_pad(as.character(settlements_raw_2$settlement_id),8,"left",pad="0")
settlements_raw_2$settlement_name<-as.character(settlements_raw_2$settlement_name)
settlements_raw_2$longitude[settlements_raw_2$longitude==0] <- NA
settlements_raw_2$latitude[settlements_raw_2$latitude==0] <- NA

settlements_raw_2$source <- source_name_2


settlements_raw_3 <- read.csv2(file_name_3)

settlements_raw_3 <- settlements_raw_3[,c(3,6,9,10)]

names(settlements_raw_3) <- c('settlement_id',
                                    'settlement_name',
                                    'longitude',
                                    'latitude')


settlements_raw_3$settlement_id<-as.character(settlements_raw_3$settlement_id)
settlements_raw_3$settlement_id<-gsub(',','',settlements_raw_3$settlement_id)

settlements_raw_3$settlement_id<-str_pad(settlements_raw_3$settlement_id,8,"left",pad="0")
settlements_raw_3$settlement_name<-as.character(settlements_raw_3$settlement_name)

settlements_raw_3$latitude<-as.numeric(as.character(settlements_raw_3$latitude))
settlements_raw_3$longitude<-as.numeric(as.character(settlements_raw_3$longitude))

settlements_raw_3$longitude[settlements_raw_3$longitude==0] <- NA
settlements_raw_3$latitude[settlements_raw_3$latitude==0] <- NA

settlements_raw_3$source <- source_name_3


settlements_raw_4 <- read_excel(file_name_4, skip=1)

settlements_raw_4 <- settlements_raw_4[,c(1:6, 13,14)]

names(settlements_raw_4) <- c('settlement_id',
                                    'admin_division_1_name',
                                    'admin_division_2_name',
                                    'settlement_name', 
                                    'area', 
                                    'class', 
                                    'latitude',
                                    'longitude')


settlements_raw_4$settlement_id<-str_pad(as.character(settlements_raw_4$settlement_id),8,"left",pad="0")

settlements_raw_4$source <- source_name_4


settlements_raw_5 <- read_excel(file_name_5, sheet='POblacion General',skip=1)

settlements_raw_5 <- settlements_raw_5[1:(nrow(settlements_raw_5)-1),c(1,2,4:6,9:10,18,19,23)]

names(settlements_raw_5) <- c('admin_division_1_id',
                                    'settlement_id',
                                    'admin_division_2_name',
                                    'admin_division_1_name',
                                    'settlement_name',
                                    'longitude',
                                    'latitude',
                                    'capital',
                                    'rest',
                                    'population_census')


settlements_raw_5$admin_division_1_id<-str_pad(as.character(settlements_raw_5$admin_division_1_id),5,"left",pad="0")

settlements_raw_5$settlement_id<-str_pad(as.character(settlements_raw_5$settlement_id),8,"left",pad="0")

settlements_raw_5$latitude<-as.character(settlements_raw_5$latitude)
settlements_raw_5$latitude<-as.numeric(gsub(',','.',settlements_raw_5$latitude))

settlements_raw_5$longitude<-as.character(settlements_raw_5$longitude)
settlements_raw_5$longitude<-as.numeric(gsub(',','.',settlements_raw_5$longitude))

settlements_raw_5$longitude[settlements_raw_5$longitude==0] <- NA
settlements_raw_5$latitude[settlements_raw_5$latitude==0] <- NA

settlements_raw_5$source <- source_name_5


settlements_raw_6 <- read_excel(file_name_6,skip = 4)

settlements_raw_6 <- settlements_raw_6[,c(1:6,8,10)]

names(settlements_raw_6) <- c('admin_division_2_id',
                              'admin_division_1_id',
                                    'settlement_id',
                                    'admin_division_2_name',
                                    'admin_division_1_name',
                                    'settlement_name',
                                    'longitude',
                                    'latitude')
settlements_raw_6$latitude<-as.numeric(settlements_raw_6$latitude)
settlements_raw_6$longitude<-as.numeric(settlements_raw_6$longitude)

#Remove settlements with duplicated coordinates
settlements_raw_6 <- settlements_raw_6[!duplicated(settlements_raw_6$latitude),]
#AD-HOC Remove erroneous location
settlements_raw_6$latitude[settlements_raw_6$settlement_id =='52678001'] <- NA
settlements_raw_6$longitude[settlements_raw_6$settlement_id =='52678001'] <- NA

settlements_raw_6$source <- source_name_6


# Merge geographic coordinates from all the sources possible to locate as many settlements as possible


settlements_basic<-Reduce(mergeDataFrames,list(settlements_raw_1,
                                        settlements_raw_3,
                                        settlements_raw_4[,c('settlement_name',
                                                              'settlement_id',
                                                              'latitude',
                                                              'longitude',
                                                              'source')],
                                        settlements_raw_5[,c('settlement_name',
                                                              'settlement_id',
                                                              'capital',
                                                              'rest',
                                                              'latitude',
                                                              'longitude',
                                                              'source')],
                                        settlements_raw_6[,c('settlement_name',
                                                              'settlement_id',
                                                              'latitude',
                                                              'longitude',
                                                              'source')]))




# Create normalized dataframe

# Define the data that we are going to collect for the basic_settlements dataset:
basic_names <- c("settlement_id", 
                 "settlement_name", 
                 "admin_division_1_id", 
                 "admin_division_1_name", 
                 "admin_division_2_id", 
                 "admin_division_2_name",
                 "admin_division_3_id",
                 "admin_division_3_name",
                 "population_census",
                 "population_corrected",
                 "latitude",
                 "longitude",
                 "source")

# Settlement_id: already done

# Administrative division one level above basic settlement division (ID)
settlements_basic$admin_division_1_id <- str_sub(settlements_basic$settlement_id,1,5)

# Administrative division two levels above basic settlement division (ID)
settlements_basic$admin_division_2_id <- str_sub(settlements_basic$settlement_id,1,2)

# Fill in admin_division_1_name and admin_division_2_name
# Create list of municipalities and departaments with id and name

admin_div_2_aux <- unique(settlements_basic[,c('admin_division_2_id','admin_division_2_name')])
admin_div_2_aux <- admin_div_2_aux[!is.na(admin_div_2_aux$admin_division_2_name),]

admin_div_1_aux <-unique(settlements_basic[,c('admin_division_1_id','admin_division_1_name')])
admin_div_1_aux <- admin_div_1_aux[!is.na(admin_div_1_aux$admin_division_1_name),]

settlements_basic<- within(settlements_basic,admin_division_2_name[is.na(admin_division_2_name)]<-
                             admin_div_2_aux[match(admin_division_2_id[is.na(admin_division_2_name)],admin_div_2_aux$admin_division_2_id),'admin_division_2_name'] )

settlements_basic<- within(settlements_basic,admin_division_1_name[is.na(admin_division_1_name)]<-
                             admin_div_1_aux[match(admin_division_1_id[is.na(admin_division_1_name)],admin_div_1_aux$admin_division_1_id),'admin_division_1_name'] )

# Fill in admin_division_3. Excel provides information of the departaments included in each region


filename_admin_div_3 <- paste(input_path_demography, source_admin_div_3, sep = "/")

admin_div_3_aux <- read_excel(filename_admin_div_3,col_names = c('','admin_division_2_name','admin_division_3_name',''))

admin_div_3_aux$admin_division_2_id <- admin_div_2_aux$admin_division_2_id[match(tolower(admin_div_3_aux$admin_division_2_name),tolower(admin_div_2_aux$admin_division_2_name))]

admin_div_3_aux$admin_division_2_id[admin_div_3_aux$admin_division_2_name=='Bogota']<-as.character("11")
admin_div_3_aux$admin_division_2_id[admin_div_3_aux$admin_division_2_name=='Archipielago de San Andres, Providencia y Santa Catalina']<-as.character("88")

settlements_basic$admin_division_3_name <- toupper(admin_div_3_aux$admin_division_3_name[match(settlements_basic$admin_division_2_id,tolower(admin_div_3_aux$admin_division_2_id))])

settlements_basic$admin_division_3_id <- toupper(admin_div_3_aux$admin_division_3_name[match(settlements_basic$admin_division_2_id,tolower(admin_div_3_aux$admin_division_2_id))])

#Settlement name:
settlements_basic$settlement_name <- as.character(settlements_basic$settlement_name)

#Administrative division one level above basic settlement division (name)
settlements_basic$admin_division_1_name <- as.character(settlements_basic$admin_division_1_name)

#Administrative division two levels above basic settlement division (Name)
settlements_basic$admin_division_2_name <- as.character(settlements_basic$admin_division_2_name)

#Remove location source of NA latitudes
settlements_basic$source[is.na(settlements_basic$latitude)]<-NA

##Population based on latest census (2005)

# Set only the projection of the capital of the province (CABECERA MUNICIPAL) from the 2005 census to 2018.

names(settlements_basic)[names(settlements_basic)=='capital'] <- 'population_census'
settlements_basic$population_census[settlements_basic$population_census==0] <- NA

#Corrected population
#Changeable in next process
settlements_basic$population_corrected <- NA

#Keep only the data we updated and remove last row
settlements_basic <- settlements_basic[,basic_names]

##### SET ENCODINGS

Encoding(settlements_basic$admin_division_1_name) <- "UTF-8"
Encoding(settlements_basic$admin_division_2_name) <- "UTF-8"
Encoding(settlements_basic$admin_division_3_name) <- "UTF-8"
Encoding(settlements_basic$settlement_name) <- "UTF-8"


#AD-HOC QA: remove incorrect geographic data and add some settlements' information
ad_hoc_remove_list<- c('05480005','50711001','52540004','18592002','25322003','50568008','94887001','94343004','91540002','97666001','99524007','99773021','99773008','27160009')
settlements_basic$latitude[settlements_basic$settlement_id%in%ad_hoc_remove_list] <- NA

settlements_basic$longitude[settlements_basic$settlement_id%in%ad_hoc_remove_list] <- NA

settlements_basic$source[settlements_basic$settlement_id%in%ad_hoc_remove_list] <- NA


ad_hoc_settlements <- read_excel(paste(input_path_demography,source_name_7, sep="/"))
ad_hoc_settlements$settlement_id<-str_pad(as.character(ad_hoc_settlements$settlement_id),8,"left",pad="0")
ad_hoc_settlements$source <-'geografia a mano colombia.xlsx'

settlements_basic <- mergeDataFrames(settlements_basic,ad_hoc_settlements[,c('settlement_id','settlement_name','latitude','longitude','source')])


##############################################
# IMPORTANT: DON'T RUN THIS CHUNK UNLESS IT'S NECESSARY TO RUN GOOGLE MAPS API AGAIN
##############################################

# ADD EXTRA GEOGREAPHIC INFORMATION

# Filter settlements without coordinates
settlements_basic_google<-settlements_basic[is.na(settlements_basic$latitude) | is.na(settlements_basic$longitude),]

# Get coordinates from the given settlements

country <- "Colombia"

settlements_basic_google$search_string <- gsub(" ","+",paste(tolower(settlements_basic_google$settlement_name), tolower(settlements_basic_google$admin_division_1_name),
tolower(settlements_basic_google$admin_division_2_name), country, sep=", "))

settlements_basic_google$search_string_2 <- gsub(" ","+",paste(tolower(settlements_basic_google$settlement_name), tolower(settlements_basic_google$admin_division_2_name), country, sep=", "))

settlements_basic_google$latitude_google <- NA
settlements_basic_google$latitude_google <- as.numeric(settlements_basic_google$latitude_google)

settlements_basic_google$longitude_google <- NA
settlements_basic_google$longitude_google <- as.numeric(settlements_basic_google$longitude_google)

#Upload settlements without location to DB to make it easier to run the loop in different computers
unlocated_settlements <- uploadGoogleData(schema_dev,table_google,settlements_basic_google)

unlocated_settlements$latitude_google <- NA
unlocated_settlements$longitude_google <- NA

count_limit <- 0
for (i in (1:nrow(unlocated_settlements))) {
  if(count_limit==15) break
  cat("Buscando ",i, " de ",nrow(unlocated_settlements) ,"\n")
  #GOOGLE API
  output_google <- geoCode(unlocated_settlements$search_string_2[i], key_google_api)
  if (output_google[5]=="OVER_QUERY_LIMIT"){ 
    count_limit<-count_limit+1
    cat("OVER_QUERY_LIMIT \n")
    Sys.sleep(0.25) }
  
  unlocated_settlements$latitude_google[i] <- output_google[1]
  unlocated_settlements$longitude_google[i] <- output_google[2]
   
  #Second recursion
  if(is.na(unlocated_settlements$latitude_google[i])){
    output_google <- geoCode(unlocated_settlements$search_string[i], key_google_api)
    if (output_google[5]=="OVER_QUERY_LIMIT"){ 
      count_limit<-count_limit+1
      cat("OVER_QUERY_LIMIT \n")
      Sys.sleep(0.25) }
      unlocated_settlements$latitude_google[i] <- output_google[1]
      unlocated_settlements$longitude_google[i] <- output_google[2]
  }
  
  if(!is.na(unlocated_settlements$latitude_google[i])){
    count_limit<-0
    unlocated_settlements$source[i]<-"Google API"
    updateDBGoogle(schema_dev, table_google, unlocated_settlements$latitude_google[i], unlocated_settlements$longitude_google[i],unlocated_settlements$settlement_id[i])
  }
}

rm(unlocated_settlements)

#Google Maps API has a limit of queries, when we reach that limit the loop stops and we try to locate missing settlemnts with OSM API
unlocated_settlements <- loadOSMAPIData(schema_dev,table_google)

for (i in (1:nrow(unlocated_settlements))) {
  cat("Buscando ",i, " de ",nrow(unlocated_settlements) ,"\n")
  url <-paste(paste(OSM_url_start,gsub(" ","+",unlocated_settlements$search_string[i]), sep=""),OSM_url_end,sep="")

    json_data_frame <- as.data.frame(fromJSON(paste(readLines(url,warn=FALSE), collapse="")))
    if(nrow(json_data_frame)!=0){
      unlocated_settlements$latitude_google[i] <- as.numeric(as.character(json_data_frame$lat[1]))
      unlocated_settlements$longitude_google[i] <- as.numeric(as.character(json_data_frame$lon[1]))
      unlocated_settlements$source[i]<-"OSM API"
      updateDBGoogle(schema_dev, table_google, unlocated_settlements$latitude_google[i], unlocated_settlements$longitude_google[i],unlocated_settlements$settlement_id[i])
    }
    Sys.sleep(1)
}


# Import located settlements by Google and OSM and merge with existing data
settlements_basic_google <- getAllTable(schema_dev, table_google)

settlements_basic_google$longitude <- settlements_basic_google$longitude_google
settlements_basic_google$latitude <- settlements_basic_google$latitude_google

# Merge Google located settlements with previous settlements dataframe
settlements_basic<-mergeDataFrames(settlements_basic,settlements_basic_google[,c('settlement_id','settlement_name','latitude','longitude','source')])

##ADD GEOMETRIES OF DEPARTAMENTS, MUNICIPALITIES AND SETTLEMENTS
folder_shp <- paste(input_path_demography, "SHP MUNICIPIOS", sep = "/")
departament_folders <- list.dirs(folder_shp,recursive = F,full.names = F)

admin_div_1_list<-NULL
admin_div_2_list <- NULL
settlement_list <-NULL

#Loop through the folders and create a list with all the geometries
for(i in 1:length(departament_folders)){
  cat("\r Procesando carpeta ",i, " de ", length(departament_folders))
  shp_municipio <- paste(folder_shp,departament_folders[i],"ADMINISTRATIVO",shp_municipality_name,sep="/")
  shp_departament <- paste(folder_shp,departament_folders[i],"ADMINISTRATIVO",shp_departament_name,sep="/")
  settlement_polygons <- paste(folder_shp,departament_folders[i],"MGN",shp_settlement_name,sep="/")

  admin_div_1_list <- c(admin_div_1_list,readOGR(shp_municipio,verbose = F))
  admin_div_2_list <- c(admin_div_2_list,readOGR(shp_departament,verbose = F))
  settlement_list <- c(settlement_list,readOGR(settlement_polygons,verbose = F))
}

total_admin_div_1<-do.call("rbind", admin_div_1_list)
total_admin_div_2<-do.call("rbind", admin_div_2_list)
total_settlements <-do.call("rbind", settlement_list)

#Extract and rename the information needed
names(total_admin_div_2) <- c('admin_division_2_id',
                               'admin_division_2_name')

total_admin_div_2<-total_admin_div_2[,c('admin_division_2_id',
                                          'admin_division_2_name')]
                               

names(total_admin_div_1) <- c('admin_division_2_id',
                                 'admin_division_1_id',
                                 'admin_division_1_name',
                                 'crslc',
                                 'area',
                                 'nano',
                                 'admin_division_2_name')

total_admin_div_1<-total_admin_div_1[,c('admin_division_2_id',
                                              'admin_division_2_name',
                                              'admin_division_1_id',
                                              'admin_division_1_name')]    

names(total_settlements) <- c('admin_division_2_id',
                              'admin_division_1_id',
                              'clas',
                              'setr',
                              'secr',
                              'settlement_id',
                              'settlement_name')


total_settlements<-total_settlements[,c('admin_division_2_id',
                                              'admin_division_1_id',
                                              'settlement_id',
                                              'settlement_name')]  


uploadDBWithIndex(schema_dev,table_admin_division_1, total_admin_div_1, "co_municipios_gix", "GIST (geom)")
uploadDBWithIndex(schema_dev,table_admin_division_2, total_admin_div_2, "co_departamentos_gix", "GIST (geom)")
uploadDBWithIndex(schema_dev,table_settlements_polygons, total_settlements, "co_settlements_polygons_gix", "GIST (geom)")

##ADD INFORMATION FROM AGROPECUARIUS CENSUS 

file_hab_house <-  paste(input_path_demography, source_hab_house, sep = "/")

hab_house_departament <- read_excel(file_hab_house)

#Upload information to departaments table in database

addColumnDepartments(schema_dev, table_admin_division_2)

hab_house_departament$admin_division_2_id<-str_pad(as.character(hab_house_departament$admin_division_2_id),2,"left",pad="0")
hab_house_departament$hab_house<-as.numeric(hab_house_departament$hab_house)


setHabHouse(schema_dev, table_admin_division_2,hab_house_departament)


## Export to Postgresql and perform  AD-Hoc corrections

# Upload intermediate output to DB 
uploadIntermediateOutput(schema_dev, table_co_settlements, settlements_basic, table_admin_division_1, table_settlements_polygons)


#IMPORT FACEBOOK HOUSEHOLDS

file_households <-  paste(input_path_demography, households_file, sep = "/")

households<- read.csv(file_households)

facebookHouseholds(schema_dev,table_households, households[,c('latitude','longitude')], table_admin_division_2)

setAdminDivision1(admin_div_2_aux, schema_dev, table_households, table_admin_division_1)


facebookHouseholds02(schema_dev, table_households_raw, table_households)

setInsidePolygon(schema_dev,table_settlements_polygons, table_households, admin_div_2_aux)


## Assign closest settlement to households if distance < 3km
for (id in admin_div_2_aux$admin_division_2_id){
  for (idMun in admin_div_1_aux$admin_division_1_id[substr(admin_div_1_aux$admin_division_1_id,1,2)==id]){
    assignClosestSettlement(schema_dev, table_households, table_co_settlements, id, idMun)
    flush.console()
  }
}



## Import FALSE POSITIVE data collected AD-HOC in QGIS for households and admin_division_1
false_positive_households <- read_excel(paste(input_path_demography, file_false_households, sep='/'))

false_positive_households <- as.array(false_positive_households$household_id)

falsePositive(schema_dev, table_households, false_positive_households)

## DBSCAN CLUSTER 960.000 households which are further than the radius of influence established for a settlement (3km) from any settlement in aggregates of at least 15 points and less than 200m of distance between one and another
DBSCANCluster(schema_dev, table_households)

## DELETE households that are not assigned to a settlement or haven't been clustered from municipalities flagged as mainly false positive

false_positive_admin_division_1 <- read_excel(paste(input_path_demography, file_falsos_positivos_municipios, sep='/'))
deleteUnassignedHouseholds(schema_dev, table_households, false_positive_admin_division_1$admin_division_1_id)


#Flag admin_division_1 where there are many false positives.
flagFalsePoisitive(schema_dev, table_admin_division_1, false_positive_admin_division_1$admin_division_1_id)

 
## ADD relevant information about admin_division_1 (norm factor, remove false positives, etc)

population_admin_division_1 <- settlements_raw_5[str_sub(settlements_raw_5$settlement_id,-3,-1)=='000', c('admin_division_1_id', 'capital', 'rest')]

# There are 20 municipalities where the capital population is 0 but there are households. 
admin_division_1_wrong_capital <-population_admin_division_1[population_admin_division_1$capital == 0,'admin_division_1_id']

## ADD columns: population_cabecera and households_cabecera, population_resto and households_resto
addColumns(schema_dev,table_admin_division_1, population_admin_division_1, table_households, table_admin_division_2, admin_division_1_wrong_capital)


## ADD NUMBER OF HOUSEHOLDS TO SETTLEMENTS TABLE
addNumberHousehold(schema_dev, table_co_settlements, table_households)


## COMPLETE settlements table (add clusters, add ZRD and update population_corrected)
completeSettlements(schema_dev, table_co_settlements, table_households, table_admin_division_1, table_admin_division_2)


## CREATE NORMALIZED CLUSTERS
createNormalizedCluster(schema_dev, table_co_settlements, table_households, table_admin_division_1, table_admin_division_2)


createNormalizedZRD(schema_dev, table_co_settlements, table_households, table_admin_division_1, table_admin_division_2)


# Linealize official settlements with number of households lower than 20 
updateHousehold(schema_dev, table_admin_division_1, table_co_settlements, admin_division_1_wrong_capital, table_admin_division_2)


## Fill in missing admin division 3 and population census from settlements_raw_5

# Upload census data to database and then transfer information to settlements table
tempPopCensus <- settlements_raw_5[(settlements_raw_5$population_census != 0) & (substr(settlements_raw_5$settlement_id,6,9)!='000'),c('settlement_id','population_census')]

fillMissingValues(schema_dev, temp_Table_census, tempPopCensus, table_co_settlements, admin_div_3_aux, settlements_basic)



#Modify dbscan clusters' id 
modifyDbscanClusterId(schema_dev, table_co_settlements)
 

#SET Population_corrected to 0 in 4 settlements where population is null. 4 capitals where population_census is 0 and there are no households.
updatePopulationCorrected(schema_dev,table_co_settlements)


#Export dataset to DB
settlements_basic <- getAllTable(schema_dev, table_co_settlements)

settlements_output <- settlements_basic[settlements_basic$settlement_name!="ZONA RURAL DISPERSA",
                                        c("settlement_id",
                                          "settlement_name",
                                          "admin_division_1_id",
                                          "admin_division_1_name",
                                          "admin_division_2_id",
                                          "admin_division_2_name",
                                          "admin_division_3_id",
                                          "admin_division_3_name",
                                          "population_census",
                                          "population_corrected",
                                          "latitude",
                                          "longitude",
                                          "geom")]

settlements_zrd_output <- settlements_basic[settlements_basic$settlement_name=="ZONA RURAL DISPERSA",
                                        c("settlement_id",
                                          "settlement_name",
                                          "admin_division_1_id",
                                          "admin_division_1_name",
                                          "admin_division_2_id",
                                          "admin_division_2_name",
                                          "admin_division_3_id",
                                          "admin_division_3_name",
                                          "population_census",
                                          "population_corrected",
                                          "latitude",
                                          "longitude",
                                          "geom")]

settlements_output<-settlements_output[order(settlements_output$settlement_id),]
settlements_zrd_output<-settlements_zrd_output[order(settlements_zrd_output$settlement_id),]

exportSettlements(schema_dev, table_settlements, table_settlements_zrd, settlements_output, settlements_zrd_output)


## CREATE UNAGGREGATED ZRD TABLE
createUnaggregatedZRD(schema_dev, table_zrd_unaggregated, table_households, table_admin_division_1, table_admin_division_2)


## Correct aggregate population from 2018 census to 45.5M
correctPopulation(schema_dev, table_settlements, table_zrd)


