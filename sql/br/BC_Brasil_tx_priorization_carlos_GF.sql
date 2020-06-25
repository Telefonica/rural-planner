--------------------------------------------------------------------------------------------------------------------------
-- QUERY 1: Transporte por cluster
----- 2G or LESS (NO LONGTAIL)
SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, 
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g, type, 
source, --segmento, 
tamano
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size, n.node_type,
CASE WHEN C.cluster_weight >= 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE when T.distance_movistar_transport_m <= 500 AND I2.fiber IS TRUE THEN 'qw fiber tef'
     WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 5000 and I2.fiber IS TRUE THEN 'qw fiber tef'          
     WHEN t.distance_movistar_transport_m <=500 AND I2.radio IS TRUE THEN 'fiber tef'        
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=5000 AND I2.radio IS TRUE THEN 'fiber tef'     
     WHEN T.distance_regional_transport_m <= 500 THEN 'fiber third pty'  
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_regional_transport_m <= 5000 THEN 'fiber third pty'            
     WHEN T.distance_third_party_transport_m <= 500 THEN 'fiber third pty'  
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 5000 THEN 'fiber third pty'  
     /*WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I3.fiber IS TRUE) THEN '2hops to fiber tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I3.radio IS TRUE) THEN '2hops to radio tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I4.fiber IS TRUE OR I5.fiber IS TRUE)) THEN '2hops to fiber 3rd pty'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I4.radio IS TRUE OR I5.radio IS TRUE)) THEN '2hops to radio 3rd pty'*/
     ELSE 'satellite' END AS type,
I.source AS source,
ROUND(v.competitors_presence_4g*v.cluster_weight)::integer as pop_4g,
ROUND(v.competitors_presence_3g*v.cluster_weight)::integer as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner.clusters C
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
                FROM rural_planner.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner.clusters)
                UNION 
                SELECT * FROM rural_planner.transport_greenfield_clusters) T
ON C.centroid=T.centroid
/*LEFT JOIN rural_planner.transport_clusters_multihop T2
ON C.centroid=T2.centroid*/
LEFT JOIN rural_planner.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
/*LEFT JOIN rural_planner.infrastructure_global I3
ON I3.tower_id=T2.movistar_transport_id
LEFT JOIN rural_planner.infrastructure_global I4  
ON I4.tower_id=T2.regional_transport_id
LEFT JOIN rural_planner.infrastructure_global I5
ON I5.tower_id=T2.third_party_transport_id*/
LEFT JOIN (SELECT tower_id, internal_id,  source, tech_3g, tech_4g
        FROM rural_planner.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner.v_coberturas_clusters v
on v.centroid=C.centroid
LEFT JOIN rural_planner.node_table n
on n.node_id=C.centroid
WHERE (C.cluster_weight>=500) AND n.node_type NOT LIKE '%2G%') A
GROUP BY tamano, source, segmento, type 

UNION
-- 3G CLUSTERS

SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, 
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g, type, 
source, --segmento, 
tamano
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size, n.node_type,
CASE WHEN C.cluster_weight >= 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE when T.distance_movistar_transport_m <= 500 AND I2.fiber IS TRUE THEN 'qw fiber tef'
     WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 5000 and I2.fiber IS TRUE THEN 'qw fiber tef'               
     WHEN t.distance_movistar_transport_m <= 500 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=5000 AND I2.radio IS TRUE THEN 'fiber tef'    
     WHEN T.distance_regional_transport_m <= 500 THEN 'fiber third pty'         
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_regional_transport_m <= 5000 THEN 'fiber third pty'         
     WHEN T.distance_third_party_transport_m <= 500 THEN 'fiber third pty'     
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 5000 THEN 'fiber third pty'     
     /*WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I3.fiber IS TRUE) THEN '2hops to fiber tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I3.radio IS TRUE) THEN '2hops to radio tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I4.fiber IS TRUE OR I5.fiber IS TRUE)) THEN '2hops to fiber 3rd pty'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I4.radio IS TRUE OR I5.radio IS TRUE)) THEN '2hops to radio 3rd pty' */
     WHEN I.satellite IS TRUE THEN 'satellite'    
     ELSE 'radio tef' END AS type,
