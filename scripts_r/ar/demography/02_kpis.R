
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(XLConnect)
library(XLConnectJars)
library(xlsx)
library(dplyr)


#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_ar'
source(config_path)

#VARIABLES

file_name_1 <- "Localidades + Prospect Aliados.xlsx"
file_name_2 <- "Localidades V3.xlsx"
file_name_3 <- "Base_Prueba_Piloto.xlsx"
file_clientes <- "Localidades + Clientes FM.xlsx"

source('~/shared/rural_planner/sql/ar/demography/listSettlements.R')
source('~/shared/rural_planner/sql/ar/demography/exportKpis.R')
source('~/shared/rural_planner/sql/ar/demography/exportClientes.R')
source('~/shared/rural_planner/sql/ar/demography/updateDBPartners.R')
source('~/shared/rural_planner/sql/ar/demography/exportPartners.R')
source('~/shared/rural_planner/sql/ar/demography/exportCategorization.R')

#LOAD INPUTS
etapa_raw <- read_excel(paste(input_path_demography, file_name_1, sep='/'))
etapa_raw <- read_excel(paste(input_path_demography, file_name_2, sep='/'))
categorization_raw <- read_excel(paste(input_path_demography, file_name_3, sep='/'))

#clientes
clientes_raw <- read_excel(paste(input_path_demography, file_clientes, sep='/'))

#partners
alianzas_raw <- read_excel(paste(input_path_demography, file_name_1, sep='/'))

#categorization
categorization_source <- read_excel(paste(input_path_demography,  file_name_3, sep = "/"), sheet = "Base Prueba Piloto")

# Select and rename relevant data columns
categorization_source <- categorization_source[,c(1:4,7:9,14,20)]
names(categorization_source) <- c("settlement_id","admin_div_2_name", "admin_div_1_name", "settlement_name", "a_zone", "cable", "clarin_cable","category_b_prospect","ran_sharing")

# Import the complete settlements list from the database
settlements_categorization <- listSettlements(schema_dev, table_settlements)



######################################################################################################################

#Select useful columns from raw input

etapa_int <- data.frame(etapa_raw$ID_LOC,
                           etapa_raw$Provincia,
                           etapa_raw$Departamento,
                           etapa_raw$Localidad,
                           etapa_raw$Latitud,
                           etapa_raw$Longitud,
                          etapa_raw$Region,
                          etapa_raw$`Zona de Exclusividad`,
                          etapa_raw$Etapa,
                           etapa_raw$`Plan 2019`,
                           stringsAsFactors = F)


#Change names of the variables we already have
colnames(etapa_int) <- c("settlement_id",
                       "admin_division_2_id",
                       "admin_division_1_id",
                       "settlement_name",
                       "latitude",
                       "longitude",
                       "region",
                       "exclusivity_zone",
                       "stage",
                       "plan_2019")



######################################################################################################################

#Settlement id: Already done

#Latitude: as numeric
etapa_int$latitude <- as.numeric(etapa_int$latitude)

#Longitude: as numeric
etapa_int$longitude <- as.numeric(etapa_int$longitude)

#Settlement_name: to upper case
etapa_int$settlement_name <- toupper(etapa_int$settlement_name)

##AD-HOC: Add settlement_ids manually
etapa_int$settlement_id[etapa_int$settlement_name=="D'ORBIGNY"] <- 'BA00269'
etapa_int$settlement_id[(etapa_int$settlement_name=="ZONA AEROPUERTO INTERNACIONAL EZEIZA")] <- 'BA00307'
etapa_int$settlement_id[(etapa_int$settlement_name=="VILLA LIBERTAD (MUNICIPIO LEANDRO N. ALEM)")] <- 'MI03336'
etapa_int$settlement_id[grepl("DIAGONAL NORTE",etapa_int$settlement_name)] <- 'TU04990'



#Admin_division_1_id: to upper case
etapa_int$admin_division_1_id <- toupper(etapa_int$admin_division_1_id)

#Admin_division_2_id: to upper case
etapa_int$admin_division_2_id <- toupper(etapa_int$admin_division_2_id)

etapa_int$region <- as.character(etapa_int$region)

