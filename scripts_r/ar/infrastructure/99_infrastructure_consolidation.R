
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(tidyr)
library(dplyr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_ar'
source(config_path)

#VARIABLES
source('~/shared/rural_planner/functions/readAllFiles.R')

input_path <- paste0(input_path_infrastructure,"/intermediate outputs",sep="")
file_names <- c("tasa_ipt.rds",
                "arsat.rds",
                "claro.rds",
                "gigared.rds",
                "personal.rds",
                "tasa_fixed.rds",
                "silica_nodes.rds",
                "third_party_nodes.rds")

source('~/shared/rural_planner/sql/ar/infrastructure/exportConsolidation.R')

#LOAD INPUTS
#Join all outputs to one single data frame except for IPT. Remove some duplicates

#Function to combine data frames
towers_raw <- readAllFiles(file_names, input_path)

towers <- towers_raw


exportConsolidation(schema_dev, table_infrastructure, towers, view_infrastructure)



