--------------------------------------------------------------------------------------------------------------------------
-- QUERY 1: Transporte por cluster
----- 2G or LESS (NO LONGTAIL)
SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, 
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g, type, 
source, --segmento, 
tamano
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
CASE WHEN C.cluster_weight >= 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 5000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=5000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN (T.line_of_sight_regional IS TRUE OR T.line_of_sight_third_party IS TRUE) THEN 'radio third pty'   
     WHEN (T.distance_regional_transport_m <= 5000 OR T.distance_third_party_transport_m <= 5000) THEN 'fiber third pty'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I3.fiber IS TRUE) THEN '2hops to fiber tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I3.radio IS TRUE) THEN '2hops to radio tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I4.fiber IS TRUE OR I5.fiber IS TRUE)) THEN '2hops to fiber 3rd pty'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I4.radio IS TRUE OR I5.radio IS TRUE)) THEN '2hops to radio 3rd pty'
     ELSE 'satellite' END AS type,
I.source AS source,
ROUND(v.competitors_presence_4g*v.cluster_weight)::integer as pop_4g,
ROUND(v.competitors_presence_3g*v.cluster_weight)::integer as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner_dev.clusters_north_2020 C
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
                FROM rural_planner_dev.transport_by_tower_north WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_north)
                UNION 
                SELECT * FROM rural_planner_dev.transport_greenfield_clusters_north) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.transport_clusters_multihop T2
ON C.centroid=T2.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN rural_planner_dev.infrastructure_global I3
ON I3.tower_id=T2.movistar_transport_id
LEFT JOIN rural_planner_dev.infrastructure_global I4
ON I4.tower_id=T2.regional_transport_id
LEFT JOIN rural_planner_dev.infrastructure_global I5
ON I5.tower_id=T2.third_party_transport_id
LEFT JOIN (SELECT tower_id, internal_id,  source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_north v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.node_table_north n
on n.node_id=C.centroid
WHERE (C.cluster_weight>=500 OR n.node_type LIKE '%%VIVO TOWER 2G%')) A
GROUP BY tamano, source, segmento, type 

UNION
-- 3G CLUSTERS

SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, 
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g, type, 
source, --segmento, 
tamano
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
     WHEN (T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 OR T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000) THEN 'radio third pty'   
     WHEN (T.distance_regional_transport_m <= 5000 OR T.distance_third_party_transport_m <= 5000) THEN 'fiber third pty'   
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I3.fiber IS TRUE) THEN '2hops to fiber tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I3.radio IS TRUE) THEN '2hops to radio tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I4.fiber IS TRUE OR I5.fiber IS TRUE)) THEN '2hops to fiber 3rd pty'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I4.radio IS TRUE OR I5.radio IS TRUE)) THEN '2hops to radio 3rd pty'
     WHEN I.satellite IS TRUE THEN 'satellite'    
     ELSE 'radio tef' END AS type,
I.source as source,
ROUND(v.competitors_presence_4g*v.cluster_weight)::integer as pop_4g,
ROUND(v.competitors_presence_3g*v.cluster_weight)::integer as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner_dev.clusters_north_3g_2020 C
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
                FROM rural_planner_dev.transport_by_tower_north WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_north_3g)
                UNION
                SELECT * FROM rural_planner_dev.transport_greenfield_clusters_north_3g) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.transport_clusters_multihop T2
ON C.centroid=T2.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN rural_planner_dev.infrastructure_global I3
ON I3.tower_id=T2.movistar_transport_id
LEFT JOIN rural_planner_dev.infrastructure_global I4
ON I4.tower_id=T2.regional_transport_id
LEFT JOIN rural_planner_dev.infrastructure_global I5
ON I5.tower_id=T2.third_party_transport_id
LEFT JOIN (SELECT tower_id, internal_id, source, tech_3g, tech_4g, satellite
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_north_3g v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.node_table_north_3G n
on n.node_id=C.centroid
WHERE (C.cluster_weight>=500 OR n.node_type LIKE '%%VIVO TOWER 3G%')) A
GROUP BY tamano, source, segmento, type 

UNION
-- AD-HOC: add sites wo/potential close to roads and work places

SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, 
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g, type, 
source, --segmento, 
tamano
FROM (
SELECT DISTINCT ON (a.tower_id) a.tower_id::text as centroid, 5000 as ran_weight, 
CONCAT('EMPTY TOWER ', (CASE WHEN a.tech_3g IS TRUE THEN '3G' 
                                WHEN a.tech_2g IS TRUE THEN '2G'
                                ELSE '' END)) as centroid_type,
                                'sin 3G+ comp'::TEXT as segmento,
'mediano'::TEXT as tamano,
0 as ran_size, 
A.source, 
0 as pop_3g, 0 as pop_4g,
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 5000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=5000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN (T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 OR T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000) THEN 'radio third pty'   
     WHEN (T.distance_regional_transport_m <= 5000 OR T.distance_third_party_transport_m <= 5000) THEN 'fiber third pty'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I3.fiber IS TRUE) THEN '2hops to fiber tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I3.radio IS TRUE) THEN '2hops to radio tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I4.fiber IS TRUE OR I5.fiber IS TRUE)) THEN '2hops to fiber 3rd pty'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I4.radio IS TRUE OR I5.radio IS TRUE)) THEN '2hops to radio 3rd pty'
     WHEN A.satellite IS TRUE THEN 'satellite'        
     WHEN (A.tech_3g IS TRUE OR A.tech_4g IS TRUE) THEN 'radio tef'
     ELSE 'satellite' END AS type,
