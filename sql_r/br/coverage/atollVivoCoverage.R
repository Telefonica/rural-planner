atollVivoCoverage <- function(schema, vivo_table_temp, vivo_table_final, i){
  
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd) 
    
     query <- paste0('CREATE TABLE ', schema,'.', vivo_table_final,'_', i, ' AS (
      SELECT internal_id, ST_Union(ST_Buffer(geometry,0.0001)) as coverage_area_', i, ' FROM (
      SELECT internal_id, (ST_Dump(coverage_area_',i,')).geom as geometry 
      FROM ',  schema, '.',  vivo_table_temp, '_', i, ' 
      WHERE coverage_area_', i, ' IS NOT NULL) a
      GROUP BY internal_id)')
   dbDisconnect(con)
    
}