
#title: "Rural Planner Brasil settlements_basic"
#author: "Internet para Todos"
#date: "20 de noviembre de 2017"
#output: html_document

### Load libraries ###
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(XLConnect)
library(XLConnectJars)
library(foreign)
library(rgdal)
library(xlsx)

### DB Connection parameters and brasil global variables ###
config_path <- '~/shared/rural_planner_r/config_files/config_br'
source(config_path)


### variables ###

# SOURCE census: ftp://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_do_Universo/Agregados_por_Setores_Censitarios/

# SOURCE shapefile: ftp://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_de_setores_censitarios__divisoes_intramunicipais/censo_2010/setores_censitarios_shp/

# Download municiaplities shapes from ftp://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2018/Brasil/BR/ and upload to db

file_name_es <- "Basico_ES.xls"
file_name_to <- "Basico_TO.XLS"
file_name_municipalities <- '08.2019_RAIO-X_MÓVEL.xlsx'

#Auxiliary functions 
source('~/shared/rural_planner_r/sql/br/demography/readData.R')
source('~/shared/rural_planner_r/sql/br/demography/update_settlements_dev.R')
source('~/shared/rural_planner_r/sql/br/demography/missingMunicipalities_PopulationCorrected.R')
source('~/shared/rural_planner_r/sql/br/demography/separateZRD_Settlements.R')


### Load inputs ###
#Read population CSVs (divided by region); TOCANTINS REGION with another format (XLS) and 2000 census data and ESPIRITO SANTO with another format (XLS)
file_names <- list.files(input_path_demography,pattern=".csv")
csv_path <- paste(input_path_demography, file_names, sep='/')

#Read all files and join them
settlements_all_raw <- do.call("rbind",lapply(csv_path[1:25], read.csv, sep=";", stringsAsFactors = F,  fileEncoding = 'latin1'))

settlements_all_raw <- rbind(settlements_all_raw[,c(1:33)],read.csv(csv_path[26],sep=";",col.names = names(settlements_all_raw)[c(1:33)], stringsAsFactors = F),read_excel(paste(input_path_demography, file_name_es, sep='/'),col_names=names(settlements_all_raw)[c(1:33)], skip=1)[,c(1:33)])

settlements_to <- read_excel(paste(input_path_demography, file_name_to, sep='/'))


settlements_int <- subset(settlements_all_raw, select= c(Cod_setor, Cod_UF, Nome_da_UF, Cod_municipio, Nome_do_municipio, Cod_distrito, Nome_do_distrito, V002))

names(settlements_int) <- c("settlement_id",
                            "admin_division_3_id",
                            "admin_division_3_name",
                            "admin_division_2_id",
                            "admin_division_2_name",
                            "admin_division_1_id",
                            "admin_division_1_name",
                            "population_census")

settlements_to_int <- subset(settlements_to, select= c(Cod_setor, Cod_UF, Nome_da_UF, Cod_municipio, Nome_do_municipio, Cod_distrito, Nome_do_distrito, Var12))

names(settlements_to_int) <- c("settlement_id",
                               "admin_division_3_id",
                               "admin_division_3_name",
                               "admin_division_2_id",
                               "admin_division_2_name",
                               "admin_division_1_id",
                               "admin_division_1_name",
                               "population_census")

settlements_int <- rbind(settlements_int, settlements_to_int)

#Load census latitude and longitude data and load .dat file to DEV DB through QGIS
settlements_geolocated <- readData(schema, table_census)

#Read municipality population corrections (2017)
municipality_pop <- read_excel(paste(input_path_demography, file_name_municipalities, sep ='/'), sheet = 'Raio-X_Móvel', skip = 5)

municipality_pop <- municipality_pop[,c(1,12,13)]
names(municipality_pop) <- c("admin_division_2_id",
                             "population_census",
                             "population_corrected")

admin_division_3_names <- settlements_int[!duplicated(settlements_int$admin_division_3_id),c("admin_division_3_id","admin_division_3_name")]
admin_division_3_names[admin_division_3_names$admin_division_3_id=="SP","admin_division_3_id"] <- '35'
admin_division_3_names[admin_division_3_names$admin_division_3_id=="ES","admin_division_3_id"] <- '32'


admin_division_3_names <- admin_division_3_names[!duplicated(admin_division_3_names$admin_division_3_id),c("admin_division_3_id","admin_division_3_name")]


### Select useful columns from raw input and normalize all columns ###
settlements_int$settlement_id <- as.character(settlements_int$settlement_id)

settlements_geolocated$settlement_id <- as.character(settlements_geolocated$settlement_id)

