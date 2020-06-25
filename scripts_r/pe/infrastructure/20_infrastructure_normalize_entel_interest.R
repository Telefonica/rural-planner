
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
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)


#VARIABLES
output_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_name <- "PAM_2019_2020_TdP.xlsx"
sheet <- 2

source('~/shared/rural_planner/sql/pe/infrastructure/exportSitesPAM.R')
source('~/shared/rural_planner/sql/pe/infrastructure/createMatchingPAM.R')
source('~/shared/rural_planner/sql/pe/infrastructure/exportEntel.R')
source('~/shared/rural_planner/sql/pe/infrastructure/deleteTables.R')


file.exists(paste(input_path_infrastructure, file_name, sep = "/"))
pam_raw <- read_excel(paste(input_path_infrastructure, file_name, sep = "/"), sheet = sheet)


#Select useful columns from ka_raw input
pam_int <- data.frame(pam_raw$PAM,
                        pam_raw$'DETALLE DEL PAM',
                        pam_raw$NombreEstacion,
                        pam_raw$Latitud,
                        pam_raw$Longitud,
                        pam_raw$ID_DISTRITO,
                        pam_raw$DISTRITO,
                        pam_raw$DEPARTAMENTO,
                        pam_raw$PROVINCIA,
                        pam_raw$CLUSTER_NAME,
                        pam_raw$'Coberturas IPT',
                        pam_raw$INFRAESTRUCTURA,
                        pam_raw$COUBICACION,
                        pam_raw$'POBLACION A IMPACTAR',
                        pam_raw$VENDOR,
                        pam_raw$CONFIGURACION,
                        stringsAsFactors = FALSE
                       )

#Change names of the variables we already have
colnames(pam_int) <- c("pam",
                         "pam_detail",
                         "tower_name",
                         "latitude",
                         "longitude",
                         "admin_division_1_id",
                         "admin_division_1_name",
                         "admn_division_2_name",
                         "admin_division_3_name",
                         "cluster_name",
                         "ipt_tower",
                         "type",
                         "subtype",
                         "target_population",
                         "vendor",
                         "tech"
                         )



#Delete wrong coordinates
pam_int <- pam_int[!(pam_int$latitude==pam_int$longitude),]

#Set source file
pam_int$source_file <- file_name


exportSitesPAM(schema_dev, table_entel_interest, pam_int)

# Create a table with matching PAM (Priority ENTEL RANSharing sites) sites from sites_pam table(182 sites)
createMatchingPAM(schema_dev, table_entel_interest_match, table_entel_interest)


# Create infrastructure_global_entel_interest table with all the sites (28453) with location _detail: set to ENTEL_INTEREST_{location_detail} if the site is included in the sites_pam_matching table; no modification if not.

exportEntel(schema_dev, table_infrastrcuture_global_entel_interest, table_infrastructure, infra_match_table)

# Drop input and intermediate tables from dev schema
deleteTables(schema_dev, table_entel_interest_match, table_entel_interest, infra_match_table)


