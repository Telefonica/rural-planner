
#Load libraries
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(XLConnect)
library(XLConnectJars)
library(foreign)
library(rgdal)

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)

### SOURCE: https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib1541/index.htm

input_path <- paste(input_path_demography, "censo_departamentos", sep ='/')

#### SOURCES: http://www.geogpsperu.com/2017/08/descarga-gratis-centros-poblados-censo.html  ->  https://drive.google.com/drive/folders/0By1rYqKYtPp5YnJ5MjJhWUxCckk for main source file
### http://catalogo.geoidep.gob.pe/metadatos/srv/spa/catalog.search;jsessionid=445C9B2747A110273ED020E1479BF616#/metadata/2d20144d-22f6-4609-bde6-9c9b686fdf57 for complementary source file

dbfFile <- paste(input_path_demography, 'Centros Poblados INEI', 'Centros Poblado Base INEI_geogpsperu.dbf', sep='/')

shpFile2 <- paste(input_path_demography, 'Centros Poblados Armonizados','Armonizado2012.shp', sep='/')

source('~/shared/rural_planner/sql/pe/demography/exportSettlementsBasic.R')
source('~/shared/rural_planner/sql/pe/demography/processSettlementsDB.R')

excel_path <- paste(input_path, file_names_demography, sep='/')

## Read all files and join them

settlements_all_raw <- do.call("rbind",lapply(excel_path[1:26], read_excel, col_names = as.character(c("settlement_id",                                                                                  "settlement_name",
                3:4,
                "population_census",
                6:10))))

#### Load latitudes and longitudes

df_locations_INEI <- foreign::read.dbf(dbfFile)
df_locations_INEI <- df_locations_INEI[,c("IDCCPP","LONG_X","LAT_Y")]
 
names(df_locations_INEI) <- c("settlement_id","longitude","latitude")
 
df_locations_INEI$settlement_id <- as.character(df_locations_INEI$settlement_id)
df_locations_INEI$longitude <- as.numeric(as.character(df_locations_INEI$longitude))
df_locations_INEI$latitude <- as.numeric(as.character(df_locations_INEI$latitude))
 

shp_raw <- readOGR(shpFile2)

df_shp_locations <- as.data.frame(shp_raw@data[,c("IDARM_12")])
df_shp_locations$longitude <- shp_raw@coords[,"coords.x1"]
df_shp_locations$latitude <- shp_raw@coords[,"coords.x2"]
 
names(df_shp_locations) <- c("settlement_id","longitude","latitude")

######################################################################################################################

#Select useful columns from raw input

settlements_int <- settlements_all_raw[,c("settlement_id","settlement_name","population_census")]

### Initialise admin_division columns

settlements_int$admin_division_1_id <- NA
settlements_int$admin_division_1_name <- NA
settlements_int$admin_division_2_id <- NA
settlements_int$admin_division_2_name <- NA
settlements_int$admin_division_3_id <- NA
settlements_int$admin_division_3_name <- NA


### Clean rows that are not useful

settlements_int <- settlements_int[!is.na(settlements_int$settlement_id),]

settlements_int <- settlements_int[!grepl("DEPARTAMENTO",settlements_int$settlement_id),]
settlements_int <- settlements_int[!grepl("PROVINCIA",settlements_int$settlement_id),]
settlements_int <- settlements_int[!grepl("REGIÓN",settlements_int$settlement_id),]
settlements_int <- settlements_int[!grepl("1/ Comprende viviendas ",settlements_int$settlement_id),]
settlements_int <- settlements_int[!grepl("2/ Centro poblado con",settlements_int$settlement_id),]
settlements_int <- settlements_int[!grepl("Fuente: INEI",settlements_int$settlement_id),]
settlements_int <- settlements_int[!grepl("CÓDIGO",settlements_int$settlement_id),]


## DEFINE REGION NAMES AND IDs
regions_rows <- sort(c(grep("REGIÓN",settlements_int$settlement_name),which(nchar(settlements_int$settlement_id)==2)))

for (i in (1:(length(regions_rows)-1))){
  admin_division_3_id <- settlements_int$settlement_id[regions_rows[i]]
  admin_division_3_name <- gsub("DEPARTAMENTO ","",settlements_int$settlement_name[regions_rows[i]])
  admin_division_3_name <- gsub("REGIÓN ","",admin_division_3_name)
  settlements_int$admin_division_3_id[((regions_rows[i]+1):(regions_rows[i+1]-1))] <- admin_division_3_id
  settlements_int$admin_division_3_name[((regions_rows[i]+1):(regions_rows[i+1]-1))] <- admin_division_3_name
}

# Last region
admin_division_3_id <- settlements_int$settlement_id[tail(regions_rows,n=1)]
admin_division_3_name <- gsub("PROVINCIA ","",settlements_int$settlement_name[tail(regions_rows,n=1)])
settlements_int$admin_division_3_id[((tail(regions_rows,n=1)+1):nrow(settlements_int))] <- admin_division_3_id
settlements_int$admin_division_3_name[((tail(regions_rows,n=1)+1):nrow(settlements_int))] <- admin_division_3_name


