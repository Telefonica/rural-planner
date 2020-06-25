
```{r setup, include=FALSE}
#LIBRARIES
library(RPostgreSQL)
library(plyr)
library(tidyverse)
library(stringr)
library(readxl)
library(data.table)

#DB Connection parameters
config_path <- '~/shared/rural_planner_r/config_files/config_pe'
source(config_path)

operator_names<-c('Movistar','Claro','Entel','Bitel')
source('~/shared/rural_planner_r/sql/pe/coverage/listSettlements.R')
source('~/shared/rural_planner_r/sql/dropTable.R')
source('~/shared/rural_planner_r/sql/pe/coverage/indirectCoverage.R')
source('~/shared/rural_planner_r/sql/pe/coverage/indirectCoverageClaro.R')
source('~/shared/rural_planner_r/sql/pe/coverage/indirectNormalized.R')
source('~/shared/rural_planner_r/sql/pe/coverage/facebookNormalized.R')
source('~/shared/rural_planner_r/sql/pe/coverage/facebookCompetitorsNormalized.R')
source('~/shared/rural_planner_r/sql/exportNormalization.R')
```

```{r load_inputs}
#LOAD INPUTS

### Telcos ###
telco_list <- read_excel(paste0(coverage_input_path,coverage_file_name),sheet=coverage_sheet_name)

rm(coverage_file_name)
rm(coverage_sheet_name)

### Settlements ###

#List of all settlements registered in the country
settlements_list <- listSettlements(schema_dev, table_settlements)

### Indirect Coverage ###

#Create a PostgreSQL table with the coverage that provides each infrastructure with access from the country, from the datatable created in the infrastructure process, to calculate indirect coverage for each settlement. No need to import the table to the workspace because the subprocess will be writen in SQL launching the queries from the Rmd file.


# Clean previous data
dropTable(schema_dev, indirect_polygons_table)


indirectPolygons(schema_dev, indirect_polygons_table, infrastructure_table)


#### Claro coverage polygons
dropTable(schema_dev, claro_indirect_polygons_table)

indirectPolygonsClaro(schema_dev, claro_indirect_polygons_table, infrastructure_table)

#### Reported Coverage ###

#List of coverages from all telcos and all technologies by settlement, provided by national telco regulatory agency
regulator_raw_movistar <- read_excel(paste0(coverage_input_path, coverage_file_name_2), sheet = 'Movistar 1T2018', col_names = TRUE, skip = 2)[,c(2,12:21)]

regulator_raw_claro <- read_excel(paste0(coverage_input_path, coverage_file_name_2), sheet = 'Claro 1T2018', col_names = TRUE, skip = 2)[,c(2,12:21)]

regulator_raw_entel <- read_excel(paste0(coverage_input_path, coverage_file_name_2), sheet = 'Bitel 1T2018', col_names = TRUE, skip = 2)[,c(2,12:21)]

regulator_raw_bitel <- read_excel(paste0(coverage_input_path, coverage_file_name_2), sheet = 'Entel 1T2018', col_names = TRUE, skip = 2)[,c(2,12:21)]

#Set values to TRUE and FALSE

regulator_raw_movistar[regulator_raw_movistar == "X"] <- as.logical(TRUE)
regulator_raw_movistar[regulator_raw_movistar == "FALSE"] <- as.logical(FALSE)
regulator_raw_movistar[regulator_raw_movistar == "TRUE"] <- as.logical(TRUE)
regulator_raw_movistar[is.na(regulator_raw_movistar)] <- as.logical(FALSE)
regulator_raw_movistar$operator_id <- 'MOVISTAR'

regulator_raw_movistar$tech_2g_regulator <- FALSE
regulator_raw_movistar[(regulator_raw_movistar$GSM == 'TRUE') | (regulator_raw_movistar$GPRS == 'TRUE') | (regulator_raw_movistar$EDGE == 'TRUE'),'tech_2g_regulator'] <- TRUE

regulator_raw_movistar$tech_3g_regulator <- FALSE
regulator_raw_movistar[(regulator_raw_movistar$UMTS == 'TRUE') | (regulator_raw_movistar$HSDPA == 'TRUE') | (regulator_raw_movistar$HSUPA == 'TRUE') | (regulator_raw_movistar$`HSPA+` == 'TRUE'),'tech_3g_regulator'] <- TRUE

regulator_raw_movistar$tech_4g_regulator <- FALSE
regulator_raw_movistar[(regulator_raw_movistar$WIMAX == 'TRUE') | (regulator_raw_movistar$IDEN == 'TRUE') | (regulator_raw_movistar$LTE == 'TRUE'),'tech_4g_regulator'] <- TRUE

regulator_raw_movistar <- regulator_raw_movistar[,c(1,13:15,12)]
colnames(regulator_raw_movistar) <- c("settlement_id",
                                      "tech_2g_regulator",
                                      "tech_3g_regulator",
                                      "tech_4g_regulator",
                                   "operator_id")

regulator_raw_claro[regulator_raw_claro == "X"] <- TRUE
regulator_raw_claro[regulator_raw_claro == "FALSE"] <- FALSE
regulator_raw_claro[is.na(regulator_raw_claro)] <- FALSE
regulator_raw_claro$operator_id <- 'CLARO'

regulator_raw_claro$tech_2g_regulator <- FALSE
regulator_raw_claro[(regulator_raw_claro$GSM == 'TRUE') | (regulator_raw_claro$GPRS == 'TRUE') | (regulator_raw_claro$EDGE == 'TRUE'),'tech_2g_regulator'] <- TRUE

regulator_raw_claro$tech_3g_regulator <- FALSE
regulator_raw_claro[(regulator_raw_claro$UMTS == 'TRUE') | (regulator_raw_claro$HSDPA == 'TRUE') | (regulator_raw_claro$HSUPA == 'TRUE') | (regulator_raw_claro$`HSPA+` == 'TRUE'),'tech_3g_regulator'] <- TRUE

regulator_raw_claro$tech_4g_regulator <- FALSE
regulator_raw_claro[(regulator_raw_claro$WIMAX == 'TRUE') | (regulator_raw_claro$IDEN == 'TRUE') | (regulator_raw_claro$LTE == 'TRUE'),'tech_4g_regulator'] <- TRUE

regulator_raw_claro <- regulator_raw_claro[,c(1,13:15,12)]
colnames(regulator_raw_claro) <- c("settlement_id",
                                      "tech_2g_regulator",
                                      "tech_3g_regulator",
                                      "tech_4g_regulator",
                                   "operator_id")

regulator_raw_entel[regulator_raw_entel == "X"] <- TRUE
regulator_raw_entel[regulator_raw_entel == "FALSE"] <- FALSE
regulator_raw_entel[is.na(regulator_raw_entel)] <- FALSE
regulator_raw_entel$operator_id <- 'ENTEL'


regulator_raw_entel$tech_2g_regulator <- FALSE
regulator_raw_entel[(regulator_raw_entel$GSM == 'TRUE') | (regulator_raw_entel$GPRS == 'TRUE') | (regulator_raw_entel$EDGE == 'TRUE'),'tech_2g_regulator'] <- TRUE

regulator_raw_entel$tech_3g_regulator <- FALSE
regulator_raw_entel[(regulator_raw_entel$UMTS == 'TRUE') | (regulator_raw_entel$HSDPA == 'TRUE') | (regulator_raw_entel$HSUPA == 'TRUE') | (regulator_raw_entel$`HSPA+` == 'TRUE'),'tech_3g_regulator'] <- TRUE

regulator_raw_entel$tech_4g_regulator <- FALSE
regulator_raw_entel[(regulator_raw_entel$WIMAX == 'TRUE') | (regulator_raw_entel$IDEN == 'TRUE') | (regulator_raw_entel$LTE == 'TRUE'),'tech_4g_regulator'] <- TRUE

regulator_raw_entel <- regulator_raw_entel[,c(1,13:15,12)]
colnames(regulator_raw_entel) <- c("settlement_id",
                                      "tech_2g_regulator",
                                      "tech_3g_regulator",
                                      "tech_4g_regulator",
                                   "operator_id")

regulator_raw_bitel[regulator_raw_bitel == "X"] <- TRUE
regulator_raw_bitel[regulator_raw_bitel == "FALSE"] <- FALSE
regulator_raw_bitel[is.na(regulator_raw_bitel)] <- FALSE
regulator_raw_bitel$operator_id <- 'BITEL'

regulator_raw_bitel$tech_2g_regulator <- FALSE
regulator_raw_bitel[(regulator_raw_bitel$GSM == 'TRUE') | (regulator_raw_bitel$GPRS == 'TRUE') | (regulator_raw_bitel$EDGE == 'TRUE'),'tech_2g_regulator'] <- TRUE

regulator_raw_bitel$tech_3g_regulator <- FALSE
regulator_raw_bitel[(regulator_raw_bitel$UMTS == 'TRUE') | (regulator_raw_bitel$HSDPA == 'TRUE') | (regulator_raw_bitel$HSUPA == 'TRUE') | (regulator_raw_bitel$`HSPA+` == 'TRUE'),'tech_3g_regulator'] <- TRUE

regulator_raw_bitel$tech_4g_regulator <- FALSE
regulator_raw_bitel[(regulator_raw_bitel$WIMAX == 'TRUE') | (regulator_raw_bitel$IDEN == 'TRUE') | (regulator_raw_bitel$LTE == 'TRUE'),'tech_4g_regulator'] <- TRUE

regulator_raw_bitel <- regulator_raw_bitel[,c(1,13:15,12)]
colnames(regulator_raw_bitel) <- c("settlement_id",
                                      "tech_2g_regulator",
                                      "tech_3g_regulator",
                                      "tech_4g_regulator",
                                   "operator_id")


#### Facebook Coverage ###

#Input imported directly to PostgreSQL database.

```