ST_Distance(A.geom::geography, B.geom::geography) as distance_m
FROM (
select * from rural_planner_dev.vivo_infrastructure_location_new where
(tech_2g is true or tech_3g is true) and tech_4g is false and admin_division_3_id in ('11','12','13','14','15','16','17','21')
and admin_division_2_id not in (SELECT admin_division_2_id FROM rural_planner_dev.municipios_tim) AND source='VIVO') A
LEFT JOIN (SELECT * FROM rural_planner_dev.infrastructure_global where source='VIVO'
AND tech_4g IS TRUE) B
ON ST_DWithin(A.geom::geography, B.geom::geography, 5000)
LEFT JOIN rural_planner_dev.transport_by_tower_north T
ON a.tower_id=T.tower_id
LEFT JOIN rural_planner_dev.transport_clusters_multihop T2
ON a.tower_id::TEXT=T2.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN rural_planner_dev.infrastructure_global I3
ON I3.tower_id=T2.movistar_transport_id
LEFT JOIN rural_planner_dev.infrastructure_global I4
ON I4.tower_id=T2.regional_transport_id
LEFT JOIN rural_planner_dev.infrastructure_global I5
ON I5.tower_id=T2.third_party_transport_id
WHERE ST_Distance(A.geom::geography, B.geom::geography) IS NULL 
AND a.tower_id::text not in (SELECT centroid from rural_planner_dev.clusters_north_2020
union
SELECT centroid from rural_planner_dev.clusters_north_3g_2020)
AND a.tower_id::text NOT IN (
SELECT distinct(ran_centroid) from rural_planner_dev.analisis_clusters_ednei_v2 a
left join rural_planner_dev.infra_master_vivo i
on a.centroid_name=i.internal_id
where segment_ov_gf='OVERLAY' AND (tech_2020 like '%L%' OR  priorizacion='RASCUNHO' OR internal_id IS NULL))
ORDER BY a.tower_id, ST_Distance(A.geom::geography, B.geom::geography)
) C
GROUP BY tamano, source, type 
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
FROM rural_planner_dev.clusters_north_2020 C
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
                FROM rural_planner_dev.transport_by_tower_north WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_north)
                UNION 
                SELECT * FROM rural_planner_dev.transport_greenfield_clusters_north) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_north v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.node_table_north n
on n.node_id=C.centroid
WHERE (C.cluster_weight>=500 OR n.node_type LIKE '%%VIVO TOWER 2G%')) A
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
FROM rural_planner_dev.clusters_north_3g_2020 C
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
                FROM rural_planner_dev.transport_by_tower_north WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_north_3g)
                UNION
                SELECT * FROM rural_planner_dev.transport_greenfield_clusters_north_3g) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, source, tech_3g, tech_4g, satellite
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_north_3g v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.node_table_north_3G n
on n.node_id=C.centroid
WHERE (C.cluster_weight>=500 OR n.node_type LIKE '%%VIVO TOWER 3G%')) A
group by source, segmento, tamano

UNION
-- AD-HOC: add sites wo/potential close to roads and work places

