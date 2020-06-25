indirectCoverageZRDTech <- function(schema, infrastructure_table, g){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)
  query <- paste0("SELECT (ST_Union(coverage_area_",g,")) 
                FROM ",schema,".", infrastructure_table, 
                  " WHERE coverage_area_",g," IS NOT NULL")
  
  aux_df <- dbGetQuery(con,query)
  dbDisconnect(con)
  aux_df
}