
SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, 
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g, type, 
source,-- segmento, 
tamano, franquiciado
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
     ELSE 'satellite' END AS type,
I.source,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento,
franchise as franquiciado
FROM rural_planner_dev.clusters C
LEFT JOIN (SELECT tower_id::TEXT as centroid,                
                movistar_transport_id,
                distance_movistar_transport_m,
                line_of_sight_movistar,
                additional_height_tower_1_movistar_m,
                additional_height_tower_2_movistar_m,
                regional_transport_id,
                distance_regional_transport_m,
                line_of_sight_regional,
                additional_height_tower_1_regional_m,
                additional_height_tower_2_regional_m,
                third_party_transport_id,
                distance_third_party_transport_m,
                line_of_sight_third_party,
                additional_height_tower_1_third_party_m,
                additional_height_tower_2_third_party_m
                FROM rural_planner_dev.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters)
                UNION 
                SELECT * FROM rural_planner_dev.ec_clusters_greenfield_los) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN rural_planner_dev.infrastructure_global I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.cluster_franchise_map F
on F.centroid=C.centroid) A
GROUP BY tamano, source, type, franquiciado 
ORDER BY tamano, source, type

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--QUERY 1: Análisis Segmentación Clusters por población & competidores (CÉSAR)
SELECT COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, source, segmento, tamano, franquiciado 
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
CASE WHEN C.cluster_weight >= 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport <= 2000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport<=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport<=2000 AND I2.radio IS TRUE THEN 'fiber tef'       
     WHEN T.line_of_sight_regional IS TRUE AND T.distance_regional_transport <= 40000 THEN 'radio regional'   
     WHEN T.distance_regional_transport <= 2000 THEN 'fiber regional'          
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport <= 2000 THEN 'fiber third pty'     
     ELSE 'satellite' END AS type,
I.source,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento,
F.franchise as franquiciado
FROM rural_planner_dev.clusters C
LEFT JOIN (SELECT * FROM rural_planner_dev.ec_clusters_greenfield_los
                UNION
                SELECT tower_id::TEXT as centroid,                
                movistar_transport_id,
                distance_movistar_transport_m,
                line_of_sight_movistar,
                additional_height_tower_1_movistar_m,
                additional_height_tower_2_movistar_m,
                regional_transport_id,
                distance_regional_transport_m,
                line_of_sight_regional,
                additional_height_tower_1_regional_m,
                additional_height_tower_2_regional_m,
                third_party_transport_id,
                distance_third_party_transport_m,
                line_of_sight_third_party,
                additional_height_tower_1_third_party_m,
                additional_height_tower_2_third_party_m
                FROM rural_planner_dev.transport_by_tower WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner_dev.clusters)
                ) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner_dev.infrastructure_global I2
ON I2.tower_id=T.movistar_transport
LEFT JOIN rural_planner_dev.infrastructure_global I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner_dev.v_coberturas_clusters v
on v.centroid=C.centroid
LEFT JOIN rural_planner_dev.cluster_franchise_map F
on F.centroid=C.centroid) A
group by source, segmento, tamano, franquiciado