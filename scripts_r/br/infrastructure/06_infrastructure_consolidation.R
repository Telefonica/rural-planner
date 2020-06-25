
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(geosphere)
library(tidyr)
library(dplyr)
library(sf)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_br'
source(config_path)

#VARIABLES
input_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")

#Intermediate outputs to be consolidated
file_names_pts <- c("vivo.rds", "third_party_nodes.rds", "infra_competitors.rds")
file_names_tx_vivo <- c("vivo_fo_pops.rds", "vivo_mw_pops.rds")
file_names_lines <- c("third_party_lines.rds", "vogel_lines.rds")

output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name <- "towers_aux.rds"

source('~/shared/rural_planner/sql/br/infrastructure/06_uploadDBFinalConsolidation.R')
source('~/shared/rural_planner/sql/br/infrastructure/06_updateDBIOConsolidation.R')
source('~/shared/rural_planner/functions/readAllFiles.R')

#Join all outputs to one single data frame. Remove some duplicates

#Function to combine data frames
towers_pts_raw <- readAllFiles(file_names_pts,output_path)
towers_lines_raw <- readAllFiles(file_names_lines, output_path)
towers_tx <- readAllFiles(file_names_tx_vivo, output_path)

vivo_ids <- unique(towers_pts_raw$internal_id[towers_pts_raw$source=="VIVO"])
towers_tx <- towers_tx[!(towers_tx$internal_id%in%vivo_ids),]

towers_pts_raw <- rbind(towers_pts_raw,towers_tx)


# AD-HOC: Clean corrupt geometries and parse geom format from wkt
towers_lines_raw <- towers_lines_raw[!(towers_lines_raw$wkt=='LINESTRING Z ()'),]

# This line removes linestrings with one point only:
towers_lines_raw <- towers_lines_raw[(grepl(",",towers_lines_raw$wkt)),]


# AD-HOC: Remove duplicates 

towers <- towers_pts_raw[order(towers_pts_raw$source, towers_pts_raw$internal_id),]

towers <- towers %>% distinct(source, latitude, longitude, .keep_all=T)


traces <- towers_lines_raw[order(towers_lines_raw$source, towers_lines_raw$internal_id),]

traces <- traces %>% distinct(source, wkt, .keep_all=T)

## AD-HOC: Fix tower_heights

towers$tower_height[towers$tower_height<0] <- -(towers$tower_height[towers$tower_height<0])

towers$tower_height[towers$tower_height>150] <- mean(towers$tower_height[towers$tower_height<=150])


##Upload to database (intermediate output)
infra_all <- updateDBIOConsolidation(schema_dev, table_lines, table_points, traces, towers)

#Export the normalized output
saveRDS(infra_all, paste(output_path, file_name, sep = "/"))

test <- readRDS(paste(output_path, file_name, sep = "/"))
identical(test, infra_all)

#Export and separate towers, access and transport
uploadDBFinalConsolidation(schema_dev, table_infrastructure_global, infra_all, atoll_table_all)




