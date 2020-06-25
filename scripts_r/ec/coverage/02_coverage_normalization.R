
library(RPostgreSQL)
library(plyr)
library(stringr)
library(readxl)
library(data.table)
library(rgdal)
library(wkb)
library(sf)

#DB Connection parameters
config_path <- '~/shared/rural_planner_r/config_files/config_ec'
source(config_path)

atoll_folder <- 'Cobertura 2G_3G_LTE ATOLL_Junio 2019'

source('~/shared/rural_planner_r/sql/ec/coverage/listSettlements.R')
source('~/shared/rural_planner_r/sql/ec/coverage/uploadDB.R')
source('~/shared/rural_planner_r/sql/ec/coverage/createAtollPolygonsTable.R')
source('~/shared/rural_planner_r/sql/ec/coverage/createIndirectPolygonsTable.R')
source('~/shared/rural_planner_r/sql/ec/coverage/officialSettlements.R')
source('~/shared/rural_planner_r/sql/ec/coverage/indirectCoverage.R')
source('~/shared/rural_planner_r/sql/ec/coverage/atollNormalized.R')
source('~/shared/rural_planner_r/sql/ec/coverage/exportDBCoverage.R')


### Reported coverage ###
regulator_raw <- data.frame(read_excel(paste0(coverage_input_path,coverage_file_name),sheet=coverage_sheet_name, skip=9))
regulator_raw <- head(regulator_raw, -1)

names(regulator_raw) <- c("admin_division_2_name",
                          "admin_division_1_name",
                          "settlement_name",
                          "population_census",
                          "population_corrected",
                          "status",
                          "claro_2g",
                          "claro_3g",
                          "claro_4g",
                          "movistar_2g",
                          "movistar_3g",
                          "movistar_4g",
                          "cnt_2g",
                          "cnt_4g",
                          "segment",
                          "tef_coverage",
                          "park",
                          "yr1",
                          "yr2",
                          "yr3",
                          "yr4",
                          "yr5")

regulator_int <- regulator_raw[, c("admin_division_2_name",
                          "admin_division_1_name",
                          "settlement_name",
                          "claro_2g",
                          "claro_3g",
                          "claro_4g",
                          "movistar_2g",
                          "movistar_3g",
                          "movistar_4g",
                          "cnt_2g",
                          "cnt_4g")]

rm(coverage_file_name)
rm(coverage_sheet_names)

### Telcos ###

#List of all telcos with presence in LatAm
telco_list <- read_excel(paste0(coverage_input_path,coverage_file_name_2),sheet=coverage_sheet_name_2)

rm(coverage_file_name_2)
rm(coverage_sheet_name_2)

### Settlements ###
settlements_list <- listSettlements(schema_dev, table_settlements)

## Atoll shapefiles: ONLY EXECUTE IF ITS THE FIRST TIME and the atoll tables are not created in the DB

# Read atoll datasets
atoll_4g <- read_sf(dsn=paste(coverage_input_path, atoll_folder, sep='/'),
                 layer="LTE_LTE Ecuador completo 90%")

atoll_3g <- read_sf(dsn=paste(coverage_input_path, atoll_folder, sep='/'),
                 layer="UMTS_UMTS Ecuador 70%")

atoll_2g <- read_sf(dsn=paste(coverage_input_path, atoll_folder, sep='/'),
                 layer="GSM_Cobertura GSM Ecuador 70%")


# Subset largest threshold (except LTE -120)
atoll_4g <- atoll_4g[atoll_4g$THRESHOLD=="-120",]
red_4g <- st_geometry(atoll_4g)
atoll_3g <- atoll_3g[atoll_3g$THRESHOLD=="-105",]
red_3g <- st_geometry(atoll_3g)
atoll_2g <- atoll_2g[atoll_2g$THRESHOLD=="-105",]
red_2g <- st_geometry(atoll_2g)


# Upload df to DB
uploadDB(schema_dev, red_4g, table_atoll_4g, red_3g, table_atoll_3g, red_2g, table_atoll_2g)

