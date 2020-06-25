
library(RPostgreSQL)
library(plyr)
library(tidyverse)
library(stringr)
library(readxl)
library(data.table)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)


data_categories <- c('regulator','indirect','app','corrected')

#Set operators available in the country
operator_names <- c('Movistar', 'Claro', 'Tigo')

source('~/shared/rural_planner/sql/co/coverage/listSettlementsZRD.R')
source('~/shared/rural_planner/sql/co/coverage/movistarRegulatorNormalizedZRD.R')
source('~/shared/rural_planner/sql/co/coverage/claroRegulatorNormalizedZRD.R')
source('~/shared/rural_planner/sql/co/coverage/tigoRegulatorNormalizedZRD.R')
source('~/shared/rural_planner/sql/co/coverage/indirectNormalizedZRD.R')
source('~/shared/rural_planner/sql/co/coverage/facebookZRD.R')
source('~/shared/rural_planner/sql/co/coverage/fbCompetitorsZRD.R')
source('~/shared/rural_planner/sql/co/coverage/exportZRD.R')

#LOAD INPUTS
### Telcos ###
telco_list <- read_excel(paste0(coverage_input_path,coverage_file_name),sheet=coverage_sheet_name)

### Settlements ###

#List of all settlements registered in the country
settlements_list <- listSettlementsZRD(schema_dev, table_zrd)

#### Reported Coverage ###

#List of coverages from all telcos and all technologies by settlement, provided by national telco regulatory agency

#Imput imported directly to PostgreSQL database.

#### Facebook Coverage ###

#Imput imported directly to PostgreSQL database.


#NORMALIZATION REGULATOR RAW DATA

### Reported coverage ###
#We create a table according to the geographic location of each settlement and the coverage area for each technology from the print reported to the regulator.

## MOVISTAR
movistar_regulator_normalized_df <- movistarRegulatorNormalizedZRD(schema_dev, table_zrd, movistar_polygons_table)

#Having all the indirect coverage from Movistar:

movistar_regulator_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Movistar','telco_id'])


## CLARO (25 min aprox)
claro_regulator_normalized_df <- claroRegulatorNormalizedZRD(schema, table_zrd, schema_dev, claro_polygons_table)

#Having all the indirect coverage from Claro:

claro_regulator_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Claro','telco_id'])


## TIGO
tigo_regulator_normalized_df <- tigoRegulatorNormalizedZRD(schema, table_zrd, schema_dev, tigo_polygons_table)

#Having all the indirect coverage from Movistar:

tigo_regulator_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Tigo','telco_id'])



#Merge with the rest of the data (regulator data)

regulator_normalized_df <- rbind(movistar_regulator_normalized_df,claro_regulator_normalized_df,tigo_regulator_normalized_df)

regulator_normalized_df <- regulator_normalized_df[order(regulator_normalized_df$centroid,regulator_normalized_df$operator_id),]


### Indirect coverage ###

#We create a table according to the geographic location of each settlement and the coverage area for each technology calculated from the infrastructure information.
indirect_normalized_df <- indirectNormalizedZRD(schema_dev, table_zrd, indirect_polygons_table)

#Having all the indirect coverage from Movistar:

indirect_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Movistar','telco_id'])


#Merge with the rest of the data (regulator data)

merged_indirect_regulator_df <- merge(regulator_normalized_df,indirect_normalized_df, by.x=c('centroid','operator_id'), by.y=c('centroid','operator_id'), all.x=TRUE)


#For the rest of operators assume FALSE

merged_indirect_regulator_df[is.na(merged_indirect_regulator_df)]<-FALSE


### Facebook Coverage ###

#We create a table according to the geographic location of each settlement and the coverage area for each technology calculated and provided by Facebook.


facebook_normalized_df <- facebookZRD(schema, schema_dev, table_zrd, facebook_polygons_tf_table_2g, facebook_polygons_tf_table_3g, facebook_polygons_tf_table_4g)

#Taking only Movistar coverage from the Facebook data

facebook_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Movistar','telco_id'])


#Merge with the rest of the data (regulator and infrastructure data)
merged_indirect_regulator_app_df <- merge(merged_indirect_regulator_df,facebook_normalized_df, by.x=c('centroid','operator_id'), by.y=c('centroid','operator_id'), all.x=TRUE)


