
library(sqldf)
library(RPostgreSQL)
library(rpostgis)
library(RSQLite)

############################################################################################
#    Generating data from ruralplanner database 
############################################################################################

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_ar'
source(config_path)




drv <- dbDriver("PostgreSQL")
conPG <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd)

# Load inputs


# Input for Tabs 1 and 2: 'Segmentacion oportunidad' and 'Priorizacion centros poblados'

query <- paste0("SELECT distinct on (b.id_localidad) b.localidad, b.departamento, b.provincia, b.id_localidad,
                  b.poblacion, b.longitude, b.latitude,
                  b.region, b.zona_exclusividad, b.etapa_enacom, b.plan_2019,
                  d.segmento_telefonica, d.segmento_overlay, d.segmento_greenfield,
                  c.cobertura_movistar, c.cobertura_claro, c.cobertura_nextel,
                  c.cobertura_personal, c.cobertura_competidores,
                  CASE WHEN a.torre_acceso IS NULL THEN 'NO' ELSE 'SI' END as acceso_disponible,
                  a.km_dist_torre_acceso, a.los_acceso_transporte, a.owner_torre_acceso,
                  a.altura_torre_acceso, a.tipo_torre_acceso, a.tecnologia_torre_acceso, 
                  a.torre_acceso_internal_id, a.latitude_torre_acceso, a.longitude_torre_acceso,
                  CASE WHEN a.torre_transporte IS NULL THEN 'NO' ELSE 'SI' END as transporte_disponible,
                  a.km_dist_torre_transporte, a.owner_torre_transporte, a.altura_torre_transporte,
                  a.tipo_torre_transporte as tecnologia_torre_transporte,
                  CASE WHEN a.torre_transporte IN (SELECT tower_id 
                                                   FROM ", schema, ".", towers_table," 
                                                   WHERE tx_third_pty IS TRUE 
                                                   AND fiber IS FALSE AND radio IS FALSE) THEN 'OTROS' 
                       ELSE a.torre_transporte_source END as tipo_torre_transporte,
                  a.banda_satelite_torre_transporte, torre_transporte_internal_id, 
                  a.latitude_torre_transporte, a.longitude_torre_transporte,
                  torre_acceso_movistar_optima,
                  distancia_torre_acceso_movistar_optima,
                  torre_acceso_arsat_optima,
                  distancia_torre_acceso_arsat_optima,
                  torre_acceso_silica_optima,
                  distancia_torre_acceso_silica_optima,
                  torre_acceso_gigared_optima,
                  distancia_torre_acceso_gigared_optima,
                  torre_acceso_points_optima,
                  distancia_torre_acceso_points_optima,
                  torre_acceso_partners,
                  distancia_partners,
                  torre_transporte_movistar_optima,
                  distancia_torre_transporte_movistar_optima,
                  torre_transporte_arsat_optima,
                  distancia_torre_transporte_arsat_optima,
                  torre_transporte_silica_optima,
                  distancia_torre_transporte_silica_optima,
                  torre_transporte_gigared_optima,
                  distancia_torre_transporte_gigared_optima,
                  torre_transporte_points_optima,
                  distancia_torre_transporte_points_optima,
                  torre_transporte_otros_optima,
                  distancia_torre_transporte_otros_optima,
                  ST_AsText(ST_GeomFromEWKB(a.geom_line_torre_acceso)) as line_acceso,
                  ST_AsText(ST_GeomFromEWKB(a.geom_line_trasnporte_torre_acceso)) as line_transporte,
                  ST_AsText(ST_GeomFromEWKB(geom_line_torre_transporte)) as line_transporte_cp
                  FROM ", schema, ".", settlements_view, " b
                  LEFT JOIN ", schema, ".", segmentation_view, " d
                  ON d.ubigeo=b.id_localidad
                  LEFT JOIN ", schema, ".", coverage_view, " c
                  ON d.ubigeo=c.ubigeo
                  LEFT JOIN ", schema, ".", access_transport_view, " a
                  ON d.ubigeo=a.codigo_ccpp;")

input_tab_2 <- dbGetQuery(conPG,query)

input_tab_2$poblacion[is.na(input_tab_2$poblacion)] <-0


Encoding(input_tab_2$departamento) <- "UTF-8"
input_tab_2$departamento <- enc2native(input_tab_2$departamento)
input_tab_2$departamento[is.na(input_tab_2$departamento)] <- '-'

Encoding(input_tab_2$provincia) <- "UTF-8"
input_tab_2$provincia <- enc2native(input_tab_2$provincia)
input_tab_2$provincia[is.na(input_tab_2$provincia)] <- '-'

Encoding(input_tab_2$localidad) <- "UTF-8"
input_tab_2$localidad <- enc2native(input_tab_2$localidad)
input_tab_2$localidad[is.na(input_tab_2$localidad)] <- '-'

input_tab_2$segmentacion[input_tab_2$segmento_telefonica!='TELEFONICA UNSERVED'] <- 'TELEFONICA SERVED'
input_tab_2$segmentacion[grepl("OVERLAY",input_tab_2$segmento_overlay)] <- input_tab_2$segmento_overlay[grepl("OVERLAY",input_tab_2$segmento_overlay)]
input_tab_2$segmentacion[grepl("GREENFIELD",input_tab_2$segmento_greenfield)] <- input_tab_2$segmento_greenfield[grepl("GREENFIELD",input_tab_2$segmento_greenfield)]

input_tab_2$etapa_enacom[is.na(input_tab_2$etapa_enacom)] <- "NA"


# Input for 3rd tab: Priorización clusters

query <- paste0("SELECT b.centroide, b.nombre_centroide, b.tipo_cluster,
          CASE WHEN b.localidades IS NULL THEN '-' 
               ELSE b.localidades END AS localidades,
          CASE WHEN b.departamentos IS NULL THEN '-' 
               ELSE b.departamentos END AS departamentos,
          CASE WHEN b.provincias IS NULL THEN '-' 
               ELSE b.provincias END AS provincias, 
          b.tamano_cluster, b.poblacion_unserved, b.poblacion_total, b.latitud as latitude, b.longitud as longitude, 
          k.regiones, k.zona_exclusividad, k.etapas_enacom, k.plan_2019,
          cv.competitors_presence_2g, cv.competitors_presence_3g, cv.competitors_presence_4g,
          d.segmento_overlay, d.segmento_greenfield,
          CASE WHEN (a.torre_acceso IS NULL OR torre_acceso_partners IS NULL) THEN 'NO' 
               ELSE 'SI' END as acceso_disponible,
          a.km_dist_torre_acceso, a.owner_torre_acceso, a.altura_torre_acceso,
          a.tipo_torre_acceso as subtipo_torre_acceso, a.tecnologia_torre_acceso,
          CONCAT(a.torre_acceso_partners,' ; ',a.torre_acceso_source) as tipo_torre_acceso,
          a.torre_acceso_internal_id, a.latitude_torre_acceso, a.longitude_torre_acceso,
          CASE WHEN a.torre_transporte IS NULL THEN 'NO' 
               ELSE 'SI' END as transporte_disponible,
          a.km_dist_torre_transporte, a.owner_torre_transporte, a.altura_torre_transporte,
          a.tipo_torre_transporte as tecnologia_torre_transporte,
          CASE WHEN a.torre_transporte IN (SELECT tower_id 
                                           FROM ", schema, ".", towers_table," 
                                           WHERE tx_third_pty IS TRUE 
                                           AND fiber IS FALSE AND radio IS FALSE) THEN 'OTROS' 
               ELSE a.torre_transporte_source END as tipo_torre_transporte,
          a.banda_satelite_torre_transporte, a.torre_transporte_internal_id, 
          a.latitude_torre_transporte, a.longitude_torre_transporte,
          ST_AsText(a.geom_line_torre_acceso) as line_acceso,
          ST_AsText(a.geom_line_trasnporte_torre_acceso) as line_transporte,
          ST_AsText(geom_line_torre_transporte) as line_transporte_cp,
          torre_acceso_movistar_optima,
          distancia_torre_acceso_movistar_optima,
          torre_acceso_arsat_optima,
          distancia_torre_acceso_arsat_optima,
          torre_acceso_silica_optima,
          distancia_torre_acceso_silica_optima,
          torre_acceso_gigared_optima,
          distancia_torre_acceso_gigared_optima,
          torre_acceso_points_optima,
          distancia_torre_acceso_points_optima,
          torre_acceso_partners,
          torre_transporte_movistar_optima,
          distancia_torre_transporte_movistar_optima,
          torre_transporte_arsat_optima,
          distancia_torre_transporte_arsat_optima,
          torre_transporte_silica_optima,
          distancia_torre_transporte_silica_optima,
          torre_transporte_gigared_optima,
          distancia_torre_transporte_gigared_optima,
          torre_transporte_points_optima,
          distancia_torre_transporte_points_optima,
          torre_transporte_otros_optima,
          distancia_torre_transporte_otros_optima,
          b.id_nodos_cluster as ids_centros_poblados,
          a.los_acceso_transporte
          FROM ", schema, ".", clusters_view, " b
          LEFT JOIN ", schema, ".", clusters_kpis_view, " k
          ON k.centroide = b.centroide
          LEFT JOIN ", schema, ".", segmentation_c_view, " d
          ON b.centroide=d.centroide
          LEFT JOIN ", schema, ".", access_transport_c_view, " a
          ON d.centroide=a.cluster_id
          LEFT JOIN ", schema, ".", coverage_c_view, " cv
          ON d.centroide=cv.centroid
          WHERE b.poblacion_unserved>0;")

input_tab_3 <- dbGetQuery(conPG, query)

query <- paste0('SELECT c.centroide, s.localidad as localidades, s.id_localidad,
          CASE WHEN c.centroide=s.id_localidad THEN NULL 
               ELSE c.nodes_centroide END AS nodes_centroide,
          CASE WHEN c.centroide=s.id_localidad THEN NULL 
               ELSE c.lines_centroide END AS lines_centroide
          FROM
              (SELECT ST_AsText(UNNEST(geom_links)) AS lines_centroide, 
                      ST_AsText(UNNEST(geom_nodes)) AS nodes_centroide, 
                      centroide, poblacion_unserved
               FROM ', schema, '.', clusters_view, ') c
          LEFT JOIN ', schema, '.', settlements_view, ' s
          ON nodes_centroide=ST_AsText(s.geom)
          WHERE c.poblacion_unserved>0')

input_tab_3_lines <- dbGetQuery(conPG, query)

Encoding(input_tab_3$nombre_centroide) <- "UTF-8"
input_tab_3$nombre_centroide <- enc2native(input_tab_3$nombre_centroide)
input_tab_3$nombre_centroide[is.na(input_tab_3$nombre_centroide)] <- '-'

Encoding(input_tab_3$departamentos) <- "UTF-8"
input_tab_3$departamentos <- enc2native(input_tab_3$departamentos)
input_tab_3$departamentos[is.na(input_tab_3$departamentos)] <- '-'

Encoding(input_tab_3$provincias) <- "UTF-8"
input_tab_3$provincias <- enc2native(input_tab_3$provincias)
input_tab_3$provincias[is.na(input_tab_3$provincias)] <- '-'

Encoding(input_tab_3$localidades) <- "UTF-8"
input_tab_3$localidades <- enc2native(input_tab_3$localidades)
input_tab_3$localidades[is.na(input_tab_3$localidades)] <- '-'

input_tab_3$segmentacion <- NA
input_tab_3$segmentacion[grepl("OVERLAY",input_tab_3$segmento_overlay)] <- input_tab_3$segmento_overlay[grepl("OVERLAY",input_tab_3$segmento_overlay)]
input_tab_3$segmentacion[grepl("GREENFIELD",input_tab_3$segmento_greenfield)] <- input_tab_3$segmento_greenfield[grepl("GREENFIELD",input_tab_3$segmento_greenfield)]

input_tab_3$movistar_tx_disponible <- NA
input_tab_3$movistar_tx_disponible[!is.na(input_tab_3$torre_transporte_movistar_optima)] <- "SI"
input_tab_3$arsat_tx_disponible <- NA
input_tab_3$arsat_tx_disponible[!is.na(input_tab_3$torre_transporte_arsat_optima)] <- "SI"
input_tab_3$silica_tx_disponible <- NA
input_tab_3$silica_tx_disponible[!is.na(input_tab_3$torre_transporte_silica_optima)] <- "SI"
input_tab_3$gigared_tx_disponible <- NA
input_tab_3$gigared_tx_disponible[!is.na(input_tab_3$torre_transporte_gigared_optima)] <- "SI"
input_tab_3$points_tx_disponible <- NA
input_tab_3$points_tx_disponible[!is.na(input_tab_3$torre_transporte_points_optima)] <- "SI"


query <- paste0("SELECT cluster_id,
          b.poblacion_unserved,
          b.tamano_cluster,
          CASE WHEN b.localidades IS NULL THEN '-' ELSE b.localidades END AS localidades,
          CASE WHEN b.departamentos IS NULL THEN '-' ELSE b.departamentos END AS departamentos,
          CASE WHEN b.provincias IS NULL THEN '-' ELSE b.provincias END AS provincias,
          CASE WHEN a.torre_transporte IN (SELECT tower_id 
                                           FROM ", schema, ".", towers_table," 
                                           WHERE tx_third_pty IS TRUE 
                                           AND fiber IS FALSE AND radio IS FALSE) THEN 'OTROS' 
               ELSE a.torre_transporte_source END as tipo_torre_transporte,
          UNNEST(string_to_array(CONCAT(torre_acceso_partners,' ; ',torre_acceso_source, ' ; ', owner_torre_acceso),' ; ')) as tipo_torre_acceso
          FROM ", schema, ".", access_transport_c_view, " a
          LEFT JOIN ", schema, ".", clusters_view, " b
          ON b.centroide=a.cluster_id
          WHERE b.poblacion_unserved>0")

input_tab_3_access <- dbGetQuery(conPG, query)

input_tab_3_access[input_tab_3_access==''] <- NA

Encoding(input_tab_3_access$departamentos) <- "UTF-8"
input_tab_3_access$departamentos <- enc2native(input_tab_3_access$departamentos)
input_tab_3_access$departamentos[is.na(input_tab_3_access$departamentos)] <- '-'

Encoding(input_tab_3_access$provincias) <- "UTF-8"
input_tab_3_access$provincias <- enc2native(input_tab_3_access$provincias)
input_tab_3_access$provincias[is.na(input_tab_3_access$provincias)] <- '-'

Encoding(input_tab_3_access$localidades) <- "UTF-8"
input_tab_3_access$localidades <- enc2native(input_tab_3_access$localidades)
input_tab_3_access$localidades[is.na(input_tab_3_access$localidades)] <- '-'


# Input for 4th tab: Priorizacion clusters IPT

query <- paste0("SELECT b.centroide, b.nombre_centroide, b.tipo_cluster,
          CASE WHEN b.localidades IS NULL THEN '-' ELSE b.localidades END AS localidades,
          CASE WHEN b.departamentos IS NULL THEN '-' ELSE b.departamentos END AS departamentos,
          CASE WHEN b.provincias IS NULL THEN '-' ELSE b.provincias END AS provincias,
          b.tamano_cluster, b.poblacion_unserved, b.poblacion_total, b.latitud as latitude, b.longitud as longitude, 
          k.regiones, k.zona_exclusividad, k.etapas_enacom, k.plan_2019,
          cv.competitors_presence_2g, cv.competitors_presence_3g, cv.competitors_presence_4g,
          d.segmento_overlay, d.segmento_greenfield,
          CASE WHEN (a.torre_acceso IS NULL OR torre_acceso_partners IS NULL) THEN 'NO' 
               ELSE 'SI' END as acceso_disponible,
          a.km_dist_torre_acceso, a.owner_torre_acceso, a.altura_torre_acceso,
          a.tipo_torre_acceso as subtipo_torre_acceso, a.tecnologia_torre_acceso,
          CONCAT(a.torre_acceso_partners,' ; ',a.torre_acceso_source) as tipo_torre_acceso,
          a.torre_acceso_internal_id, a.latitude_torre_acceso, a.longitude_torre_acceso,
          CASE WHEN a.torre_transporte IS NULL THEN 'NO' ELSE 'SI' END as transporte_disponible,
          a.km_dist_torre_transporte, a.owner_torre_transporte, a.altura_torre_transporte,
          a.tipo_torre_transporte as tecnologia_torre_transporte,
          CASE WHEN a.torre_transporte IN (SELECT tower_id 
                                           FROM ", schema, ".", towers_table," 
                                           WHERE tx_third_pty IS TRUE 
                                           AND fiber IS FALSE AND radio IS FALSE) THEN 'OTROS' 
               ELSE a.torre_transporte_source END as tipo_torre_transporte,
          a.banda_satelite_torre_transporte, a.torre_transporte_internal_id, 
          a.latitude_torre_transporte, a.longitude_torre_transporte,
          ST_AsText(a.geom_line_torre_acceso) as line_acceso,
          ST_AsText(a.geom_line_trasnporte_torre_acceso) as line_transporte,
          ST_AsText(geom_line_torre_transporte) as line_transporte_cp,
          torre_acceso_movistar_optima,
          distancia_torre_acceso_movistar_optima,
          torre_acceso_arsat_optima,
          distancia_torre_acceso_arsat_optima,
          torre_acceso_silica_optima,
          distancia_torre_acceso_silica_optima,
          torre_acceso_gigared_optima,
          distancia_torre_acceso_gigared_optima,
          torre_acceso_points_optima,
          distancia_torre_acceso_points_optima,
          torre_acceso_partners,
          torre_transporte_movistar_optima,
          distancia_torre_transporte_movistar_optima,
          torre_transporte_arsat_optima,
          distancia_torre_transporte_arsat_optima,
          torre_transporte_silica_optima,
          distancia_torre_transporte_silica_optima,
          torre_transporte_gigared_optima,
          distancia_torre_transporte_gigared_optima,
          torre_transporte_points_optima,
          distancia_torre_transporte_points_optima,
          torre_transporte_otros_optima,
          distancia_torre_transporte_otros_optima,
          b.id_nodos_cluster as ids_centros_poblados,
          a.los_acceso_transporte
          FROM ", schema, ".", clusters_ipt_view, " b
          LEFT JOIN ", schema, ".", clusters_kpis_ipt_view, " k
          ON k.centroide = b.centroide
          LEFT JOIN ", schema, ".", segmentation_c_ipt_view, " d
          ON b.centroide=d.centroide
          LEFT JOIN ", schema, ".", access_transport_c_ipt_view, " a
          ON d.centroide=a.cluster_id
          LEFT JOIN ", schema, ".", coverage_c_ipt_view, " cv
          ON d.centroide=cv.centroid
          WHERE b.poblacion_unserved>0;")

input_tab_4 <- dbGetQuery(conPG, query)

query <- paste0('SELECT c.centroide, s.localidad as localidades, s.id_localidad,
          CASE WHEN c.centroide=s.id_localidad THEN NULL ELSE c.nodes_centroide END as nodes_centroide,
          CASE WHEN c.centroide=s.id_localidad THEN NULL ELSE c.lines_centroide END as lines_centroide
          FROM
              (SELECT ST_AsText(UNNEST(geom_links)) AS lines_centroide, 
                      ST_AsText(UNNEST(geom_nodes)) AS nodes_centroide, 
                      centroide, poblacion_unserved
              FROM ', schema, '.', clusters_ipt_view, ' ) c
          LEFT JOIN ', schema, '.', settlements_view, ' s
          ON nodes_centroide=ST_AsText(s.geom)
          WHERE c.poblacion_unserved>0')

input_tab_4_lines <- dbGetQuery(conPG, query)

Encoding(input_tab_4$nombre_centroide) <- "UTF-8"
input_tab_4$nombre_centroide <- enc2native(input_tab_4$nombre_centroide)
input_tab_4$nombre_centroide[is.na(input_tab_4$nombre_centroide)] <- '-'

Encoding(input_tab_4$departamentos) <- "UTF-8"
input_tab_4$departamentos <- enc2native(input_tab_4$departamentos)
input_tab_4$departamentos[is.na(input_tab_4$departamentos)] <- '-'

Encoding(input_tab_4$provincias) <- "UTF-8"
input_tab_4$provincias <- enc2native(input_tab_4$provincias)
input_tab_4$provincias[is.na(input_tab_4$provincias)] <- '-'

Encoding(input_tab_4$localidades) <- "UTF-8"
input_tab_4$localidades <- enc2native(input_tab_4$localidades)
input_tab_4$localidades[is.na(input_tab_4$localidades)] <- '-'

input_tab_4$segmentacion <- NA
input_tab_4$segmentacion[grepl("OVERLAY",input_tab_4$segmento_overlay)] <- input_tab_4$segmento_overlay[grepl("OVERLAY",input_tab_4$segmento_overlay)]
input_tab_4$segmentacion[grepl("GREENFIELD",input_tab_4$segmento_greenfield)] <- input_tab_4$segmento_greenfield[grepl("GREENFIELD",input_tab_4$segmento_greenfield)]

input_tab_4$movistar_tx_disponible <- NA
input_tab_4$movistar_tx_disponible[!is.na(input_tab_4$torre_transporte_movistar_optima)] <- "SI"
input_tab_4$arsat_tx_disponible <- NA
input_tab_4$arsat_tx_disponible[!is.na(input_tab_4$torre_transporte_arsat_optima)] <- "SI"
input_tab_4$silica_tx_disponible <- NA
input_tab_4$silica_tx_disponible[!is.na(input_tab_4$torre_transporte_silica_optima)] <- "SI"
input_tab_4$gigared_tx_disponible <- NA
input_tab_4$gigared_tx_disponible[!is.na(input_tab_4$torre_transporte_gigared_optima)] <- "SI"
input_tab_4$points_tx_disponible <- NA
input_tab_4$points_tx_disponible[!is.na(input_tab_4$torre_transporte_points_optima)] <- "SI"


Encoding(input_tab_4_lines$localidades) <- "UTF-8"
input_tab_4_lines$localidades <- enc2native(input_tab_4_lines$localidades)
input_tab_4_lines$localidades[is.na(input_tab_4_lines$localidades)] <- '-'

#Disconnect from database

dbDisconnect(conPG)

##################################################################################################
##################################################################################################
##################################################################################################
##################################################################################################
##################################################################################################

# Set working directory as needed
sqlitePath <- "."
setwd(sqlitePath)


database <- 'rpdashboard.sqlite'

#Remove files if they already exist: 
if (file.exists(database) == TRUE) file.remove(database) 
db <- dbConnect(SQLite(), dbname=database)

dbWriteTable(conn = db, name = "input_tab_2", value = input_tab_2, row.names = FALSE)
dbWriteTable(conn = db, name = "input_tab_3", value = input_tab_3, row.names = FALSE)
dbWriteTable(conn = db, name = "input_tab_3_lines", value = input_tab_3_lines, row.names = FALSE)
dbWriteTable(conn = db, name = "input_tab_3_access", value = input_tab_3_access, row.names = FALSE)
dbWriteTable(conn = db, name = "input_tab_4", value = input_tab_4, row.names = FALSE)
dbWriteTable(conn = db, name = "input_tab_4_lines", value = input_tab_4_lines, row.names = FALSE)
dbDisconnect(db)

