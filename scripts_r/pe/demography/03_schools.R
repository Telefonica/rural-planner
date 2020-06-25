
#LIBRARIES

library(RPostgreSQL)
library(plyr)
library(tidyverse)
library(stringr)
library(readxl)
library(data.table)
library(foreign)

#CONFIG
config_path <- '~/shared/rural_planner_r/config_files/config_pe'
source(config_path)

source('~/shared/rural_planner_r/sql/pe/demography/missingSettlements.R')
source('~/shared/rural_planner_r/sql/pe/demography/exportSchoolsDF.R')
source('~/shared/rural_planner_r/sql/pe/demography/schoolsIndirect.R')
source('~/shared/rural_planner_r/sql/pe/demography/schoolsDirect.R')
source('~/shared/rural_planner_r/sql/pe/demography/mergeWithSettlements.R')
source('~/shared/rural_planner_r/sql/pe/demography/exportSchools.R')
source('~/shared/rural_planner_r/sql/pe/demography/deleteTables.R')

# Load and collect inputs

schools <- read.dbf(paste(input_path_demography,schools_file_name,sep="/"),as.is=TRUE)


schools <- schools[,c("CEN_EDU","D_NIV_MOD","CODCP_INEI","CEN_POB","CODGEO","CODLOCAL","TALUMNO","D_ESTADO","NLAT_IE","NLONG_IE")]
colnames(schools) <- c("school_name","educational_level","settlement_id","settlement","settlement_id_6","school_id","number_students","status","latitude","longitude")

Encoding(schools$educational_level) <- "latin1"
# 
# Encoding(schools$school_name) <- "UTF-8"

schools$ed_level[grepl("Alternativa",schools$educational_level)] <- "initial, primary and secondary"
schools$ed_level[grepl("Especial",schools$educational_level)] <- "initial and primary"
schools$ed_level[grepl("Inicial",schools$educational_level)] <- "initial"
schools$ed_level[grepl("Primaria",schools$educational_level)] <- "primary"
schools$ed_level[grepl("Inicial e Intermedio",schools$educational_level)] <- "initial and primary"
schools$ed_level[grepl("Secundaria",schools$educational_level)] <-"secondary"
schools$ed_level[grepl("Avanzado",schools$educational_level)] <- "secondary"
schools$ed_level[grepl("Superior",schools$educational_level)] <- "superior"
schools$ed_level[grepl("Ocupacional",schools$educational_level)] <- "others"
schools$ed_level[grepl("Productiva",schools$educational_level)] <- "others"

# Change status types

schools$status[grepl("Activa",schools$status)] <- 'ACTIVE'
schools$status[grepl("Inactiva",schools$status)] <- 'INACTIVE'

# AD-HOC: Add missing settlements from the input using auxiliary information (settlement_name and settlement_id_6 combined) 
settlement_ids_corrected <- missingSettlements(schema_dev, schools_incomplete_settlements_table, table_settlements, schools)

schools_corrected_settlements<-join(schools, settlement_ids_corrected, by=c('school_name','settlement'), type="left", match="first")

schools_corrected_settlements$settlement_id[is.na(schools_corrected_settlements$settlement_id)]<-schools_corrected_settlements$settlement_id_corrected[is.na(schools_corrected_settlements$settlement_id)]

schools_corrected_settlements <- schools_corrected_settlements[,c(1,2,4,6:11)]

schools_corrected_settlements <- schools_corrected_settlements[!is.na(schools_corrected_settlements$settlement_id),]


#Creation of datatable schools
schools_df<- schools_corrected_settlements[,c(4,3,9,5:8)]

names(schools_df)[names(schools_df) == 'ed_level'] <- 'educational_level'

exportSchoolsDF(schema_dev, schools_table, schools_df)

# Creation of schools_summary

schools_by_category_indirect <- schoolsIndirect(schools_by_category_indirect_table, table_settlements, schema_dev, schools_table, school_radius_km)


schools_by_category_direct <- schoolsDirect(schema_dev, table_settlements, schools_table)

# Add the schools contained in the settlement itself to the indirect schools table

schools_by_category_indirect <- base::merge(schools_by_category_indirect,  schools_by_category_direct, by = c("settlement_id","educational_level"), all = TRUE)

schools_by_category_indirect$school_count <- rowSums(cbind(schools_by_category_indirect$school_count.x,schools_by_category_indirect$school_count.y), na.rm=TRUE)

schools_by_category_indirect$total_students <- rowSums(cbind(schools_by_category_indirect$total_students.x,schools_by_category_indirect$total_students.y), na.rm=TRUE)

schools_by_category_indirect <- schools_by_category_indirect[,c('settlement_id','educational_level','school_count','total_students')]

settlements_with_schools_array <- as.array(unique(schools_by_category_indirect$settlement_id))

schools_summary_indirect <- as.data.frame(settlements_with_schools_array)
names(schools_summary_indirect) <- 'settlement_id'

