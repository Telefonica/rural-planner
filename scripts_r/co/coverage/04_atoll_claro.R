

library(gdalUtils)
library(RCurl)
library(curl)
library(raster)
library(rgeos)
library(rgdal)
library(pbapply)
library(rpostgis)


#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

source('~/shared/rural_planner/sql/createTableTechnologiesAtoll.R')
source('~/shared/rural_planner/sql/co/coverage/exportAtollClaro.R')

#This URL changes when they update the maps, check for all technologies with element inspector in google chrome.

downloads_folder <-"Downloads"
png_folder <-"PNG"
raster_folder <- "Raster"
shp_folder <- "SHP"

technologies <- c("2G","3G","4G")

xMin <- 144
xMax <- 159
yMin <- 239
yMax <- 260
zoom <- 9

xMinIslas<-139
xMaxIslas<-140
yMinIslas<-236
yMaxIslas<-237


source('~/shared/rural_planner/functions/functions_atoll.R')



for(technology in technologies){
  dir.create(file.path(folders_path_claro,technology))
  dir.create(file.path(folders_path_claro,technology,downloads_folder))
  dir.create(file.path(folders_path_claro,technology,png_folder))
  dir.create(file.path(folders_path_claro,technology,raster_folder))
  dir.create(file.path(folders_path_claro,technology,shp_folder))
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

dfFiles$url[dfFiles$technology == "2G"] <- paste0(urlGSMClaro,"Z",zoom,"/",dfFiles$Y[dfFiles$technology == "2G"],"/",dfFiles$X[dfFiles$technology == "2G"],".png")
dfFiles$url[dfFiles$technology == "3G"] <- paste0(urlUMTSClaro,"Z",zoom,"/",dfFiles$Y[dfFiles$technology == "3G"],"/",dfFiles$X[dfFiles$technology == "3G"],".png")
dfFiles$url[dfFiles$technology == "4G"] <- paste0(urlLTEClaro,"Z",zoom,"/",dfFiles$Y[dfFiles$technology == "4G"],"/",dfFiles$X[dfFiles$technology == "4G"],".png")

dfFiles$base_path <- paste(folders_path_claro,dfFiles$technology,sep="/")

dfFiles$file_name <- paste0(dfFiles$Y,"_",dfFiles$X)

dfFiles$downloadname <- paste0(dfFiles$file_name,".png")
dfFiles$downloadpath <- paste(dfFiles$base_path,downloads_folder,dfFiles$downloadname,sep="/")

dfFiles$geoPNGname<-paste0(dfFiles$file_name,"_geo.png")
dfFiles$geoPNGpath<-paste(dfFiles$base_path,png_folder,dfFiles$geoPNGname,sep="/")

dfFiles$rastername<-paste0(dfFiles$file_name,"_raster.tif")
dfFiles$rasterpath<-paste(dfFiles$base_path,raster_folder,dfFiles$rastername,sep="/")

dfFiles$shpName<-paste0(dfFiles$file_name,"_shp.shp")
dfFiles$shpPath<-paste(dfFiles$base_path,shp_folder,dfFiles$shpName,sep="/")


dfFiles$dowloaded <- pbmapply(downloadFile,dfFiles$url,dfFiles$downloadpath)

######Save dataframe and read from file 

saveRDS(dfFiles,file="dfFilesClaro.rds")
dfFiles <- readRDS("dfFilesClaro.rds")

#Sometimes it downloads empty png files where there is no coverage. This time it only happens with 4G. check every time if there are too many png files.
#file.remove(dfFiles[(file.info(dfFiles[,"downloadpath"])$size==172),"downloadpath"])

dfFiles<-dfFiles[dfFiles$dowloaded==T,]

dfFiles$west <- pbmapply(tile2long,dfFiles$X,zoom)
dfFiles$north <- pbmapply(tile2lat,dfFiles$Y,zoom)
dfFiles$east <- pbmapply(tile2long,(dfFiles$X+1),zoom)
dfFiles$south <- pbmapply(tile2lat,(dfFiles$Y+1),zoom)

invisible(pbmapply(georeferencePNG, 
                   normalizePath(dfFiles$downloadpath, winslash = "/"), 
                   normalizePath(dfFiles$geoPNGpath, winslash = "/"), 
                   dfFiles$west, 
                   dfFiles$north, 
                   dfFiles$east, 
                   dfFiles$south))

invisible(pbmapply(simplifyRaster,
                   dfFiles$geoPNGpath,
                   dfFiles$rasterpath))

invisible(pbmapply(polygonizeRaster,
                   normalizePath(dfFiles$rasterpath),
                   normalizePath(dfFiles$shpPath, mustWork=F)))



## for maximum coverage: threshold 5
createTableTechnologiesAtoll(technologies, dfFiles, claro_atoll_table, schema_dev)



exportAtollClaro(schema_dev, claro_atoll_table, technologies)

