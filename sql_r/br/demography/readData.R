readData <- function(schema, table_census){
  #Read raw data from DB
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)
  
  #Add geometry
  query <- paste0("SELECT settlement_id,
                          ST_X(geom) as longitude,
                          ST_Y(geom) as latitude,
                          admin_division_1_id,
                          admin_division_2_id,
                          admin_division_3_id,
                          admin_division_1_name,
                          admin_division_2_name,
                      geom FROM (
                      SELECT
                      cd_geocodi as settlement_id,
                      cd_geocodd as admin_division_1_id,
                      cd_geocodm as admin_division_2_id,
                      LEFT(cd_geocodd,2) as admin_division_3_id,
                      nm_distrit as admin_division_1_name,
                      nm_municip as admin_division_2_name,
                      ST_PointOnSurface(ST_MakeValid(geom)) as geom
                      FROM ", schema, ".", table_census,") c;")
  
  settlements_geolocated <- dbGetQuery(con,query)
  
  dbDisconnect(con)
  
  settlements_geolocated
}