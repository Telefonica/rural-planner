setAdminDivision1 <- function(admin_div_2_aux, schema, table_households, table_admin_division_1){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)
  
  # Invisible avoids printing return null every time
  invisible(lapply(admin_div_2_aux$admin_division_2_id,function(id){
    query <-paste(" UPDATE ",schema,".",table_households,
                  " SET admin_division_1_id= ",table_admin_division_1, ".admin_division_1_id
                  FROM ", schema,".",table_admin_division_1, "
                  WHERE ST_Within(",table_households,".geom::geometry, ",table_admin_division_1,".geom)
                  AND ",table_households,".admin_division_2_id='",id,"'
                  AND ",table_admin_division_1,".admin_division_2_id='",id, "'",sep = "")
    dbGetQuery(con,query)
  }))
  
  dbDisconnect(con)
}



