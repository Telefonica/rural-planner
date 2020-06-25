#LIBRARIES
library(gdalUtils)
library('png')
library(raster)
library("XML")
library(rgdal)
library(rgeos)
library(sf)
library(sp)
library(rpostgis)
library("spex")
library('pbapply')
library(readxl)

if (!requireNamespace("devtools")) install.packages("devtools")
devtools::install_github("psolymos/pbapply")

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

folders_path <- paste(input_path_infrastructure, qw_atoll_folder, sep ='/')

unzip_folder <- "KMZ_unzip"
png_folder <-"PNG"
raster_folder <- "Raster"
shp_folder <- "SHP"

color_threshold <- 3

source('~/shared/rural_planner/sql/co/infrastructure/updateDBFiles.R')
source('~/shared/rural_planner/sql/co/infrastructure/uploadIntermediateOutputs.R')
source('~/shared/rural_planner/sql/co/infrastructure/uploadDBAtoll.R')
source('~/shared/rural_planner/functions/functions_atoll.R')

dir.create(file.path(folders_path,unzip_folder))
dir.create(file.path(folders_path,png_folder))
dir.create(file.path(folders_path,raster_folder))
dir.create(file.path(folders_path,shp_folder))


# Get all kmz files from inside folders
kmz_files <- list.files(folders_path, full.names = T,recursive = T,pattern='.kmz$',ignore.case = T)

# Rename filenames replacing blank spaces with underscores
file.rename(kmz_files[grepl(" ",basename(kmz_files))],paste(dirname(kmz_files[grepl(" ", 
                                                                                    basename(kmz_files))]),gsub(" ","_",basename(kmz_files[grepl(" ",basename(kmz_files))])),sep = "/") )

# Update kmz files list with the new file names
kmz_files <- list.files(folders_path,full.names = T,recursive = T,pattern='.kmz$',ignore.case = T)


lapply(kmz_files, function(x){unzip(x,exdir=paste(dirname(x),unzip_folder,strsplit(basename(x),".kmz")[[1]],sep ="/"))})

# Folders containing unzipped kmz files
coverage_folders <- list.dirs(paste(unique(dirname(kmz_files)),unzip_folder,sep="/"),full.names = T,recursive = F)


contador <- 1

#Create data frame with complete list of png files, extracting info from xml files
dfFiles<- data.frame()

for (i in 1:length(coverage_folders)){
  #
  print(coverage_folders[i])
  
  
  pngs_path <- "files/overlays"
  xml_path <- "files/predictions.kml"
  
  xml_file <- paste(coverage_folders[i],xml_path,sep = "/")
  
  if (file.exists(xml_file)){
    xml_tree <- xmlTreeParse(xml_file,useInternalNodes=TRUE)
    root <-xmlRoot(xml_tree)
    
    lista <- xmlElementsByTagName(root[["Document"]][["Folder"]],"GroundOverlay")
    if(length(lista)>0){
      for (j in 1:length(lista)){
        
        north <-xmlValue(lista[[j]][["Region"]][["LatLonAltBox"]][["north"]])
        south <-xmlValue(lista[[j]][["Region"]][["LatLonAltBox"]][["south"]])
        east <-xmlValue(lista[[j]][["Region"]][["LatLonAltBox"]][["east"]])
        west <-xmlValue(lista[[j]][["Region"]][["LatLonAltBox"]][["west"]])
        nombre <- strsplit(xmlValue(lista[[j]][["Icon"]][["href"]]),"/")[[1]][[2]]
        
        dfFiles[contador,'file_name'] <- paste0(basename(coverage_folders[i]),"_",strsplit(nombre,".png")[[1]])
        dfFiles[contador,'north'] <- north
        dfFiles[contador,'east'] <- east
        dfFiles[contador,'south'] <- south
        dfFiles[contador,'west'] <- west
        dfFiles[contador,'base_path'] <- dirname(dirname(coverage_folders[i]))
        dfFiles[contador,'png_path'] <- paste(coverage_folders[i],pngs_path,nombre,sep = "/")
        dfFiles[contador,'invertedColors']<- F
        
        
        contador <- contador + 1 
        }
    }
  }else{ # Hay algunas carpetas con estructura diferente, a lo mejor se podria integrar todo a la vez explorando el archivo doc.kml
    pngs_path <- "files"
    xml_path <- "doc.kml"
    xml_file <- paste(coverage_folders[i],xml_path,sep = "/")

    xml_tree <- xmlTreeParse(xml_file,useInternalNodes=TRUE)
    root <-xmlRoot(xml_tree)

    listaDocuments <- xmlElementsByTagName(root[["Folder"]],"Document")
    for (j in 1:length(listaDocuments)){
      listaFolders <- xmlElementsByTagName(listaDocuments[[j]],"Folder")
      for (k in 1:length(listaFolders)) {
        listaGround <- xmlElementsByTagName(listaFolders[[k]],"GroundOverlay")
        for (l in 1:length(listaGround)){
          north <-xmlValue(listaGround[[l]][["Region"]][["LatLonAltBox"]][["north"]])
          south <-xmlValue(listaGround[[l]][["Region"]][["LatLonAltBox"]][["south"]])
          east <-xmlValue(listaGround[[l]][["Region"]][["LatLonAltBox"]][["east"]])
          west <-xmlValue(listaGround[[l]][["Region"]][["LatLonAltBox"]][["west"]])
          nombre <- strsplit(xmlValue(listaGround[[l]][["Icon"]][["href"]]),"/")[[1]][[2]]

          dfFiles[contador,'file_name'] <- paste0(basename(coverage_folders[i]),"_",strsplit(nombre,".png")[[1]])
          dfFiles[contador,'north'] <- north
          dfFiles[contador,'east'] <- east
          dfFiles[contador,'south'] <- south
          dfFiles[contador,'west'] <- west
          dfFiles[contador,'base_path'] <- dirname(dirname(coverage_folders[i]))
          dfFiles[contador,'png_path'] <- paste(coverage_folders[i],pngs_path,nombre,sep = "/")
          dfFiles[contador,'invertedColors']<- T

          contador <- contador + 1

        }
      }
    }
  }
}

