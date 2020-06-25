#Libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(rgdal)
library(gdalUtils)
library(postGIStools)
library(maptools)
library(raster)
library(sp)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

### VARIABLES ###
file_name <- "Bogota_Bogota_PIRE.KMZ"

source('~/shared/rural_planner/sql/co/infrastructure/uploadToProd.R')
source('~/shared/rural_planner/sql/co/infrastructure/createInfraAuxTable.R')

#Load KMLs
kmzfile <- paste(input_path_infrastructure,  file_name, sep = "/")

raw_polygons <- getKMLcoordinates(unzip(kmzfile), ignoreAltitude = T)

lyr_5 <- raw_polygons[2]
lyr_4 <- raw_polygons[3]
lyr_3 <- raw_polygons[4]
lyr_2 <- raw_polygons[5]
lyr_1 <- raw_polygons[6]


#We create spatial objects and define CRS

P1 = Polygon(lyr_1)
P2 = Polygon(lyr_2)
P3 = Polygon(lyr_3)
P4 = Polygon(lyr_4)
P5 = Polygon(lyr_5)

Ps1 = SpatialPolygons(list(Polygons(list(P1), ID = "-1"), Polygons(list(P2), ID = "-2"), Polygons(list(P3), ID = "-3"), Polygons(list(P4), ID = "-4"), Polygons(list(P5), ID = "-5")), proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))

#Normalize the structure of the data and upload it to prod
uploadToProd(schema_dev, table_satellite_ka_beams, Ps1)


## Create auxiliar infra table
createInfraAuxTable(schema, infrastructure_table, infrastructure_beams_table, table_satellite_ka_beams)

