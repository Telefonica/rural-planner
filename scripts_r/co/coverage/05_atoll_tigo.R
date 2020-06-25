

library(gdalUtils)
library('RCurl')
library(raster)
library(rgeos)
library(rgdal)
library('pbapply')
library(rpostgis)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

downloads_folder <-"Downloads"
png_folder <-"PNG"
raster_folder <- "Raster"
shp_folder <- "SHP"

technologies <- c("2G","3G","4G")

xMin <- 286
xMax <- 322
yMin <- 475
yMax <- 524
zoom <- 10


xMinIslas<-279
xMaxIslas<-280
yMinIslas<-473
yMaxIslas<-476


source('~/shared/rural_planner/functions/functions_atoll.R')
source('~/shared/rural_planner/sql/createTableTechnologiesAtoll.R')
source('~/shared/rural_planner/sql/exportAtoll.R')

for(technology in technologies){
  dir.create(file.path(folders_path_tigo,technology))
  dir.create(file.path(folders_path_tigo,technology,downloads_folder))
  dir.create(file.path(folders_path_tigo,technology,png_folder))
  dir.create(file.path(folders_path_tigo,technology,raster_folder))
  dir.create(file.path(folders_path_tigo,technology,shp_folder))
}


dfGridContinente <- data.frame(expand.grid(yMin:yMax,xMin:xMax))
names(dfGridContinente) <- c("Y","X")

dfGridIslas <- data.frame(expand.grid(yMinIslas:yMaxIslas,xMinIslas:xMaxIslas))
names(dfGridIslas) <- c("Y","X")

dfGrid<-rbind(dfGridContinente,dfGridIslas)

dfFiles <-data.frame()

for (technology in technologies){
  dfGrid$technology <-technology
  dfFiles<-rbind(dfFiles,dfGrid)
}
rm(dfGridContinente)
rm(dfGridIslas)
rm(dfGrid)

dfFiles$url[dfFiles$technology == "2G"] <- paste0(urlGSMTigo,"Z",zoom,"/",dfFiles$Y[dfFiles$technology == "2G"],"/",dfFiles$X[dfFiles$technology == "2G"],".png")
dfFiles$url[dfFiles$technology == "3G"] <- paste0(urlUMTSTigo,"Z",zoom,"/",dfFiles$Y[dfFiles$technology == "3G"],"/",dfFiles$X[dfFiles$technology == "3G"],".png")
dfFiles$url[dfFiles$technology == "4G"] <- paste0(urlLTETigo,"Z",zoom,"/",dfFiles$Y[dfFiles$technology == "4G"],"/",dfFiles$X[dfFiles$technology == "4G"],".png")

dfFiles$base_path <- paste(folders_path_tigo,dfFiles$technology,sep="/")

dfFiles$file_name <- paste0(dfFiles$Y,"_",dfFiles$X)

dfFiles$downloadname <- paste0(dfFiles$file_name,".png")
dfFiles$downloadpath <- paste(normalizePath(dfFiles$base_path),downloads_folder,dfFiles$downloadname,sep="/")

dfFiles$geoPNGname<-paste0(dfFiles$file_name,"_geo.png")
dfFiles$geoPNGpath<-paste(normalizePath(dfFiles$base_path),png_folder,dfFiles$geoPNGname,sep="/")

dfFiles$rastername<-paste0(dfFiles$file_name,"_raster.tif")
dfFiles$rasterpath<-paste(normalizePath(dfFiles$base_path),raster_folder,dfFiles$rastername,sep="/")

dfFiles$shpName<-paste0(dfFiles$file_name,"_shp.shp")
dfFiles$shpPath<-paste(normalizePath(dfFiles$base_path),shp_folder,dfFiles$shpName,sep="/")

dfFiles$dowloaded[dfFiles$technology=="2G"] <- pbmapply(downloadFile,dfFiles$url[dfFiles$technology=="2G"],dfFiles$downloadpath[dfFiles$technology=="2G"])
dfFiles$dowloaded[dfFiles$technology=="3G"] <- pbmapply(downloadFile,dfFiles$url[dfFiles$technology=="3G"],dfFiles$downloadpath[dfFiles$technology=="3G"])
dfFiles$dowloaded[dfFiles$technology=="4G"] <- pbmapply(downloadFile,dfFiles$url[dfFiles$technology=="4G"],dfFiles$downloadpath[dfFiles$technology=="4G"])


saveRDS(dfFiles,file="dfFilesTigo.rds")

#Sometimes it downloads empty png files where there is no coverage. This time it only happens with 4G. check every time if there are too many png files.
file.remove(dfFiles[(file.info(dfFiles[,"downloadpath"])$size==172),"downloadpath"])

dfFiles$dowloaded[is.na(file.info(dfFiles$downloadpath)$size)]<-F

dfFiles<-dfFiles[dfFiles$dowloaded==T,]

dfFiles$west <- pbmapply(tile2long,dfFiles$X,zoom)
dfFiles$north <- pbmapply(tile2lat,dfFiles$Y,zoom)
dfFiles$east <- pbmapply(tile2long,(dfFiles$X+1),zoom)
dfFiles$south <- pbmapply(tile2lat,(dfFiles$Y+1),zoom)

invisible(pbmapply(georeferencePNG, 
                   normalizePath(dfFiles$downloadpath), 
                   normalizePath(dfFiles$geoPNGpath), 
                   dfFiles$west,
                   dfFiles$north,
                   dfFiles$east,
                   dfFiles$south))

invisible(pbmapply(simplifyRaster,
                   normalizePath(dfFiles$geoPNGpath),
                   normalizePath(dfFiles$rasterpath)
                   ))


invisible(pbmapply(polygonizeRaster,
                   normalizePath(dfFiles$rasterpath),
                   normalizePath(dfFiles$shpPath, mustWork=F)))

createTableTechnologiesAtoll(technologies, dfFiles, tigo_atoll_table, schema_dev)


exportAtoll(schema_dev, tigo_atoll_table, technologies)