rm(north,east,west,south,i,j,k,l,root,xml_file,xml_path,xml_tree,lista,listaDocuments,listaFolders,listaGround)

dfFiles$geoPNGname<-paste0(dfFiles$file_name,"_geo.png")
dfFiles$geoPNGpath<-paste(dfFiles$base_path,png_folder,dfFiles$geoPNGname,sep="/")

dfFiles$rastername<-paste0(dfFiles$file_name,"_raster.tif")
dfFiles$rasterpath<-paste(dfFiles$base_path,raster_folder,dfFiles$rastername,sep="/")

dfFiles$shpName<-paste0(dfFiles$file_name,"_shp.shp")
dfFiles$shpPath<-paste(dfFiles$base_path,shp_folder,dfFiles$shpName,sep="/")

dfFiles$technology<-"4G"


invisible(pbmapply(georeferencePNG, 
                   dfFiles$png_path, 
                   dfFiles$geoPNGpath, 
                   dfFiles$west, 
                   dfFiles$north, 
                   dfFiles$east, 
                   dfFiles$south))

invisible(pbmapply(simplifyRaster,
                   dfFiles$geoPNGpath,
                   dfFiles$rasterpath,
                   dfFiles$invertedColors,
                   color_threshold))

#1 hour
invisible(pbmapply(polygonizeRaster,
                   dfFiles$rasterpath,
                   dfFiles$shpPath))


files <- unique(dfFiles$file_name)

source('~/shared/rural_planner/sql/co/infrastructure/insertFile')

for(file in files){
  time<-proc.time()
  dfSHPs <- readOGR(dfFiles[dfFiles$file_name==file,"shpPath"], verbose = F)
  dfSHPs<-dfSHPs[dfSHPs$DN==0,]
  dfSHPs@data$name <- file
  
  insertFile(schema_dev, table_atoll_infrastructure_temp, dfSHPs)
    
  rm(dfSHPs)
  print(proc.time()-time)

}

intermediate_output <- updateDBFiles(schema_dev, table_atoll_infrastructure_temp)

## Ad-HOC Matching atoll projections with centroids
match <- read_excel(paste(input_path_infrastructure, qw_atoll_input_file, sep='/'))

intermediate_output <- merge(intermediate_output,match, by.x="name", by.y="file_name", all.x=T)
intermediate_output$centroid <- as.character(intermediate_output$centroid)


uploadIntermediateOutputs(schema_dev, table_atoll_infrastructure_temp, intermediate_output)


uploadDBAtoll(table_atoll_infrastructure, schema_dev, table_atoll_infrastructure_temp, table_clusters, infrastructure_table)
