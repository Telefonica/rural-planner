createTableTecnologiesClaro <- function(technologies, schema, df_geoms, table){    
    for(technology in technologies){
      table_technology <-paste0(table,"_",tolower(technology))
      
      #aux_geom <- data.frame(st_collection_extract(df_geoms[df_geoms$tech==technology,], "POLYGON"))
      #aux_geom$geom <- aux_geom$geom[[1]][1]
      
      aux_geom <- df_geoms[df_geoms$tech==technology,]
      aux_geom <- aux_geom[!(grepl('Bajo',aux_geom$name)),]
      
      conn <- RPostgres::dbConnect(Postgres(), dbname = dbname, host = host, port = port, 
                        user = user, password = pwd)
      drv <- DBI::dbDriver("PostgreSQL")
      con <- RPostgreSQL::dbConnect(drv, dbname = dbname,
                       host = host, port = port,
                       user = user, password = pwd)
      
      query<-paste0("DROP TABLE IF EXISTS ", schema ,".", table_technology)
      RPostgreSQL::dbGetQuery(con,query)
      st_write(aux_geom, dsn=conn, DBI::Id(schema=schema,table=table_technology))
      #pgInsert(conn = con, name = c(schema,table_technology), data.obj = aux_geom)
      RPostgres::dbDisconnect(conn)
      RPostgreSQL::dbDisconnect(con)
      rm(aux_geom)
    }
    
    
    for(technology in technologies){
      drv <- DBI::dbDriver("PostgreSQL")
      con <- RPostgreSQL::dbConnect(drv, dbname = dbname,
                       host = host, port = port,
                       user = user, password = pwd) 
      
      table_technology <-paste0(table,"_",tolower(technology))
      
      #query<-paste0("DELETE FROM ", schema ,".", table_technology ," WHERE name LIKE '%Bajo%'")
      #dbGetQuery(con,query)
      
      query<-paste0("DELETE FROM ", schema ,".", table_technology ," WHERE ST_Area(geom)=0")
      dbGetQuery(con,query)
      
      query<-paste0("UPDATE ", schema ,".", table_technology ," SET geom = ST_Multi(ST_Buffer(geom,0))")
      dbGetQuery(con,query)
      
      query<-paste0("UPDATE ", schema ,".", table_technology ," SET geom = ST_Simplify(geom,0.001)")
      dbGetQuery(con,query)
      
      query<-paste0("UPDATE ", schema ,".", table_technology ," SET geom = ST_CollectionExtract(ST_MakeValid(geom),3)")
      dbGetQuery(con,query)
      
      dbDisconnect(con)
      
    }
}