### Remove admin division 3 columns (Departments, regions and Callao)
settlements_int <- settlements_int[!grepl("REGIÓN",settlements_int$settlement_name),]
settlements_int <- settlements_int[!(nchar(settlements_int$settlement_id)==2),]


## DEFINE PROVINCE NAMES AND IDs
provinces_rows <- grep("PROVINCIA",settlements_int$settlement_name)

for (i in (1:(length(provinces_rows)-1))){
  admin_division_2_id <- settlements_int$settlement_id[provinces_rows[i]]
  admin_division_2_name <- gsub("PROVINCIA ","",settlements_int$settlement_name[provinces_rows[i]])
  settlements_int$admin_division_2_id[((provinces_rows[i]+1):(provinces_rows[i+1]-1))] <- admin_division_2_id
  settlements_int$admin_division_2_name[((provinces_rows[i]+1):(provinces_rows[i+1]-1))] <- admin_division_2_name
}

# Last province
admin_division_2_id <- settlements_int$settlement_id[tail(provinces_rows,n=1)]
admin_division_2_name <- gsub("PROVINCIA ","",settlements_int$settlement_name[tail(provinces_rows,n=1)])
settlements_int$admin_division_2_id[((tail(provinces_rows,n=1)+1):nrow(settlements_int))] <- admin_division_2_id
settlements_int$admin_division_2_name[((tail(provinces_rows,n=1)+1):nrow(settlements_int))] <- admin_division_2_name

settlements_int <- settlements_int[!grepl("PROVINCIA",settlements_int$settlement_name),]


## DEFINE DISTRICT NAMES AND IDs AND SETTLEMENT IDs (concatenation of district ID + actual settlement ID)
districts_rows <- grep("DISTRITO",settlements_int$settlement_name)

for (i in (1:(length(districts_rows)-1))){
  admin_division_1_id <- settlements_int$settlement_id[districts_rows[i]]
  admin_division_1_name <- gsub("DISTRITO ","",settlements_int$settlement_name[districts_rows[i]])
  settlements_int$settlement_id[((districts_rows[i]+1):(districts_rows[i+1]-1))] <- paste0(admin_division_1_id,settlements_int$settlement_id[((districts_rows[i]+1):(districts_rows[i+1]-1))])
  settlements_int$admin_division_1_id[((districts_rows[i]+1):(districts_rows[i+1]-1))] <- admin_division_1_id
  settlements_int$admin_division_1_name[((districts_rows[i]+1):(districts_rows[i+1]-1))] <- admin_division_1_name
}

#Last district
admin_division_1_id <- settlements_int$settlement_id[tail(districts_rows,n=1)]
admin_division_1_name <- settlements_int$settlement_name[tail(districts_rows,n=1)]
settlements_int$settlement_id[(tail(districts_rows,n=1):nrow(settlements_int))] <- paste0(admin_division_1_id,settlements_int$settlement_id[(tail(districts_rows,n=1):nrow(settlements_int))])
settlements_int$admin_division_1_id[(tail(districts_rows,n=1):nrow(settlements_int))] <- admin_division_1_id
settlements_int$admin_division_1_name[(tail(districts_rows,n=1):nrow(settlements_int))] <- admin_division_1_name

settlements_int <- settlements_int[!grepl("DISTRITO",settlements_int$settlement_name),]


#Population: remove white spaces and introduce NA 
settlements_int[grepl("-",settlements_int$population_census),"population_census"]<-NA
settlements_int$population_census <- as.numeric(gsub(" ","",settlements_int$population_census))

settlements_int$population_census[is.na(settlements_int$population_census)] <- 0

settlements_int$population_corrected <- settlements_int$population_census

#### Merge with latitudes and longitudes

 
df_shp_locations$settlement_id <- as.character(df_shp_locations$settlement_id)
df_shp_locations$longitude <- as.numeric(df_shp_locations$longitude)
df_shp_locations$latitude <- as.numeric(df_shp_locations$latitude)
 

duplicated_rows <- match(df_locations_INEI$settlement_id,df_shp_locations$settlement_id)
 
new_locations_df <- rbind(df_locations_INEI,df_shp_locations[-duplicated_rows[!is.na(duplicated_rows)],])

settlements_int <- merge(settlements_int, new_locations_df, by.x="settlement_id", by.y="settlement_id", all.x=TRUE)



#Create final dataframe

settlements <- settlements_int[,c("settlement_id",
                                  "settlement_name",
                                  "admin_division_1_id",
                                  "admin_division_1_name",
                                  "admin_division_2_id",
                                  "admin_division_2_name",
                                  "admin_division_3_id",
                                  "admin_division_3_name",
                                  "population_census",
                                  "population_corrected",
                                  "latitude",
                                  "longitude")]

#### Add missing settlements that appear in Rural Eye
# Manually created from rural_eye data, new census data.

missing_settlements <- read_excel(paste(input_path_demography,file_name_demography,sep="/"))

settlements <- rbind(settlements, missing_settlements[!(missing_settlements$settlement_id%in%settlements$settlement_id),])


#upload to database and left join with existing table
exportSettlementsBasic(schema_dev, table_settlements, settlements)

# Processes for which PostgreSQL is needed (or is more efficient):
processSettlementsDB(schema_dev, table_settlements)