##

settlements_int$settlement_name <- as.character(settlements_int$settlement_id)
settlements_geolocated$settlement_name <- as.character(settlements_geolocated$settlement_id)

##

settlements_int$admin_division_1_id <- as.character(settlements_int$admin_division_1_id)
settlements_geolocated$admin_division_1_id <- as.character(settlements_geolocated$admin_division_1_id)


##

settlements_int$admin_division_1_name <- as.character(settlements_int$admin_division_1_name)
settlements_geolocated$admin_division_1_name <- as.character(settlements_geolocated$admin_division_1_name)

##

settlements_int$admin_division_2_id <- as.character(settlements_int$admin_division_2_id)
settlements_geolocated$admin_division_2_id <- as.character(settlements_geolocated$admin_division_2_id)

municipality_pop$admin_division_2_id <- as.character(municipality_pop$admin_division_2_id)

##

settlements_int$admin_division_2_name <- as.character(settlements_int$admin_division_2_name)
settlements_geolocated$admin_division_2_name <- as.character(settlements_geolocated$admin_division_2_name)

##

settlements_int$admin_division_3_id <- as.character(settlements_int$admin_division_3_id)
settlements_geolocated$admin_division_3_id <- as.character(settlements_geolocated$admin_division_3_id)


settlements_int[settlements_int$admin_division_3_id=="SP","admin_division_3_id"] <- '35'
settlements_int[settlements_int$admin_division_3_id=="ES","admin_division_3_id"] <- '32'

##

settlements_int$admin_division_3_name <- as.character(settlements_int$admin_division_3_name)

settlements_geolocated$admin_division_3_name <- as.character(NA)


settlements_int <- within(settlements_int,admin_division_3_name[admin_division_3_id =='35']<-
                            admin_division_3_names[match(admin_division_3_id[admin_division_3_id =='35'],admin_division_3_names$admin_division_3_id),'admin_division_3_name'] )

settlements_geolocated <- within(settlements_geolocated,admin_division_3_name[is.na(admin_division_3_name)] <-
                                   admin_division_3_names[match(admin_division_3_id[is.na(admin_division_3_name)],admin_division_3_names$admin_division_3_id),'admin_division_3_name'] )


##

settlements_int$population_census <- as.numeric(gsub(",",".",settlements_int$population_census))
municipality_pop$population_census <- as.numeric(municipality_pop$population_census)

# Population correction done afterwards
settlements_int$population_corrected <- as.numeric(NA)
municipality_pop$population_corrected <- as.numeric(municipality_pop$population_corrected)

##

settlements_geolocated$latitude <- as.numeric(settlements_geolocated$latitude)

settlements_geolocated$longitude <- as.numeric(settlements_geolocated$longitude)



### Merge with latitudes and longitudes ###
settlements <- merge(settlements_int, settlements_geolocated, by.x="settlement_id", by.y="settlement_id", all.y=TRUE)

settlements$settlement_name <- ifelse(is.na(settlements$settlement_name.x), settlements$settlement_name.y, settlements$settlement_name.x)

settlements$admin_division_1_id <- ifelse(is.na(settlements$admin_division_1_id.x), settlements$admin_division_1_id.y, settlements$admin_division_1_id.x)
settlements$admin_division_1_name <- ifelse(is.na(settlements$admin_division_1_name.x), settlements$admin_division_1_name.y, settlements$admin_division_1_name.x)

settlements$admin_division_2_id <- ifelse(is.na(settlements$admin_division_2_id.x), settlements$admin_division_2_id.y, settlements$admin_division_2_id.x)
settlements$admin_division_2_name <- ifelse(is.na(settlements$admin_division_2_name.x), settlements$admin_division_2_name.y, settlements$admin_division_2_name.x)

settlements$admin_division_3_id <- ifelse(is.na(settlements$admin_division_3_id.x), settlements$admin_division_3_id.y, settlements$admin_division_3_id.x)
settlements$admin_division_3_name <- ifelse(is.na(settlements$admin_division_3_name.x), settlements$admin_division_3_name.y, settlements$admin_division_3_name.x)



### Create final dataframe ###

settlements <- settlements[,c("settlement_id",
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
                              "longitude")]


### export ###
updateSettlementsDev(settlements, schema_dev, table_settlements_dev)

missingMunicipalities_PopulationCorrected(schema, schema_dev, table_settlements_dev, table_municipality, table_population, table_facebook_polygons, table_municipality_correction, municipality_pop)

separateZRD_Settlements(schema, schema_dev, table_zrd, table_settlements_dev, table_settlements)





