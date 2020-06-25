
library(RPostgreSQL)
library(plyr)
library(stringr)
library(readxl)
library(data.table)
library(gdata)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)


data_categories <- c('regulator','indirect','app','corrected')

#Set operators available in the country
operator_names <- c('Movistar', 'Claro', 'Tigo')


source('~/shared/rural_planner/sql/co/coverage/listSettlements.R')
source('~/shared/rural_planner/sql/truncateTable.R')
source('~/shared/rural_planner/sql/co/coverage/indirectCoverageTable.R')
source('~/shared/rural_planner/sql/co/coverage/claroRegulatorNormalized.R')
source('~/shared/rural_planner/sql/co/coverage/tigoRegulatorNormalized.R')
source('~/shared/rural_planner/sql/co/coverage/indirectNormalized.R')
source('~/shared/rural_planner/sql/co/coverage/facebookNormalized.R')
source('~/shared/rural_planner/sql/co/coverage/fbCompetitorsNormalized.R')
source('~/shared/rural_planner/sql/co/coverage/exportNormalization.R')

#LOAD INPUTS
### Telcos ###

#List of all telcos with presence in LatAm
telco_list <- read_excel(paste0(coverage_input_path,coverage_file_name, sep='/'),sheet=coverage_sheet_name)

rm(coverage_file_name)
rm(coverage_sheet_name)

### Settlements ###

#List of all settlements registered in the country
settlements_list <- listSettlements(schema_dev, table_settlements)

#List of settlements with movistar regulator coverage info
movistar_regulator_raw <- read.xls(paste(coverage_input_path, coverage_file_name_2, sep = '/'), sheet = coverage_sheet_name_2)


### Indirect Coverage ###

#Create a PostgreSQL table with the coverage that provides each Telefonica infrastructure with access from the country, from the datatable created in the infrastructure process, to calculate indirect coverage for each settlement. No need to import the table to the workspace because the subprocess will be writen in SQL launching the queries from the Rmd file.
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd) 

# Clean previous data
truncateTable(schema_dev, indirect_polygons_table)


indirect_coverage_polygons_df <- as.data.frame(matrix(ncol=3,nrow=1))
names(indirect_coverage_polygons_df) <- c('geom_2g','geom_3g','geom_4g')


indirectCoverageTable(schema_dev, indirect_polygons_table, infrastructure_table)

#### Reported Coverage ###

#List of coverages from all telcos and all technologies by settlement, provided by national telco regulatory agency

#Imput imported directly to PostgreSQL database.

#### Facebook Coverage ###

#Imput imported directly to PostgreSQL database.

#NORMALIZATION REGULATOR RAW DATA

### Reported coverage ###

#We create a table according to the geographic location of each settlement and the coverage area for each technology from the print reported to the regulator.

## MOVISTAR
source('~/shared/rural_planner/sql/co/coverage/movistarRegulatorNormalized.R')
movistar_regulator_normalized_df <- movistarRegulatorNormalized(schema_dev, table_settlements, schema, telefonica_atoll_ouptut_table)

#Select useful data from movistar regulator coverage raw input and fill/normalize where necessary

movistar_regulator_int <- data.frame(movistar_regulator_raw$codigo,
                                    movistar_regulator_raw$COBERTURA_2G,
                                    movistar_regulator_raw$COBERTURA_3G,
                                    movistar_regulator_raw$COBERTURA_HSPA,
                                    movistar_regulator_raw$COBERTURA_LTE,
                                    stringsAsFactors = F)

colnames(movistar_regulator_int) <- c("settlement_id",
                                    "coverage_2g",
                                    "coverage_3g",
                                    "coverage_3g+",
                                    "coverage_4g")

#Settlement id
movistar_regulator_int$settlement_id <- str_pad(movistar_regulator_int$settlement_id, width = 8, side = "left", pad = "0") 

#Movistar regulator coverage
movistar_regulator_int$movistar_2g_regulator <- FALSE
movistar_regulator_int$movistar_3g_regulator <- FALSE
movistar_regulator_int$movistar_4g_regulator <- FALSE

movistar_regulator_int[grepl("S", movistar_regulator_int$coverage_2g), 'movistar_2g_regulator'] <- TRUE
movistar_regulator_int[grepl("S", movistar_regulator_int$coverage_3g) | grepl("S", movistar_regulator_int$'coverage_3g+'), 'movistar_3g_regulator'] <- TRUE
movistar_regulator_int[grepl("S", movistar_regulator_int$coverage_4g), 'movistar_4g_regulator'] <- TRUE

#Create final normalized data frame in the right order
movistar_regulator <- movistar_regulator_int[, c("settlement_id",
                                                 "movistar_2g_regulator",
                                                 "movistar_3g_regulator",
                                                 "movistar_4g_regulator")]

#Merge with settlements to have all settlement ids
merged_movistar_regulator_df <- merge(movistar_regulator_normalized_df, movistar_regulator, by.x=c('settlement_id'), by.y=c('settlement_id'), all.x=TRUE)

#Fill as false null values (empty values)
merged_movistar_regulator_df[is.na(merged_movistar_regulator_df$movistar_2g_regulator), "movistar_2g_regulator"] <- FALSE
merged_movistar_regulator_df[is.na(merged_movistar_regulator_df$movistar_3g_regulator), "movistar_3g_regulator"] <- FALSE
merged_movistar_regulator_df[is.na(merged_movistar_regulator_df$movistar_4g_regulator), "movistar_4g_regulator"] <- FALSE