SELECT COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, source, segmento, tamano
FROM (
SELECT DISTINCT ON (a.tower_id) a.tower_id::text as centroid, 5000 as ran_weight, 
CONCAT('EMPTY TOWER ', (CASE WHEN a.tech_3g IS TRUE THEN '3G' 
                                WHEN a.tech_2g IS TRUE THEN '2G'
                                ELSE '' END)) as centroid_type,
                                'sin 3G+ comp'::TEXT as segmento,
'mediano'::TEXT as tamano,
0 as ran_size, 
A.source, 
0 as pop_3g, 0 as pop_4g,
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 5000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m <=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m <=5000 AND I2.radio IS TRUE THEN 'fiber tef'   
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport_m <= 40000 THEN 'radio regional'   
     WHEN T.distance_regional_transport_m <= 5000 THEN 'fiber regional'         
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 5000 THEN 'fiber third pty'
     WHEN A.satellite IS TRUE THEN 'satellite'        
     WHEN (A.tech_3g IS TRUE OR A.tech_4g IS TRUE) THEN 'radio tef'
     ELSE 'satellite' END AS type,
ST_Distance(A.geom::geography, B.geom::geography) as distance_m
FROM (
select * from rural_planner_dev.vivo_infrastructure_location_new where
(tech_2g is true or tech_3g is true) and tech_4g is false and admin_division_3_id in ('11','12','13','14','15','16','17','21')
and admin_division_2_id not in (SELECT admin_division_2_id FROM rural_planner_dev.municipios_tim) AND source='VIVO') A
LEFT JOIN (SELECT * FROM rural_planner_dev.infrastructure_global where source='VIVO'
AND tech_4g IS TRUE) B
ON ST_DWithin(A.geom::geography, B.geom::geography, 5000)
LEFT JOIN rural_planner_dev.transport_by_tower_north T
ON a.tower_id=T.tower_id
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
WHERE ST_Distance(A.geom::geography, B.geom::geography) IS NULL 
AND a.tower_id::text not in (SELECT centroid from rural_planner_dev.clusters_north_2020
union
SELECT centroid from rural_planner_dev.clusters_north_3g_2020)
AND a.tower_id::text NOT IN (
SELECT distinct(ran_centroid) from rural_planner_dev.analisis_clusters_ednei_v2 a
left join rural_planner_dev.infra_master_vivo i
on a.centroid_name=i.internal_id
where segment_ov_gf='OVERLAY' AND (tech_2020 like '%L%' OR  priorizacion='RASCUNHO' OR internal_id IS NULL))
ORDER BY a.tower_id, ST_Distance(A.geom::geography, B.geom::geography)
) C
group by source, segmento, tamano, type

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
FROM rural_planner_dev.clusters_north_3g_2020 C
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
                FROM rural_planner_dev.transport_by_tower_north WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_north_3g)
                UNION
                SELECT * FROM rural_planner_dev.transport_greenfield_clusters_north_3g) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_north_3g v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.node_table_north_3g n
on n.node_id=C.centroid
WHERE (C.cluster_weight>=500 OR n.node_type LIKE '%%VIVO TOWER 3G%')) A
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
FROM rural_planner_dev.clusters_north_2020 C
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
                FROM rural_planner_dev.transport_by_tower_north WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_north)
                UNION 
                SELECT * FROM rural_planner_dev.transport_greenfield_clusters_north) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_north v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.node_table_north n
on n.node_id=C.centroid
WHERE (C.cluster_weight>=500 OR n.node_type LIKE '%%VIVO TOWER 2G%')) A
group by centroid_type, segmento, tamano

UNION
-- AD-HOC: add sites wo/potential close to roads and work places

SELECT count(*), 
SUM(ran_weight) AS poblacion, centroid_type, segmento, tamano 
FROM (
SELECT DISTINCT ON (a.tower_id) a.*, a.tower_id::text as centroid, 5000 as ran_weight, 
CONCAT('EMPTY TOWER ', (CASE WHEN a.tech_3g IS TRUE THEN '3G' 
                                WHEN a.tech_2g IS TRUE THEN '2G'
                                ELSE '' END)) as centroid_type,
                                'sin 3G+ comp'::TEXT as segmento,
'mediano'::TEXT as tamano, 
ST_Distance(A.geom::geography, B.geom::geography) as distance_m
FROM (
select * from rural_planner_dev.vivo_infrastructure_location_new where
(tech_2g is true or tech_3g is true) and tech_4g is false and admin_division_3_id in ('11','12','13','14','15','16','17','21')
and admin_division_2_id not in (SELECT admin_division_2_id FROM rural_planner_dev.municipios_tim) AND source='VIVO') A
LEFT JOIN (SELECT * FROM rural_planner_dev.infrastructure_global where source='VIVO'
AND tech_4g IS TRUE) B
ON ST_DWithin(A.geom::geography, B.geom::geography, 5000)
WHERE ST_Distance(A.geom::geography, B.geom::geography) IS NULL 
AND a.tower_id::text not in (SELECT centroid from rural_planner_dev.clusters_north_2020
union
SELECT centroid from rural_planner_dev.clusters_north_3g_2020)
AND a.tower_id::text NOT IN (
SELECT distinct(ran_centroid) from rural_planner_dev.analisis_clusters_ednei_v2 a
left join rural_planner_dev.infra_master_vivo i
on a.centroid_name=i.internal_id
where segment_ov_gf='OVERLAY' AND (tech_2020 like '%L%' OR  priorizacion='RASCUNHO' OR internal_id IS NULL))
ORDER BY a.tower_id, ST_Distance(A.geom::geography, B.geom::geography)
) C
GROUP BY centroid_type, segmento, tamano 

-------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--QUERY 4: GREENFIELD VS OVERLAY ZRD
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
        n.node_type as centroid_type,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner_dev.clusters_north_zrd C
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
                FROM rural_planner_dev.transport_by_tower_north WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters_north_zrd)) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_north_zrd v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.node_table_north_zrd n
on n.node_id=C.centroid
WHERE C.cluster_weight>0) A
group by centroid_type, segmento, tamano
