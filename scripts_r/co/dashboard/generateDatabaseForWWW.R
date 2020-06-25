library(sqldf)
library(RPostgreSQL)
library(rpostgis)
library(RSQLite)
library(stringr)

############################################################################################
#    Generating data from ruralplanner database 
############################################################################################

#Establish connection to database
config_path <- '~/shared/rural_planner/config_files/config_co'
source(config_path)

drv <- dbDriver("PostgreSQL")
conPG <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)

# Load inputs




# Input for Tabs 1 and 2: 'Segmentacion oportunidad' and 'Priorizacion centros poblados'

query <- paste0("SELECT b.centro_poblado, b.municipio, b.departamento, b.poblacion, b.longitude, b.latitude, d.*, c.cobertura_movistar, c.cobertura_claro, c.cobertura_tigo, c.cobertura_competidores,
c.claro_roaming_2g, claro_roaming_3g, claro_roaming_4g, tigo_roaming_2g, tigo_roaming_3g, tigo_roaming_4g,
CASE WHEN a.torre_acceso IS NULL THEN 'NO' ELSE 'SI' END as acceso_disponible, a.owner_torre_acceso, a.los_acceso_transporte, a.altura_torre_acceso, a.tipo_torre_acceso as subtipo_torre_acceso,
a.torre_acceso_source as tipo_torre_acceso, a.tecnologia_torre_acceso, a.torre_acceso_internal_id, a.latitude_torre_acceso, a.longitude_torre_acceso,
CASE WHEN a.torre_transporte IS NULL THEN 'NO' ELSE 'SI' END as transporte_disponible, a.owner_torre_transporte, a.altura_torre_transporte,
a.tipo_torre_transporte as tecnologia_torre_transporte,
a.torre_transporte_source as tipo_torre_transporte,
a.banda_satelite_torre_transporte, torre_transporte_internal_id, a.latitude_torre_transporte, a.longitude_torre_transporte,
a.torre_acceso_movistar_optima,
a.distancia_torre_acceso_movistar_optima,
a.torre_acceso_anditel_optima,
a.distancia_torre_acceso_anditel_optima,
a.torre_acceso_atc_optima,
a.distancia_torre_acceso_atc_optima,
torre_acceso_atp_optima,
distancia_torre_acceso_atp_optima,
torre_acceso_phoenix_optima,
distancia_torre_acceso_phoenix_optima,
torre_acceso_qmc_optima,
distancia_torre_acceso_qmc_optima,
torre_acceso_uniti_optima,
distancia_torre_acceso_uniti_optima,
torre_transporte_movistar_optima,
distancia_torre_transporte_movistar_optima,
torre_transporte_anditel_optima,
distancia_torre_transporte_anditel_optima,
torre_transporte_azteca_optima,
distancia_torre_transporte_azteca_optima,
torre_transporte_atc_optima,
distancia_torre_transporte_atc_optima,
torre_transporte_atp_optima,
a.distancia_torre_transporte_atp_optima,
torre_transporte_phoenix_optima,
distancia_torre_transporte_phoenix_optima,
torre_transporte_qmc_optima,
distancia_torre_transporte_qmc_optima,
torre_transporte_uniti_optima,
distancia_torre_transporte_uniti_optima,
escuelas,
b2bcoffee,
lluvias as lluvias_mm,
cl.centroid as id_cluster,
ST_AsText(ST_GeomFromEWKB(a.geom_line_torre_acceso)) as line_acceso,
ST_AsText(ST_GeomFromEWKB(a.geom_line_trasnporte_torre_acceso)) as line_transporte,
ST_AsText(ST_GeomFromEWKB(geom_line_torre_transporte)) as line_transporte_cp
FROM ", schema, ".", settlements_kpis_view," b
LEFT JOIN ", schema, ".", segmentation_view," d
ON d.codigo_divipola=b.codigo_divipola
LEFT JOIN ", schema, ".", coverage_view," c
ON d.codigo_divipola=c.codigo_divipola
LEFT JOIN ", schema, ".", access_transport_view," a
ON d.codigo_divipola=a.codigo_divipola
LEFT JOIN (SELECT CASE WHEN node_2_id='' then centroid else node_2_id END as node, 
                            centroid 
          FROM ", schema, ".", clusters_links_table,") cl
ON cl.node=d.codigo_divipola;")

input_tab_2 <- dbGetQuery(conPG,query)

Encoding(input_tab_2$departamento) <- "UTF-8"
input_tab_2$departamento <- enc2native(input_tab_2$departamento)

Encoding(input_tab_2$municipio) <- "UTF-8"
input_tab_2$municipio <- enc2native(input_tab_2$municipio)

Encoding(input_tab_2$centro_poblado) <- "UTF-8"
input_tab_2$centro_poblado <- enc2native(input_tab_2$centro_poblado)

input_tab_2$segmentacion[input_tab_2$segmento_telefonica!='TELEFONICA UNSERVED'] <- 'TELEFONICA SERVED'
input_tab_2$segmentacion[input_tab_2$segmento_overlay=='OVERLAY'] <- 'OVERLAY'
input_tab_2$segmentacion[input_tab_2$segmento_greenfield=='GREENFIELD'] <- 'GREENFIELD'

input_tab_2$tx_owner <- 'INFRA_PARTNERS'
input_tab_2$tx_owner[input_tab_2$tipo_torre_transporte=='AZTECA'] <- 'AZTECA'
input_tab_2$tx_owner[input_tab_2$tipo_torre_transporte=='CLARO'||input_tab_2$tipo_torre_transporte=='TIGO'] <- 'COMPETITORS'
input_tab_2$tx_owner[input_tab_2$tipo_torre_transporte=='ANDITEL'] <- 'ANDITEL'
input_tab_2$tx_owner[input_tab_2$tipo_torre_transporte=='SITES_TEF'] <- 'TELEFONICA'

input_tab_2$poblacion[is.na(input_tab_2$poblacion)] <- 0


# Input for 3rd tab: Priorización clusters

query <- paste0("SELECT b.centroide, b.tipo_cluster,
CASE WHEN b.centros_poblados IS NULL THEN '-' ELSE b.centros_poblados END AS centros_poblados,
CASE WHEN b.municipios IS NULL THEN '-' ELSE b.municipios END AS municipios, 
CASE WHEN b.departamentos IS NULL THEN '-' ELSE b.departamentos END AS departamentos, b.tamano_cluster, b.poblacion_no_conectada_movistar, b.poblacion_total, b.latitud as latitude, b.longitud as longitude, 
cv.competitors_presence_2g, cv.competitors_presence_3g, cv.competitors_presence_4g,
cv.claro_roaming_2g, claro_roaming_3g, claro_roaming_4g, tigo_roaming_2g, tigo_roaming_3g, tigo_roaming_4g, d.segmento_overlay, d.segmento_greenfield,
CASE WHEN a.torre_acceso IS NULL THEN 'NO' ELSE 'SI' END as acceso_disponible,
a.km_dist_torre_acceso, a.owner_torre_acceso, a.los_acceso_transporte, a.altura_torre_acceso, a.tipo_torre_acceso as subtipo_torre_acceso, a.tecnologia_torre_acceso,
a.torre_acceso_source as tipo_torre_acceso, a.torre_acceso_internal_id, a.latitude_torre_acceso, a.longitude_torre_acceso,
CASE WHEN a.torre_transporte IS NULL THEN 'NO' ELSE 'SI' END as transporte_disponible,
a.km_dist_torre_transporte, a.owner_torre_transporte, a.altura_torre_transporte,
a.tipo_torre_transporte as tecnologia_torre_transporte,
a.torre_transporte_source as tipo_torre_transporte,
a.banda_satelite_torre_transporte, a.torre_transporte_internal_id, a.latitude_torre_transporte, a.longitude_torre_transporte,
ST_AsText(a.geom_line_torre_acceso) as line_acceso,
ST_AsText(a.geom_line_trasnporte_torre_acceso) as line_transporte,
ST_AsText(geom_line_torre_transporte) as line_transporte_cp,
b.poblacion_fully_unconnected,
torre_acceso_movistar_optima,
distancia_torre_acceso_movistar_optima,
torre_acceso_anditel_optima,
distancia_torre_acceso_anditel_optima,
torre_acceso_atc_optima,
distancia_torre_acceso_atc_optima,
torre_acceso_atp_optima,
distancia_torre_acceso_atp_optima,
torre_acceso_phoenix_optima,
distancia_torre_acceso_phoenix_optima,
torre_acceso_qmc_optima,
distancia_torre_acceso_qmc_optima,
torre_acceso_uniti_optima,
distancia_torre_acceso_uniti_optima,
torre_transporte_movistar_optima,
distancia_torre_transporte_movistar_optima,
torre_transporte_anditel_optima,
distancia_torre_transporte_anditel_optima,
torre_transporte_azteca_optima,
distancia_torre_transporte_azteca_optima,
torre_transporte_atc_optima,
distancia_torre_transporte_atc_optima,
torre_transporte_atp_optima,
distancia_torre_transporte_atp_optima,
torre_transporte_phoenix_optima,
distancia_torre_transporte_phoenix_optima,
torre_transporte_qmc_optima,
distancia_torre_transporte_qmc_optima,
torre_transporte_uniti_optima,
distancia_torre_transporte_uniti_optima,
b.id_nodos_cluster as ids_centros_poblados,
b.nombre_centroide,
e.departamento_centroide,
e.municipio_centroide,
escuelas,
b2bcoffee,
lluvias as lluvias_mm,
f.id_centroide_transporte,
f.nombre_centroide_transporte,
f.tamano_cluster_tx,
f.poblacion_cluster_tx,
g.torre_transporte_movistar_optima_2,
distancia_torre_transporte_movistar_optima_2,
lv_torre_transporte_movistar_optima_2,
torre_transporte_anditel_optima_2,
distancia_torre_transporte_anditel_optima_2,
lv_torre_transporte_anditel_optima_2,
torre_transporte_azteca_optima_2,
distancia_torre_transporte_azteca_optima_2,
lv_torre_transporte_azteca_optima_2,
torre_transporte_atp_optima_2,
distancia_torre_transporte_atp_optima_2,
lv_torre_transporte_atp_optima_2,
torre_transporte_atc_optima_2,
distancia_torre_transporte_atc_optima_2,
lv_torre_transporte_atc_optima_2,
torre_transporte_phoenix_optima_2,
distancia_torre_transporte_phoenix_optima_2,
lv_torre_transporte_phoenix_optima_2,
torre_transporte_qmc_optima_2,
distancia_torre_transporte_qmc_optima_2,
lv_torre_transporte_qmc_optima_2,
torre_transporte_uniti_optima_2,
distancia_torre_transporte_uniti_optima_2,
lv_torre_transporte_uniti_optima_2,
ccpp_competitors_2g as ccpp_competidores_2g,
ccpp_competitors_3g as ccpp_competidores_3g,
ccpp_competitors_4g as ccpp_competidores_4g,
z.tamano as tamano_clasificacion_bc, z.type as segmento_clasificacion_bc, z.source as tipo_clasificacion_bc,
z.segmento as competidores_clasificacion_bc
FROM ", schema, ".", clusters_kpis_view," b
LEFT JOIN ", schema, ".", segmentation_c_view, " d
ON d.centroide=b.centroide
LEFT JOIN ", schema, ".", access_transport_c_view, " a
ON d.centroide=a.cluster_id
LEFT JOIN ", schema, ".", coverage_c_view, " cv
ON d.centroide=cv.centroid
LEFT JOIN (select  c.centroide,
            case when length(c.centroide) >= 8 then s.departamento else m.admin_division_2_name END AS departamento_centroide,
case when length(c.centroide) >= 8 then s.municipio else m.admin_division_1_name END AS municipio_centroide

FROM ", schema, ".", clusters_view," c
LEFT JOIN ", schema, ".", settlements_view," s 
ON c.centroide=s.codigo_divipola
LEFT JOIN ", schema_dev, ".", municipality_shp_table, " m 
ON ST_Within(c.geom_centroid::geometry, m.geom)
) e
ON b.centroide=e.centroide
LEFT JOIN ", schema, ".", clusters_tx_view, " f
ON b.centroide=f.centroide
LEFT JOIN ", schema, ".", clusters_greenfield_tx_view, " g
ON b.centroide=g.centroide
LEFT JOIN ", schema, ".", clusters_bc_view, "z
on z.ran_centroid=b.centroide;")

input_tab_3 <- dbGetQuery(conPG, query)

query <- paste0('SELECT c.centroide, s.centro_poblado as centros_poblados, s.codigo_divipola,
CASE WHEN c.centroide=s.codigo_divipola THEN NULL ELSE c.nodes_centroide END as nodes_centroide,
CASE WHEN c.centroide=s.codigo_divipola THEN NULL ELSE c.lines_centroide END as lines_centroide
FROM
(SELECT ST_AsText(UNNEST(geom_links)) AS lines_centroide, ST_AsText(UNNEST(geom_nodes)) AS nodes_centroide, centroide
FROM ', schema, '.', clusters_view,') c
LEFT JOIN ', schema, '.', settlements_view,' s
ON nodes_centroide=ST_AsText(s.geom)')

input_tab_3_lines <- dbGetQuery(conPG, query)


Encoding(input_tab_3$departamentos) <- "UTF-8"
input_tab_3$departamentos <- enc2native(input_tab_3$departamentos)
input_tab_3$departamentos[is.na(input_tab_3$departamentos)] <- '-'

Encoding(input_tab_3$municipios) <- "UTF-8"
input_tab_3$municipios <- enc2native(input_tab_3$municipios)
input_tab_3$municipios[is.na(input_tab_3$municipios)] <- '-'

Encoding(input_tab_3$centros_poblados) <- "UTF-8"
input_tab_3$centros_poblados <- enc2native(input_tab_3$centros_poblados)
input_tab_3$centros_poblados[is.na(input_tab_3$centros_poblados)] <- '-'

Encoding(input_tab_3$municipio_centroide) <- "UTF-8"
input_tab_3$municipio_centroide <- enc2native(input_tab_3$municipio_centroide)
input_tab_3$municipio_centroide[is.na(input_tab_3$municipio_centroide)] <- '-'

Encoding(input_tab_3$departamento_centroide) <- "UTF-8"
input_tab_3$departamento_centroide <- enc2native(input_tab_3$departamento_centroide)
input_tab_3$departamento_centroide[is.na(input_tab_3$departamento_centroide)] <- '-'


Encoding(input_tab_3$tamano_clasificacion_bc) <- "UTF-8"
input_tab_3$tamano_clasificacion_bc <- enc2native(input_tab_3$tamano_clasificacion_bc)

input_tab_3$segmentacion <- 'TORRE SIN POTENCIAL'
input_tab_3$segmentacion[grepl("OVERLAY",input_tab_3$segmento_overlay)] <- 'OVERLAY'
input_tab_3$segmentacion[grepl("GREENFIELD",input_tab_3$segmento_greenfield)] <- 'GREENFIELD'


input_tab_3$tx_owner <- 'INFRA_PARTNERS'
input_tab_3$tx_owner[input_tab_3$tipo_torre_transporte=='AZTECA'] <- 'AZTECA'
input_tab_3$tx_owner[input_tab_3$tipo_torre_transporte=='CLARO'||input_tab_3$tipo_torre_transporte=='TIGO'] <- 'COMPETITORS'
input_tab_3$tx_owner[input_tab_3$tipo_torre_transporte=='ANDITEL'] <- 'ANDITEL'
input_tab_3$tx_owner[input_tab_3$tipo_torre_transporte=='SITES_TEF'] <- 'TELEFONICA'

input_tab_3$poblacion_total[is.na(input_tab_3$poblacion_total)] <- 0

input_tab_3$municipios <- str_replace_all(input_tab_3$municipios,"\\(","")
input_tab_3$municipios <- str_replace_all(input_tab_3$municipios,"\\)","")

input_tab_3$tecnologia_torre_transporte[is.na(input_tab_3$tecnologia_torre_transporte)] <- "-"


# Input for 4th tab: Localización por coordenadas

query <- paste0("SELECT internal_id, tower_id,
      latitude, longitude, tower_height, owner, location_detail,
tower_type, tech_2g, tech_3g, tech_4g,type,
subtype,
in_service,
vendor,
fiber,
radio,
satellite,
satellite_band_in_use,
radio_distance_km,
last_mile_bandwidth,
source_file, 
source,
closest_cluster,
in_cluster,
distance_to_centroid
FROM ", schema, ".", infrastructure_view,"
 ORDER BY tower_id")

input_tab_4 <- dbGetQuery(conPG, query)

input_tab_4$icon_owner <- 'INFRA_PARTNERS'
input_tab_4$icon_owner[input_tab_4$source=='AZTECA'] <- 'AZTECA'
input_tab_4$icon_owner[input_tab_4$source=='CLARO'||input_tab_4$source=='TIGO'] <- 'COMPETITORS'
input_tab_4$icon_owner[input_tab_4$source=='ANDITEL'] <- 'ANDITEL'
input_tab_4$icon_owner[input_tab_4$source=='SITES_TEF'] <- 'TELEFONICA'

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
dbWriteTable(conn = db, name = "input_tab_4", value = input_tab_4, row.names = FALSE)

dbDisconnect(db)








