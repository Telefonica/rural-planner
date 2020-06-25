
#LIBRARIES
library(RPostgreSQL)
library(dplyr)
library(stringr)
library(readxl)
library(data.table)
library(gdata)


#CONFIG
config_path <- '~/shared/rural_planner_r/config_files/config_ec'
source(config_path)

#VARIABLES
file_name <- "Base procesada ESTRUCTURAS corte Junio 2019 Proyección Diciembre 2019 Final 03_07_2019.xlsx"


table_franchises_map <- 'temp_franchises_map_aux'
table_cluster_franchise <- 'cluster_franchise_map_aux'
table_settlements <- 'settlements'
table_infrastructure <- 'infrastructure_global_aux'
table_cantones <- 'ec_cantones_shp'

source('~/shared/rural_planner_r/sql/ec/infrastructure/uploadFranchisesMap.R')


### SOURCE shapefile (YEAR 2012): https://www.ecuadorencifras.gob.ec/clasificador-geografico-estadistico-dpa/ 

# Read population CSVs (divided by region); TOCANTINS REGION with another format (XLS) and 2000 census data and ESPIRITO SANTO with another format (XLS)

franchises_raw <- read_excel(paste(input_path_infrastructure, file_name, sep='/'), skip=6)

franchises_int <- data.frame(franchises_raw$ASIGNACION,
                             franchises_raw$provincia,
                             franchises_raw$canton,
                             franchises_raw$parroquia,
                             franchises_raw$ciudad,
                             franchises_raw$LATITUD,
                             franchises_raw$LONGITUD, stringsAsFactors = F)

names(franchises_int) <- c("franchise",
                            "admin_division_2_name",
                            "admin_division_1_name",
                            "settlement_name",
                            "city_name",
                            "latitude",
                            "longitude")

franchises_map <- franchises_int %>% arrange(franchise) %>% distinct(admin_division_1_name, .keep_all=T) %>% dplyr::select(franchise, admin_division_1_name)

franchises_map$admin_division_1_name <- as.character(franchises_map$admin_division_1_name)

##AD-HOC : correct limit divisions that are marked as franchises (AND ARE ACTUALLY FROM TELEFONICA)
franchises_map$franchise[franchises_map$admin_division_1_name%in%c('PUERTO LOPEZ','MOCACHE','MONTECRISTI','24 DE MAYO')] <- 'TELEFONICA'


##AD-HOC : correct new divisions that have been given to franchise_2
franchises_map$franchise[franchises_map$admin_division_1_name%in%c('SANTO DOMINGO','SAN MIGUEL DE LOS BANCOS','PEDRO VICENTE MALDONADO','PUERTO QUITO')] <- 'FRANQUICIADO_2'

## Ad hoc admin_division_1_name corrections
franchises_map$admin_division_1_name[franchises_map$admin_division_1_name=="URBINA JADO"] <- "SALITRE"
franchises_map$admin_division_1_name[franchises_map$admin_division_1_name=="GENERAL ANTONIO ELIZALDE"] <- "GNRAL. ANTONIO ELIZALDE"
franchises_map$admin_division_1_name[franchises_map$admin_division_1_name=="CORONEL MARCELINO MARIDUEÑA"] <- "CRNEL. MARCELINO MARIDUEÑA"
franchises_map$admin_division_1_name[franchises_map$admin_division_1_name=="LIMON-INDANZA"] <- "LIMON INDANZA"
franchises_map$admin_division_1_name[franchises_map$admin_division_1_name=="NOBOL (VICENTE PIEDRAHITA)"] <- "NOBOL"
franchises_map$admin_division_1_name[franchises_map$admin_division_1_name=="PLAYAS (GENERAL VILLAMIL)"] <- "PLAYAS"
franchises_map$admin_division_1_name[franchises_map$admin_division_1_name=="YAGUACHI"] <- "SAN JACINTO DE YAGUACHI"
franchises_map$admin_division_1_name[franchises_map$admin_division_1_name=="YANZATZA"] <- "YANTZAZA"
franchises_map$admin_division_1_name[franchises_map$admin_division_1_name=="LOGROÑO"] <- "LOGROÐO"
franchises_map$admin_division_1_name[franchises_map$admin_division_1_name=="RUMIÑAHUI"] <- "QUITO"



## Read raw data from DEV DB
uploadFranchisesMap(schema_dev, table_franchises_map, franchises_map, table_cluster_franchise, table_infrastructure, table_cantones, table_settlements)

