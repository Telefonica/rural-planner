
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(rgdal)
library(gdalUtils)
library(postGIStools)
library(maptools)
library(raster)

#CONFIG
config_path <- '~/shared/rural_planner_r/config_files/config_pe'
source(config_path)

#VARIABLES
output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name <- "sites_ka_migration_may2019.xlsx"
file_name2 <- "sites IpT migrar Ka 3Q.xlsx"

source('~/shared/rural_planner_r/sql/pe/infrastructure/exportKaMigration.R')
source('~/shared/rural_planner_r/sql/pe/infrastructure/matchingSites.R')
source('~/shared/rural_planner_r/sql/pe/infrastructure/createTableKaMigrationInfrastructure.R')
source('~/shared/rural_planner_r/sql/pe/infrastructure/deleteTablesKaMigration.R')


file.exists(paste(input_path_infrastructure, file_name, sep = "/"))
ka_raw <- read_excel(paste(input_path_infrastructure, file_name, sep = "/"))


file.exists(paste(input_path_infrastructure, file_name, sep = "/"))
ka_tdp_raw <- read_excel(paste(input_path_infrastructure, file_name2, sep = "/"))


#Select useful columns from ka_raw input
ka_int <- data.frame(ka_raw$Estacion,
                     ka_raw$ID,
                     ka_raw$Tipo,
                     ka_raw$Proyecto,
                     ka_raw$CU,
                     ka_raw$Ubigeo,
                     ka_raw$Localidad,
                     ka_raw$Latitud,
                     ka_raw$Longitud,
                     ka_raw$'Tecnología',
                     ka_raw$banda,
                     ka_raw$Flag_migr,
                     ka_raw$'AÑO DE MIGRACION',
                     ka_raw$IpT,
                     stringsAsFactors = FALSE
                     )

#Change names of the variables we already have
colnames(ka_int) <- c("tower_name",
                      "tower_id",
                      "type",
                      "subtype",
                      "internal_id",
                      "ubigeo",
                      "location_detail",
                      "latitude",
                      "longitude",
                      "tech",
                      "band",
                      "migration_flag",
                      "anio_migracion",
                      "ipt_perimeter"
                      )
#SITES TDP
#Select useful columns from ka_tdp_raw input
ka_tdp_int <- data.frame(ka_tdp_raw$'Estación',
                     ka_tdp_raw$ID,
                     ka_tdp_raw$Tipo,
                     ka_tdp_raw$Proyecto,
                     ka_tdp_raw$CU,
                     ka_tdp_raw$Ubigeo,
                     ka_tdp_raw$Localidad,
                     ka_tdp_raw$Latitud,
                     ka_tdp_raw$Longitud,
                     ka_tdp_raw$'Tecnología',
                     ka_tdp_raw$banda,
                     ka_tdp_raw$Operador,
                     stringsAsFactors = FALSE
                     )

#Change names of the variables we already have
colnames(ka_tdp_int) <- c("tower_name",
                      "tower_id",
                      "type",
                      "subtype",
                      "internal_id",
                      "ubigeo",
                      "location_detail",
                      "latitude",
                      "longitude",
                      "tech",
                      "band",
                      "owner"
                      )

#Sites ka migration
#Delete wrong coordinates
ka_int <- ka_int[!(ka_int$latitude==ka_int$longitude),]

#Set source file
ka_int$source_file <- file_name

#IpT perimeter
ka_int$ipt_perimeter <- toupper(ka_int$ipt_perimeter)


#Sites migration TdP

#Set source file
ka_int$source_file <- file_name2


#Normalize the structure of the data and create tables
exportKaMigration(schema_dev, table_sites_ka_migration, ka_int, table_3q_dev, ka_tdp_int)

# Create a table with matching ka migration sites from ka_migration table (7800 sites)
matchingSites(schema_dev, sites_ka_matching_table, table_infrastructure, table_sites_ka_migration)

# Create infrastructure_global_ka_migration table with all the sites and a new text column migration_tag: set to KA_MIGRATION_{flag} if the site is included in the ka_migration_matching table; NULL if not.
createTableKaMigrationInfrastructure(schema_dev, table_infrastructure_global_ka_mi, table_infrastructure, sites_ka_matching_table)


# Drop input and intermediate tables from dev schema
deleteTablesKaMigration(schema_dev, sites_ka_matching_table, table_sites_ka_migration, table_3q_dev)


