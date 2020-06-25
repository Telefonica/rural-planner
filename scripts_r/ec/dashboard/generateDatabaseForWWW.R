library(sqldf)
library(RPostgreSQL)
library(rpostgis)
library(RSQLite)
library(stringr)

############################################################################################
#    Generating data from ruralplanner database 
############################################################################################

#Establish connection to database
config_path <- '~/shared/rural_planner/config_files/config_ec'
source(config_path)


drv <- dbDriver("PostgreSQL")
conPG <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)

# Load inputs


# Input for Tabs 1 and 2: 'Segmentacion oportunidad' and 'Priorizacion centros poblados'

query <- paste0("SELECT b.centro_poblado, b.canton, b.provincia, b.poblacion, b.longitude, b.latitude, d.*, c.cobertura_movistar, c.cobertura_claro, c.cobertura_cnt, c.cobertura_competidores,
CASE WHEN a.torre_acceso IS NULL THEN 'NO' ELSE 'SI' END as acceso_disponible,
a.km_dist_torre_acceso, a.owner_torre_acceso, a.los_acceso_transporte, a.altura_torre_acceso, a.tipo_torre_acceso as subtipo_torre_acceso,
a.torre_acceso_source as tipo_torre_acceso, a.tecnologia_torre_acceso, a.torre_acceso_internal_id, a.latitude_torre_acceso, a.longitude_torre_acceso,
CASE WHEN a.torre_transporte IS NULL THEN 'NO' ELSE 'SI' END as transporte_disponible,
a.km_dist_torre_transporte, a.owner_torre_transporte, a.altura_torre_transporte,
a.tipo_torre_transporte as tecnologia_torre_transporte,
a.torre_transporte_source as tipo_torre_transporte,
a.banda_satelite_torre_transporte, torre_transporte_internal_id, a.latitude_torre_transporte, a.longitude_torre_transporte,
torre_transporte_movistar_optima,
distancia_torre_transporte_movistar_optima,
torre_transporte_regional_optima,
distancia_torre_transporte_regional_optima,
torre_transporte_terceros_optima,
distancia_torre_transporte_terceros_optima,
cl.centroid as id_cluster,
ST_AsText(ST_GeomFromEWKB(a.geom_line_torre_acceso)) as line_acceso,
ST_AsText(ST_GeomFromEWKB(a.geom_line_trasnporte_torre_acceso)) as line_transporte,
ST_AsText(ST_GeomFromEWKB(geom_line_torre_transporte)) as line_transporte_cp
FROM ", schema, ".", settlements_view, " b
LEFT JOIN ", schema, ".", segmentation_view, " d
ON d.codigo_divipola=b.codigo_divipola
LEFT JOIN ", schema, ".", coverage_view, " c
ON d.codigo_divipola=c.codigo_divipola
LEFT JOIN ", schema, ".", access_transport_view, " a
ON d.codigo_divipola=a.codigo_divipola
LEFT JOIN (SELECT CASE WHEN node_2_id='' then centroid else node_2_id END as node, 
                            centroid 
          FROM ", schema, ".", clusters_links_table,") cl
ON cl.node=d.codigo_divipola;")

input_tab_2 <- dbGetQuery(conPG,query)

Encoding(input_tab_2$provincia) <- "UTF-8"
input_tab_2$provincia <- enc2native(input_tab_2$provincia)

Encoding(input_tab_2$canton) <- "UTF-8"
input_tab_2$canton <- enc2native(input_tab_2$canton)

Encoding(input_tab_2$centro_poblado) <- "UTF-8"
input_tab_2$centro_poblado <- enc2native(input_tab_2$centro_poblado)

input_tab_2$segmentacion[input_tab_2$segmento_telefonica!='TELEFONICA UNSERVED'] <- 'TELEFONICA SERVED'
input_tab_2$segmentacion[input_tab_2$segmento_overlay=='OVERLAY'] <- 'OVERLAY'
input_tab_2$segmentacion[input_tab_2$segmento_greenfield=='GREENFIELD'] <- 'GREENFIELD'


input_tab_2$tx_owner <- input_tab_2$owner_torre_transporte
input_tab_2$poblacion[is.na(input_tab_2$poblacion)] <- 0


# Input for 3rd tab: Priorización clusters

query <- paste0("SELECT b.centroide, b.tipo_cluster,
CASE WHEN b.centros_poblados IS NULL THEN '-' ELSE b.centros_poblados END AS centros_poblados,
CASE WHEN b.parroquias IS NULL THEN '-' ELSE b.parroquias END AS parroquias,
CASE WHEN b.cantones IS NULL THEN '-' ELSE b.cantones END AS cantones,
CASE WHEN b.provincias IS NULL THEN '-' ELSE b.provincias END AS provincias, b.tamano_cluster, b.poblacion_no_conectada_movistar, b.latitud as latitude, b.longitud as longitude, 
cv.competitors_presence_2g, cv.competitors_presence_3g, cv.competitors_presence_4g,
d.segmento_overlay, d.segmento_greenfield,
CASE WHEN a.torre_acceso IS NULL THEN 'NO' ELSE 'SI' END as acceso_disponible,
a.km_dist_torre_acceso, a.owner_torre_acceso, a.los_acceso_transporte, a.altura_torre_acceso, a.tipo_torre_acceso as subtipo_torre_acceso, a.tecnologia_torre_acceso,
a.torre_acceso_source as tipo_torre_acceso, a.torre_acceso_internal_id, a.latitude_torre_acceso, a.longitude_torre_acceso,
CASE WHEN a.torre_transporte IS NULL THEN 'NO' ELSE 'SI' END as transporte_disponible,
a.km_dist_torre_transporte, a.owner_torre_transporte, a.altura_torre_transporte,
a.tipo_torre_transporte as tecnologia_torre_transporte,
a.torre_transporte_source as tipo_torre_transporte,
a.banda_satelite_torre_transporte, a.torre_transporte_internal_id, a.latitude_torre_transporte, a.longitude_torre_transporte,
ST_AsText(a.geom_line_torre_acceso) as line_acceso,
ST_AsText(a.geom_line_transporte_torre_acceso) as line_transporte,
ST_AsText(geom_line_torre_transporte) as line_transporte_cp,
b.poblacion_fully_unconnected,
torre_acceso_movistar_optima,
torre_transporte_movistar_optima,
distancia_torre_transporte_movistar_optima,
torre_transporte_regional_optima,
distancia_torre_transporte_regional_optima,
torre_transporte_terceros_optima,
distancia_torre_transporte_terceros_optima,
b.id_nodos_cluster as ids_centros_poblados,
b.nombre_centroide,
ccpp_competitors_2g as ccpp_competidores_2g,
ccpp_competitors_3g as ccpp_competidores_3g,
ccpp_competitors_4g as ccpp_competidores_4g
FROM ", schema, ".", clusters_kpis_view," b
LEFT JOIN ", schema, ".", segmentation_c_view, " d
ON d.centroide=b.centroide
LEFT JOIN ", schema, ".", access_transport_c_view, " a
ON d.centroide=a.cluster_id
LEFT JOIN ", schema, ".", coverage_c_view, " cv
ON d.centroide=cv.centroid;")

input_tab_3 <- dbGetQuery(conPG, query)

query <- paste0('SELECT c.centroide, s.centro_poblado as centros_poblados, s.codigo_divipola,
CASE WHEN c.centroide=s.codigo_divipola THEN NULL ELSE c.nodes_centroide END as nodes_centroide,
CASE WHEN c.centroide=s.codigo_divipola THEN NULL ELSE c.lines_centroide END as lines_centroide
FROM
(SELECT ST_AsText(UNNEST(geom_links)) AS lines_centroide, ST_AsText(UNNEST(geom_nodes)) AS nodes_centroide, centroide
FROM ', schema, '.', clusters_view, ') c
LEFT JOIN ', schema, '.', settlements_view, ' s
ON nodes_centroide=ST_AsText(s.geom)')

input_tab_3_lines <- dbGetQuery(conPG, query)


Encoding(input_tab_3$provincias) <- "UTF-8"
input_tab_3$provincias <- enc2native(input_tab_3$provincias)
input_tab_3$provincias[is.na(input_tab_3$provincias)] <- '-'

Encoding(input_tab_3$cantones) <- "UTF-8"
input_tab_3$cantones <- enc2native(input_tab_3$cantones)
input_tab_3$cantones[is.na(input_tab_3$cantones)] <- '-'

Encoding(input_tab_3$centros_poblados) <- "UTF-8"
input_tab_3$centros_poblados <- enc2native(input_tab_3$centros_poblados)
input_tab_3$centros_poblados[is.na(input_tab_3$centros_poblados)] <- '-'

input_tab_3$segmentacion <- 'TORRE SIN POTENCIAL'
input_tab_3$segmentacion[grepl("OVERLAY",input_tab_3$segmento_overlay)] <- 'OVERLAY'
input_tab_3$segmentacion[grepl("GREENFIELD",input_tab_3$segmento_greenfield)] <- 'GREENFIELD'


input_tab_2$tx_owner <- input_tab_2$owner_torre_transporte
input_tab_2$tx_owner[is.na(input_tab_2$tx_owner)] <- '-'

input_tab_3$poblacion_no_conectada_movistar[is.na(input_tab_3$poblacion_no_conectada_movistar)] <- 0

input_tab_3$tecnologia_torre_transporte[is.na(input_tab_3$tecnologia_torre_transporte)] <- "-"

#Disconnect from database

dbDisconnect(conPG)

##################################################################################################
##################################################################################################
##################################################################################################
##################################################################################################
##################################################################################################

sqlitePath <- "."
setwd(sqlitePath)  
database <- 'rpdashboard.sqlite'

#Remove files if they already exist: 
if (file.exists(database) == TRUE) file.remove(database) 
db <- dbConnect(SQLite(), dbname=database)

dbWriteTable(conn = db, name = "input_tab_2", value = input_tab_2, row.names = FALSE)
dbWriteTable(conn = db, name = "input_tab_3", value = input_tab_3, row.names = FALSE)
dbWriteTable(conn = db, name = "input_tab_3_lines", value = input_tab_3_lines, row.names = FALSE)

dbDisconnect(db)








