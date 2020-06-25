
#LIBRARIES
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(scales)
library(readxl)
library(xlsx)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_ar'
source(config_path)

#VARIABLES
file_name_1 <-  paste(input_path_demography, "Localidades V3.xlsx", sep = "/")
source('~/shared/rural_planner/sql/ar/demography/exportBasic.R')


#LOAD INPUTS
#Load and collect data that we have

settlements_raw <- read_excel(file_name_1)#, sheet = sheet, skip = skip)

#We select the fields that we will use
fields <- c("ID_LOC",
            "Etapa",
            "Localidad",
            "Departamento",
            "Provincia",
            "Latitud",
            "Longitud",
            "Población",
            "ESC 5KM",
            "Sitio mas cercano",
            "Distancia Km",
            "Plan 2019"
            )
settlements_basic <- settlements_raw[,fields]
settlements_raw <- settlements_raw[,fields]

settlements_basic_ipt <- settlements_raw[settlements_raw$Etapa%in%c("E4","E5"),]
settlements_basic_ipt <- settlements_basic_ipt[is.na(settlements_basic_ipt$`Plan 2019`),]


#Create normalized dataframe

#Define the data that we are going to collect for the basic_settlements dataset:
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
                 "longitude")

#Settlement_id: as integer
settlements_basic$settlement_id <- as.character(settlements_basic$ID_LOC)

#Settlement name: to upper as character
settlements_basic$settlement_name <- toupper(as.character(settlements_basic$Localidad))

#Administrative division one level above basic settlement division (ID) - in Argentina we put the name as ID and it is a repeated column
settlements_basic$admin_division_1_id <- toupper(as.character(settlements_basic$Departamento))

#Administrative division one level above basic settlement division (name) - in Argentina we put the name as ID and it is a repeated column
settlements_basic$admin_division_1_name <- toupper(as.character(settlements_basic$Departamento))


#Administrative division two levels above basic settlement division (ID) - in Argentina we put the name as ID and it is a repeated column
settlements_basic$admin_division_2_id <- toupper(as.character(settlements_basic$Provincia))

#Administrative division two levels above basic settlement division (Name) - in Argentina we put the name as ID and it is a repeated column 
settlements_basic$admin_division_2_name <- toupper(as.character(settlements_basic$Provincia))



#Administrative division three levels above basic settlement division (ID). Does not exist in Argentina
settlements_basic$admin_division_3_id <- NA
settlements_basic$admin_division_3_id <- as.character(settlements_basic$admin_division_3_id)

#Administrative division three levels above basic settlement division
settlements_basic$admin_division_3_name <- NA
settlements_basic$admin_division_3_id <- as.character(settlements_basic$admin_division_3_name)


#Population based on latest census
settlements_basic$population_census <- as.integer(settlements_basic$"Población")

#Corrected population
#Changeable in next process
settlements_basic$population_corrected <- settlements_basic$population_census

#Latitude and longitude
settlements_basic$latitude <- as.numeric(as.character(settlements_basic$Latitud))
settlements_basic$longitude <- as.numeric(as.character(settlements_basic$Longitud))

#Set population corrected to 0 where no information available

settlements_basic$population_corrected[is.na(settlements_basic$population_corrected)] <- 0
settlements_basic$population_census[is.na(settlements_basic$population_census)] <- 0

#Keep only the data we updated
settlements_basic <- settlements_basic[,basic_names]

##AD-HOC: Add settlement_ids manually
settlements_basic$settlement_id[settlements_basic$settlement_name=="D'ORBIGNY"] <- 'BA00269'
settlements_basic$settlement_id[(settlements_basic$settlement_name=="ZONA AEROPUERTO INTERNACIONAL EZEIZA")] <- 'BA00307'
settlements_basic$settlement_id[(settlements_basic$settlement_name=="VILLA LIBERTAD (MUNICIPIO LEANDRO N. ALEM)")] <- 'MI03336'
settlements_basic$settlement_id[grepl("DIAGONAL NORTE",settlements_basic$settlement_name)] <- 'TU04990'


##AD-HOC: Add coordinates manually
settlements_basic$latitude[settlements_basic$settlement_id=="LBA1156"] <- -34.4330506
settlements_basic$longitude[settlements_basic$settlement_id=="LBA1156"] <- -58.7863135
settlements_basic$latitude[settlements_basic$settlement_id=="LBA1199"] <- -34.4211840676985
settlements_basic$longitude[settlements_basic$settlement_id=="LBA1199"] <- -58.7708347345652

## Filter by settlement_id only
settlements_basic <- settlements_basic[!is.na(settlements_basic$settlement_id),]




####### SETTLEMENTS IPT #######
## Remove settlements outside universe considered (only stages 4 and 5 not in plan 2019)
#Create normalized dataframe
#Define the data that we are going to collect for the basic_settlements dataset:
basic_names_ipt <- c("settlement_id", 
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
                 "longitude")

#Settlement_id: as integer
settlements_basic_ipt$settlement_id <- as.character(settlements_basic_ipt$ID_LOC)