```{r regulator_coverage}

#NORMALIZATION REGULATOR RAW DATA

#Set operators available in the country

regulator_movistar <- merge(settlements_list,regulator_raw_movistar,by.x="settlement_id", by.y="settlement_id", all.x=TRUE)
regulator_movistar$operator_id <- 'MOVISTAR'
regulator_entel <- merge(settlements_list,regulator_raw_entel,by.x="settlement_id", by.y="settlement_id", all.x=TRUE)
regulator_entel$operator_id <- 'ENTEL'
regulator_bitel <- merge(settlements_list,regulator_raw_bitel,by.x="settlement_id", by.y="settlement_id", all.x=TRUE)
regulator_bitel$operator_id <- 'BITEL'
regulator_claro <-  merge(settlements_list,regulator_raw_claro,by.x="settlement_id", by.y="settlement_id", all.x=TRUE)
regulator_claro$operator_id <- 'CLARO'  

regulator_normalized_df <- rbind(regulator_movistar,regulator_bitel, regulator_entel, regulator_claro)

regulator_normalized_df[order(regulator_normalized_df$settlement_id,regulator_normalized_df$operator_id),]

```

```{r indirect_coverage}

### Indirect coverage ###

#We create a table according to the geographic location of each settlement and the coverage area for each technology calculated from the infrastructure information.
indirect_normalized_df <- indirectCoverage(schema_dev, table_settlements, indirect_polygons_table)

#Having all the indirect coverage from Movistar:

indirect_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Movistar','telco_id'])

#Indirect coverage Claro
claro_indirect_normalized_df <- indirectCoverage(schema_dev, table_settlements, claro_indirect_polygons_table)

claro_indirect_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Claro','telco_id'])

#Merge Claro and Movistar indirect df
indirect_normalized_df <- rbind(claro_indirect_normalized_df,indirect_normalized_df)

#Merge with the rest of the data (regulator data)

merged_indirect_regulator_df <- merge(regulator_normalized_df,indirect_normalized_df, by.x=c('settlement_id','operator_id'), by.y=c('settlement_id','operator_id'), all.x=TRUE)

#For the rest of operators assume FALSE

merged_indirect_regulator_df[is.na(merged_indirect_regulator_df)]<-FALSE

```

