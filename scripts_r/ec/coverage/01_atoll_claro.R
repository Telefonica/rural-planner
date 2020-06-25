library(gdalUtils)
library(RCurl)
library(curl)
library(raster)
library(rgeos)
library(rgdal)
library(pbapply)
library(rpostgis)
library(XML)
library(sf)
library(RPostgres)
library(RPostgreSQL)
library(DBI)

#DB Connection parameters
config_path <- '~/shared/rural_planner_r/config_files/config_ec'
source(config_path)

source('~/shared/rural_planner_r/sql/ec/coverage/createTableTecnologiesClaro.R')
source('~/shared/rural_planner_r/sql/ec/coverage/createCoverageTable.R')

## DOWNLOAD files FROM all country coverage by technology FROM: 
# http://186.71.19.36:8080/geoserver/web/wicket/bookmarkable/org.geoserver.web.demo.MapPreviewPage?1

folders_path <- "~/shared/rural_planner_r/data/ec/coverage/coberturas_claro"

#technologies <- c("2G","3G","4G")
technologies <- c("3G","4G")

kmlfilelist <- list.files(folders_path, pattern =".kml$", full.names=TRUE, recursive=FALSE)

# AD- HOC: 2G input file is too big for processing
kmlfilelist <- kmlfilelist[!(grepl("GSM", kmlfilelist))]

dfFiles <- data.frame()

for (i in (1:length(kmlfilelist))){
  aux <- data.frame( layers= sf::st_layers(kmlfilelist[i])$name, kml_name= kmlfilelist[i])
  dfFiles <- rbind(dfFiles, aux)
  rm(aux)
}

dfFiles$layers <- as.character(dfFiles$layers)
dfFiles$kml_name <- as.character(dfFiles$kml_name)


df_geoms <- do.call("rbind",pblapply(as.numeric(row.names(dfFiles)),function(x) {sf::read_sf(dfFiles$kml_name[x],layer=dfFiles$layers[x])}))

df_geoms <- df_geoms[as.character(sf::st_geometry_type(df_geoms$geometry))=="GEOMETRYCOLLECTION",]
df_geoms <- df_geoms[,c("Name", "geometry")]

#names(df_geoms) <- c("name", "geom")

df_geoms$tech <- NA
df_geoms$tech[grepl('LTE',df_geoms$Name)] <- "4G"

df_geoms$tech[grepl('UMTS',df_geoms$Name)] <- "3G"
#df_geoms$tech[grepl('GSM',df_geoms$name)] <- "2G"

names(df_geoms) <- c("name", "geom", "tech")

st_geometry(df_geoms) <- "geom"

df_geoms <- st_collection_extract(df_geoms, "POLYGON")

## for average optimistic coverage: FILTER by name LIKE '%ALTO%' or '%MEDIO%' (remove '%BAJO%')
createTableTecnologiesClaro(technologies, schema_dev, df_geoms, claro_atoll_table)

createCoverageTable(schema_dev, claro_atoll_table, technologies)

