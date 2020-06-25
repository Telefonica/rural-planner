

library(RPostgreSQL)
library(rpostgis)
library(tidyverse)
library(stringr)
library(scales)
library(readxl)
library(xlsx)


#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

source_name_1 <- '3000 obligaciones de hacer.xlsx'



source('~/shared/rural_planner/sql/exportDB_AddGeom.R')

## Import input data
schools_raw <-read_excel(paste(input_path_demography, source_name_1, sep="/") )

schools_int <- schools_raw[,c(7,8,4,13,14)]

names(schools_int) <- c("internal_id",
                        "school_name",
                        "settlement_id",
                        "latitude",
                        "longitude")




schools_int$internal_id <- as.character(schools_int$internal_id)
schools_int$internal_id[schools_int$internal_id=='NO APLICA'] <- NA
schools_int$internal_id[schools_int$internal_id=='NA'] <- NA
schools_int$internal_id[schools_int$internal_id=='ND'] <- NA
schools_int$internal_id[schools_int$internal_id=='N/A'] <- NA
schools_int$internal_id[schools_int$internal_id=='No Aplica'] <- NA

schools_int$school_name <- as.character(schools_int$school_name)

schools_int$settlement_id <- as.character(schools_int$settlement_id)
schools_int$settlement_id <- str_pad(schools_int$settlement_id, 8, side = "left", pad = "0")

schools_int$latitude <- as.numeric(schools_int$latitude)
schools_int$longitude <- as.numeric(schools_int$longitude)

schools_int <- schools_int[order(schools_int$internal_id, schools_int$school_name, schools_int$settlement_id),]
schools_int$school_id <- as.integer(1:nrow(schools_int))

#Export dataset to DB
exportDB_AddGeom(schema_dev,table_schools,schools_int, "geom")

