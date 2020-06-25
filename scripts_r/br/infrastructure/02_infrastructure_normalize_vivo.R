

```{r setup, include=FALSE}
#LIBRARIES
library(readxl)
library(xlsx)
library(RPostgreSQL)
library(rpostgis)
library(stringr)

#CONFIG
config_path <- '~/shared/rural_planner/config_files/config_br'
source(config_path)

#VARIABLES
intermediate_output_path <- paste0(input_path_infrastructure,"/intermediate outputs", sep="")

#geo and access info
file_name_main <- "Máster 2019 v9.2 - sem fórmulas.xlsx"
sheet_main <- "Sites"
skip_main <- 2

#transport file
file_name_toro <- "ConsolidadoSitesTORO_2019_09_v1_env_final.xlsx"
skip_toro <- 1

file_name_atoll <- "network_config_atoll_vivo.xlsx"
skip_atoll <- 0

file_name_satelite <- "PLANTA SATELITE 2019_Ku_C_medianetworks_overlay comprometido.xlsx"
skip_satelite <- 2


file_name_tb <- "TB_ESTRUTURAS_VERTICAIS_2019-11-04.xlsx"
skip_tb <- 0

mw_output <- "vivo_mw_pops_aux.rds"
fo_output <- "vivo_fo_pops_aux.rds"

table_vivo_test  <- "test_vivo_aux"
atoll_table_all <- 'vivo_coverage_site_aux'
table_vivo <- "sites_vivo_aux"

file_name_io <- "vivo_aux.rds"

source('~/shared/rural_planner/sql/br/infrastructure/02_updateDBVivo.R')
source('~/shared/rural_planner/sql/br/infrastructure/02_updateCoverageAreaAtoll.R')

#LOAD INPUTS
#Load geo and access info
geo_raw <- read_excel(paste(input_path_infrastructure, file_name_main, sep = "/"), skip=skip_main, sheet=sheet_main)

#Load transport file
tx_raw <- read_excel(paste(input_path_infrastructure, file_name_toro, sep = "/"),skip=skip_toro)
heights_raw <- read_excel(paste(input_path_infrastructure, file_name_atoll, sep = "/"),skip=skip_atoll)
satellite_raw <- read_excel(paste(input_path_infrastructure, file_name_satelite, sep = "/"),skip=skip_satelite)
infra_raw <- read_excel(paste(input_path_infrastructure, file_name_tb, sep = "/"),skip=skip_tb)


tx_mw_output <- readRDS(paste(intermediate_output_path, mw_output, sep="/"))
tx_fo_output <- readRDS(paste(intermediate_output_path, fo_output, sep="/"))

######################################################################################################################
#Process to normalize the input to a given normalized structure

#Normalized structure: (three chunks: infrastructure, access and transport)

#(ID, latitude, longitude, tower_height, owner, location_detail, tower_type 
#tech_2g, tech_3g, tech_4g, type, subtype, in_service, vendor, coverage_area_2g, coverage_area_3g, coverage_area_4g
#fiber, radio, satellite, satellite_band_in_use, radio_distance_km, last_mile_bandwidth)

#The ID will be that of the row from the data frame
######################################################################################################################


#Select useful columns from geo raw input

geo_int <- data.frame(geo_raw$UF,
                      geo_raw$Sigla,
                      geo_raw$"Nome Site",
                      geo_raw$Latitude,
                      geo_raw$Longitude,
                      geo_raw$Fornecedor,
                      geo_raw$Cobertura,
                      geo_raw$Altura,
                      geo_raw$`TEC Final 2018`,
                      geo_raw$`TEC Final 2019`,
                      geo_raw$Categoria,
                      stringsAsFactors = FALSE
                      )


#Change names of the variables we already have from geo raw

colnames(geo_int) <- c("id1",
                       "id2",
                       "location_detail",
                       "latitude",
                       "longitude",
                       "vendor",
                       "subtype",
                       "tower_height",
                       "tech2018",
                       "tech2019",
                       "status"
                       )

#Select useful columns from geo raw input

tx_int <- data.frame(tx_raw$CHAVE,
                     tx_raw$"Tec Science",
                     tx_raw$IBGE,
                     tx_raw$"Tipo Tx TORO",
                     stringsAsFactors = FALSE
                     )

#Change names of the variables we already have from tx raw

colnames(tx_int) <- c("internal_id",
                      "technology",
                      "IBGE_municipio",
                      "tx_type"
                      )


satellite_int <- data.frame(satellite_raw$`SITE A`,
                      satellite_raw$`LAT A`,
                      satellite_raw$`LONG A`,
                      stringsAsFactors = FALSE
                      )


#Change names of the variables we already have from satellite raw

colnames(satellite_int) <- c("internal_id",
                       "latitude",
                       "longitude"
                       )

## INFRA SOURCE
infra_int <- data.frame(infra_raw$LATITUDE,
                      infra_raw$LONGITUDE,
                      infra_raw$ALTURA,
                      infra_raw$PROPRIETARIO_SITE,
                      infra_raw$ENDERECO_SITE,
                      infra_raw$DES_TIPO_ESTRUTURA,
                      infra_raw$TIPO_EQUIPAMENTO,
                      infra_raw$SITUACAO,
                      infra_raw$UF,
                      infra_raw$SIGLA_SITE,
                      infra_raw$NOME_SITE,
                      stringsAsFactors = FALSE
                      )

#Change names of the variables we already have from infra raw
colnames(infra_int) <- c("latitude",
                        "longitude", 
                        "tower_height", 
                        "owner", 
                        "location_detail",
                        "tower_type",
                        "subtype", 
                        "in_service",
                        "id1",
                        "id2",
                        "tower_name"
                        )


## HEIGHTS SOURCE
heights_int <- data.frame(heights_raw$internal_id,
                      heights_raw$HEIGHT,
                      stringsAsFactors = FALSE
                      )


#Change names of the variables we already have from heights raw

colnames(heights_int) <- c("internal_id",
                            "height")

#Normalize all to merge tables with "internal_id" 

satellite_int <- satellite_int[!is.na(satellite_int$internal_id),]

#internal_id:
geo_int$internal_id <- paste0(geo_int$id1,geo_int$id2)
infra_int$internal_id <- paste0(infra_int$id1,infra_int$id2)

#Merge both dataframes 

vivo_int <- Reduce(function(x, y) merge(x, y, by.x="internal_id", by.y="internal_id", all=TRUE), list(tx_int,geo_int, infra_int, heights_int))

```


