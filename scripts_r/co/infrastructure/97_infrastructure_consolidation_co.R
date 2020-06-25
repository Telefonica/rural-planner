#Libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(geosphere)
library(tidyr)
library(dplyr)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)


input_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")

#Intermediate outputs
file_names <- c("anditel.rds",
                "atc.rds",
                "atp.rds",
                "azteca.rds",
                "casanare.rds",
                "claro.rds", 
                "isp.rds",
                "pti.rds",
                "qmc.rds",
                "tigo.rds", 
                "towers.rds",
                "uniti.rds"
                )


file_name <- "towers_complete.rds"

source('~/shared/rural_planner/sql/co/infrastructure/deleteDuplicates_1.R')
source('~/shared/rural_planner/sql/co/infrastructure/deleteDuplicates_2.R')
source('~/shared/rural_planner/sql/co/infrastructure/deleteDuplicates_3.R')
source('~/shared/rural_planner/sql/co/infrastructure/deleteDuplicates_4.R')
source('~/shared/rural_planner/sql/co/infrastructure/deleteDuplicates_5.R')
source('~/shared/rural_planner/sql/co/infrastructure/export_separate_towers.R')
source('~/shared/rural_planner/sql/co/infrastructure/keepOldIds_1.R')
source('~/shared/rural_planner/sql/co/infrastructure/keepOldIds_2.R')
source('~/shared/rural_planner/sql/co/infrastructure/setAtollCoverageArea2G.R')

#Function to combine data frames
source('~/shared/rural_planner/functions/readAllFiles.R')

#Join all outputs to one single data frame. Remove some duplicates

towers_raw <- readAllFiles(file_names, input_path)

#We leave some duplicates in the same location because they are different BTS with different technologies and different kinds (for instance, we can have a Conventional Macro with 3G 4G and an HBTS in the lower part of the same tower)
# AD HOC: set lat/lon values from towers dataframe from character string to double and remove unlocated BTS

towers_raw$latitude <- as.numeric(towers_raw$latitude)
towers_raw$longitude <- as.numeric(towers_raw$longitude)

towers_raw <- towers_raw[!is.na(towers_raw$latitude),]
towers_raw <- towers_raw[!is.na(towers_raw$longitude),]


# AD-HOC: Remove duplicates 

towers <- towers_raw[order(towers_raw$internal_id, towers_raw$source),]

# 1) Remove from Tigo Ran-sharing
duplicates <- deleteDuplicates_1(schema_dev,table_tef, table_tigo)
  
towers <- towers[!(((towers$latitude%in%duplicates$latitude)&(towers$longitude%in%duplicates$longitude))&towers$source=='TIGO'),]

# 2) Remove duplicates from ATP in Azteca
duplicates_2 <- deleteDuplicates_2(schema_dev,table_azteca, table_atp, "atp", "ATP")

towers <- towers[!((towers$internal_id%in%duplicates_2$internal_id_azteca)&towers$source=='AZTECA'),]
towers$fiber[((towers$internal_id%in%duplicates_2$internal_id_atp)&towers$source=='ATP')] <- TRUE
towers$subtype[((towers$internal_id%in%duplicates_2$internal_id_atp)&towers$source=='ATP')] <- 'AZTECA'


# 3) Remove duplicates from ATC in Azteca
duplicates_3 <- deleteDuplicates_2(schema_dev,table_azteca, table_atc, "atc", "ATC")

towers <- towers[!((towers$internal_id%in%duplicates_3$internal_id_azteca)&towers$source=='AZTECA'),]
towers$fiber[((towers$internal_id%in%duplicates_3$internal_id_atc)&towers$source=='ATC')] <- TRUE
towers$subtype[((towers$internal_id%in%duplicates_3$internal_id_atc)&towers$source=='ATC')] <- 'AZTECA'


# 4) Remove duplicates from Azteca in Telefónica
duplicates_4 <- deleteDuplicates_3(schema_dev,table_azteca, table_tef)

towers <- towers[!((towers$internal_id%in%duplicates_4$internal_id_azteca)&towers$source=='AZTECA'),]
towers$fiber[((towers$internal_id%in%duplicates_4$internal_id_tef)&towers$source=='SITES_TEF')] <- TRUE
towers$subtype[((towers$internal_id%in%duplicates_4$internal_id_tef)&towers$source=='SITES_TEF')] <- 'AZTECA'
towers$owner[((towers$internal_id%in%duplicates_4$internal_id_tef)&towers$source=='SITES_TEF')] <- 'AZTECA'