```{r facebook_coverage}
### Facebook Coverage ###

#We create a table according to the geographic location of each settlement and the coverage area for each technology calculated and provided by Facebook.
facebook_normalized_df <- facebookNormalized(schema_dev, table_settlements, schema, facebook_polygons_tf_table_2g, facebook_polygons_tf_table_3g, facebook_polygons_tf_table_4g)


#Taking only Movistar coverage from the Facebook data

facebook_normalized_df$operator_id <- as.character(telco_list[telco_list$telco_name == 'Movistar','telco_id'])


#Merge with the rest of the data (regulator and infrastructure data)
merged_indirect_regulator_app_df <- merge(merged_indirect_regulator_df,facebook_normalized_df, by.x=c('settlement_id','operator_id'), by.y=c('settlement_id','operator_id'), all.x=TRUE)


#For the rest of operators assume FALSE

merged_indirect_regulator_app_df[is.na(merged_indirect_regulator_app_df)]<-FALSE


```

```{r corrected_coverage}

#Define corrected fields: if any of the sources (regulator, infrastructure or Facebook) indicates that there is coverage in a settlement for a given technology, the corrected field for this technology is TRUE.

merged_indirect_regulator_app_df$tech_2g_corrected <- FALSE
merged_indirect_regulator_app_df[(merged_indirect_regulator_app_df$tech_2g_regulator == TRUE) | (merged_indirect_regulator_app_df$tech_2g_indirect == TRUE) | (merged_indirect_regulator_app_df$tech_2g_app == TRUE),'tech_2g_corrected'] <- TRUE

merged_indirect_regulator_app_df$tech_3g_corrected <- FALSE
merged_indirect_regulator_app_df[(merged_indirect_regulator_app_df$tech_3g_regulator == TRUE) | (merged_indirect_regulator_app_df$tech_3g_indirect == TRUE) | (merged_indirect_regulator_app_df$tech_3g_app == TRUE),'tech_3g_corrected'] <- TRUE

merged_indirect_regulator_app_df$tech_4g_corrected <- FALSE
merged_indirect_regulator_app_df[(merged_indirect_regulator_app_df$tech_4g_regulator == TRUE) | (merged_indirect_regulator_app_df$tech_4g_indirect == TRUE) | (merged_indirect_regulator_app_df$tech_4g_app == TRUE),'tech_4g_corrected'] <- TRUE

```

