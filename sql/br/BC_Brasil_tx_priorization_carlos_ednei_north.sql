
SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, 
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g, type, 
source, segmento, 
tamano
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
CASE WHEN C.cluster_weight >= 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 2000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=2000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio regional'   
     WHEN T.distance_regional_transport_m <= 2000 THEN 'fiber regional'         
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 2000 THEN 'fiber third pty'     
     WHEN (I.tech_3g IS TRUE OR I.tech_4g IS TRUE) THEN 'radio tef'
     ELSE 'satellite' END AS type,
CASE WHEN n.node_type IN ('SETTLEMENT 2G','VIRTUAL TOWER 2G') THEN 'VIVO' ELSE I.source END AS source,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner_dev.clusters_ednei_north C
LEFT JOIN (SELECT tower_id::TEXT as centroid,                
                movistar_transport_id,
                distance_movistar_transport_m,
                line_of_sight_movistar,
                additional_height_tower_1_movistar_m,
                additional_height_tower_2_movistar_m,
                backhaul_movistar,
                regional_transport_id,
                distance_regional_transport_m,
                line_of_sight_regional,
                additional_height_tower_1_regional_m,
                additional_height_tower_2_regional_m,
                backhaul_regional,
                third_party_transport_id,
                distance_third_party_transport_m,
                line_of_sight_third_party,
                additional_height_tower_1_third_party_m,
                additional_height_tower_2_third_party_m,
                backhaul_third_party,
                geom_tower,
                geom_movistar,
                geom_regional,
                geom_third_party,
                geom_line_movistar,
                geom_line_regional,
                geom_line_third_party
                FROM rural_planner_dev.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_ednei_north)
                UNION 
                SELECT * FROM rural_planner_dev.transport_greenfield_clusters_ednei_north) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN source='VIVO' THEN owner
                                                ELSE source end as source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_ednei_north v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.node_table_ednei_north n
on n.node_id=C.centroid
WHERE C.cluster_weight>0) A
GROUP BY tamano, source, segmento, type 
ORDER BY tamano, source, segmento, type
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--QUERY 1: Análisis Segmentación Clusters por población & competidores (CÉSAR)
SELECT COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, source, segmento, tamano 
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
CASE WHEN C.cluster_weight >= 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 2000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=2000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio regional'   
     WHEN T.distance_regional_transport_m <= 2000 THEN 'fiber regional'         
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 2000 THEN 'fiber third pty'       
     WHEN (I.tech_3g IS TRUE OR I.tech_4g IS TRUE) THEN 'radio tef'   
     ELSE 'satellite' END AS type,
CASE WHEN n.node_type IN ('SETTLEMENT 2G','VIRTUAL TOWER 2G') THEN 'VIVO' ELSE I.source END AS source,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner_dev.clusters_ednei_north C
LEFT JOIN (SELECT tower_id::TEXT as centroid,                
                movistar_transport_id,
                distance_movistar_transport_m,
                line_of_sight_movistar,
                additional_height_tower_1_movistar_m,
                additional_height_tower_2_movistar_m,
                backhaul_movistar,
                regional_transport_id,
                distance_regional_transport_m,
                line_of_sight_regional,
                additional_height_tower_1_regional_m,
                additional_height_tower_2_regional_m,
                backhaul_regional,
                third_party_transport_id,
                distance_third_party_transport_m,
                line_of_sight_third_party,
                additional_height_tower_1_third_party_m,
                additional_height_tower_2_third_party_m,
                backhaul_third_party,
                geom_tower,
                geom_movistar,
                geom_regional,
                geom_third_party,
                geom_line_movistar,
                geom_line_regional,
                geom_line_third_party
                FROM rural_planner_dev.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_ednei_north)
                UNION 
                SELECT * FROM rural_planner_dev.transport_greenfield_clusters_ednei_north) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN source='VIVO' THEN owner
                                                ELSE source end as source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_ednei_north v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.node_table_ednei_north n
on n.node_id=C.centroid
WHERE C.cluster_weight>0) A
group by source, segmento, tamano

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
-- 3G CLUSTERS

SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, 
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g, type, 
source, segmento, 
tamano
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
CASE WHEN C.cluster_weight >= 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 2000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=2000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio regional'   
     WHEN T.distance_regional_transport_m <= 2000 THEN 'fiber regional'         
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 2000 THEN 'fiber third pty'      
     WHEN (I.tech_3g IS TRUE OR I.tech_4g IS TRUE) THEN 'radio tef'     
     ELSE 'radio tef' END AS type,
CASE WHEN I.source IS NULL THEN 'VIVO' ELSE I.source end as source,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner_dev.clusters_ednei_north_3g C
LEFT JOIN (SELECT tower_id::TEXT as centroid,                
                movistar_transport_id,
                distance_movistar_transport_m,
                line_of_sight_movistar,
                additional_height_tower_1_movistar_m,
                additional_height_tower_2_movistar_m,
                backhaul_movistar,
                regional_transport_id,
                distance_regional_transport_m,
                line_of_sight_regional,
                additional_height_tower_1_regional_m,
                additional_height_tower_2_regional_m,
                backhaul_regional,
                third_party_transport_id,
                distance_third_party_transport_m,
                line_of_sight_third_party,
                additional_height_tower_1_third_party_m,
                additional_height_tower_2_third_party_m,
                backhaul_third_party,
                geom_tower,
                geom_movistar,
                geom_regional,
                geom_third_party,
                geom_line_movistar,
                geom_line_regional,
                geom_line_third_party
                FROM rural_planner_dev.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_ednei_north_3g)) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN source='VIVO' THEN owner
                                                ELSE source end as source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_ednei_north_3g v