# Atoll Coverage
createAtollPolygonsTable(schema_dev, atoll_polygons_table, table_atoll_2g, table_atoll_3g, table_atoll_4g)


##Indirect coverage
indirect_coverage_polygons_df <- as.data.frame(matrix(ncol=3,nrow=1))
names(indirect_coverage_polygons_df) <- c('geom_2g','geom_3g','geom_4g')

createIndirectPolygonsTable(schema_dev, indirect_polygons_table,infrastructure_table, indirect_coverage_polygons_df)


### Reported coverage ###
official_settlements <- officialSettlements(schema_dev, table_census)

settlements_list$official_id <- str_split_fixed(settlements_list$settlement_id,"-", n=2)[,1]

regulator_int <- merge(regulator_int, official_settlements,  by=c("admin_division_1_name", "settlement_name", "admin_division_2_name"), all.x=T)
regulator_int <- regulator_int[!is.na(regulator_int$settlement_id),]
regulator_int <- merge(settlements_list, regulator_int, by.x= "official_id", by.y= "settlement_id", all.x=T)
regulator_int <- regulator_int[,c("settlement_id",
                                  "claro_2g",
                                  "claro_3g",
                                  "claro_4g",
                                  "movistar_2g",
                                  "movistar_3g",
                                  "movistar_4g",
                                  "cnt_2g",
                                  "cnt_4g")]
regulator_int$cnt_3g <- NA


regulator_int_movistar <- regulator_int[,c("settlement_id",
                                  "movistar_2g",
                                  "movistar_3g",
                                  "movistar_4g")]
regulator_int_movistar$operator_id <- 'MOVISTAR'
regulator_int_movistar$movistar_2g <- as.logical(regulator_int_movistar$movistar_2g)
regulator_int_movistar$movistar_3g <- as.logical(regulator_int_movistar$movistar_3g)
regulator_int_movistar$movistar_4g <- as.logical(regulator_int_movistar$movistar_4g)
names(regulator_int_movistar) <- c("settlement_id",
                              "tech_2g_regulator",
                              "tech_3g_regulator",
                              "tech_4g_regulator",
                              "operator_id")

regulator_int_claro <- regulator_int[,c("settlement_id",
                                  "claro_2g",
                                  "claro_3g",
                                  "claro_4g")]
regulator_int_claro$operator_id <- 'CLARO'
regulator_int_claro$claro_2g[regulator_int_claro$claro_2g=="-"] <- '0'
regulator_int_claro$claro_2g <- as.logical(as.integer(regulator_int_claro$claro_2g))
regulator_int_claro$claro_3g <- as.logical(regulator_int_claro$claro_3g)
regulator_int_claro$claro_4g <- as.logical(regulator_int_claro$claro_4g)
names(regulator_int_claro) <- c("settlement_id",
                              "tech_2g_regulator",
                              "tech_3g_regulator",
                              "tech_4g_regulator",
                              "operator_id")


regulator_int_cnt <- regulator_int[,c("settlement_id",
                                  "cnt_2g",
                                  "cnt_3g",
                                  "cnt_4g")]
regulator_int_cnt$operator_id <- 'CNT'
regulator_int_cnt$cnt_2g[regulator_int_cnt$cnt_2g=="-"] <- '0'
regulator_int_cnt$cnt_2g <- as.logical(as.integer(regulator_int_cnt$cnt_2g))
regulator_int_cnt$cnt_3g <- as.logical(regulator_int_cnt$cnt_3g)
regulator_int_cnt$cnt_4g <- as.logical(regulator_int_cnt$cnt_4g)
names(regulator_int_cnt) <- c("settlement_id",
                              "tech_2g_regulator",
                              "tech_3g_regulator",
                              "tech_4g_regulator",
                              "operator_id")


regulator_normalized_df <- rbind(regulator_int_claro, regulator_int_movistar, regulator_int_cnt)

regulator_normalized_df[is.na(regulator_normalized_df)]<-FALSE


### Indirect coverage ###

indirect_normalized_df <- indirectCoverage(schema_dev, table_settlements, indirect_polygons_table)

#Having all the indirect coverage from Movistar:

