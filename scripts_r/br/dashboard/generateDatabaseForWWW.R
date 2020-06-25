
###   DASHBOARD BRASIL   ###

library(sqldf)
library(RPostgreSQL)
library(rpostgis)
library(RSQLite)

############################################################################################
#    Generating data from ruralplanner database 
############################################################################################

#Establish connection to database
#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_br'
source(config_path)


drv <- dbDriver("PostgreSQL")
conPG <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd)


# Load inputs

# Input for Tabs 1 and 2: 'Segmentacion oportunidad' and 'Priorizacion centros poblados'

query <- paste0("SELECT b.centro_poblado,
                 b.distrito,
                 b.municipio,
                 b.estado,
                 b.poblacion,
                 b.longitude, 
                 b.latitude, 
                 d.*, 
                 c.cobertura_claro,
                 c.cobertura_oi,
                 c.cobertura_vivo,
                 c.cobertura_tim,
                 c.cobertura_competidores,
                   CASE WHEN a.torre_acceso IS NULL 
                      THEN 'NO' 
                      ELSE 'SI' END as acceso_disponible,
                 a.owner_torre_acceso,
                 a.altura_torre_acceso,
                 a.tipo_torre_acceso as subtipo_torre_acceso,
                 a.torre_acceso_source as tipo_torre_acceso,
                 a.tecnologia_torre_acceso,
                 a.torre_acceso_internal_id,
                 a.latitude_torre_acceso,
                 a.longitude_torre_acceso,
                   CASE WHEN a.torre_transporte IS NULL 
                      THEN 'NO' 
                      ELSE 'SI' END as transporte_disponible,
                 a.owner_torre_transporte,
                 a.altura_torre_transporte,
                 a.tipo_torre_transporte as tecnologia_torre_transporte,
                 a.torre_transporte_source as tipo_torre_transporte,
                 a.banda_satelite_torre_transporte,
                 a.torre_transporte_internal_id,
                 a.latitude_torre_transporte,
                 a.longitude_torre_transporte,
                   ST_AsText(ST_GeomFromEWKB(a.geom_line_torre_acceso)) as line_acceso,
                   ST_AsText(ST_GeomFromEWKB(a.geom_line_transporte_torre_acceso)) as line_transporte,
                   ST_AsText(ST_GeomFromEWKB(geom_line_torre_transporte)) as line_transporte_cp

           FROM ", schema,".", settlements_view, " b
           
           LEFT JOIN ", schema,".", segmentation_view, " d
                ON d.codigo_setor=b.codigo_setor
           LEFT JOIN ", schema,".", coverage_view, " c
                ON d.codigo_setor=c.codigo_setor
           LEFT JOIN ", schema,".", access_transport_view, " a
                ON d.codigo_setor=a.codigo_setor;")

input_tab_2 <- dbGetQuery(conPG,query)

Encoding(input_tab_2$distrito) <- "UTF-8"
input_tab_2$distrito <- enc2native(input_tab_2$distrito)

Encoding(input_tab_2$municipio) <- "UTF-8"
input_tab_2$municipio <- enc2native(input_tab_2$municipio)

Encoding(input_tab_2$estado) <- "UTF-8"
input_tab_2$estado <- enc2native(input_tab_2$estado)

Encoding(input_tab_2$centro_poblado) <- "UTF-8"
input_tab_2$centro_poblado <- enc2native(input_tab_2$centro_poblado)

input_tab_2$segmentacion[input_tab_2$segmento_telefonica!='TELEFONICA UNSERVED'] <- 'TELEFONICA SERVED'
input_tab_2$segmentacion[input_tab_2$segmento_overlay=='OVERLAY'] <- 'OVERLAY'
input_tab_2$segmentacion[input_tab_2$segmento_greenfield=='GREENFIELD'] <- 'GREENFIELD'

input_tab_2$poblacion[is.na(input_tab_2$poblacion)] <- 0


# Input for 3rd tab: Priorización clusters

query <- paste0("SELECT b.centroide, 
                 b.tipo_cluster,
                 b.centros_poblados,
                 b.distritos,
                 b.municipios,
                 b.estados,
                 b.tamano_cluster,
                 b.poblacion_no_conectada_movistar,
                 b.poblacion_total, 
                 b.latitud as latitude,
                 b.longitud as longitude, 
                 cv.competitors_presence_2g,
                 cv.competitors_presence_3g,
                 cv.competitors_presence_4g, 
                 d.segmento_overlay, 
                 d.segmento_greenfield,
                   CASE WHEN a.torre_acceso IS NULL 
                      THEN 'NO' 
                      ELSE 'SI' END as acceso_disponible,
                 a.km_dist_torre_acceso, 
                 a.owner_torre_acceso,
                 a.altura_torre_acceso,
                 a.tipo_torre_acceso as subtipo_torre_acceso, 
                 a.tecnologia_torre_acceso,
                 a.torre_acceso_source as tipo_torre_acceso,
                 a.torre_acceso_internal_id,
                 a.latitude_torre_acceso, 
                 a.longitude_torre_acceso,
                   CASE WHEN a.torre_transporte IS NULL 
                      THEN 'NO' 
                      ELSE 'SI' END as transporte_disponible,
                 a.km_dist_torre_transporte,
                 a.owner_torre_transporte,
                 a.altura_torre_transporte,
                 a.tipo_torre_transporte as tecnologia_torre_transporte,
                 a.torre_transporte_source as tipo_torre_transporte,
                 a.banda_satelite_torre_transporte, 
                 a.torre_transporte_internal_id, 
                 a.latitude_torre_transporte, 
                 a.longitude_torre_transporte,
                   ST_AsText(a.geom_line_torre_acceso) as line_acceso,
                   ST_AsText(a.geom_line_transporte_torre_acceso) as line_transporte,
                   ST_AsText(a.geom_line_torre_transporte) as line_transporte_cp,
                 b.poblacion_fully_unconnected,
                 b.id_nodos_cluster as ids_centros_poblados

          FROM ", schema,".", clusters_view, " b
          
          LEFT JOIN ", schema,".", segmentation_c_view, " d
               ON d.centroide=b.centroide
          LEFT JOIN ", schema,".", access_transport_c_view, " a
               ON d.centroide=a.cluster_id
          LEFT JOIN ", schema,".", coverage_c_view, " cv
               ON d.centroide=cv.centroid;")

input_tab_3 <- dbGetQuery(conPG, query)

query <- paste0('SELECT c.centroide,
                 s.centro_poblado as centros_poblados,
                 s.codigo_setor,
                   CASE WHEN c.centroide=s.codigo_setor 
                        THEN NULL 
                        ELSE c.nodes_centroide END as nodes_centroide,
                   CASE WHEN c.centroide=s.codigo_setor 
                        THEN NULL 
                        ELSE c.lines_centroide END as lines_centroide
          FROM
                (SELECT ST_AsText(UNNEST(geom_links)) AS lines_centroide,
                        ST_AsText(UNNEST(geom_nodes)) AS nodes_centroide, 
                        centroide

                 FROM ', schema,'.v_clusters) c

          LEFT JOIN ', schema,'.v_centros_poblados s
               ON nodes_centroide=ST_AsText(s.geom)')

input_tab_3_lines <- dbGetQuery(conPG, query)


Encoding(input_tab_3$distritos) <- "UTF-8"
input_tab_3$distritos <- enc2native(input_tab_3$distritos)

Encoding(input_tab_3$municipios) <- "UTF-8"
input_tab_3$municipios <- enc2native(input_tab_3$municipios)

Encoding(input_tab_3$estados) <- "UTF-8"
input_tab_3$estados <- enc2native(input_tab_3$estados)

Encoding(input_tab_3$centros_poblados) <- "UTF-8"
input_tab_3$centros_poblados <- enc2native(input_tab_3$centros_poblados)

input_tab_3$segmentacion[input_tab_3$segmento_overlay=='OVERLAY'] <- 'OVERLAY'
input_tab_3$segmentacion[input_tab_3$segmento_greenfield=='GREENFIELD'] <- 'GREENFIELD'

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








