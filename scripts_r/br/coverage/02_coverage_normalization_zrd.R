
library(RPostgreSQL)
library(plyr)
library(stringr)
library(readxl)
library(data.table)
library(rgdal)
library(rpostgis)
library(XML)

#DB Connection parameters
config_path <- '~/shared/rural_planner_r/config_files/config_br'
source(config_path)

#List of all settlements registered in the country
operator_names <- c('Vivo', 'Claro', 'Oi Móvil', 'TIM')

source('~/shared/rural_planner_r/sql/br/coverage/normalizationMovistar.R')
source('~/shared/rural_planner_r/sql/br/coverage/normalizationCompetitors.R')
source('~/shared/rural_planner_r/sql/br/coverage/withoutMunicipalityVivo.R')
source('~/shared/rural_planner_r/sql/br/coverage/withoutMunicipalityCompetitors.R')
source('~/shared/rural_planner_r/sql/br/coverage/indirectCoverage.R')
source('~/shared/rural_planner_r/sql/br/coverage/facebookCoverage.R')
source('~/shared/rural_planner_r/sql/br/coverage/facebookCompetitorsCoverage.R')
source('~/shared/rural_planner_r/sql/exportNormalization.R')
source('~/shared/rural_planner_r/sql/br/coverage/listSettlements.R')

table_zrd <- 'settlements_zrd_aux'

#### Reported Coverage ###

##Uploaded to DB in previous process

### Indirect Coverage ###

#Create a PostgreSQL table with the coverage that provides each Telefonica infrastructure with access from the country, from the datatable created in the infrastructure process, to calculate indirect coverage for each settlement. No need to import the table to the workspace because the subprocess will be writen in SQL launching the queries from the Rmd file.


##Uploaded to DB in previous process


### Settlements ###

#List of all settlements registered in the country
settlements_list <- listSettlements(schema_dev,table_zrd)
municipalities_list <- listMunicipalities(schema_dev,table_zrd)
municipalities_list <- as.array(municipalities_list$admin_division_2_id[!(is.na(municipalities_list$admin_division_2_id))])

#### Facebook Coverage ###

#Imput imported directly to PostgreSQL database.


#NORMALIZATION REGULATOR RAW DATA
### Reported coverage ###

movistar_regulator_normalized_df <- data.frame()
claro_regulator_normalized_df <- data.frame()
tim_regulator_normalized_df <- data.frame()
oi_regulator_normalized_df <- data.frame()

for (i in c(1:length(municipalities_list))){

        print(paste0("Processing municipality ",municipalities_list[i]," , ", i, "/", length(municipalities_list)))
        
        # MOVISTAR
        aux_df <-  normalizationMovistar(schema_dev, table_zrd, municipalities_list[i], movistar_polygons_table)
        movistar_regulator_normalized_df <- rbind(movistar_regulator_normalized_df, aux_df)
        rm(aux_df)
        
        ## CLARO
        aux_df <-  normalizationCompetitors(schema_dev, table_zrd, competitors_polygons_table, municipalities_list[i], 'CLARO')
        claro_regulator_normalized_df <- rbind(claro_regulator_normalized_df, aux_df)
        rm(aux_df)


        ## OI
        aux_df <-  normalizationCompetitors(schema_dev, table_zrd, competitors_polygons_table, municipalities_list[i], 'OI')
        oi_regulator_normalized_df <- rbind(oi_regulator_normalized_df, aux_df)
        rm(aux_df)
        
        
        ## TIM
        aux_df <- normalizationCompetitors(schema_dev, table_zrd, competitors_polygons_table, municipalities_list[i], 'TIM')
        tim_regulator_normalized_df <- rbind(tim_regulator_normalized_df, aux_df)
        rm(aux_df)
        
}



#### Settlements without admin_divison_2_id

## MOVISTAR
aux_df <- withoutMunicipalityVivo(schema_dev, table_zrd, movistar_polygons_table)
movistar_regulator_normalized_df <- rbind(movistar_regulator_normalized_df, aux_df)
rm(aux_df)

## CLARO
aux_df <- withoutMunicipalityCompetitors(schema_dev, table_zrd, competitors_polygons_table, 'CLARO')
claro_regulator_normalized_df <- rbind(claro_regulator_normalized_df, aux_df)
rm(aux_df)

## OI
aux_df <- withoutMunicipalityCompetitors(schema_dev, table_zrd, competitors_polygons_table, 'OI')
oi_regulator_normalized_df <- rbind(oi_regulator_normalized_df, aux_df)
rm(aux_df)


## TIM
aux_df <- withoutMunicipalityCompetitors(schema_dev, table_zrd, competitors_polygons_table, 'TIM')
tim_regulator_normalized_df <- rbind(tim_regulator_normalized_df, aux_df)
rm(aux_df)


movistar_regulator_normalized_df$operator_id <- as.character("VIVO")
tim_regulator_normalized_df$operator_id <- as.character("TIM")
oi_regulator_normalized_df$operator_id <- as.character("OI")
claro_regulator_normalized_df$operator_id <- as.character("CLARO")

#We create a table according to the geographic location of each settlement and the coverage area for each technology from the print reported to the regulator.

#Merge with the rest of the data (regulator data)

regulator_normalized_df <- rbind(movistar_regulator_normalized_df,claro_regulator_normalized_df,oi_regulator_normalized_df, tim_regulator_normalized_df)

### Indirect coverage ###

#We create a table according to the geographic location of each settlement and the coverage area for each technology calculated from the infrastructure information.

