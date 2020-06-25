#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(geosphere)
library(tidyr)
library(dplyr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)

#VARIABLES
input_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_names <- c("advisia.rds",
                "azteca.rds",
                "claro.rds",
                "claro_nodes.rds",
                "ehas.rds",
                "entel.rds",
                "femtos.rds",
                "fiber_planned.rds",
                "gilat.rds",
                "ipt.rds",
                "lambayeque.rds", 
                "macros.rds",
                "pia.rds",
                "regional.rds",
                "torres_andinas.rds",
                "yofc.rds"
                )


output_path <- "../outputs"
file_name <- "towers.rds"

#Function to combine data frames
source('~/shared/rural_planner/functions/readAllFiles.R')

source('~/shared/rural_planner/sql/pe/infrastructure/exportSeparateTowers.R')
source('~/shared/rural_planner/sql/pe/infrastructure/createMacros.R')
source('~/shared/rural_planner/sql/pe/infrastructure/createOldNewIdMapping.R')
source('~/shared/rural_planner/sql/pe/infrastructure/updateDB.R')

#Join all outputs to one single data frame except for IPT. Remove some duplicates

#Read the normalized intermediate outputs to be consolidated
towers_raw <- readAllFiles(file_names)

#Remove duplicates that:
#Only differ in internal ID
fields <- colnames(towers_raw)
fields_internal_id <- fields[! fields %in% "internal_id"] #This takes out the last element
towers_raw <- towers_raw[!duplicated(towers_raw[c(fields_internal_id)]),]

#Only differ in tower height and internal ID
fields_height <- fields_internal_id[! fields_internal_id %in% "tower_height"]
towers_raw <- towers_raw[order(towers_raw$internal_id, towers_raw$tower_height, decreasing = TRUE),]
towers_raw <- towers_raw[!duplicated(towers_raw[c(fields_height)]),]
towers_raw <- towers_raw[order(towers_raw$owner, decreasing = FALSE),]

#We leave some duplicates in the same location because they are different BTS with different technologies and different kinds (for instance, we can have a Conventional Macro with 3G 4G and an HBTS in the lower part of the same tower)


# AD HOC: set lat/lon values from towers dataframe from character string to double and remove unlocated BTS

towers_raw$latitude <- as.numeric(towers_raw$latitude)
towers_raw$longitude <- as.numeric(towers_raw$longitude)


towers_raw$latitude[(towers_raw$latitude==0)] <- NA
towers_raw$longitude[(towers_raw$longitude==0)] <- NA

towers <- towers_raw[!is.na(towers_raw$latitude),]
towers <- towers[!is.na(towers$longitude),]

towers$tower_height[is.na(towers$tower_height)] <- 15

towers$tower_height[(towers$tower_height==0)] <- 15


#AD HOC: Remove duplicate from PIA (already in MACROS source)
#towers <- towers[!(towers$internal_id=='LO00073' & towers$owner=='PIA'),]

towers <- towers[-(which(towers$internal_id == 'LO00073' & towers$owner=='PIA')),]

#Reset row.names
row.names(towers) <- NULL

## AD-HOC : Update fiber-planned information and remove duplicates

towers$fiber[towers$internal_id%in%c('AM00160','PI00100','PI00120','LI01134','LI01108','AY00147')] <- TRUE

towers <- towers[!(towers$internal_id%in%c('La Quinua','Santa Eulalia','Santa Rosa Ancón','Pedro Ruiz Gallo','Salitral','Marcavelica')),]


#Export the normalized output
saveRDS(towers, paste(output_path, file_name, sep = "/"))

test <- readRDS(paste(output_path, file_name, sep = "/"))
identical(test, towers)


#Export and separate towers, access and transport
exportSeparateTowers(schema_dev, table_old_id, table_infrastructure, towers)


## Keep old IDs
createMacros(schema_dev, table_infrastructure, table_old_id)

# Create old-new ID mapping
createOldNewIdMapping(schema_dev, table_id_map, table_infrastructure, table_old_id)

#Update infrastructure global fields with ka migration & entel interest new info from infrastructure_global_ka_migration and infrastrucuture_global_entel_interest tables
updateDB(schema_dev, table_infrastructure, table_infrastrcuture_global_entel_interest)



