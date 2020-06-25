

library(RPostgreSQL)
library(plyr)
library(stringr)
library(readxl)
library(data.table)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_ar'
source(config_path)

#LOAD INPUTS
### Telcos ###

#List of all telcos with presence in LatAm

telco_list <- read_excel(paste0(coverage_input_path,coverage_file_name),sheet=coverage_sheet_name)

rm(coverage_file_name)
rm(coverage_sheet_name)

### Settlements ###

#List of all settlements registered in the country
source('~/shared/rural_planner/sql/ar/coverage/listSettlements.R')
settlements_list <- listSettlements(schema_dev, table_settlements)



### Indirect Coverage ###

#Create a PostgreSQL table with the coverage that provides each infrastructure with access from the country, from the datatable created in the infrastructure process, to calculate indirect coverage for each settlement. No need to import the table to the workspace because the subprocess will be writen in SQL launching the queries from the Rmd file.


# Clean previous data
source('~/shared/rural_planner/sql/truncateTable.R')
cleanData(schema_dev, indirect_polygons_table)


# AD-HOC: 3 rows since we have infrastrucutre from Telefonica, Claro, Personal

indirect_coverage_polygons_df <- as.data.frame(matrix(ncol=4,nrow=3))
names(indirect_coverage_polygons_df) <- c('operator','geom_2g','geom_3g','geom_4g')

indirect_coverage_polygons_df$operator <- c('Movistar','Claro','Personal')


source('~/shared/rural_planner/sql/ar/coverage/insertIndirectPolygons.R')
insertIndirectPolygons(schema_dev, indirect_polygons_table, infrastructure_table)


#### Hypothesis Coverage ###

#List of coverages from all telcos and all technologies by settlement
hypothesis_raw <- read_excel(paste0(coverage_input_path, coverage_file_name_2), sheet = 'Localidades Enacom', col_names = TRUE, skip = 0)[,c(2,14)]

colnames(hypothesis_raw) <- c("settlement_id",
                                       "scenario_3km")

#Clean data
hypothesis_raw$operator_id <- 'MOVISTAR'

hypothesis_raw$tech_2g_hypothesis <- FALSE
hypothesis_raw[grepl('2G',hypothesis_raw$scenario_3km),'tech_2g_hypothesis'] <- TRUE

hypothesis_raw$tech_3g_hypothesis <- FALSE
hypothesis_raw[grepl('3G',hypothesis_raw$scenario_3km),'tech_3g_hypothesis'] <- TRUE

hypothesis_raw$tech_4g_hypothesis <- FALSE
hypothesis_raw[grepl('4G',hypothesis_raw$scenario_3km),'tech_4g_hypothesis'] <- TRUE

hypothesis_raw[is.na(hypothesis_raw)] <- as.logical(FALSE)

hypothesis_raw <- hypothesis_raw[,c("settlement_id",
                                      "tech_2g_hypothesis",
                                      "tech_3g_hypothesis",
                                      "tech_4g_hypothesis",
                                   "operator_id")]

##Regulator coverage
regulator_raw <- read_excel(paste0(coverage_input_path, coverage_file_name_3))[,c(1:3,8:9)]

colnames(regulator_raw) <- c("admin_division_2_name",
                             "admin_division_1_name",
                             "settlement_name",
                                       "competitors_3g_regulator",
                                       "competitors_4g_regulator")


#Match settlemnt names with ids
source('~/shared/rural_planner/sql/ar/coverage/matchSettlementsIds.R')
settlements_info <- matchSettlementsIds(schema_dev, table_settlements)

regulator_raw$settlement_name <- toupper(regulator_raw$settlement_name)
regulator_raw$admin_division_1_name <- toupper(regulator_raw$admin_division_1_name)
regulator_raw$admin_division_2_name <- toupper(regulator_raw$admin_division_2_name)

regulator_raw$competitors_3g_regulator[regulator_raw$competitors_3g_regulator=="--"] <- 'FALSE'
regulator_raw$competitors_3g_regulator[regulator_raw$competitors_3g_regulator=="SI"] <- 'TRUE'
regulator_raw$competitors_4g_regulator[regulator_raw$competitors_4g_regulator=="--"] <- 'FALSE'
regulator_raw$competitors_4g_regulator[regulator_raw$competitors_4g_regulator=="SI"] <- 'TRUE'
regulator_raw$competitors_3g_regulator <- as.logical(regulator_raw$competitors_3g_regulator)
regulator_raw$competitors_4g_regulator <- as.logical(regulator_raw$competitors_4g_regulator)

regulator_raw <- merge(regulator_raw, settlements_info, by=c("settlement_name", "admin_division_1_name", "admin_division_2_name"), all.y=TRUE)

regulator_raw <- regulator_raw[!(is.na(regulator_raw$settlement_id)),]

