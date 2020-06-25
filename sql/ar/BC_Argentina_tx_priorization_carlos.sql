
SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, 
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g, type, 
source, segmento, 
tamano
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
CASE WHEN C.cluster_weight > 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 2000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m<=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m<=2000 AND I2.radio IS TRUE THEN 'fiber tef'       
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 2000 THEN 'fiber third pty'     
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m<=40000 AND I2.tx_3g IS TRUE THEN 'radio tx_3g tef'      
     WHEN t.distance_movistar_transport_m<=2000 AND I2.tx_3g IS TRUE THEN  'fiber tx_3g tef' 
     ELSE 'satellite' END AS type,
I.source,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner.clusters_ipt C
LEFT JOIN (SELECT tower_id::TEXT as centroid,
                optimal_transport_id,
                optimal_transport_owner,
                optimal_transport_fiber,
                optimal_transport_radio,
                line_of_sight_optimal_transport,
                distance_optimal_transport_m,
                movistar_transport_id,
                distance_movistar_transport_m,
                line_of_sight_movistar,
                additional_height_tower_1_movistar_m,
                additional_height_tower_2_movistar_m,
                backhaul_movistar,
                third_party_transport_id,
                distance_third_party_transport_m,
                line_of_sight_third_party,
                additional_height_tower_1_third_party_m,
                additional_height_tower_2_third_party_m,
                backhaul_third_party,
                arsat_transport_id,
                distance_arsat_transport_m,
                line_of_sight_arsat,
                additional_height_tower_1_arsat_m,
                additional_height_tower_2_arsat_m,
                backhaul_arsat,
                silica_transport_id,
                distance_silica_transport_m,
                line_of_sight_silica,
                additional_height_tower_1_silica_m,
                additional_height_tower_2_silica_m,
                backhaul_silica,
                gigared_transport_id,
                distance_gigared_transport_m,
                line_of_sight_gigared,
                additional_height_tower_1_gigared_m,
                additional_height_tower_2_gigared_m,
                backhaul_gigared,
                points_transport_id,
                distance_points_transport_m,
                line_of_sight_points,
                additional_height_tower_1_points_m,
                additional_height_tower_2_points_m,
                backhaul_points,
                others_transport_id,
                distance_others_transport_m,
                line_of_sight_others,
                additional_height_tower_1_others_m,
                additional_height_tower_2_others_m,
                backhaul_others,
                geom_tower,
                geom_movistar,
                geom_third_party,
                geom_arsat,
                geom_silica,
                geom_gigared,
                geom_points,
                geom_others,
                geom_line_movistar,
                geom_line_third_party,
                geom_line_arsat,
                geom_line_silica,
                geom_line_gigared,
                geom_line_points,
                geom_line_others FROM rural_planner.transport_by_tower_all WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner.clusters_ipt)
                UNION 
                SELECT * FROM rural_planner.transport_greenfield_clusters_ipt) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN (owner NOT LIKE '%TASA%' AND source IN ('TASA','TASA_FIXED')) THEN 'THIRD PTY' 
                                                WHEN source IN ('TASA','TASA_FIXED') THEN 'SITES_TEF' ELSE source end as source
        FROM rural_planner.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner.v_coberturas_clusters_ipt v
on v.centroid=C.centroid) A
GROUP BY tamano, source, segmento, type 
ORDER BY tamano, source, segmento, type

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--QUERY 1: Análisis Segmentación Clusters por población & competidores (CÉSAR)
SELECT COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, source, segmento, tamano 
FROM (
SELECT C.centroid as ran_centroid, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
CASE WHEN C.cluster_weight > 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
        WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
        WHEN C.cluster_weight >= 2500 THEN 'grande'       
        ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I2.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.distance_movistar_transport_m <= 2000 and I2.fiber IS TRUE THEN 'qw fiber tef'         
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m<=40000 AND I2.radio IS TRUE THEN 'radio tef'      
     WHEN t.distance_movistar_transport_m<=2000 AND I2.radio IS TRUE THEN 'fiber tef'       
     WHEN T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport_m <= 40000 THEN 'radio third pty'   
     WHEN T.distance_third_party_transport_m <= 2000 THEN 'fiber third pty'     
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m<=40000 AND I2.tx_3g IS TRUE THEN 'radio tx_3g tef'      
     WHEN t.distance_movistar_transport_m<=2000 AND I2.tx_3g IS TRUE THEN  'fiber tx_3g tef' 
     ELSE 'satellite' END AS type,
I.source,
v.competitors_presence_4g*v.cluster_weight as pop_4g,
v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento
FROM rural_planner.clusters_ipt C
LEFT JOIN (SELECT tower_id::TEXT as centroid,
                optimal_transport_id,
                optimal_transport_owner,
                optimal_transport_fiber,
                optimal_transport_radio,
                line_of_sight_optimal_transport,
                distance_optimal_transport_m,
                movistar_transport_id,
                distance_movistar_transport_m,
                line_of_sight_movistar,
                additional_height_tower_1_movistar_m,
                additional_height_tower_2_movistar_m,
                backhaul_movistar,
                third_party_transport_id,
                distance_third_party_transport_m,
                line_of_sight_third_party,
                additional_height_tower_1_third_party_m,
                additional_height_tower_2_third_party_m,
                backhaul_third_party,
                arsat_transport_id,
                distance_arsat_transport_m,
                line_of_sight_arsat,
                additional_height_tower_1_arsat_m,
                additional_height_tower_2_arsat_m,
                backhaul_arsat,
                silica_transport_id,
                distance_silica_transport_m,
                line_of_sight_silica,
                additional_height_tower_1_silica_m,
                additional_height_tower_2_silica_m,
                backhaul_silica,
                gigared_transport_id,
                distance_gigared_transport_m,
                line_of_sight_gigared,
                additional_height_tower_1_gigared_m,
                additional_height_tower_2_gigared_m,
                backhaul_gigared,
                points_transport_id,
                distance_points_transport_m,
                line_of_sight_points,
                additional_height_tower_1_points_m,
                additional_height_tower_2_points_m,
                backhaul_points,
                others_transport_id,
                distance_others_transport_m,
                line_of_sight_others,
                additional_height_tower_1_others_m,
                additional_height_tower_2_others_m,
                backhaul_others,
                geom_tower,
                geom_movistar,
                geom_third_party,
                geom_arsat,
                geom_silica,
                geom_gigared,
                geom_points,
                geom_others,
                geom_line_movistar,
                geom_line_third_party,
                geom_line_arsat,
                geom_line_silica,
                geom_line_gigared,
                geom_line_points,
                geom_line_others FROM rural_planner.transport_by_tower_all WHERE tower_id::TEXT IN (SELECT centroid FROM rural_planner.clusters_ipt)
                UNION 
                SELECT * FROM rural_planner.transport_greenfield_clusters_ipt) T
ON C.centroid=T.centroid
LEFT JOIN rural_planner.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN (owner NOT LIKE '%TASA%' AND source IN ('TASA','TASA_FIXED')) THEN 'THIRD PTY' 
                                                WHEN source IN ('TASA','TASA_FIXED') THEN 'SITES_TEF' ELSE source end as source
        FROM rural_planner.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN rural_planner.v_coberturas_clusters_ipt v
on v.centroid=C.centroid) A
group by source, segmento, tamano
