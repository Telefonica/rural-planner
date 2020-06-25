
#LIBRARIES
library(rgdal)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(readl)

#CONFIG 
config_path <- '~/shared/rural_planner_r/config_files/config_ec'
source(config_path)

#VARIABLES
shapefile_path <- paste0(input_path_demography, "/SHP", sep = "") 
gdb_path <- paste0(input_path_demography, '/GEODATABASE_EMPATADA NACIONAL', sep = "") 

source('~/shared/rural_planner_r/sql/dropTable.R')

source('~/shared/rural_planner_r/sql/ec/demography/uploadNodes.R')
source('~/shared/rural_planner_r/sql/ec/demography/uploadCensusData.R')
source('~/shared/rural_planner_r/sql/ec/demography/insertCensusShp.R')
source('~/shared/rural_planner_r/sql/ec/demography/createSettlements.R')
source('~/shared/rural_planner_r/sql/ec/demography/createSettlementsV2.R')
source('~/shared/rural_planner_r/sql/ec/demography/createPoblatowns.R')
source('~/shared/rural_planner_r/sql/ec/demography/createNodesConsolidation.R')
source('~/shared/rural_planner_r/sql/ec/demography/createIntermediateTables.R')


bbb <- readOGR(dsn= paste(shapefile_path,'nodes_bbbike', sep='/'), layer='nodes_bbbike', use_iconv = T, encoding = 'UTF-8', stringsAsFactors = FALSE)

poblados <- readOGR(dsn=paste(shapefile_path,'nodes_poblados', sep='/'),
                    layer='poblado_p',encoding = 'UTF-8', stringsAsFactors = FALSE)

cantones <- readOGR(dsn=paste(shapefile_path,'cantones', sep='/'),
                 layer='nxcantones', stringsAsFactors = FALSE)

parroquias <- readOGR(dsn=paste(shapefile_path,'parroquias', sep='/'),
                layer='nxparroquias', stringsAsFactors = FALSE)

towns <- readOGR(dsn=paste(shapefile_path,'nodes_towns', sep='/'),
                 layer='GISPORTAL_GISOWNER01_ECUADOR250KTOWNS12', encoding =  'UTF-8', stringsAsFactors = FALSE)


census_loc <- readOGR(paste(gdb_path, 'GEODATABASE.gdb', sep='/'), layer = "GEO_LOC2010")
census_sec <- readOGR(paste(gdb_path, 'GEODATABASE.gdb', sep='/'), layer = "GEO_SEC2010")
census_secdis <- readOGR(paste(gdb_path, 'GEODATABASE.gdb', sep='/'), layer = "GEO_SECDIS2010")

census_pop <- read.csv(paste(input_path_demography, census_file_name, sep='/'))
projections_pop <- read_excel(paste(input_path_demography, projections_file_name, sep='/'), skip=2)

Encoding(bbb$name) <- "latin1"
bbb$name <- enc2utf8(bbb$name)
Encoding(poblados$nam) <- "latin1"
poblados$nam <- enc2utf8(poblados$nam)
Encoding(towns$nam) <- "latin1"
towns$nam <- enc2utf8(towns$nam)


Encoding(cantones$DPA_DESCAN) <- "latin1"
cantones$DPA_DESCAN <- enc2utf8(cantones$DPA_DESCAN)
names(cantones) <- tolower(names(cantones))
Encoding(parroquias$DPA_DESPAR) <- "latin1"
parroquias$DPA_DESPAR <- enc2utf8(parroquias$DPA_DESPAR)
names(parroquias) <- tolower(names(parroquias))

bbb$name <- as.character(toupper(bbb$name))
poblados$nam <- as.character(toupper(poblados$nam))
towns$nam <- as.character(toupper(towns$nam))

names(census_loc) <- tolower(names(census_loc))
names(census_sec) <- tolower(names(census_sec))
names(census_secdis) <- tolower(names(census_secdis))

poblados <- poblados[,c("nam")]
towns <- towns[,c("nam")]

projections_pop <- projections_pop[,c(2:14)]
names(projections_pop) <- c('admin_division_1_id',
                            'admin_division_1_name',
                            'pop_2010',
                            'pop_2011',
                            'pop_2012',
                            'pop_2013',
                            'pop_2014',
                            'pop_2015',
                            'pop_2016',
                            'pop_2017',
                            'pop_2018',
                            'pop_2019',
                            'pop_2020')


dropTable(schema_dev, table_bbb)
dropTable(schema_dev, table_pob)
dropTable(schema_dev, table_tow)
dropTable(schema_dev, table_parroquias)
dropTable(schema_dev, table_cantones)

#############upload nodes

Sys.setlocale('LC_ALL','C')

tables <- c(table_bbb, table_pob, table_tow)
objects <- c(bbb, poblados, towns)

uploadNodes(schema_dev, tables, objects)

##################################

tables_census <- c(table_parroquias, table_cantones)
objects_census <- c(parroquias, cantones)

insertCensusShp(schema_dev, tables_census, objects_census)

########################

createPoblatowns(schema_dev, table_poblatowns, table_pob, table_tow)

################ CREATE NODES CONSOLIDATION
createNodesConsolidation(schema_dev, table_nodes_all, table_bbb, table_poblatowns)

##########################################

# DROP PREVIOUS TABLES AND AUXILIARY TABLES

dropTable(schema_dev, table_bbb)
dropTable(schema_dev, table_pob)
dropTable(schema_dev, table_tow)
dropTable(schema_dev, table_poblatowns)



dropTable(schema_dev, table_census_pop)
dropTable(schema_dev, table_projections)
dropTable(schema_dev, table_geo_loc)
dropTable(schema_dev, table_geo_sec)
dropTable(schema_dev, table_geo_secdis)

uploadCensusData(schema_dev, table_census_pop, table_projections, table_geo_loc, table_geo_sec, table_geo_secdis, census_pop, projections_pop, census_loc, census_sec, census_secdis)



createIntermediateTables(schema_dev, table_census_pop, table_households_pop, table_geo_sec, table_geo_loc, table_geo_secdis)

######################## create settlements table
createSettlements(schema_dev, table_settlements, table_households_pop, table_nodes_all, table_parroquias, table_projections)
######################################

########################## create settlements_v2 table
createSettlementsV2(schema_dev, table_settlements_v2, table_settlements, table_projections)

## Drop auxiliary and intermediate tables
dropTable(schema_dev, table_nodes_all)
dropTable(schema_dev, table_households_pop)
dropTable(schema_dev, table_projections)
dropTable(schema_dev, table_census_pop)
dropTable(schema_dev, paste(table_census_pop, 'sec', sep='_'))
dropTable(schema_dev, paste(table_census_pop, 'man', sep='_'))
dropTable(schema_dev, table_geo_secdis)
dropTable(schema_dev, table_geo_sec)
dropTable(schema_dev, table_geo_loc)