```{r output}

### Creation output dataframe ###

#"COLUMNIZE". Transform the master table into one with one row per settlement and personalized columns for each operator

coverage <- data.frame()
coverage <- settlements_list
names(coverage)<-'settlement_id'


operator_ids <- telco_list[(telco_list$telco_name %in% operator_names),'telco_id']
operator_ids <- as.array(operator_ids$telco_id)


data_categories <- c('regulator','indirect','app','corrected')


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


```

```{r competitors information}

#Add the competitors' information from the Facebook data
facebook_competitors_normalized_df <- facebookCompetitorsNormalized(schema_dev, table_settlements, schema, facebook_competitors_polygons_2g, facebook_competitors_polygons_3g, facebook_competitors_polygons_4g)


#Merge with the rest of the data (regulator and infrastructure data)
coverage <- merge(coverage,facebook_competitors_normalized_df, by.x='settlement_id', by.y='settlement_id', all.x=TRUE)

# Add the corrected information from the competitors' data

coverage$competitors_2g_corrected <- FALSE
coverage[(coverage$bitel_2g_regulator == 'TRUE') | (coverage$entel_2g_regulator == 'TRUE') | (coverage$claro_2g_regulator == 'TRUE') | (coverage$competitors_2g_app == 'TRUE') | (coverage$claro_2g_indirect == 'TRUE') ,'competitors_2g_corrected'] <- TRUE

coverage$competitors_3g_corrected <- FALSE
coverage[(coverage$bitel_3g_regulator == 'TRUE') | (coverage$entel_3g_regulator == 'TRUE') | (coverage$claro_3g_regulator == 'TRUE') | (coverage$competitors_3g_app == 'TRUE') | (coverage$claro_3g_indirect == 'TRUE'),'competitors_3g_corrected'] <- TRUE


coverage$competitors_4g_corrected <- FALSE
coverage[(coverage$bitel_4g_regulator == 'TRUE') | (coverage$entel_4g_regulator == 'TRUE') | (coverage$claro_4g_regulator == 'TRUE') | (coverage$competitors_4g_app == 'TRUE') | (coverage$claro_4g_indirect == 'TRUE') ,'competitors_4g_corrected'] <- TRUE

```

```{r export}

### Export output to PostreSQL ###
exportNormalization(schema_dev, table_coverage, coverage)

```