on v.centroid=C.centroid
WHERE C.cluster_weight>0 ) A
GROUP BY tamano, source, segmento, type 
ORDER BY tamano, source, segmento, type
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--QUERY 1: Análisis Segmentación Clusters por población & competidores (CÉSAR)
SELECT COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, source, segmento, tamano 
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
CASE WHEN C.cluster_weight >= 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 2000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=2000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio regional'   
     WHEN T.distance_regional_transport_m <= 2000 THEN 'fiber regional'         
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 2000 THEN 'fiber third pty'     
     ELSE 'radio tef' END AS type,
CASE WHEN I.source IS NULL THEN 'VIVO' ELSE I.source end as source,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner_dev.clusters_ednei_north_3g C
LEFT JOIN (SELECT tower_id::TEXT as centroid,                
                movistar_transport_id,
                distance_movistar_transport_m,
                line_of_sight_movistar,
                additional_height_tower_1_movistar_m,
                additional_height_tower_2_movistar_m,
                backhaul_movistar,
                regional_transport_id,
                distance_regional_transport_m,
                line_of_sight_regional,
                additional_height_tower_1_regional_m,
                additional_height_tower_2_regional_m,
                backhaul_regional,
                third_party_transport_id,
                distance_third_party_transport_m,
                line_of_sight_third_party,
                additional_height_tower_1_third_party_m,
                additional_height_tower_2_third_party_m,
                backhaul_third_party,
                geom_tower,
                geom_movistar,
                geom_regional,
                geom_third_party,
                geom_line_movistar,
                geom_line_regional,
                geom_line_third_party
                FROM rural_planner_dev.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_ednei_north_3g)) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN source='VIVO' THEN owner
                                                ELSE source end as source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_ednei_north_3g v
on v.centroid=C.centroid
WHERE C.cluster_weight>0) A
group by source, segmento, tamano

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--QUERY 3: GREENFIELD VS OVERLAY
SELECT COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, centroid_type, segmento, tamano 
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
CASE WHEN C.cluster_weight >= 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 2000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=2000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio regional'   
     WHEN T.distance_regional_transport_m <= 2000 THEN 'fiber regional'         
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 2000 THEN 'fiber third pty'     
     ELSE 'radio tef' END AS type,
CASE WHEN n.node_type LIKE '%SETTLEMENT%' THEN 'VIRTUAL TOWER 3G' ELSE 'TOWER 3G' END AS centroid_type,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner_dev.clusters_ednei_north_3g C
LEFT JOIN (SELECT tower_id::TEXT as centroid,                
                movistar_transport_id,
                distance_movistar_transport_m,
                line_of_sight_movistar,
                additional_height_tower_1_movistar_m,
                additional_height_tower_2_movistar_m,
                backhaul_movistar,
                regional_transport_id,
                distance_regional_transport_m,
                line_of_sight_regional,
                additional_height_tower_1_regional_m,
                additional_height_tower_2_regional_m,
                backhaul_regional,
                third_party_transport_id,
                distance_third_party_transport_m,
                line_of_sight_third_party,
                additional_height_tower_1_third_party_m,
                additional_height_tower_2_third_party_m,
                backhaul_third_party,
                geom_tower,
                geom_movistar,
                geom_regional,
                geom_third_party,
                geom_line_movistar,
                geom_line_regional,
                geom_line_third_party
                FROM rural_planner_dev.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_ednei_north_3g)) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN source='VIVO' THEN owner
                                                ELSE source end as source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_ednei_north_3g v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.node_table_ednei_north_3g n
on n.node_id=C.centroid
WHERE C.cluster_weight>0) A
group by centroid_type, segmento, tamano

UNION


--QUERY 1: Análisis Segmentación Clusters por población & competidores (CÉSAR)
SELECT COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, centroid_type, segmento, tamano 
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
CASE WHEN C.cluster_weight >= 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 2000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=2000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio regional'   
     WHEN T.distance_regional_transport_m <= 2000 THEN 'fiber regional'         
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 2000 THEN 'fiber third pty'       
     WHEN (I.tech_3g IS TRUE OR I.tech_4g IS TRUE) THEN 'radio tef'   
     ELSE 'satellite' END AS type,
--CASE WHEN n.node_type IN ('SETTLEMENT 2G','VIRTUAL TOWER 2G') THEN 'VIVO' ELSE I.source END AS source,
        CASE WHEN n.node_type LIKE '%SETTLEMENT%' OR n.node_type='TOWER' THEN NULL ELSE 'TOWER 2G' END as centroid_type,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner_dev.clusters_ednei_north C
LEFT JOIN (SELECT tower_id::TEXT as centroid,                
                movistar_transport_id,
                distance_movistar_transport_m,
                line_of_sight_movistar,
                additional_height_tower_1_movistar_m,
                additional_height_tower_2_movistar_m,
                backhaul_movistar,
                regional_transport_id,
                distance_regional_transport_m,
                line_of_sight_regional,
                additional_height_tower_1_regional_m,
                additional_height_tower_2_regional_m,
                backhaul_regional,
                third_party_transport_id,
                distance_third_party_transport_m,
                line_of_sight_third_party,
                additional_height_tower_1_third_party_m,
                additional_height_tower_2_third_party_m,
                backhaul_third_party,
                geom_tower,
                geom_movistar,
                geom_regional,
                geom_third_party,
                geom_line_movistar,
                geom_line_regional,
                geom_line_third_party
                FROM rural_planner_dev.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_ednei_north)
                UNION 
                SELECT * FROM rural_planner_dev.transport_greenfield_clusters_ednei_north) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN source='VIVO' THEN owner
                                                ELSE source end as source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_ednei_north v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.node_table_ednei_north n
on n.node_id=C.centroid
WHERE C.cluster_weight>0) A
group by centroid_type, segmento, tamano
