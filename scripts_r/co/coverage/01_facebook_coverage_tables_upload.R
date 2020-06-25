library(utils)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

source('~/shared/rural_planner/sql/co/coverage/exportDBFacebook.R')

input_path <- paste(input_path_data_coverage, facebook_folder, sep = '/')

df_tables <- list()

for(i in (1:length(file_names_fb))){
  df_tables[[i]]<- read.csv(paste(input_path, file_names_fb[i], sep = '/'), header = TRUE, sep = ";", stringsAsFactors = FALSE)
}

#Set connection data
exportDBFacebook(table_names_fb, schema, df_tables)
