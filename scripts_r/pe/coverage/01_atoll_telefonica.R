
library(gdalUtils)
library('png')
library(raster)
library("XML")
library(rgdal)
library(rgeos)
library(sf)
library("spex")

#DB Connection parameters
config_path <- '~/shared/rural_planner_r/config_files/config_pe'
source(config_path)

source('~/shared/rural_planner_r/functions/functions_atoll.R')
source('~/shared/rural_planner_r/sql/createTableTechnologiesAtoll.R')
source('~/shared/rural_planner_r/sql/exportAtoll.R')

unzip_folder <- "KMZ_unzip"
png_folder <-"PNG"
raster_folder <- "Raster"
shp_folder <- "SHP"

technologies <- c("3G","4G")

color_threshold <- 5


for(technology in technologies){
  dir.create(file.path(atoll_folders_path,technology))
  dir.create(file.path(atoll_folders_path,technology,unzip_folder))
  dir.create(file.path(atoll_folders_path,technology,png_folder))
  dir.create(file.path(atoll_folders_path,technology,raster_folder))
  dir.create(file.path(atoll_folders_path,technology,shp_folder))
}

# Get all kmz files from inside folders
kmz_files <- list.files(atoll_folders_path,full.names = T,recursive = T,pattern='\\.kmz$')

# Rename filenames replacing blank spaces with underscores
file.rename(kmz_files[grepl(" ",basename(kmz_files))],paste(dirname(kmz_files[grepl(" ",basename(kmz_files))]),gsub(" ","_",basename(kmz_files[grepl(" ",basename(kmz_files))])),sep = "/") )

# Update kmz files list with the new file names
kmz_files <- list.files(atoll_folders_path,full.names = T,recursive = T,pattern='\\.kmz$')

# Unzip kmz files
lapply(kmz_files, function(x){unzip(x,exdir=paste(dirname(dirname(x)),unzip_folder,strsplit(basename(x),".kmz")[[1]],sep ="/"))})

# Folders containing unzipped kmz files
coverage_folders <- list.dirs(paste(unique(dirname(dirname(kmz_files))),unzip_folder,sep="/"),full.names = T,recursive = F)


contador <- 1


dfFiles<- data.frame()

for (i in 1:length(coverage_folders)){
  
    pngs_path <- "files/overlays"
    xml_path <- "files/predictions.kml"
    
    xml_file <- paste(coverage_folders[i],xml_path,sep = "/")
    
    xml_tree <- xmlTreeParse(xml_file,useInternalNodes=TRUE)
    root <-xmlRoot(xml_tree)
    
    lista <- xmlElementsByTagName(root[["Document"]][["Folder"]],"GroundOverlay")
    if(length(lista)>0){
      for (j in 1:length(lista)){
      
      #cat("Procesando png ",j, " de ", length(lista), "\n")
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

      contador <- contador + 1
      }
    }
}


a <- getwd()
path<-paste0(a,"/shared/rural_planner_r/data/pe/coverage", sep = "")

for(i in 1:nrow(dfFiles)){
  dfFiles[i,'geoPNGname'] <- paste0(i,"_geo.png")
  dfFiles[i,'geoPNGpath']<- paste(path,png_folder,dfFiles[i,'geoPNGname'],sep="/")
  dfFiles[i,'rastername']<-paste0(i,"_raster.tif")
  dfFiles[i,'shpName']<-paste0(i,"_shp.shp")
 
}




dfFiles$rasterpath<-paste(path,raster_folder,dfFiles$rastername,sep="/")

dfFiles$shpPath<-paste(path,shp_folder,dfFiles$shpName,sep="/")


dfFiles$technology[grepl("2G|GSM",dfFiles$file_name,ignore.case = T)] <- "2G"
dfFiles$technology[grepl("3G|UMTS",dfFiles$file_name,ignore.case = T)] <- "3G"
dfFiles$technology[grepl("4G|LTE",dfFiles$file_name,ignore.case = T)] <- "4G"


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
                   FALSE,
                   color_threshold))


invisible(pbmapply(polygonizeRaster,
                   dfFiles$rasterpath,
                   dfFiles$shpPath))


#Insert shp files in DB
createTableTechnologesAtoll(technologies,schema_dev, atoll_intermediate_table)

exportAtoll(schema_dev, atoll_intermediate_table, technologies)



