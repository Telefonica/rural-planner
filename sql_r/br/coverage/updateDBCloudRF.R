updateDBCloudRF <- function(schema, table_final, shp_files){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    table_aux <- "cloudrf_aux"
    
    query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table_final)
    dbGetQuery(con,query)
    
    query <-paste0("CREATE TABLE ", schema,".",table_final," (ident text, dn int4, geom geometry)")
    dbGetQuery(con,query)
    
    for(i in 1:length(shp_files)){
      
      dfSHPs <- do.call("rbind",pblapply(paste(input_path,shp_folder_unzip,shp_files[i],sep="/"),readOGR,verbose = F))
      dfSHPs<-dfSHPs[dfSHPs$DN !=0,]
      
      query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table_aux)
      dbGetQuery(con,query)
      
      pgInsert(conn = con, name = c(schema,table_aux), data.obj = dfSHPs, geom = "geom")
      query<-paste0("ALTER TABLE ", schema, ".", table_aux," ALTER COLUMN geom TYPE geometry (MULTIPOLYGON, 4326)
                USING ST_Multi(geom)")
      dbGetQuery(con,query)
      
      query<-paste0("ALTER TABLE ", schema, ".", table_aux," ADD COLUMN ident text CONSTRAINT constante DEFAULT '", gsub("/coverage.shp","",shp_files[i]),"'")
      dbGetQuery(con,query)
      
      query<-paste0("INSERT INTO ", schema, ".", table_final," (ident, dn, geom) SELECT ident, \"DN\", ST_Union(geom) FROM ", schema, ".", table_aux, " GROUP BY ident, \"DN\"")
      dbGetQuery(con,query)
      
      print(paste0("Iteration ", i, "/", length(shp_files), " upload to DB."))
    }
    
    query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table_aux)
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}