indirect_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Movistar','telco_id'])


#Merge with the rest of the data (regulator data)
merged_indirect_regulator_df <- merge(regulator_normalized_df, indirect_normalized_df, by.x=c('settlement_id','operator_id'), by.y=c('settlement_id','operator_id'), all.x=TRUE)


merged_indirect_regulator_df[is.na(merged_indirect_regulator_df)]<-FALSE

### Atoll coverage ###


atoll_normalized_df <- atollNormalized(schema_dev, table_settlements, atoll_polygons_table)

atoll_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Movistar','telco_id'])

#Merge with the rest of the data (infrastructure data)
merged_indirect_regulator_app_df <- merge(merged_indirect_regulator_df,atoll_normalized_df, by.x=c('settlement_id','operator_id'), by.y=c('settlement_id','operator_id'), all.x=TRUE)


merged_indirect_regulator_app_df[is.na(merged_indirect_regulator_app_df)]<-FALSE


#Define corrected fields: if any of the sources (ONLY ATOLL) indicates that there is coverage in a settlement for a given technology, the corrected field for this technology is TRUE.

merged_indirect_regulator_app_df$tech_2g_corrected <- FALSE
merged_indirect_regulator_app_df[ (merged_indirect_regulator_app_df$tech_2g_app == TRUE)
                                 ,'tech_2g_corrected'] <- TRUE

merged_indirect_regulator_app_df$tech_3g_corrected <- FALSE
merged_indirect_regulator_app_df[(merged_indirect_regulator_app_df$tech_3g_app == TRUE)
                                 ,'tech_3g_corrected'] <- TRUE


merged_indirect_regulator_app_df$tech_4g_corrected <- FALSE
merged_indirect_regulator_app_df[ (merged_indirect_regulator_app_df$tech_4g_app == TRUE)
                                 ,'tech_4g_corrected'] <- TRUE


### Creation output dataframe ###

#"COLUMNIZE". Transform the master table into one with one row per settlement and personalized columns for each operator

coverage <- data.frame(settlements_list$settlement_id)
names(coverage)<-'settlement_id'

operator_ids <- unique(merged_indirect_regulator_app_df$operator_id)


data_categories <- c('regulator','indirect','app','corrected')


for (i in 1:length(operator_ids))
{
  operator_df<-data.frame()
  operator_df <- merged_indirect_regulator_app_df[merged_indirect_regulator_app_df$operator_id == operator_ids[i],names(merged_indirect_regulator_app_df) !="operator_id"]
  coverage <- merge(coverage, operator_df, by='settlement_id', all.x=T)
  rm(operator_df)
}

#Set names for the columns of the dataframe

names_coverage<-c('settlement_id')

for (i in 1:length(operator_ids)){
  for(j in 1:length(data_categories)){
     names_coverage<-append(names_coverage, paste0(tolower(operator_ids[i]),'_2g_',data_categories[j]))
     names_coverage<-append(names_coverage, paste0(tolower(operator_ids[i]),'_3g_',data_categories[j]))
     names_coverage<-append(names_coverage, paste0(tolower(operator_ids[i]),'_4g_',data_categories[j]))
  }
}

names(coverage)<-names_coverage

rm(names_coverage)


# Add the corrected information from the competitors' data 

coverage$competitors_2g_corrected <- FALSE
coverage[((coverage$claro_2g_corrected == TRUE) | (coverage$cnt_2g_corrected == TRUE)),'competitors_2g_corrected'] <- TRUE

coverage$competitors_3g_corrected <- FALSE
coverage[((coverage$claro_3g_corrected == TRUE) | (coverage$cnt_3g_corrected == TRUE)) ,'competitors_3g_corrected'] <- TRUE


coverage$competitors_4g_corrected <- FALSE
coverage[((coverage$claro_4g_corrected == TRUE) | (coverage$cnt_4g_corrected == TRUE)),'competitors_4g_corrected'] <- TRUE


coverage[is.na(coverage)]<-FALSE

### Export output to PostreSQL ###

#Establish connection
exportDBCoverage(schema_dev, table_coverage, coverage)



