createTableTechnologiesAtoll <- function(technologies, dfFiles, table, schema){
    for(technology in technologies){
      time<-proc.time()
      dfSHPs <- do.call("rbind",pblapply(dfFiles[dfFiles$technology==technology,"shpPath"],readOGR,verbose = F))
      dfSHPs<-dfSHPs[dfSHPs$DN==0,]
      
      drv <- dbDriver("PostgreSQL")
      con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
      
      table_technology <-paste0(table,"_",tolower(technology))
      
      pgInsert(conn = con, name = c(schema,table_technology),data.obj = dfSHPs)
      
      rm(dfSHPs)
      
      dbDisconnect(con)
    }
    
    
    for(technology in technologies){
      drv <- dbDriver("PostgreSQL")
      con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
      
      table_technology <-paste0(table,"_",tolower(technology))
    
      query<-paste0("UPDATE ", schema ,".", table_technology ," SET geom = ST_Multi(ST_Buffer(geom,0))")
      dbGetQuery(con,query)
      
      query<-paste0("UPDATE ", schema ,".", table_technology ," SET geom = ST_Simplify(geom,0.001)")
      dbGetQuery(con,query)
     
      query<-paste0("UPDATE ", schema ,".", table_technology ," SET geom = ST_CollectionExtract(ST_MakeValid(geom),3)")
      dbGetQuery(con,query)
    
      dbDisconnect(con)
    }

}