I.source as source,
ROUND(v.competitors_presence_4g*v.cluster_weight)::integer as pop_4g,
ROUND(v.competitors_presence_3g*v.cluster_weight)::integer as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner.clusters_3g C
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
                FROM rural_planner.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner.clusters_3g)
                UNION
                SELECT * FROM rural_planner.transport_greenfield_clusters_3g) T
ON C.centroid=T.centroid
/*LEFT JOIN rural_planner.transport_clusters_multihop T2
ON C.centroid=T2.centroid*/
LEFT JOIN rural_planner.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
/*LEFT JOIN rural_planner.infrastructure_global I3
ON I3.tower_id=T2.movistar_transport_id
LEFT JOIN rural_planner.infrastructure_global I4
ON I4.tower_id=T2.regional_transport_id
LEFT JOIN rural_planner.infrastructure_global I5
ON I5.tower_id=T2.third_party_transport_id*/
LEFT JOIN (SELECT tower_id, internal_id, source, tech_3g, tech_4g, satellite
        FROM rural_planner.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner.v_coberturas_clusters_3g v
on v.centroid=C.centroid
LEFT JOIN rural_planner.node_table_3g n
on n.node_id=C.centroid
WHERE (C.cluster_weight>=500) AND n.node_type NOT LIKE 'VIVO TOWER %' AND n.node_type NOT LIKE 'EMPTY TOWER%') A
GROUP BY tamano, source, segmento, type 
ORDER BY tamano, source, type
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--QUERY 1: Análisis Segmentación Clusters por población & competidores (CÉSAR)
----- 2G or LESS (NO LONGTAIL)
SELECT COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, source, segmento, tamano 
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
CASE WHEN C.cluster_weight >= 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 5000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=5000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio regional'   
     WHEN T.distance_regional_transport_m <= 5000 THEN 'fiber regional'         
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 5000 THEN 'fiber third pty'   
     ELSE 'satellite' END AS type,
I.source AS source,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner.clusters C
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
                FROM rural_planner.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner.clusters)
                UNION 
                SELECT * FROM rural_planner.transport_greenfield_clusters) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, source, tech_3g, tech_4g
        FROM rural_planner.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner.v_coberturas_clusters v
on v.centroid=C.centroid
LEFT JOIN rural_planner.node_table n
on n.node_id=C.centroid
WHERE (C.cluster_weight>=500) AND n.node_type NOT LIKE '%2G%') A
group by source, segmento, tamano

UNION

--3G CLUSTERS
SELECT COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, source, segmento, tamano 
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
CASE WHEN C.cluster_weight >= 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 5000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=5000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio regional'   
     WHEN T.distance_regional_transport_m <= 5000 THEN 'fiber regional'         
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 5000 THEN 'fiber third pty'    
     WHEN I.satellite IS TRUE THEN 'satellite'        
     WHEN (I.tech_3g IS TRUE OR I.tech_4g IS TRUE) THEN 'radio tef'
     ELSE 'satellite' END AS type,
I.source as source,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner.clusters_3g C
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
                FROM rural_planner.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner.clusters_3g)
                UNION
                SELECT * FROM rural_planner.transport_greenfield_clusters_3g) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, source, tech_3g, tech_4g, satellite
        FROM rural_planner.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner.v_coberturas_clusters_3g v
on v.centroid=C.centroid
LEFT JOIN rural_planner.node_table_3G n
on n.node_id=C.centroid
WHERE (C.cluster_weight>=500)  AND n.node_type NOT LIKE 'VIVO TOWER %' AND n.node_type NOT LIKE 'EMPTY TOWER%') A
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
     WHEN T.distance_movistar_transport_m <= 5000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=5000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio regional'   
     WHEN T.distance_regional_transport_m <= 5000 THEN 'fiber regional'         
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 5000 THEN 'fiber third pty'     
     ELSE 'satellite' END AS type,