##VIVO
vivo_indirect_normalized_df <-  indirectCoverage(schema_dev,table_zrd, indirect_polygons_table, 'VIVO')

##OI
oi_indirect_normalized_df <- indirectCoverage(schema_dev,table_zrd, indirect_polygons_table, 'OI')

##CLARO
claro_indirect_normalized_df <- indirectCoverage(schema_dev,table_zrd, indirect_polygons_table, 'CLARO')

##TIM
tim_indirect_normalized_df <- indirectCoverage(schema_dev,table_zrd, indirect_polygons_table, 'TIM')

#Set operators:
vivo_indirect_normalized_df$operator_id <- as.character("VIVO")
oi_indirect_normalized_df$operator_id <- as.character("OI")
claro_indirect_normalized_df$operator_id <- as.character("CLARO")
tim_indirect_normalized_df$operator_id <- as.character("TIM")


##Merge all operators
indirect_normalized_df <- rbind(vivo_indirect_normalized_df, claro_indirect_normalized_df, oi_indirect_normalized_df, tim_indirect_normalized_df)

#Merge with the rest of the data (regulator data)
merged_indirect_regulator_df <- merge(regulator_normalized_df,indirect_normalized_df, by.x=c('settlement_id','operator_id'), by.y=c('settlement_id','operator_id'), all.x=TRUE)

 
#For the rest of operators assume FALSE
merged_indirect_regulator_df[is.na(merged_indirect_regulator_df)]<-FALSE


### Facebook Coverage ###

#We create a table according to the geographic location of each settlement and the coverage area for each technology calculated and provided by Facebook.
facebook_normalized_df <- facebookCoverage(schema_dev, table_zrd, schema, facebook_polygons_tf_table_2g, facebook_polygons_tf_table_3g, facebook_polygons_tf_table_4g)

#Taking only Movistar coverage from the Facebook data
facebook_normalized_df$operator_id <- as.character("VIVO")


#Merge with the rest of the data (regulator and infrastructure data)
merged_indirect_regulator_app_df <- merge(merged_indirect_regulator_df,facebook_normalized_df, by.x=c('settlement_id','operator_id'), by.y=c('settlement_id','operator_id'), all.x=TRUE)


#For the rest of operators assume FALSE
merged_indirect_regulator_app_df[is.na(merged_indirect_regulator_app_df)]<-FALSE



#Define corrected fields: if any of the sources (regulator or infrastructure) indicates that there is coverage in a settlement for a given technology, the corrected field for this technology is TRUE.

merged_indirect_regulator_app_df$tech_2g_corrected <- FALSE
merged_indirect_regulator_app_df[(merged_indirect_regulator_app_df$tech_2g_regulator == TRUE) | (merged_indirect_regulator_app_df$tech_2g_indirect == TRUE) | (merged_indirect_regulator_app_df$tech_2g_app == TRUE)
                                 ,'tech_2g_corrected'] <- TRUE

merged_indirect_regulator_app_df$tech_3g_corrected <- FALSE
merged_indirect_regulator_app_df[(merged_indirect_regulator_app_df$tech_3g_regulator == TRUE) | (merged_indirect_regulator_app_df$tech_3g_indirect == TRUE) | (merged_indirect_regulator_app_df$tech_3g_app == TRUE)
                                 ,'tech_3g_corrected'] <- TRUE


merged_indirect_regulator_app_df$tech_4g_corrected <- FALSE
merged_indirect_regulator_app_df[(merged_indirect_regulator_app_df$tech_4g_regulator == TRUE) | (merged_indirect_regulator_app_df$tech_4g_indirect == TRUE) | (merged_indirect_regulator_app_df$tech_4g_app == TRUE)
                                 ,'tech_4g_corrected'] <- TRUE


### Creation output dataframe ###

#"COLUMNIZE". Transform the master table into one with one row per settlement and personalized columns for each operator

coverage <- data.frame()
coverage<- settlements_list
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



#Add the competitors' information from the Facebook data
facebook_competitors_normalized_df <- facebookCompetitorsCoverage(schema_dev, table_zrd, schema, facebook_competitors_polygons_2g, facebook_competitors_polygons_3g, facebook_competitors_polygons_4g)


#Merge with the rest of the data (regulator and infrastructure data)
coverage <- merge(coverage,facebook_competitors_normalized_df, by.x='settlement_id', by.y='settlement_id', all.x=TRUE)

# Add the corrected information from the competitors' data

coverage$competitors_2g_corrected <- FALSE
coverage[((coverage$oi_2g_regulator == TRUE) | (coverage$tim_2g_regulator == TRUE) | (coverage$claro_2g_regulator == TRUE) | (coverage$competitors_2g_app == TRUE)),'competitors_2g_corrected'] <- TRUE

coverage$competitors_3g_corrected <- FALSE
coverage[((coverage$oi_3g_regulator == TRUE) | (coverage$tim_3g_regulator == TRUE) | (coverage$claro_3g_regulator == TRUE) | (coverage$competitors_3g_app == TRUE)),'competitors_3g_corrected'] <- TRUE


coverage$competitors_4g_corrected <- FALSE
coverage[((coverage$oi_4g_regulator == TRUE) | (coverage$tim_4g_regulator == TRUE) | (coverage$claro_4g_regulator == TRUE) | (coverage$competitors_4g_app == TRUE)),'competitors_4g_corrected'] <- TRUE


coverage[is.na(coverage)]<-FALSE


### Export output to PostreSQL ###

#Replace existing old data and cast columns to boolean type

exportNormalization(schema_dev, table_coverage_zrd, coverage)




