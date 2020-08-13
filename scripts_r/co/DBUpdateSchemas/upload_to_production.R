#LIBRARIES
library(RPostgreSQL)

#CONFIG
config_path <- '~/shared/rural_planner/config_files_r/config_co'
source(config_path)

#QUERIES
source('~/shared/rural_planner/sql_r/co/DBUpdateSchemas/copyTableUpdateSchemas.R')
source('~/shared/rural_planner/sql_r/dropTableCascade.R')

#CONFIRMATION
ans<-NA
while (!ans %in% c("YES","NO")){
  ans <- readline(prompt="Upload to production schema? (YES/NO): ")
}


if (ans=="YES"){
  
  for(table in tables){
    dropTableCascade(schema,table)
  }
  
  for(table in tables){
    copyTable(schema, schema_dev, table)
  }
  
} else if (ans=="NO") {
  stop()
} 


