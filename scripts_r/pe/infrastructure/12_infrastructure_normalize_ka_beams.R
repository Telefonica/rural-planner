
#LIBRARIES
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(rgdal)
library("sp")
library(gdalUtils)
library(postGIStools)
library(maptools)
library(raster)

#CONFIG
config_path <- '~/shared/rural_planner_r/config_files/config_pe'
source(config_path)

#VARIABLES
output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")
file_name_1 <- "banda_ka_sin_piura.kml"
file_name_2 <- "banda_ka_ingenieria.kml"

source('~/shared/rural_planner_r/sql/pe/infrastructure/exportKaBeams.R')

#Load KMLs
kmlfile_1 <- paste(input_path_infrastructure,  file_name_1, sep = "/")
kmlfile_2 <- paste(input_path_infrastructure,  file_name_2, sep = "/")

lyr_1 <- ogrListLayers(kmlfile_1)
lyr_2 <- ogrListLayers(kmlfile_2)

#We have the KML with 4 beams (no Piura) and the other one with way heavier
ka_no_piura <- readOGR(kmlfile_1,lyr_1[2])
ka_piura <- readOGR(kmlfile_2,lyr_2[1])

ka_no_piura <- as(ka_no_piura, "SpatialLinesDataFrame")
ka_piura <- as(ka_piura, "SpatialLinesDataFrame")

ka <- rbind(ka_piura, ka_no_piura)

#Now you need to go to QGIS, import the KML file and export it to the dev database. 
#Once this is done, run the next code chunk
#writeOGR(ka, paste(output_path,"ka_band.kml", sep = "/"),  layer = 'ka', driver="KML")
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
query <- paste("DROP TABLE IF EXISTS ", schema_dev,".", table_satellite_ka_beams,sep = "")
dbGetQuery(con, query)
pgInsert(con, name = c(schema_dev, table_satellite_ka_beams), ka)
dbDisconnect(con)

#Normalize the structure of the data and upload it to prod

#Set connection data
exportKaBeams(schema_dev, table_satellite_ka_beams, schema)
