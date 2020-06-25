
#LIBRARIES
library(RPostgreSQL)
library(rpostgis)
library(tidyverse)
library(stringr)
library(scales)
library(readxl)
library(xlsx)
library(stringi)


#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)

#VARIABLES

excel_path <- paste(input_path_demography, file_name_demography_kpis, sep='/')
sheet_name_osiptel <- "kpi incidencias tdp"


source('~/shared/rural_planner/sql/pe/demography/exportSettlementsDevelopment.R')


#Load and collect data that we already have
aux_df_a <-read.csv2(paste(input_path_demography,kpisA, sep = "/"), stringsAsFactors=F) 
aux_df_a<-aux_df_a[,c(1,5:10,15:24,25:29,12:14)]

aux_df_b<-read.csv2(paste(input_path_demography,kpisB, sep = "/"), stringsAsFactors=F)
aux_df_b<-aux_df_b[,c('ubigeo','orografia','pbi_2011')]

aux_df_c<-read.csv2(paste(input_path_demography,kpisC, sep = "/"), stringsAsFactors=F, fileEncoding = "latin1")
aux_df_c<-aux_df_c[,c('UBIGEO','NOMCCPP','NOMB_CAT','CLASIF_CCPP','NOMB_DEP')]

#Normalize settlement ids
aux_df_a$Ubigeo<-str_pad(aux_df_a$Ubigeo,6,"left",pad=0)
aux_df_b$ubigeo<-str_pad(aux_df_b$ubigeo,10,"left",pad=0)
aux_df_c$UBIGEO<-str_pad(aux_df_c$UBIGEO,10,"left",pad=0)

aux_df_1<-merge(aux_df_b,aux_df_c,by.x="ubigeo", by.y="UBIGEO", all=TRUE)
aux_df_1$admin_division_1_id<-str_sub(aux_df_1$ubigeo,1,6)
settlements_development_data<-merge(aux_df_1,aux_df_a,by.x="admin_division_1_id", by.y="Ubigeo", all.x=TRUE)

#Set the desired names to the dataframe columns

dev_names<-c('admin_division_1_id',
             'settlement_id',
             'orography',
             'gdp_latest',
             'settlement_name',
             'category',
             'classification',
             'admin_division_3_name',
             'edu_no_education',
             'edu_initial_education',
             'edu_primary_education',
             'edu_secondary_education',
             'edu_higher_non_universitary_education',
             'edu_higher_universitary_education',
             'occupation_public_sector_employments',
             'occupation_academia',
             'occupation_mid_level_technicians',
             'occupation_office',
             'occupation_commerce',
             'occupation_agriculture_fishing',
             'mining_employments',
             'occupation_construction',
             'occupation_non_qualified',
             'occupation_others',
             'households_with_water',
             'public_lighting',
             'sanitary_facilities',
             'homes_without_telecom',
             'homes_without_technology',
             'eap_employed',
             'eap_unemployed',
             'eap_non_active')

names(settlements_development_data)<-dev_names

#Parse to desired format

settlements_development_data$settlement_id <- as.character(settlements_development_data$settlement_id)

settlements_development_data$settlement_name <- as.character(settlements_development_data$settlement_name)

settlements_development_data$gdp_latest <- as.numeric(settlements_development_data$gdp_latest)

settlements_development_data$edu_no_education <- as.numeric(gsub("%", "",settlements_development_data$edu_no_education))/100

settlements_development_data$edu_initial_education <- as.numeric(gsub("%", "",settlements_development_data$edu_initial_education))/100

settlements_development_data$edu_primary_education <- as.numeric(gsub("%", "",settlements_development_data$edu_primary_education))/100

settlements_development_data$edu_secondary_education <- as.numeric(gsub("%", "",settlements_development_data$edu_secondary_education))/100

settlements_development_data$edu_higher_non_universitary_education <- as.numeric(gsub("%", "",settlements_development_data$edu_higher_non_universitary_education))/100