etapa_int$exclusivity_zone[grepl("SI", etapa_int$exclusivity_zone)] <- TRUE
etapa_int$exclusivity_zone[grepl("NO", etapa_int$exclusivity_zone)] <- FALSE
etapa_int$exclusivity_zone[is.na(etapa_int$exclusivity_zone)] <- FALSE
etapa_int$exclusivity_zone <- as.logical(etapa_int$exclusivity_zone)

etapa_int$plan_2019[grepl("SI", etapa_int$plan_2019)] <- TRUE
etapa_int$plan_2019[grepl("plan 2019", etapa_int$plan_2019)] <- TRUE
etapa_int$plan_2019[is.na(etapa_int$plan_2019)] <- FALSE
etapa_int$plan_2019 <- as.logical(etapa_int$plan_2019)

etapa_int$stage <- as.character(etapa_int$stage)
etapa_int$stage[grepl("NA", etapa_int$stage)] <- NA


## Filter by settlement_id only
etapa_int <- etapa_int[!is.na(etapa_int$settlement_id),]

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
etapa <- etapa_int[,c("settlement_id",
                       "admin_division_2_id",
                       "admin_division_1_id",
                       "settlement_name",
                       "latitude",
                       "longitude",
                       "region",
                       "exclusivity_zone",
                       "stage",
                       "plan_2019")]


######################################################################################################################



###### CLIENTES ######

#Select useful columns from raw input
clientes_int <- data.frame(clientes_raw$Id_localidad,
                           clientes_raw$Provincia,
                           clientes_raw$Departamento,
                           clientes_raw$Localidad,
                           clientes_raw$Lat_IpT,
                           clientes_raw$Lon_IpT,
                           clientes_raw$q_cli_pospagos,
                           clientes_raw$q_anis_stb_b2c,
                           clientes_raw$q_anis_stb_b2b,
                           clientes_raw$q_anis_ba_xDSL_b2b,
                           clientes_raw$q_anis_ba_xDSL_b2c,
                           clientes_raw$q_uips,
                           stringsAsFactors = F)


#Change names of the variables we already have
colnames(clientes_int) <- c("settlement_id",
                       "admin_division_2_name",
                       "admin_division_1_name",
                       "settlement_name",
                       "latitude",
                       "longitude",
                       "q_cli_pospagos",
                       "q_anis_stb_b2c",
                       "q_anis_stb_b2b",
                       "q_anis_ba_xDSL_b2b",
                       "q_anis_ba_xDSL_b2c",
                       "q_uips")



######################################################################################################################

#Settlement id
clientes_int$settlement_id <- as.character(clientes_int$settlement_id)

#Latitude: as numeric
clientes_int$latitude <- as.numeric(clientes_int$latitude)

#Longitude: as numeric
clientes_int$longitude <- as.numeric(clientes_int$longitude)

#Settlement_name: to upper case
clientes_int$settlement_name <- toupper(clientes_int$settlement_name)

#Admin_division_1_id: to upper case
clientes_int$admin_division_1_name <- toupper(clientes_int$admin_division_1_name)

#Admin_division_2_id: to upper case
clientes_int$admin_division_2_name <- toupper(clientes_int$admin_division_2_name)





######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
clientes <- clientes_int[,c("settlement_id",
                       "admin_division_2_name",
                       "admin_division_1_name",
                       "settlement_name",
                       "latitude",
                       "longitude",
                       "q_cli_pospagos",
                       "q_anis_stb_b2c",
                       "q_anis_stb_b2b",
                       "q_anis_ba_xDSL_b2b",
                       "q_anis_ba_xDSL_b2c",
                       "q_uips")]


###### PARTNERS #######

######################################################################################################################

#Select useful columns from raw input
alianzas_int <- data.frame(alianzas_raw$Id_localidad,
                           alianzas_raw$Provincia,
                           alianzas_raw$Departamento,
                           alianzas_raw$Localidad,
                           alianzas_raw$Lat_IpT,
                           alianzas_raw$Lon_IpT,
                           alianzas_raw$`Población 2017 est`,
                           alianzas_raw$Aliado,
                           alianzas_raw$`Presencia Aliado`,
                           alianzas_raw$`Presencia Grupo Clarín`,
                           stringsAsFactors = F)


