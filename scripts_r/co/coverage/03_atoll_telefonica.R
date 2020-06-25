
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

if (!requireNamespace("devtools")) install.packages("devtools")
devtools::install_github("psolymos/pbapply")

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

folders_path <- '~/shared/rural_planner/data/co/coverage/kmz_files'

unzip_folder <- "KMZ_unzip"
png_folder <-"PNG"
raster_folder <- "Raster"
shp_folder <- "SHP"

technologies <- c("2G","3G","4G")

color_threshold <- 3


source('~/shared/rural_planner/functions/functions_atoll.R')
source('~/shared/rural_planner/functions/readAllFiles.R')
source('~/shared/rural_planner/sql/createTableTechnologiesAtoll.R')
source('~/shared/rural_planner/sql/exportAtoll.R')

for(technology in technologies){
  dir.create(file.path(folders_path,technology))
  dir.create(file.path(folders_path,technology,unzip_folder))
  dir.create(file.path(folders_path,technology,png_folder))
  dir.create(file.path(folders_path,technology,raster_folder))
  dir.create(file.path(folders_path,technology,shp_folder))
}

# Get all kmz files from inside folders
kmz_files <- list.files(folders_path,full.names = T,recursive = T,pattern='\\.kmz$',ignore.case = T)

# Rename filenames replacing blank spaces with underscores
file.rename(kmz_files[grepl(" ",basename(kmz_files))],paste(dirname(kmz_files[grepl(" ",basename(kmz_files))]),gsub(" ","_",basename(kmz_files[grepl(" ",basename(kmz_files))])),sep = "/") )

# Update kmz files list with the new file names
kmz_files <- list.files(folders_path,full.names = T,recursive = T,pattern='\\.kmz$',ignore.case = T)

# Unzip kmz files in respective technology folder
lapply(kmz_files[grepl("3G|UMTS",kmz_files,ignore.case = T)], function(x){unzip(x,exdir=paste(dirname(x),"3G",unzip_folder,strsplit(basename(x),".kmz")[[1]],sep ="/"))})

lapply(kmz_files[grepl("2G|GSM",kmz_files,ignore.case = T)], function(x){unzip(x,exdir=paste(dirname(x),"2G",unzip_folder,strsplit(basename(x),".kmz")[[1]],sep ="/"))})

lapply(kmz_files[grepl("4G|LTE",kmz_files,ignore.case = T)], function(x){unzip(x,exdir=paste(dirname(x),"4G",unzip_folder,strsplit(basename(x),".kmz")[[1]],sep ="/"))})


# List of folders containing unzipped kmz files

coverage_folders <-c()
for (technology in technologies){
  coverage_folders <- c(coverage_folders,list.dirs(paste(folders_path,technology,unzip_folder,sep="/"),full.names = T,recursive = F))
}

contador <- 1

#Create data frame with complete list of png files, extracting info from xml files
dfFiles<- data.frame()

for (i in 1:length(coverage_folders)){
  
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
        
        if(grepl("UMTS_Sur_Occiente_JUNIO|GSM_Sur_Occiente_JUNIO",dfFiles[contador,'file_name'])){
          dfFiles[contador,'invertedColors']<- T
        }
        contador <- contador + 1 
      }
    }
  }else{ # Hay algunas carpetas con estructura diferente, a lo mejor se podria integrar todo a la vez explorando el archivo doc.kml
    pngs_path <- "files"
    xml_path <- "/doc.kml"
    xml_file <- paste0(coverage_folders[i],xml_path,sep = "")
    
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

dfFiles$technology[grepl("2G|GSM",dfFiles$file_name,ignore.case = T)]<-"2G"
dfFiles$technology[grepl("3G|UMTS",dfFiles$file_name,ignore.case = T)]<-"3G"
dfFiles$technology[grepl("4G|LTE",dfFiles$file_name,ignore.case = T)]<-"4G"

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
pbmapply(polygonizeRaster,
         dfFiles$rasterpath,
         dfFiles$shpPath)



createTableTecnologiesAtoll(technologies, dfFiles, telefonica_atoll_ouptut_table, schema_dev)

exportAtoll(schema_dev, telefonica_atoll_ouptut_table, technologies)