# 5) Add info from Anditel in Azteca
towers$radio[(towers$owner=='ANDITEL'&towers$source=='AZTECA')] <- TRUE
towers$subtype[(towers$owner=='ANDITEL'&towers$source=='AZTECA')] <- 'AZTECA'


# 6) Remove duplicates from ATC in Telefónica
duplicates_5 <- deleteDuplicates_4(schema_dev,table_tef, table_atc)


towers <- towers[!((towers$internal_id%in%duplicates_5$internal_id_atc)&towers$source=='ATC'),]
towers$owner[((towers$internal_id%in%duplicates_5$internal_id_tef)&towers$source=='SITES_TEF')] <- 'ATC'


# 7) Remove duplicates from ATP in Telefónica
duplicates_6 <- deleteDuplicates_5(schema_dev,table_tef, table_atp)

towers <- towers[!((towers$internal_id%in%duplicates_6$internal_id_atp)&towers$source=='ATP'),]
towers$owner[((towers$internal_id%in%duplicates_6$internal_id_tef)&towers$source=='SITES_TEF')] <- 'ATP'


#AD-HOC: Solve location problems with towers: 18484, 241408, 2414360, 241362, 200401, 236169, 236170, 236171
table <- "infrastructure_global"

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd)

####184284
query <- paste("UPDATE ", schema, ".", table, " SET latitude = 3.761614
WHERE tower_name::text LIKE 'FERROCARRIL GUACARI' AND source LIKE 'QMC'", sep = "")
dbGetQuery(con,query)

####241362 y 241360
query <- paste("UPDATE ", schema, ".", table, " SET longitude = -74.1333333333333
WHERE location_detail::text LIKE 'ACEVEDO, HUILA'", sep = "")
dbGetQuery(con,query)

####200401 with location_detail = 'VARIANTE_ROMERIA-EL POLLO , VEREDA EL ESTANQUILLO 300 METROS.'
query <- paste("UPDATE ", schema, ".", table, " SET latitude = 4.83369
WHERE location_detail::text LIKE 'VARIANTE_ROMERIA-EL POLLO , VEREDA EL ESTANQUILLO 300 METROS.'", sep = "")
dbGetQuery(con,query)

query <- paste("UPDATE ", schema, ".", table, " SET longitude = -75.696051
WHERE location_detail::text LIKE 'VARIANTE_ROMERIA-EL POLLO , VEREDA EL ESTANQUILLO 300 METROS.'", sep = "")
dbGetQuery(con,query)

#236169 Borrado por tower_id antes de ver otros parametros. MIRAR EN EL SIGUIENTE E2E.
#236170 Borrado por tower_id antes de ver otros parametros. MIRAR EN EL SIGUIENTE E2E.
#236171 Borrado por tower_id antes de ver otros parametros. MIRAR EN EL SIGUIENTE E2E.
#241408 Borrado por tower_id antes de ver otros parametros. MIRAR EN EL SIGUIENTE E2E.


towers$tower_id  <- NA


#Export the normalized output
saveRDS(towers, paste(output_path, file_name, sep = "/"))

test <- readRDS(paste(output_path, file_name, sep = "/"))
identical(test, towers)

#Export and separate towers, access and transport
export_separate_towers(schema, schema_dev, table_infrastructure_old, infrastructure_table, table_towers_complete, towers)


## Keep old IDs

## FIRST SITES_TEF AND THIRD PARTIES BY INTERNAL ID

query <- paste("SELECT * from information_schema.tables where table_schema = ", schema_dev," and table_name=", table_global, sep = "")
exists_backup <- dbGetQuery(con,query)

if (nrow(exists_backup)==0){
  max_id$max <- 0
  keepOldIds_2(schema_dev, infrastructure_table)
} else {
  max_id <- keepOldIds_1(schema_dev, infrastructure_table, table_infrastructure_old)
  
  ##THEN REST OF THE TOWERS (NEW SOURCES)
  max_id_2 <- keepOldIds_2(schema_dev, infrastructure_table)
  }
setAtollCoverageArea2G(schema_dev, schema, table_atoll_infrastructure, infrastructure_table)