n.node_type  AS centroid_type,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner.clusters_3g C
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
                FROM rural_planner.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner.clusters_3g)
                UNION
                SELECT * FROM rural_planner.transport_greenfield_clusters_3g) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, source, tech_3g, tech_4g
        FROM rural_planner.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner.v_coberturas_clusters_3g v
on v.centroid=C.centroid
LEFT JOIN rural_planner.node_table_3g n
on n.node_id=C.centroid
WHERE (C.cluster_weight>=500) AND n.node_type NOT LIKE '%2G%') A
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
     WHEN T.distance_movistar_transport_m <= 5000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=5000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio regional'   
     WHEN T.distance_regional_transport_m <= 5000 THEN 'fiber regional'         
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 5000 THEN 'fiber third pty'   
     ELSE 'satellite' END AS type,
--CASE WHEN n.node_type IN ('SETTLEMENT 2G','VIRTUAL TOWER 2G') THEN 'VIVO' ELSE I.source END AS source,
        n.node_type as centroid_type,
        n.node_type,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner.clusters C
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
                FROM rural_planner.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner.clusters)
                UNION 
                SELECT * FROM rural_planner.transport_greenfield_clusters) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, source, tech_3g, tech_4g
        FROM rural_planner.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner.v_coberturas_clusters v
on v.centroid=C.centroid
LEFT JOIN rural_planner.node_table n
on n.node_id=C.centroid
WHERE (C.cluster_weight>=500) AND n.node_type NOT LIKE '%2G%') A
group by centroid_type, segmento, tamano


-------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--QUERY 4: GREENFIELD VS OVERLAY ZRD
SELECT COUNT(1) AS num_sites, round(SUM(ran_weight)) AS poblacion, centroid_type, segmento, tamano 
FROM (
SELECT C.settlement_id as ran_centroid, C.population_corrected as ran_weight, 1 as ran_size,
CASE WHEN C.population_corrected >= 0 AND C.population_corrected < 1250 THEN 'pequeño' 
        WHEN C.population_corrected >= 1250 AND C.population_corrected < 2500 THEN 'mediano'      
        WHEN C.population_corrected >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
     'SETTLEMENT LONGTAIL'::text as centroid_type,
(CASE WHEN v.competitors_4g_corrected IS TRUE THEN 1 ELSE 0 END)*C.population_corrected as pop_4g,
(CASE WHEN v.competitors_3g_corrected IS TRUE THEN 1 ELSE 0 END)*C.population_corrected as pop_3g,
case when v.competitors_4g_corrected or v.competitors_3g_corrected then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM (SELECT * FROM rural_planner.settlements WHERE settlement_id IN (SELECT case when node_2_id='' THEN centroid else node_2_id END
FROM rural_planner.clusters_links c
left join rural_planner.node_table n
on c.centroid=n.node_id 
WHERE n.node_type NOT LIKE '%2G%' AND c.cluster_weight<500)
union select * from rural_planner.settlements_zrd
        ) C
LEFT JOIN (SELECT * FROM rural_planner.coverage
union select * from rural_planner.coverage_zrd) v
on v.settlement_id=C.settlement_id
WHERE C.population_corrected>0) A
group by centroid_type, segmento, tamano

select sum(population_corrected) from rural_planner.settlements_zrd

select count(*) , sum(population) from rural_planner_dev.settlements_ipt_raw s
left join (SELECT * FROM rural_planner.coverage
union SELECT * FROM rural_planner.coverage_zrd) c
on s.settlement_id=c.settlement_id
where s.settlement_id in (SELECT case when node_2_id='' THEN centroid else node_2_id END
FROM rural_planner.clusters_links c
left join rural_planner.node_table n
on c.centroid=n.node_id 
WHERE n.node_type NOT LIKE '%2G%' AND c.cluster_weight>=500)
and vivo_4g_corrected is false