#For the rest of operators assume FALSE

merged_indirect_regulator_app_df[is.na(merged_indirect_regulator_app_df)]<-FALSE


#Define corrected fields: if any of the sources (regulator or infrastructure) indicates that there is coverage in a settlement for a given technology, the corrected field for this technology is TRUE.
## AD-HOC: IGNORE FACEBOOK INFORMATION

merged_indirect_regulator_app_df$tech_2g_corrected <- FALSE
merged_indirect_regulator_app_df[(merged_indirect_regulator_app_df$tech_2g_regulator == TRUE) | (merged_indirect_regulator_app_df$tech_2g_indirect == TRUE)
                                 ,'tech_2g_corrected'] <- TRUE

merged_indirect_regulator_app_df$tech_3g_corrected <- FALSE
merged_indirect_regulator_app_df[(merged_indirect_regulator_app_df$tech_3g_regulator == TRUE) | (merged_indirect_regulator_app_df$tech_3g_indirect == TRUE)
                                 ,'tech_3g_corrected'] <- TRUE


merged_indirect_regulator_app_df$tech_4g_corrected <- FALSE
merged_indirect_regulator_app_df[(merged_indirect_regulator_app_df$tech_4g_regulator == TRUE) | (merged_indirect_regulator_app_df$tech_4g_indirect == TRUE)
                                 ,'tech_4g_corrected'] <- TRUE


### Creation output dataframe ###

#"COLUMNIZE". Transform the master table into one with one row per settlement and personalized columns for each operator

coverage <- data.frame()
coverage<- settlements_list
names(coverage)<-'centroid'


operator_ids <- telco_list[(telco_list$telco_name %in% operator_names),'telco_id']
operator_ids <- as.array(operator_ids$telco_id)

for (i in 1:length(operator_ids))
{ 
  operator_df<-data.frame()
  operator_df <- merged_indirect_regulator_app_df[merged_indirect_regulator_app_df$operator_id == operator_ids[i],names(merged_indirect_regulator_app_df) !="operator_id"]
  coverage <- merge(coverage, operator_df, by='centroid')
  rm(operator_df)
}

#Set names for the columns of the dataframe

names_coverage<-c('centroid')

for (i in 1:length(operator_ids)){
  for(j in 1:length(data_categories)){
     names_coverage<-append(names_coverage, paste0(tolower(operator_ids[i]),'_2g_',data_categories[j]))
     names_coverage<-append(names_coverage, paste0(tolower(operator_ids[i]),'_3g_',data_categories[j]))
     names_coverage<-append(names_coverage, paste0(tolower(operator_ids[i]),'_4g_',data_categories[j]))
  }
}

names(coverage)<-names_coverage

rm(names_coverage)


#Add the competitors' information from the Facebook data
facebook_competitors_normalized_df <- fbCompetitorsZRD(schema_dev, schema_dev, table_zrd, facebook_competitors_polygons_2g, facebook_competitors_polygons_3g, facebook_competitors_polygons_4g)


#Merge with the rest of the data (regulator and infrastructure data)
coverage <- merge(coverage,facebook_competitors_normalized_df, by.x='centroid', by.y='centroid', all.x=TRUE)

# Add the corrected information from the competitors' data (ONLY REGULATOR DATA; NOT FACEBOOK)

coverage$competitors_2g_corrected <- FALSE
coverage[((coverage$claro_2g_corrected == TRUE) | (coverage$tigo_2g_corrected == TRUE)),'competitors_2g_corrected'] <- TRUE

coverage$competitors_3g_corrected <- FALSE
coverage[((coverage$claro_3g_corrected == TRUE) | (coverage$tigo_3g_corrected == TRUE)) ,'competitors_3g_corrected'] <- TRUE


coverage$competitors_4g_corrected <- FALSE
coverage[((coverage$claro_4g_corrected == TRUE) | (coverage$tigo_4g_corrected == TRUE)),'competitors_4g_corrected'] <- TRUE


coverage[is.na(coverage)]<-FALSE


### Export output to PostreSQL ###

#Establish connection
exportZRD(schema_dev, output_table_name, coverage)


