#LIBRARIES
library(RPostgreSQL)

#CONFIG
config_path <- '~/shared/rural_planner/config_files_r/config_co'
source(config_path)

#QUERIES
source('~/shared/rural_planner/sql_r/co/DBUpdateSchemas/copyTableUpdateSchemas.R')
source('~/shared/rural_planner/sql_r/dropTable.R')
source('~/shared/rural_planner/sql_r/co/DBUpdateSchemas/createTableDate.R')
source('~/shared/rural_planner/sql_r/truncateTable.R')
source('~/shared/rural_planner/sql_r/co/DBUpdateSchemas/insertDateTable.R')s


#CONFIRMATION
ans<-NA

while (!ans %in% c("YES","NO")){
  ans <- readline(prompt="Upload to production schema? (YES/NO): ")
}


if (ans=="YES"){
      #Delete all tables in schema_backup
      for(table in tables){
        dropTable(schema_backup,table)
      }
      
      #Copy all tables selected from schema to schema_backup
      for(table in tables){
        copyTable(schema_backup, schema, table)
      }
      
      createTableDate(schema_backup,table_date)
      
      truncateTable(schema_backup,table_date)
      
      insertDateTable(schema_backuptable_date) 
      
} else if (ans=="NO") {
  stop()
} 