```{r}

######################################################################################################################

#Fill vivo_int with the rest of the fields and reshape where necessary

#Location_detail to upper case
vivo_int$location_detail <- toupper(vivo_int$location_detail.x)


#Longitude: ad-hoc modification, missing negative sign
vivo_int$longitude <- ifelse(is.na(as.numeric(vivo_int$longitude.x)),as.numeric(vivo_int$longitude.y),as.numeric(vivo_int$longitude.x))


#Latitude from excel is preferred
vivo_int$latitude <- ifelse(is.na(as.numeric(vivo_int$latitude.x)),as.numeric(vivo_int$latitude.y),as.numeric(vivo_int$latitude.x))


#Vendor to upper case
vivo_int$vendor <- toupper(vivo_int$vendor)


#Subtype to upper case
vivo_int$subtype <- ifelse(is.na(toupper(vivo_int$subtype.x)),toupper(vivo_int$subtype.y),toupper(vivo_int$subtype.x))


#Technology to tech_2g, tech_3g and tech_4g
vivo_int$tech_2g <- FALSE
vivo_int$tech_3g <- FALSE
vivo_int$tech_4g <- FALSE

vivo_int[grepl("G", vivo_int$tech2018) | grepl("G", vivo_int$tech2019) | grepl("2G", vivo_int$technology), 'tech_2g'] <- TRUE
vivo_int[grepl("W", vivo_int$tech2018) | grepl("W", vivo_int$tech2019) | grepl("3G", vivo_int$technology), 'tech_3g'] <- TRUE
vivo_int[grepl("L", vivo_int$tech2018) | grepl("L", vivo_int$tech2019) | grepl("4G", vivo_int$technology), 'tech_4g'] <- TRUE

#Tower height: as integer
vivo_int$tower_height.x <- as.numeric(vivo_int$tower_height.x)
vivo_int$tower_height.y <- as.numeric(vivo_int$tower_height.y)
vivo_int$height <- as.numeric(vivo_int$height)
vivo_int$tower_height <- apply(vivo_int[,c("tower_height.x", "tower_height.y", "height")], 1, max, na.rm=TRUE) 
vivo_int$tower_height[vivo_int$tower_height>1500] <- vivo_int$tower_height[vivo_int$tower_height>1500]/100
vivo_int$tower_height[vivo_int$tower_height>160] <- vivo_int$tower_height[vivo_int$tower_height>160]/10
vivo_int$tower_height[vivo_int$tower_height<0] <- NA
vivo_int$tower_height[is.na(vivo_int$tower_height)] <- round(mean(vivo_int$tower_height[!is.na(vivo_int$tower_height)]))

#Fiber, radio or satellite: create from transport tech field (tx_type)
vivo_int$tx_type <- toupper(vivo_int$tx_type)

vivo_int$radio <- FALSE
vivo_int$fiber <- FALSE
vivo_int$satellite <- FALSE

vivo_int[grepl("FIBRA", vivo_int$tx_type), 'fiber'] <- TRUE
vivo_int$radio[vivo_int$internal_id%in%tx_fo_output$internal_id] <- TRUE
vivo_int[grepl("RÁDIO", vivo_int$tx_type), 'radio'] <- TRUE
vivo_int[grepl("TRANSMISSÃO", vivo_int$subtype.y), 'radio'] <- TRUE
vivo_int$radio[vivo_int$internal_id%in%tx_mw_output$internal_id] <- TRUE
vivo_int$satellite[vivo_int$internal_id%in%satellite_int$internal_id] <- TRUE


#Type
vivo_int$type <- NA

vivo_int <-vivo_int[!(vivo_int$subtype.x=="Indoor" | vivo_int$subtype.x=="indoor"),]
vivo_int <-vivo_int[!grepl("LAMPSITE",vivo_int$subtype.x),]
vivo_int <-vivo_int[!grepl("LAMPSITE",vivo_int$subtype.x),]
vivo_int[vivo_int$subtype.x%in%c("Outdoor", "Móvel"), 'type'] <- "MACRO"
vivo_int[grepl("SMALLCELL", vivo_int$subtype.x), 'type'] <- "FEMTO"


#Owner:
vivo_int$owner <- "VIVO"
vivo_int$owner[grepl("RANSharing",vivo_int$status) & grepl("OI",vivo_int$location_detail) ] <- "OI"
vivo_int$owner[grepl("RANSharing",vivo_int$status) & grepl("TIM",vivo_int$location_detail) ] <- "TIM"


#In Service:
vivo_int$in_service <- 'IN SERVICE'
vivo_int$in_service[vivo_int$status == "NOVO"] <- "PLANNED"

vivo_int <- vivo_int[!(vivo_int$status=="REMANEJAMENTO"),]
vivo_int <- vivo_int[!(vivo_int$status=="DESATIVADO"),]

#Coverage area 2G, 3G and 4G
vivo_int$coverage_area_2g <- NA
vivo_int$coverage_area_2g <- as.character(vivo_int$coverage_area_2g)

vivo_int$coverage_area_3g <- NA
vivo_int$coverage_area_3g <- as.character(vivo_int$coverage_area_3g)

vivo_int$coverage_area_4g <- NA
vivo_int$coverage_area_4g <- as.character(vivo_int$coverage_area_4g)

### Update coverage area with Atoll
## Upload coverage per site from QGIS (gdb file in https://telefonicacorp.sharepoint.com/sites/Colabora_CCN2/IPT/Shared%20Documents/Forms/AllItems.aspx?id=%2Fsites%2FColabora%5FCCN2%2FIPT%2FShared%20Documents%2FInternet%20para%20Todos%20%2D%20Shared%2F13%5FBrasil%2FRural%20Planner%20Data%2Fatoll%20per%20site%20NORTH&viewid=54451a46%2D1d25%2D4f9c%2D99a5%2De033c250500e): RIGHT NOW ONLY NORTHERN SITES

vivo <- updateCoverageAreaAtoll(schema_dev, table_vivo_test, atoll_table_2g, atoll_table_3g, atoll_table_4g, atoll_table_all, vivo_int)


#Tower type:
vivo$tower_type <- "INFRASTRUCTURE"

vivo[((vivo$tech_2g == TRUE) | (vivo$tech_3g == TRUE) | (vivo$tech_4g == TRUE)), 'tower_type'] <- "ACCESS"

vivo[(((vivo$fiber == TRUE) | (vivo$radio == TRUE) | (vivo$satellite == TRUE)) 
          & (vivo$tower_type == "ACCESS")), 'tower_type'] <- "ACCESS AND TRANSPORT"

vivo[(((vivo$fiber == TRUE) | (vivo$radio == TRUE) | (vivo$satellite == TRUE)) 
          & (vivo$tower_type == "INFRASTRUCTURE")), 'tower_type'] <- "TRANSPORT"

#satellite band in use: no info so set NA
vivo$satellite_band_in_use <- NA
vivo$satellite_band_in_use <- as.character(vivo$satellite_band_in_use)


#radio_distance_km: no info on this
vivo$radio_distance_km <- NA
vivo$radio_distance_km <- as.numeric(vivo$radio_distance_km)


#last_mile_bandwidth: no info
vivo$last_mile_bandwidth <- NA
vivo$last_mile_bandwidth <- as.character(vivo$last_mile_bandwidth)


#Source file:
vivo$source_file <- file_name_main


#Source:
vivo$source <- "VIVO"

#Modify encoding
Encoding(vivo$location_detail) <- "UTF-8"
Encoding(vivo$tower_name) <- "UTF-8"

######################################################################################################################

######################################################################################################################

#Create final normalized data frame in the right order

#Final macro data frame
vivo <- vivo[,c("latitude",
                        "longitude", 
                        "tower_height", 
                        "owner", 
                        "location_detail",
                        "tower_type",
                        
                        "tech_2g", 
                        "tech_3g", 
                        "tech_4g", 
                        "type", 
                        "subtype", 
                        "in_service",
                        "vendor", 
                        "coverage_area_2g",
                        "coverage_area_3g",
                        "coverage_area_4g",
                        
                        "fiber",
                        "radio",
                        "satellite",
                        "satellite_band_in_use",
                        "radio_distance_km",
                        "last_mile_bandwidth",
                        
                        "source_file",
                        "source",
                        "internal_id",
                        "tower_name"
                        )]
vivo
######################################################################################################################


```





```{r export}
#Export the normalized output
saveRDS(vivo, paste(intermediate_output_path, file_name_io, sep = "/"))

test <- readRDS(paste(intermediate_output_path, file_name_io, sep = "/"))
identical(test, vivo)
```

```{r export}
#EXPORT 
updateDBVivo(schema_dev, table_vivo, vivo)
```
