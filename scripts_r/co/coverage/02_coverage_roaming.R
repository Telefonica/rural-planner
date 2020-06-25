
library(RPostgreSQL)
library(plyr)
library(tidyverse)
library(stringr)
library(readxl)
library(data.table)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

source('~/shared/rural_planner/sql/dropTable.R')
source('~/shared/rural_planner/sql/co/coverage/createIndirectRoamingTable.R')
source('~/shared/rural_planner/sql/co/coverage/roamingTigo.R')
source('~/shared/rural_planner/sql/co/coverage/roamingClaro.R')
source('~/shared/rural_planner/sql/co/coverage/exportDBRoaming.R')

### Roaming coverage

#Create a PostgreSQL table with the coverage that provides roaming Towers

# Clean previous data
cleanRoaming(schema_dev, indirect_roaming_polygons_table)

createIndirectRoamingTable(schema_dev, indirect_roaming_polygons_table)


#We create a table according to the geographic location of each settlement and the roaming coverage area for each technology .

## Roaming

tigo_roaming <- roamingTigo(schema_dev, table_settlements, indirect_roaming_polygons_table)

claro_roaming <- roamingClaro(schema_dev, table_settlements, indirect_roaming_polygons_table)

#Merge with the rest of the data (regulator and infrastructure data)
coverage_roaming <- merge(tigo_roaming,claro_roaming, by.x='settlement_id', by.y='settlement_id', all.x=TRUE)


### Export Roaming output to PostreSQL ###


exportDBRoaming(schema_dev, output_roaming_table_name, coverage_roaming)