#Change names of the variables we already have
colnames(alianzas_int) <- c("settlement_id",
                       "admin_division_2_id",
                       "admin_division_1_id",
                       "settlement_name",
                       "latitude",
                       "longitude",
                       "population_corrected",
                       "partners",
                       "aliado",
                       "presencia_clarin")



######################################################################################################################

#Latitude: as numeric
alianzas_int$latitude <- as.numeric(alianzas_int$latitude)

#Longitude: as numeric
alianzas_int$longitude <- as.numeric(alianzas_int$longitude)

#Settlement_name: to upper case
alianzas_int$settlement_name <- toupper(alianzas_int$settlement_name)

#Admin_division_1_id: to upper case
alianzas_int$admin_division_1_id <- toupper(alianzas_int$admin_division_1_id)

#Admin_division_2_id: to upper case
alianzas_int$admin_division_2_id <- toupper(alianzas_int$admin_division_2_id)

#Population to numeric
alianzas_int$population_corrected <- floor(as.numeric(alianzas_int$population_corrected))

#aliado as boolean
alianzas_int$aliado <- as.logical(alianzas_int$aliado)

#Grupo Clarin as boolean
alianzas_int$presencia_clarin <- as.logical(alianzas_int$presencia_clarin)


######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
alianzas <- alianzas_int[,c("settlement_id",
                       "admin_division_2_id",
                       "admin_division_1_id",
                       "settlement_name",
                       "latitude",
                       "longitude",
                       "partners",
                       "aliado",
                       "presencia_clarin")]

###### CATEGORIZATION #######

######################################################################################################################

# Create a normalized dataframe with the relevant data

# The normalized structure is composed by te following columns:
### settlement_id
### cable: cable companies present or possible partners (where there is no info on any cable company, the field will indicate NO DATA)
### 3 possible categories : 
#####   ZONE A (less or equal to 3000 inhabitants or without any information on cable companies) 
#####   ZONE B (without any information on cable companies)
#####   PROSPECT (information available on cable companies)
### ran_sharing : 3 possible categories: NO COVERAGE (any coverage from Movistar or Claro identified); NO RAN SHARING and CLARO ONLY (only Claro coverage available)

##########################################################################################
##########################################################################################


# SETTLEMENTS
# Perform a left join of the complete settlements list with the input data
categorization_raw <- merge(settlements_categorization[,c("settlement_id","settlement_name", "settlement_id_numeric")], categorization_source, 
                            by.x = "settlement_id_numeric",
                            by.y = "settlement_id"
                            , all.x=TRUE)
#Column with numeric settlement_id added to match dataframes. After joined its removed.
categorization_raw$settlement_id_numeric <- NULL

categorization <- data.frame(categorization_raw)

# CABLE
categorization$cable[categorization$clarin_cable==1] <- 'Grupo Clarín'
categorization$cable[categorization$cable=='Sin dato cablera'] <- 'NO DATA'
categorization$cable[is.na(categorization$cable)] <- 'NO DATA'

# CATEGORY
#zone_a
categorization$zone_a <- FALSE
categorization$zone_a[categorization$a_zone==1] <- TRUE

#zone_b
categorization$zone_b <- FALSE
categorization$zone_b[categorization$category_b_prospect=='ZONA B'] <- TRUE

#prospect
categorization$prospect <- FALSE
categorization$prospect[categorization$category_b_prospect=='PROSPECT'] <- TRUE

# RAN SHARING
categorization$ran_sharing[categorization$ran_sharing=='sin cobertura'] <- 'NO COVERAGE'
categorization$ran_sharing[categorization$ran_sharing=='sin ran sharing'] <- 'NO RAN SHARING'
categorization$ran_sharing[categorization$ran_sharing=='CLR'] <- 'CLARO ONLY'

# Select desired columns for output dataframe
categorization <- categorization[,c("settlement_id","cable","zone_a","zone_b","prospect","ran_sharing")]

#EXPORT TO DB
#kpis
exportKpis(schema_dev, table_kpis, etapa)

#clientes
exportClientes(schema_dev, table_clientes, clientes)

#partners
updateDBPartners(schema_dev, table_alianzas, alianzas)
exportPartners(schema_dev, table_partners, table_settlements, table_alianzas)

#categorization
exportCategorization(schema_dev, table_categorization, categorization)