#OR conditional to set final movistar_regulator_normalized_df fields with the merged inputs
merged_movistar_regulator_df[(merged_movistar_regulator_df$tech_2g_regulator == TRUE) | (merged_movistar_regulator_df$movistar_2g_regulator == TRUE)
                                 ,'tech_2g_regulator'] <- TRUE

merged_movistar_regulator_df[(merged_movistar_regulator_df$tech_3g_regulator == TRUE) | (merged_movistar_regulator_df$movistar_3g_regulator == TRUE)
                                 ,'tech_3g_regulator'] <- TRUE

merged_movistar_regulator_df[(merged_movistar_regulator_df$tech_4g_regulator == TRUE) | (merged_movistar_regulator_df$movistar_4g_regulator == TRUE)
                                 ,'tech_4g_regulator'] <- TRUE

#Having all the indirect coverage from Movistar:

merged_movistar_regulator_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Movistar','telco_id'])

merged_movistar_regulator_df <- merged_movistar_regulator_df[,c("settlement_id",
                                                                "tech_2g_regulator",
                                                                "tech_3g_regulator",
                                                                "tech_4g_regulator",
                                                                "operator_id")]


#############################################
## CLARO (25 min aprox)
claro_regulator_normalized_df <- claroRegulatorNormalized(schema_dev, table_settlements, schema, claro_atoll_table)

#Having all the indirect coverage from Claro:

claro_regulator_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Claro','telco_id'])


## TIGO
tigo_regulator_normalized_df <- tigoRegulatorNormalized(schema_dev, table_settlements, schema, tigo_atoll_table)

#Having all the indirect coverage from Movistar:

tigo_regulator_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Tigo','telco_id'])



#Merge with the rest of the data (regulator data)

regulator_normalized_df <- rbind(merged_movistar_regulator_df,claro_regulator_normalized_df,tigo_regulator_normalized_df)

regulator_normalized_df <- regulator_normalized_df[order(regulator_normalized_df$settlement_id,regulator_normalized_df$operator_id),]


### Indirect coverage ###
indirect_normalized_df <- indirectNormalized(schema_dev, table_settlements, indirect_polygons_table)

#Having all the indirect coverage from Movistar:

indirect_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Movistar','telco_id'])


#Merge with the rest of the data (regulator data)

merged_indirect_regulator_df <- merge(regulator_normalized_df,indirect_normalized_df, by.x=c('settlement_id','operator_id'), by.y=c('settlement_id','operator_id'), all.x=TRUE)


#For the rest of operators assume FALSE

merged_indirect_regulator_df[is.na(merged_indirect_regulator_df)]<-FALSE


### Facebook Coverage ###

#We create a table according to the geographic location of each settlement and the coverage area for each technology calculated and provided by Facebook.

facebook_normalized_df <- facebookNormalized(schema_dev, schema, table_settlements, facebook_polygons_tf_table_2g, facebook_polygons_tf_table_3g, facebook_polygons_tf_table_4g)

#Taking only Movistar coverage from the Facebook data

facebook_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Movistar','telco_id'])


#Merge with the rest of the data (regulator and infrastructure data)
merged_indirect_regulator_app_df <- merge(merged_indirect_regulator_df,facebook_normalized_df, by.x=c('settlement_id','operator_id'), by.y=c('settlement_id','operator_id'), all.x=TRUE)


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
names(coverage)<-'settlement_id'


operator_ids <- telco_list[(telco_list$telco_name %in% operator_names),'telco_id']
operator_ids <- as.array(operator_ids$telco_id)


for (i in 1:length(operator_ids))
{ 
  operator_df<-data.frame()
  operator_df <- merged_indirect_regulator_app_df[merged_indirect_regulator_app_df$operator_id == operator_ids[i],names(merged_indirect_regulator_app_df) !="operator_id"]
  coverage <- merge(coverage, operator_df, by='settlement_id')
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



#Add the competitors' information from the Facebook data
facebook_competitors_normalized_df <- fbCompetitorsNormalized(schema_dev, schema, table_settlements, facebook_competitors_polygons_2g, facebook_competitors_polygons_3g, facebook_competitors_polygons_4g)


#Merge with the rest of the data (regulator and infrastructure data)
coverage <- merge(coverage,facebook_competitors_normalized_df, by.x='settlement_id', by.y='settlement_id', all.x=TRUE)

# Add the corrected information from the competitors' data (ONLY REGULATOR DATA; NOT FACEBOOK)

coverage$competitors_2g_corrected <- FALSE
coverage[((coverage$claro_2g_corrected == TRUE) | (coverage$tigo_2g_corrected == TRUE)),'competitors_2g_corrected'] <- TRUE

coverage$competitors_3g_corrected <- FALSE
coverage[((coverage$claro_3g_corrected == TRUE) | (coverage$tigo_3g_corrected == TRUE)) ,'competitors_3g_corrected'] <- TRUE


coverage$competitors_4g_corrected <- FALSE
coverage[((coverage$claro_4g_corrected == TRUE) | (coverage$tigo_4g_corrected == TRUE)),'competitors_4g_corrected'] <- TRUE


coverage[is.na(coverage)]<-FALSE

### Export output to PostreSQL ###
exportNormalization(schema_dev, coverage_table, coverage)



