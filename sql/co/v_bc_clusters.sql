create or replace view rural_planner.v_bc_clusters as
(SELECT DISTINCT ON (ran_centroid)  
A.ran_centroid, /*A.*, I2.internal_id, CT.centroid, CT.cluster_size, CT.cluster_weight AS transport_weight, C.centroid, (C.geom), 
C.cluster_weight AS ran_weight, C.cluster_size as ran_size, T.tower_id, T.movistar_transport_id, I3.tower_id, */
CASE
 WHEN C.cluster_weight > 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
 WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
 WHEN C.cluster_weight >= 2500 THEN 'grande'       
 ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I3.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.line_of_sight_movistar IS FALSE AND T.distance_movistar_transport_m <= 2000 and I3.fiber IS TRUE THEN 'qw fiber tef'      
     WHEN ((t.line_of_sight_anditel IS TRUE and t.distance_anditel_transport_m<=40000) or (t.line_of_sight_atc IS TRUE and t.distance_atc_transport_m<=40000) or (t.line_of_sight_atp IS TRUE and t.distance_atp_transport_m<=40000) or (t.line_of_sight_azteca IS TRUE and t.distance_azteca_transport_m<=40000) or (t.line_of_sight_isp IS TRUE and t.distance_isp_transport_m<=40000)) AND CT.cluster_weight < 2500 THEN 'radio third pty'      
     WHEN ((t.line_of_sight_anditel IS FALSE and t.distance_anditel_transport_m<=2000) or (t.line_of_sight_atc IS FALSE and t.distance_atc_transport_m<=2000) or (t.line_of_sight_atp IS FALSE and t.distance_atp_transport_m<=2000) or (t.line_of_sight_azteca IS FALSE and t.distance_azteca_transport_m<=2000) or (t.line_of_sight_isp IS FALSE and t.distance_isp_transport_m<=2000)) AND CT.cluster_weight < 2500 THEN 'fiber third pty'
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m<=40000 THEN 'radio tef'      
     WHEN t.line_of_sight_movistar IS FALSE and t.distance_movistar_transport_m<=2000 THEN 'fiber tef'      
     WHEN ((t.line_of_sight_anditel IS TRUE and t.distance_anditel_transport_m<=40000) or (t.line_of_sight_atc IS TRUE and t.distance_atc_transport_m<=40000) or (t.line_of_sight_atp IS TRUE and t.distance_atp_transport_m<=40000) or (t.line_of_sight_azteca IS TRUE and t.distance_azteca_transport_m<=40000) or (t.line_of_sight_isp IS TRUE and t.distance_isp_transport_m<=40000)) THEN 'radio third pty'      
     WHEN ((t.line_of_sight_anditel IS FALSE and t.distance_anditel_transport_m<=2000) or (t.line_of_sight_atc IS FALSE and t.distance_atc_transport_m<=2000) or (t.line_of_sight_atp IS FALSE and t.distance_atp_transport_m<=2000) or (t.line_of_sight_azteca IS FALSE and t.distance_azteca_transport_m<=2000) or (t.line_of_sight_isp IS FALSE and t.distance_isp_transport_m<=2000)) THEN 'fiber third pty'      
     ELSE 'satellite' END AS type, 
     CASE WHEN I2.source<>'SITES_TEF' THEN 'TORRE ALQUILADA'
     ELSE 'TORRE PROPIA' END AS source,
     --I2.source ,
     --v.competitors_presence_4g*v.cluster_weight as pop_4g,
     --v.competitors_presence_3g*v.cluster_weight as pop_3g,
     case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
     else 'sin 3g+ comp' end as segmento
     FROM (
                SELECT O.centroid AS transport_centroid,
                         C.centroid AS ran_centroid         
                         FROM rural_planner.clusters C         
                         LEFT JOIN (SELECT centroid,         
                                        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node         
                                        FROM rural_planner_dev.co_mw_final_clusters ) O         
                        ON C.centroid = O.node         
                        WHERE cluster_weight > 0                  
                        UNION                           
                        SELECT DISTINCT ON(O.centroid)         
                        O.centroid AS transport_centroid,         
                        C.centroid AS ran_centroid         
                        FROM rural_planner.clusters C         
                        LEFT JOIN rural_planner_dev.co_mw_final_clusters O         
                        ON C.centroid = O.centroid         
                        WHERE C.cluster_weight > 0        
                        AND O.centroid IS NOT NULL         
                        ORDER BY ran_centroid, transport_centroid ) A 
LEFT JOIN rural_planner_dev.co_mw_final_clusters CT 
ON CT.centroid = A.transport_centroid 
LEFT JOIN rural_planner.clusters C 
ON C.centroid = A.ran_centroid 
LEFT JOIN rural_planner.infrastructure_global I1 
ON I1.tower_id::text = A.transport_centroid 
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN (owner NOT LIKE '%TELEFONICA%' AND source='SITES_TEF') THEN 'THIRD PTY' ELSE source end as source
        FROM rural_planner.infrastructure_global) I2 