regulator_raw[is.na(regulator_raw)] <- as.logical(FALSE)
regulator_raw$competitors_2g_regulator <- as.logical(FALSE)

regulator_raw <- regulator_raw[,c("settlement_id",
                                      "competitors_2g_regulator",
                                      "competitors_3g_regulator",
                                      "competitors_4g_regulator")]

#### Facebook Coverage ###

#Facebook coverage directly uploaded to PostgreSQL

#NORMALIZATION hypothesis RAW DATA

#Set operators available in the country

operator_names <- c('Movistar','Claro','Personal','Nextel')

#Set normalized names to the hypothesis raw dataframe

names_input_hypothesis_coverage <- c('settlement_id')
  for (i in (1:length(operator_names))){

      names_input_hypothesis_coverage <-  append(names_input_hypothesis_coverage,paste(tolower(telco_list$telco_id[telco_list$telco_name==operator_names[i]]),'2g',sep=" "))
      names_input_hypothesis_coverage <-  append(names_input_hypothesis_coverage,paste(tolower(telco_list$telco_id[telco_list$telco_name==operator_names[i]]),'3g',sep=" "))
      names_input_hypothesis_coverage <-  append(names_input_hypothesis_coverage,paste(tolower(telco_list$telco_id[telco_list$telco_name==operator_names[i]]),'4g',sep=" "))

  }



#Create hypothesis complete datatable

hypothesis_normalized_df <- data.frame( settlement_id=character(),
                                     operator_id=character(),
                                     tech_2g_hypothesis=logical(),
                                     tech_3g_hypothesis=logical(),
                                     tech_4g_hypothesis=logical(),
                                     stringsAsFactors=FALSE)

#Create separate dataframes for each operator with fixed columns: settlement_id, operator_id (according to operator name, from telco_list table), 2G, 3G, 4G; and join them in the main table

for (i in (1:length(operator_names))) {

    aux<- as.data.frame(settlements_list)
    names(aux) <- 'settlement_id'
    aux$operator_id <- as.character(telco_list[telco_list$telco_name == operator_names[i],'telco_id'])
    aux <- merge(aux, hypothesis_raw, by=c("settlement_id","operator_id"), all.x=T)
    hypothesis_normalized_df <- rbind(hypothesis_normalized_df,aux)
    rm(aux)
}

hypothesis_normalized_df[is.na(hypothesis_normalized_df)] <- FALSE
 hypothesis_normalized_df <- hypothesis_normalized_df[order(hypothesis_normalized_df$settlement_id,hypothesis_normalized_df$operator_id),]


### ATOLL coverage ###

#We create a table according to the geographic location of each settlement and the coverage area for each technology calculated from the infrastructure information.

source('~/shared/rural_planner/sql/ar/coverage/regulatorNormalized.R')
regulator_normalized_df <- regulatorNormalized(schema_dev, table_settlements, table_atoll)

merged_regulator_hypothesis_df <- merge(regulator_normalized_df,hypothesis_normalized_df, by.x=c('settlement_id','operator_id'), by.y=c('settlement_id','operator_id'), all=TRUE)


#For the rest of operators assume FALSE

merged_regulator_hypothesis_df[is.na(merged_regulator_hypothesis_df)]<-FALSE


### Indirect coverage ###

#We create a table according to the geographic location of each settlement and the coverage area for each technology calculated from the infrastructure information.
source('~/shared/rural_planner/sql/ar/coverage/indirectNormalized.R')
indirect_normalized_df <- indirectNormalized(schema_dev, table_settlements, indirect_polygons_table)

#Merge with the rest of the data (regulator data)

merged_indirect_regulator_hypothesis_df <- merge(merged_regulator_hypothesis_df,indirect_normalized_df, by.x=c('settlement_id','operator_id'), by.y=c('settlement_id','operator_id'), all=TRUE)


#For the rest of operators assume FALSE

merged_indirect_regulator_hypothesis_df[is.na(merged_indirect_regulator_hypothesis_df)]<-FALSE

### Facebook Coverage ###

#We create a table according to the geographic location of each settlement and the coverage area for each technology calculated and provided by Facebook.

#Establish connection with database
source('~/shared/rural_planner/sql/ar/coverage/facebookNormalized.R')
facebook_normalized_df <- facebookNormalized(schema_dev, table_settlements, schema, facebook_polygons_tf_table_2g, facebook_polygons_tf_table_3g, facebook_polygons_tf_table_4g)


#Taking only Movistar coverage from the Facebook data

facebook_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Movistar','telco_id'])


#Merge with the rest of the data (regulator and infrastructure data)
merged_indirect_regulator_app_hypothesis_df <- merge(merged_indirect_regulator_hypothesis_df,facebook_normalized_df, by.x=c('settlement_id','operator_id'), by.y=c('settlement_id','operator_id'), all=TRUE)


#For the rest of operators assume FALSE