for (i in (1:length(settlements_with_schools_array))){
  
  schools_each_settlement<-schools_by_category_indirect[schools_by_category_indirect$settlement_id==settlements_with_schools_array[i],]
  
  schools_summary_indirect$indirect_total_schools[schools_summary_indirect$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$school_count)
  
  schools_summary_indirect$indirect_total_students[schools_summary_indirect$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$total_students)
    
  schools_summary_indirect$indirect_initial_education[schools_summary_indirect$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$school_count[grepl("initial",schools_each_settlement$educational_level)])
  
   schools_summary_indirect$indirect_initial_students[schools_summary_indirect$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$total_students[grepl("initial",schools_each_settlement$educational_level)])
   
  schools_summary_indirect$indirect_primary_education[schools_summary_indirect$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$school_count[grepl("primary",schools_each_settlement$educational_level)])
  
  schools_summary_indirect$indirect_primary_students[schools_summary_indirect$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$total_students[grepl("primary",schools_each_settlement$educational_level)])
   
  schools_summary_indirect$indirect_secondary_education[schools_summary_indirect$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$school_count[grepl("secondary",schools_each_settlement$educational_level)])
  
  schools_summary_indirect$indirect_secondary_students[schools_summary_indirect$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$total_students[grepl("secondary",schools_each_settlement$educational_level)])
   
  schools_summary_indirect$indirect_superior_education[schools_summary_indirect$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$school_count[grepl("superior",schools_each_settlement$educational_level)])
  
    schools_summary_indirect$indirect_superior_students[schools_summary_indirect$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$total_students[grepl("superior",schools_each_settlement$educational_level)])
   
  schools_summary_indirect$indirect_other_education[schools_summary_indirect$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$school_count[grepl("others",schools_each_settlement$educational_level)])
  
      schools_summary_indirect$indirect_other_students[schools_summary_indirect$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$total_students[grepl("others",schools_each_settlement$educational_level)])
  
  rm(schools_each_settlement)
  
}

rm(settlements_with_schools_array)


settlements_with_schools_array <- as.array(unique(schools_by_category_direct$settlement_id))

schools_summary_direct <- as.data.frame(settlements_with_schools_array)
names(schools_summary_direct) <- 'settlement_id'

for (i in (1:length(settlements_with_schools_array))){
  
  schools_each_settlement<-schools_by_category_direct[schools_by_category_direct$settlement_id==settlements_with_schools_array[i],]
  schools_summary_direct$direct_total_schools[schools_summary_direct$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$school_count)
  
  schools_summary_direct$direct_total_students[schools_summary_direct$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$total_students)
    
  schools_summary_direct$direct_initial_education[schools_summary_direct$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$school_count[grepl("initial",schools_each_settlement$educational_level)])
  
   schools_summary_direct$direct_initial_students[schools_summary_direct$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$total_students[grepl("initial",schools_each_settlement$educational_level)])
   
  schools_summary_direct$direct_primary_education[schools_summary_direct$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$school_count[grepl("primary",schools_each_settlement$educational_level)])
  
  schools_summary_direct$direct_primary_students[schools_summary_direct$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$total_students[grepl("primary",schools_each_settlement$educational_level)])
   
  schools_summary_direct$direct_secondary_education[schools_summary_direct$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$school_count[grepl("secondary",schools_each_settlement$educational_level)])
  
  schools_summary_direct$direct_secondary_students[schools_summary_direct$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$total_students[grepl("secondary",schools_each_settlement$educational_level)])
   
  schools_summary_direct$direct_superior_education[schools_summary_direct$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$school_count[grepl("superior",schools_each_settlement$educational_level)])
  
    schools_summary_direct$direct_superior_students[schools_summary_direct$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$total_students[grepl("superior",schools_each_settlement$educational_level)])
   
  schools_summary_direct$direct_other_education[schools_summary_direct$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$school_count[grepl("others",schools_each_settlement$educational_level)])
  
      schools_summary_direct$direct_other_students[schools_summary_direct$settlement_id==settlements_with_schools_array[i]] <- sum(schools_each_settlement$total_students[grepl("others",schools_each_settlement$educational_level)])
  
  rm(schools_each_settlement)
  
}

# Merge direct and indirect schools

schools_summary <- base::merge(schools_summary_direct, schools_summary_indirect, by.x='settlement_id', by.y='settlement_id', all=TRUE)

#Merge with all settlements
settlements_list <- mergeWithSettlements(schema_dev, table_settlements)

schools_summary <- base::merge(schools_summary,settlements_list,by='settlement_id',all.y = TRUE)

schools_summary[is.na(schools_summary)] <- 0


# Export output dataframes to PostgreSQL
exportSchools(schema_dev, schools_summary_table, schools_summary)


deleteTables(schema_dev, schools_incomplete_settlements_table, schools_by_category_indirect_table)