ON I2.tower_id::text = A.ran_centroid 
LEFT JOIN rural_planner.transport_by_tower_all T 
ON T.tower_id::text = A.ran_centroid 
LEFT JOIN rural_planner.infrastructure_global I3 
ON I3.tower_id = T.movistar_transport_id 
LEFT JOIN rural_planner.v_coberturas_clusters v 
ON v.centroid = A.ran_centroid 
WHERE LENGTH(ran_centroid) < 8
UNION 
SELECT DISTINCT ON (ran_centroid)  
A.ran_centroid, /*A.*, S.settlement_name, CT.centroid, CT.cluster_size, CT.cluster_weight AS transport_weight, C.centroid, ST_AsText(C.geom), 
C.cluster_weight AS ran_weight,  C.cluster_size as ran_size, T.centroid, T.movistar_transport, I3.tower_id, */
CASE
 WHEN C.cluster_weight > 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
 WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
 WHEN C.cluster_weight >= 2500 THEN 'grande'       
 ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport <= 40000 AND I3.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.line_of_sight_movistar IS FALSE AND T.distance_movistar_transport <= 2000 and I3.fiber IS TRUE THEN 'qw fiber tef'      
     WHEN ((T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport <= 40000)) AND CT.cluster_weight < 2500 THEN 'radio third pty'
     WHEN ((T.line_of_sight_third_party IS FALSE AND T.distance_third_party_transport <= 2000)) AND CT.cluster_weight < 2500 THEN 'fiber third pty'
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport<=40000 THEN 'radio tef'      
     WHEN t.line_of_sight_movistar IS FALSE and t.distance_movistar_transport<=2000 THEN 'fiber tef'      
     WHEN ((T.line_of_sight_third_party IS TRUE AND T.distance_third_party_transport <= 40000)) THEN 'radio third pty'
     WHEN ((T.line_of_sight_third_party IS FALSE AND T.distance_third_party_transport <= 2000)) THEN 'fiber third pty'     
     ELSE 'satellite' END AS type,
     'SIN TORRE'::text AS source,
     --v.competitors_presence_4g*v.cluster_weight as pop_4g,
     --v.competitors_presence_3g*v.cluster_weight as pop_3g,
     case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
     else 'sin 3g+ comp' end as segmento
     FROM (
                SELECT O.centroid AS transport_centroid,
                         C.centroid AS ran_centroid         
                         FROM rural_planner.clusters C         
                         LEFT JOIN (SELECT centroid,         
                                        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node         
                                        FROM rural_planner_dev.co_mw_final_clusters ) O         
                        ON C.centroid = O.node         
                        WHERE cluster_weight > 0                  
                        UNION                           
                        SELECT DISTINCT ON(O.centroid)         
                        O.centroid AS transport_centroid,         
                        C.centroid AS ran_centroid         
                        FROM rural_planner.clusters C         
                        LEFT JOIN rural_planner_dev.co_mw_final_clusters O         
                        ON C.centroid = O.centroid         
                        WHERE C.cluster_weight > 0        
                        AND O.centroid IS NOT NULL         
                        ORDER BY ran_centroid, transport_centroid ) A 
LEFT JOIN rural_planner_dev.co_mw_final_clusters CT 
ON CT.centroid = A.transport_centroid 
LEFT JOIN rural_planner.clusters C 
ON C.centroid = A.ran_centroid 
LEFT JOIN rural_planner.infrastructure_global I1 
ON I1.tower_id::text = A.transport_centroid 
LEFT JOIN rural_planner_dev.co_clusters_greenfield_los  T 
ON T.centroid::text = A.ran_centroid 
LEFT JOIN rural_planner.infrastructure_global I3 
ON I3.tower_id = T.movistar_transport 
LEFT JOIN rural_planner.v_coberturas_clusters v 
ON v.centroid = A.ran_centroid 
LEFT JOIN rural_planner.settlements s 
ON s.settlement_id = A.ran_centroid 
WHERE LENGTH(ran_centroid) >= 8)