merged_indirect_regulator_app_hypothesis_df[is.na(merged_indirect_regulator_app_hypothesis_df)]<-FALSE


#Define corrected fields: if any of the sources (regulator, infrastructure or Facebook) indicates that there is coverage in a settlement for a given technology, the corrected field for this technology is TRUE.
### ONLY HYPOTHESIS

merged_indirect_regulator_app_hypothesis_df$tech_2g_corrected <- FALSE
merged_indirect_regulator_app_hypothesis_df[((merged_indirect_regulator_app_hypothesis_df$tech_2g_hypothesis == 'TRUE') | (merged_indirect_regulator_app_hypothesis_df$tech_2g_regulator == 'TRUE') | (merged_indirect_regulator_app_hypothesis_df$tech_2g_indirect == 'TRUE')),'tech_2g_corrected'] <- TRUE

merged_indirect_regulator_app_hypothesis_df$tech_3g_corrected <- FALSE
merged_indirect_regulator_app_hypothesis_df[((merged_indirect_regulator_app_hypothesis_df$tech_3g_hypothesis == 'TRUE') | (merged_indirect_regulator_app_hypothesis_df$tech_3g_regulator == 'TRUE') | (merged_indirect_regulator_app_hypothesis_df$tech_3g_indirect == 'TRUE')),'tech_3g_corrected'] <- TRUE

merged_indirect_regulator_app_hypothesis_df$tech_4g_corrected <- FALSE
merged_indirect_regulator_app_hypothesis_df[((merged_indirect_regulator_app_hypothesis_df$tech_4g_hypothesis == 'TRUE') | (merged_indirect_regulator_app_hypothesis_df$tech_4g_regulator == 'TRUE') | (merged_indirect_regulator_app_hypothesis_df$tech_4g_indirect == 'TRUE')),'tech_4g_corrected'] <- TRUE

### Creation output dataframe ###

#"COLUMNIZE". Transform the master table into one with one row per settlement and personalized columns for each operator

coverage <- data.frame()
coverage<- settlements_list
names(coverage)<-'settlement_id'


operator_ids <- telco_list[(telco_list$telco_name %in% operator_names),'telco_id']
operator_ids <- as.array(operator_ids$telco_id)


data_categories <- c('regulator','indirect','app','hypothesis','corrected')


for (i in 1:length(operator_ids)) { 
  operator_df<-data.frame()
  operator_df <- merged_indirect_regulator_app_hypothesis_df[merged_indirect_regulator_app_hypothesis_df$operator_id == operator_ids[i],names(merged_indirect_regulator_app_hypothesis_df) !="operator_id"]
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


#Add the competitors' information from the Facebook data (analyzing the coverage polygons from all operators)

source('~/shared/rural_planner/sql/ar/coverage/facebookAllNormalized.R')
facebook_all_normalized_df <- facebookAllNormalized(schema_dev, table_settlements, schema, facebook_competitors_polygons_2g, facebook_competitors_polygons_3g, facebook_competitors_polygons_4g)


#Merge with the rest of the data (regulator and infrastructure data)

coverage <- merge(coverage,facebook_all_normalized_df,by.x='settlement_id', by.y='settlement_id', all.x=TRUE) 

coverage <- merge(coverage, regulator_raw, by.x='settlement_id', by.y='settlement_id', all.x=TRUE)

coverage[is.na(coverage)] <-FALSE

# Add the corrected information from the competitors' data

coverage$competitors_2g_corrected <- FALSE
coverage[(coverage$personal_2g_indirect == 'TRUE') | (coverage$nextel_2g_indirect == 'TRUE') | (coverage$claro_2g_indirect == 'TRUE') | (coverage$competitors_2g_app == 'TRUE') | (coverage$competitors_2g_regulator == 'TRUE') ,'competitors_2g_corrected'] <- TRUE

coverage$competitors_3g_corrected <- FALSE
coverage[(coverage$personal_3g_indirect == 'TRUE') | (coverage$nextel_4g_indirect == 'TRUE') | (coverage$claro_3g_indirect == 'TRUE') | (coverage$competitors_3g_app == 'TRUE') | (coverage$competitors_3g_regulator == 'TRUE') ,'competitors_3g_corrected'] <- TRUE


coverage$competitors_4g_corrected <- FALSE
coverage[(coverage$personal_4g_indirect == 'TRUE') | (coverage$nextel_4g_indirect == 'TRUE') | (coverage$claro_4g_indirect == 'TRUE') | (coverage$competitors_4g_app == 'TRUE') | (coverage$competitors_4g_regulator == 'TRUE') ,'competitors_4g_corrected'] <- TRUE


dbDisconnect(con)


### Export output to PostreSQL ###

#Establish connection
source('~/shared/rural_planner/sql/ar/coverage/exportCoverage.R')
exportCoverage(schema_dev, table_coverage, coverage)