settlements_development_data$edu_higher_universitary_education <- as.numeric(gsub("%", "",settlements_development_data$edu_higher_universitary_education))/100

settlements_development_data$occupation_public_sector_employments <- as.numeric(gsub("%", "",settlements_development_data$occupation_public_sector_employments))/100

settlements_development_data$occupation_academia <- as.numeric(gsub("%", "",settlements_development_data$occupation_academia))/100

settlements_development_data$occupation_mid_level_technicians <- as.numeric(gsub("%", "",settlements_development_data$occupation_mid_level_technicians))/100

settlements_development_data$occupation_office <- as.numeric(gsub("%", "",settlements_development_data$occupation_office))/100

settlements_development_data$occupation_commerce <- as.numeric(gsub("%", "",settlements_development_data$occupation_commerce))/100

settlements_development_data$occupation_agriculture_fishing <- as.numeric(gsub("%", "",settlements_development_data$occupation_agriculture_fishing))/100

settlements_development_data$mining_employments <- as.numeric(gsub("%", "",settlements_development_data$mining_employments))/100

settlements_development_data$occupation_construction <- as.numeric(gsub("%", "",settlements_development_data$occupation_construction))/100

settlements_development_data$occupation_non_qualified <- as.numeric(gsub("%", "",settlements_development_data$occupation_non_qualified))/100

settlements_development_data$occupation_others <- as.numeric(gsub("%", "",settlements_development_data$occupation_others))/100

settlements_development_data$households_with_water <- as.numeric(gsub("%", "",settlements_development_data$households_with_water))/100

settlements_development_data$public_lighting <- as.numeric(gsub("%", "",settlements_development_data$public_lighting))/100

settlements_development_data$sanitary_facilities <- as.numeric(gsub("%", "",settlements_development_data$sanitary_facilities))/100

settlements_development_data$homes_without_telecom <- as.numeric(gsub("%", "",settlements_development_data$homes_without_telecom))/100

settlements_development_data$homes_without_technology <- as.numeric(gsub("%", "",settlements_development_data$homes_without_technology))/100

settlements_development_data$eap_employed <- as.numeric(gsub("%", "",settlements_development_data$eap_employed))/100

settlements_development_data$eap_unemployed <- as.numeric(gsub("%", "",settlements_development_data$eap_unemployed))/100

settlements_development_data$eap_non_active <- as.numeric(gsub("%", "",settlements_development_data$eap_non_active))/100

##NEW SOURCES 

osiptel_kpis <- read_excel(excel_path, sheet=sheet_name_osiptel)[,c(1:4)]
names(osiptel_kpis) <- c("admin_division_3_name",
                         "solved_complaints",
                         "filed_complaints",
                         "lines_in_service")
osiptel_kpis$admin_division_3_name[osiptel_kpis$admin_division_3_name=="Lima y Callao"] <- "Lima"
osiptel_kpis$admin_division_3_name <- stri_trans_general(osiptel_kpis$admin_division_3_name,"Latin-ASCII")

osiptel_kpis$solved_complaints[osiptel_kpis$admin_division_3_name=="Callao"] <- osiptel_kpis$solved_complaints[osiptel_kpis$admin_division_3_name=="Lima"]

osiptel_kpis$filed_complaints[osiptel_kpis$admin_division_3_name=="Callao"] <- osiptel_kpis$filed_complaints[osiptel_kpis$admin_division_3_name=="Lima"]

osiptel_kpis$lines_in_service[osiptel_kpis$admin_division_3_name=="Callao"] <- osiptel_kpis$lines_in_service[osiptel_kpis$admin_division_3_name=="Lima"]

osiptel_kpis$admin_division_3_name <- toupper(osiptel_kpis$admin_division_3_name)

settlements_development_data <- merge(settlements_development_data, osiptel_kpis, by=c("admin_division_3_name"), all.x=T)


#Export dataset to DB
exportSettlementsDevelopment(schema_dev, table_kpis, table_settlements, settlements_development_data)