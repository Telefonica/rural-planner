library(sqldf)
library(RPostgreSQL)
library(rpostgis)
library(RSQLite)

############################################################################################
#    Generating data from ruralplanner database 
############################################################################################

#Establish connection to database

#DB Connection parameters
config_path <- '~/shared/rural_planner/config_files/config_pe'
source(config_path)

drv <- dbDriver("PostgreSQL")
conPG <- dbConnect(drv, dbname = dbname,
                 host = host, port = port,
                 user = user, password = pwd)

# Load inputs


# Input for Tabs 1 and 2: 'Segmentacion oportunidad' and 'Priorizacion centros poblados'

query <- paste0("SELECT b.centro_poblado, b.distrito, b.provincia, b.region, b.poblacion, b.longitude, b.latitude, d.*, e.num_escuelas_edu_secundaria, c.cobertura_movistar, c.cobertura_claro, c.cobertura_entel, c.cobertura_bitel, c.cobertura_competidores,
CASE WHEN a.torre_acceso IS NULL THEN 'NO' ELSE 'SI' END as acceso_disponible,
a.km_dist_torre_acceso, a.los_acceso_transporte, a.owner_torre_acceso, a.altura_torre_acceso, a.tipo_torre_acceso, a.tecnologia_torre_acceso, a.torre_acceso_internal_id, a.latitude_torre_acceso, a.longitude_torre_acceso,
CASE WHEN a.torre_transporte IS NULL THEN 'NO' ELSE 'SI' END as transporte_disponible,
a.km_dist_torre_transporte, a.owner_torre_transporte, a.altura_torre_transporte,
a.tipo_torre_transporte as tecnologia_torre_transporte,
a.torre_transporte_source as tipo_torre_transporte,
a.banda_satelite_torre_transporte, torre_transporte_internal_id, a.latitude_torre_transporte, a.longitude_torre_transporte,
ST_AsText(ST_GeomFromEWKB(a.geom_line_torre_acceso)) as line_acceso,
ST_AsText(ST_GeomFromEWKB(a.geom_line_trasnporte_torre_acceso)) as line_transporte,
ST_AsText(ST_GeomFromEWKB(geom_line_torre_transporte)) as line_transporte_cp
FROM ", schema, ".", settlements_view," b
LEFT JOIN ", schema, ".", segmentation_view," d
ON d.ubigeo=b.ubigeo
LEFT JOIN ", schema, ".", coverage_view," c
ON d.ubigeo=c.ubigeo
LEFT JOIN ", schema, ".", access_transport_view, " a
ON d.ubigeo=a.ubigeo
LEFT JOIN ", schema, ".", schools_view, " e
ON d.ubigeo=e.ubigeo;")

input_tab_2 <- dbGetQuery(conPG,query)


input_tab_2$segmentacion[input_tab_2$segmento_telefonica!='TELEFONICA UNSERVED'] <- 'TELEFONICA SERVED'
input_tab_2$segmentacion[input_tab_2$segmento_overlay=='OVERLAY FEMTO'] <- 'OVERLAY FEMTO'
input_tab_2$segmentacion[input_tab_2$segmento_overlay=='OVERLAY MACRO'] <- 'OVERLAY MACRO'
input_tab_2$segmentacion[input_tab_2$segmento_greenfield=='GREENFIELD'] <- 'GREENFIELD'

# Input for 3rd tab: Priorización clusters

query <- paste0("SELECT b.centroide,
      CASE WHEN length(b.centroide)<8 THEN t.tower_name ELSE b.centroide END AS centroide_name, 
b.tipo_cluster, b.centros_poblados, b.distritos, b.provincias, b.regiones, b.tamano_cluster, b.poblacion, b.orografias, b.latitud as latitude, b.longitud as longitude, d.segmento_overlay, d.segmento_greenfield, e.num_escuelas_cluster_edu_secundaria,
ROUND(c.competitors_presence_2g*b.poblacion) as poblacion_competidores_2g,
ROUND(c.competitors_presence_3g*b.poblacion) as poblacion_competidores_3g,
ROUND(c.competitors_presence_4g*b.poblacion) as poblacion_competidores_4g,
ROUND(c.competitors_presence_2g*100) as porcentaje_poblacion_competidores_2g,
ROUND(c.competitors_presence_3g*100) as porcentaje_poblacion_competidores_3g,
ROUND(c.competitors_presence_4g*100) as porcentaje_poblacion_competidores_4g,
CASE WHEN a.torre_acceso IS NULL THEN 'NO' ELSE 'SI' END as acceso_disponible,
a.km_dist_torre_acceso, a.los_acceso_transporte, a.owner_torre_acceso, a.altura_torre_acceso, a.tipo_torre_acceso, a.tecnologia_torre_acceso, a.torre_acceso_internal_id, a.latitude_torre_acceso, a.longitude_torre_acceso,
CASE WHEN a.torre_transporte IS NULL THEN 'NO' ELSE 'SI' END as transporte_disponible,
a.km_dist_torre_transporte, a.owner_torre_transporte, a.altura_torre_transporte,
a.tipo_torre_transporte as tecnologia_torre_transporte,
a.torre_transporte_source as tipo_torre_transporte,
a.banda_satelite_torre_transporte, a.torre_transporte_internal_id, a.latitude_torre_transporte, a.longitude_torre_transporte,
ST_AsText(a.geom_line_torre_acceso) as line_acceso,
ST_AsText(a.geom_line_trasnporte_torre_acceso) as line_transporte,
ST_AsText(geom_line_torre_transporte) as line_transporte_cp
FROM ", schema, ".", clusters_view," b
LEFT JOIN ", schema, ".", segmentation_c_view," d
ON d.centroide=b.centroide
LEFT JOIN ", schema, ".", coverage_c_view," c
ON d.centroide=c.centroid
LEFT JOIN ", schema, ".", access_transport_c_view, " a
ON d.centroide=a.cluster_id
LEFT JOIN ", schema, ".", schools_c_view, " e
ON d.centroide=e.centroide
LEFT JOIN ", schema, ".", towers_table," t
ON t.tower_id::text=b.centroide;")

input_tab_3 <- dbGetQuery(conPG, query)

query <- paste0('SELECT c.centroide, s.centro_poblado as centros_poblados, s.ubigeo,
CASE WHEN c.centroide=s.ubigeo THEN NULL ELSE c.nodes_centroide END as nodes_centroide,
CASE WHEN c.centroide=s.ubigeo THEN NULL ELSE c.lines_centroide END as lines_centroide
FROM
(SELECT ST_AsText(UNNEST(geom_links)) AS lines_centroide, ST_AsText(UNNEST(geom_nodes)) AS nodes_centroide, centroide
FROM ', schema, '.', clusters_view,') c
LEFT JOIN ', schema, '.', settlements_view,' s
ON nodes_centroide=ST_AsText(s.geom)')

input_tab_3_lines <- dbGetQuery(conPG, query)


input_tab_3$segmentacion[input_tab_3$segmento_overlay=='OVERLAY FEMTO'] <- 'OVERLAY FEMTO'
input_tab_3$segmentacion[input_tab_3$segmento_overlay=='OVERLAY MACRO'] <- 'OVERLAY MACRO'
input_tab_3$segmentacion[input_tab_3$segmento_greenfield=='GREENFIELD'] <- 'GREENFIELD'


query <- paste0("SELECT s.centroid, 
      CASE WHEN length(s.centroid)<8 THEN t.tower_name ELSE s.centroid END AS centroide_name,
s.node_id, s.site, s.type, direct_population, distance_to_road, length_fiber_movistar, length_fiber_azteca, length_fiber_regional, length_fiber_third_party,
population_movistar, population_azteca, population_regional, population_third_party,
path_movistar, fiber_node_movistar, path_azteca, fiber_node_azteca, path_regional, fiber_node_regional, path_third_party, fiber_node_third_party, ST_AsText(geom_microwave) as radio_link,
ST_AsText(ST_ForceCollection(geom_movistar)) as movistar_path, ST_AsText(z.line_movistar) as line_movistar, ST_AsText(ST_ForceCollection(geom_azteca)) as azteca_path, ST_AsText(z.line_azteca) as line_azteca, ST_AsText(ST_ForceCollection(geom_regional)) as regional_path, ST_AsText(z.line_regional) as line_regional, ST_AsText(ST_ForceCollection(geom_third_party)) as third_party_path, ST_AsText(z.line_third_party) as line_third_party, ST_AsText(c.geom) as geom
FROM ", schema_dev, ".", path_finder_fiber_table," s
LEFT JOIN ", schema, ".", clusters_table," c
ON c.centroid=s.centroid
LEFT JOIN ", schema, ".", towers_table," t
ON t.tower_id::text=s.centroid
LEFT JOIN (
SELECT z1.centroid, z1.line_movistar, z2.line_azteca, z3.line_regional, z4.line_third_party  
FROM (
SELECT DISTINCT(b.centroid), b.path_movistar, ST_MakeLine(b.movistar_geom ORDER BY b.row_id)  AS line_movistar FROM (
SELECT a.*,
CASE WHEN (a.movistar_nodes!='NULL' AND a.movistar_nodes::integer <= (SELECT MAX(node_id) FROM ", schema_dev, ".node_table_roads_aggregate)) THEN im.geom::geometry
WHEN it.geom::geometry IS NOT NULL THEN it.geom::geometry 
ELSE NULL END AS movistar_geom
FROM (
SELECT row_number() OVER () AS row_id, p.*
FROM ( SELECT centroid, unnest(string_to_array(path_movistar, ',')) AS movistar_nodes, path_movistar
FROM ", schema_dev, ".path_finder_fiber_3000_sites) p) a
LEFT JOIN ", schema_dev, ".", path_finder_node_table," im
ON a.movistar_nodes=im.node_id::text
LEFT JOIN ", schema, ".", towers_table," it
ON a.movistar_nodes = ((it.tower_id::integer) + (SELECT MAX(node_id) FROM ", schema_dev, ".node_table_roads_aggregate))::text
order by a.row_id) b
GROUP BY b.centroid, b.path_movistar) z1
LEFT JOIN (
SELECT DISTINCT(b.centroid), b.path_azteca, ST_MakeLine(b.azteca_geom ORDER BY b.row_id)  AS line_azteca FROM (
SELECT a.*,
CASE WHEN (a.azteca_nodes!='NULL' AND a.azteca_nodes::integer <= (SELECT MAX(node_id) FROM ", schema_dev, ".node_table_roads_aggregate)) THEN im.geom::geometry
WHEN it.geom::geometry IS NOT NULL THEN it.geom::geometry 
ELSE NULL END AS azteca_geom
FROM (
SELECT row_number() OVER () AS row_id, p.*
FROM ( SELECT centroid, unnest(string_to_array(path_azteca, ',')) AS azteca_nodes, path_azteca
FROM ", schema_dev, ".", path_finder_fiber_table,") p) a
LEFT JOIN ", schema_dev, ".", path_finder_node_table," im
ON a.azteca_nodes=im.node_id::text
LEFT JOIN ", schema, ".", towers_table," it
ON a.azteca_nodes = ((it.tower_id::integer) + (SELECT MAX(node_id) FROM ", schema_dev, ".node_table_roads_aggregate))::text
order by a.row_id) b
GROUP BY b.centroid, b.path_azteca) z2
ON z1.centroid=z2.centroid
LEFT JOIN (
SELECT DISTINCT(b.centroid), b.path_regional, ST_MakeLine(b.regional_geom ORDER BY b.row_id) AS line_regional FROM (
SELECT a.*,
CASE WHEN (a.regional_nodes!='NULL' AND a.regional_nodes::integer <= (SELECT MAX(node_id) FROM ", schema_dev, ".node_table_roads_aggregate)) THEN im.geom::geometry
WHEN it.geom::geometry IS NOT NULL THEN it.geom::geometry 
ELSE NULL END AS regional_geom
FROM (
SELECT row_number() OVER () AS row_id, p.*
FROM ( SELECT centroid, unnest(string_to_array(path_regional, ',')) AS regional_nodes, path_regional
FROM ", schema_dev, ".", path_finder_fiber_table,") p) a
LEFT JOIN ", schema_dev, ".", path_finder_node_table," im
ON a.regional_nodes=im.node_id::text
LEFT JOIN ", schema, ".", towers_table," it
ON a.regional_nodes = ((it.tower_id::integer) + (SELECT MAX(node_id) FROM ", schema_dev, ".node_table_roads_aggregate))::text
order by a.row_id) b
GROUP BY b.centroid, b.path_regional) z3
on z1.centroid=z3.centroid
LEFT JOIN (
SELECT DISTINCT(b.centroid), b.path_third_party, ST_MakeLine(b.third_party_geom ORDER BY b.row_id) AS line_third_party FROM (
SELECT a.*,
CASE WHEN (a.third_party_nodes!='NULL' AND a.third_party_nodes::integer <= (SELECT MAX(node_id) FROM ", schema_dev, ".node_table_roads_aggregate)) THEN im.geom::geometry
WHEN it.geom::geometry IS NOT NULL THEN it.geom::geometry 
ELSE NULL END AS third_party_geom
FROM (
SELECT row_number() OVER () AS row_id, p.*
FROM ( SELECT centroid, unnest(string_to_array(path_third_party, ',')) AS third_party_nodes, path_third_party
FROM ", schema_dev, ".", path_finder_fiber_table,") p) a
LEFT JOIN ", schema_dev, ".", path_finder_node_table," im
ON a.third_party_nodes=im.node_id::text
LEFT JOIN ", schema, ".", towers_table," it
ON a.third_party_nodes = ((it.tower_id::integer) + (SELECT MAX(node_id) FROM ", schema_dev, ".node_table_roads_aggregate))::text
order by a.row_id) b
GROUP BY b.centroid, b.path_third_party) z4
ON z1.centroid=z4.centroid) z
ON z.centroid=s.centroid;")

input_tab_4 <- dbGetQuery(conPG, query)

input_tab_4$length_fiber_movistar <- as.numeric(input_tab_4$length_fiber_movistar)
input_tab_4$length_fiber_azteca <- as.numeric(input_tab_4$length_fiber_azteca)
input_tab_4$length_fiber_regional <- as.numeric(input_tab_4$length_fiber_regional)
input_tab_4$length_fiber_third_party <- as.numeric(input_tab_4$length_fiber_third_party)

input_tab_4$longitude <- -(as.numeric(gsub(".*?([0-9]+[.][0-9]+).*", "\\1", input_tab_4$geom)))
input_tab_4$latitude <- as.numeric(gsub(".* ([-]*[0-9]+[.][0-9]+).*", "\\1", input_tab_4$geom))


query <- paste0("SELECT s.centroid,
CASE WHEN length(s.centroid)<8 THEN t.tower_name ELSE s.centroid END AS centroide_name,
s.site, s.type, direct_population, hops_movistar, hops_azteca, hops_regional, hops_third_party, population_movistar, population_azteca, population_regional, population_third_party,
path_movistar, fiber_node_movistar, path_azteca, fiber_node_azteca, path_regional, fiber_node_regional, path_third_party, fiber_node_third_party,
ST_AsText(s.geom_movistar) AS line_movistar, ST_AsText(s.geom_azteca) AS line_azteca, ST_AsText(s.geom_regional) as line_regional, ST_AsText(s.geom_third_party) as line_third_party, ST_AsText(c.geom) as geom
FROM ", schema_dev, ".", path_finder_radio_table," s
LEFT JOIN ", schema, ".", clusters_table," c
ON c.centroid=s.centroid
LEFT JOIN ", schema, ".", towers_table," t
ON t.tower_id::text=s.centroid;")

input_tab_5 <- dbGetQuery(conPG, query)


input_tab_5$longitude <- -(as.numeric(gsub(".*?([0-9]+[.][0-9]+).*", "\\1", input_tab_5$geom)))
input_tab_5$latitude <- as.numeric(gsub(".* ([-]*[0-9]+[.][0-9]+).*", "\\1", input_tab_5$geom))


query <- paste0("SELECT s.id_despliegue, s.medio_transporte, s.segmento, s.id_sitio, s.sitio, s.latitud_sitio, s.longitud_sitio, s.poblacion_directa, s.nodo_fibra, s.id_nodo_fibra,
s.latitud_fibra, s.longitud_fibra, s.proveedor_fibra, s.longitud_fibra_km, s.saltos_radioenlace,
ST_AsText(s.geom_sitio) AS site, ST_AsText(s.geom_nodo_fibra) AS fiber_node, ST_AsText(ST_LineMerge(geom_radioenlaces::geometry)) AS radio_paths,  ST_AsText(ST_LineMerge(geom_fibra::geometry)) AS fiber_paths
FROM ", schema_dev, ".", path_finder_final_table," s;")

input_tab_6 <- dbGetQuery(conPG, query)


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
dbWriteTable(conn = db, name = "input_tab_5", value = input_tab_5, row.names = FALSE)
dbWriteTable(conn = db, name = "input_tab_6", value = input_tab_6, row.names = FALSE)

dbDisconnect(db)








