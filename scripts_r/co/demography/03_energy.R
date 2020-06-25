

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


file_name <-  "1795 sitios_sin_energ_a 2019-04-02.xlsx"


source('~/shared/rural_planner/sql/co/demography/settlementsEnergy.R')
source('~/shared/rural_planner/sql/co/demography/matchingSettlementsNoGrid.R')
source('~/shared/rural_planner/sql/exportDB_AddGeom.R')
source('~/shared/rural_planner/sql/dropTable.R')

## Import input data
energy_raw <- read_excel(paste(input_path_demography, file_name, sep = "/")) 


# Select useful columns from casanare's 4 sites raw input

energy_int <- data.frame(energy_raw$id_localidad,
                         energy_raw$localidad,
                         energy_raw$id_municipio,
                         energy_raw$municipio,
                         energy_raw$id_departamento,
                         energy_raw$departamento,
                         energy_raw$latitud,
                         energy_raw$longitud,
                         stringsAsFactors = FALSE
)


#Change names of the variables we already have from casanare's 4 sites raw
colnames(energy_int) <- c("id_localidad",
                          "localidad",
                          "id_municipio",
                          "municipio",
                          "id_departamento",
                          "departamento",
                          "latitude",
                          "longitude")


#Fill energy_int with the rest of the fields and reshape where necessary

#ID localidad
energy_int$id_localidad <- as.character(str_pad(energy_int$id_localidad, 8, "left", pad="0"))

#Localidad
Encoding(energy_int$localidad) <- "UTF-8"

#ID municipio
energy_int$id_municipio <- as.character(str_pad(energy_int$id_municipio, 5, "left", pad="0"))

#Municipio
Encoding(energy_int$municipio) <- "UTF-8"

#ID departamento
energy_int$id_departamento <- as.character(str_pad(energy_int$id_departamento, 2, "left", pad="0"))

#Departamento
Encoding(energy_int$departamento) <- "UTF-8"

#Latitude
energy_int$latitude <- as.numeric(energy_int$latitude)

#Longitude
energy_int$longitude <- as.numeric(energy_int$longitude)

#Source file:
energy_int$source_file <- file_name

#Source:
energy_int$source <- "NO GRID"


#Export dataset to DB
exportDB_AddGeom(schema_dev, no_grid_table, energy_int, "geom2")

# Create a table with matching settlements from no grid table(1795 ccpp) and global settlements(11975 ccpp)
matchingSettlementsNoGrid(schema_dev, table_energy_matching, no_grid_table, schema_dev, table_settlements)


# Create settlements_energy table with all the settlements (11975 ccpp) and a new boolean column defficient_energy: set to TRUE if the settlement is included in the matching table (so it has defficient energy); FALSE if not. 
settlementsEnergy(schema_dev,schema_dev, table_energy, table_settlements, table_energy_matching)


# Drop input and intermediate tables from dev schema
dropTable(schema_dev, no_grid_table)
dropTable(schema_dev, table_energy_matching)