#Settlement name: to upper as character
settlements_basic_ipt$settlement_name <- toupper(as.character(settlements_basic_ipt$Localidad))

#Administrative division one level above basic settlement division (ID) - in Argentina we put the name as ID and it is a repeated column
settlements_basic_ipt$admin_division_1_id <- toupper(as.character(settlements_basic_ipt$Departamento))

#Administrative division one level above basic settlement division (name) - in Argentina we put the name as ID and it is a repeated column
settlements_basic_ipt$admin_division_1_name <- toupper(as.character(settlements_basic_ipt$Departamento))


#Administrative division two levels above basic settlement division (ID) - in Argentina we put the name as ID and it is a repeated column
settlements_basic_ipt$admin_division_2_id <- toupper(as.character(settlements_basic_ipt$Provincia))

#Administrative division two levels above basic settlement division (Name) - in Argentina we put the name as ID and it is a repeated column 
settlements_basic_ipt$admin_division_2_name <- toupper(as.character(settlements_basic_ipt$Provincia))


#Administrative division three levels above basic settlement division (ID). Does not exist in Argentina
settlements_basic_ipt$admin_division_3_id <- NA
settlements_basic_ipt$admin_division_3_id <- as.character(settlements_basic_ipt$admin_division_3_id)

#Administrative division three levels above basic settlement division
settlements_basic_ipt$admin_division_3_name <- NA
settlements_basic_ipt$admin_division_3_id <- as.character(settlements_basic_ipt$admin_division_3_name)


#Population based on latest census
settlements_basic_ipt$population_census <- as.integer(settlements_basic_ipt$"Población")

#Corrected population
#Changeable in next process
settlements_basic_ipt$population_corrected <- settlements_basic_ipt$population_census

#Latitude and longitude
settlements_basic_ipt$latitude <- as.numeric(as.character(settlements_basic_ipt$Latitud))
settlements_basic_ipt$longitude <- as.numeric(as.character(settlements_basic_ipt$Longitud))

#Set population corrected to 0 where no information available

settlements_basic_ipt$population_corrected[is.na(settlements_basic_ipt$population_corrected)] <- 0
settlements_basic_ipt$population_census[is.na(settlements_basic_ipt$population_census)] <- 0

#Keep only the data we updated
settlements_basic_ipt <- settlements_basic_ipt[,basic_names_ipt]




####### SETTLEMENTS IPT ANALYSIS ########
settlements_analysis <- settlements_raw[settlements_raw$Etapa%in%c("E4","E5"),]
settlements_analysis <- settlements_analysis[is.na(settlements_analysis$`Plan 2019`),]

names(settlements_analysis) <- c("settlement_id",
                                 "stage",
                                 "settlement_name",
                                 "admin_division_1_name",
                                 "admin_division_2_name",
                                 "latitude",
                                 "longitude",
                                 "population",
                                 "scenario_5km",
                                 "closest_site",
                                 "dist_site_km",
                                 "plan_2019"
                                 )

settlements_analysis$latitude <- as.numeric(as.character(settlements_analysis$latitude))
settlements_analysis$longitude <- as.numeric(as.character(settlements_analysis$longitude))

settlements_analysis$settlement_name <- toupper(settlements_analysis$settlement_name)
settlements_analysis$admin_division_1_name <- toupper(settlements_analysis$admin_division_1_name)
settlements_analysis$admin_division_2_name <- toupper(settlements_analysis$admin_division_2_name)

settlements_analysis$coverage_2g <- grepl("2G", settlements_analysis$scenario_5km)
settlements_analysis$coverage_3g <- grepl("3G", settlements_analysis$scenario_5km)
settlements_analysis$coverage_4g <- grepl("4G", settlements_analysis$scenario_5km)

settlements_analysis$dist_site_km[settlements_analysis$dist_site_km=="Sin Sitio"] <- NA
settlements_analysis$dist_site_km <- as.numeric(settlements_analysis$dist_site_km)

settlements_analysis$closest_site[settlements_analysis$closest_site=="Sin Sitio"] <- NA
settlements_analysis$closest_site[settlements_analysis$dist_site_km>5] <- NA

settlements_analysis$dist_site_km[settlements_analysis$dist_site_km>5] <- NA

settlements_analysis <- settlements_analysis[,c("settlement_id",
                                                "settlement_name",
                                                "admin_division_1_name",
                                                "admin_division_2_name",
                                                "population",
                                                "closest_site",
                                                "dist_site_km",
                                                "coverage_2g",
                                                "coverage_3g",
                                                "coverage_4g",
                                                "latitude",
                                                "longitude" )]


#EXPORT

#Export dataset to DB
exportBasic(schema_dev, table_settlements, settlements_basic)

#settlements_ipt
exportBasic(schema_dev, table_settlements_ipt, settlements_basic_ipt)

#Settlement ipt analysis

exportBasic(schema_dev, table_analysis_ipt, settlements_analysis)


