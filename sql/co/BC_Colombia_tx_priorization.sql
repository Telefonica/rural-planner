
SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, 
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g, type, 
source, --segmento, 
tamano,
case when type in ('radio tef','fiber tef') then count(distinct(transport_centroid)) else 0 end as num_sites_tx
FROM (
SELECT DISTINCT ON (ran_centroid)  
A.*, I2.internal_id, CT.centroid, CT.cluster_size, CT.cluster_weight AS transport_weight, C.centroid, (C.geom), 
C.cluster_weight AS ran_weight, C.cluster_size as ran_size, T.tower_id, T.movistar_transport_id, I3.tower_id, 
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
     WHEN (I2.tech_3g IS TRUE OR I2.tech_4g IS TRUE) THEN 'radio tef'    
     ELSE 'satellite' END AS type, 
     I2.source ,
     v.competitors_presence_4g*v.cluster_weight as pop_4g,
     v.competitors_presence_3g*v.cluster_weight as pop_3g,
     case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
     else 'sin 3g+ comp' end as segmento
     FROM (
                SELECT O.centroid AS transport_centroid,
                         C.centroid AS ran_centroid         
                         FROM rural_planner_dev.clusters C         
                         LEFT JOIN (SELECT centroid,         
                                        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node         
                                        FROM rural_planner_dev.co_mw_final_clusters ) O         
                        ON C.centroid = O.node         
                        WHERE cluster_weight > 0                  
                        UNION                           
                        SELECT DISTINCT ON(O.centroid)         
                        O.centroid AS transport_centroid,         
                        C.centroid AS ran_centroid         
                        FROM rural_planner_dev.clusters C         
                        LEFT JOIN rural_planner_dev.co_mw_final_clusters O         
                        ON C.centroid = O.centroid         
                        WHERE C.cluster_weight > 0        
                        AND O.centroid IS NOT NULL         
                        ORDER BY ran_centroid, transport_centroid ) A 
LEFT JOIN rural_planner_dev.co_mw_final_clusters CT 
ON CT.centroid = A.transport_centroid 
LEFT JOIN rural_planner_dev.clusters C 
ON C.centroid = A.ran_centroid 
LEFT JOIN rural_planner_dev.infrastructure_global I1 
ON I1.tower_id::text = A.transport_centroid 
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN (owner NOT LIKE '%TELEFONICA%' AND source='SITES_TEF') THEN 'THIRD PTY' ELSE source end as source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I2 
ON I2.tower_id::text = A.ran_centroid 
LEFT JOIN rural_planner_dev.transport_by_tower_all T 
ON T.tower_id::text = A.ran_centroid 
LEFT JOIN rural_planner_dev.infrastructure_global I3 
ON I3.tower_id = T.movistar_transport_id 
LEFT JOIN rural_planner_dev.v_coberturas_clusters v 
ON v.centroid = A.ran_centroid 
WHERE LENGTH(ran_centroid) < 8
AND c.cluster_weight>=500
)X
GROUP BY tamano, source, segmento, type 
--------------------------------------------------------------------------------------------------------------------------------------

SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion,
--source, segmento, tamano , type,
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g, type, source,
tamano,
case when type in ('radio tef','fiber tef') then count(distinct(transport_centroid)) else 0 end as num_sites_tx--, segmento 
FROM (
SELECT DISTINCT ON (ran_centroid)  
A.*, S.settlement_name, CT.centroid, CT.cluster_size, CT.cluster_weight AS transport_weight, C.centroid, ST_AsText(C.geom), 
C.cluster_weight AS ran_weight,  C.cluster_size as ran_size, T.centroid, T.movistar_transport, I3.tower_id, 
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
     v.competitors_presence_4g*v.cluster_weight as pop_4g,
     v.competitors_presence_3g*v.cluster_weight as pop_3g,
        CASE WHEN n.node_type IN ('SETTLEMENT 2G','VIRTUAL TOWER 2G') THEN 'SITES_TEF' ELSE NULL END AS source,
     case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
     else 'sin 3g+ comp' end as segmento
     FROM (
                SELECT O.centroid AS transport_centroid,
                         C.centroid AS ran_centroid         
                         FROM rural_planner_dev.clusters C         
                         LEFT JOIN (SELECT centroid,         
                                        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node         
                                        FROM rural_planner_dev.co_mw_final_clusters ) O         
                        ON C.centroid = O.node         
                        WHERE cluster_weight > 0                  
                        UNION                           
                        SELECT DISTINCT ON(O.centroid)         
                        O.centroid AS transport_centroid,         
                        C.centroid AS ran_centroid         
                        FROM rural_planner_dev.clusters C         
                        LEFT JOIN rural_planner_dev.co_mw_final_clusters O         
                        ON C.centroid = O.centroid         
                        WHERE C.cluster_weight > 0        
                        AND O.centroid IS NOT NULL         
                        ORDER BY ran_centroid, transport_centroid ) A 
LEFT JOIN rural_planner_dev.co_mw_final_clusters CT 
ON CT.centroid = A.transport_centroid 
LEFT JOIN rural_planner_dev.clusters C 
ON C.centroid = A.ran_centroid 
LEFT JOIN rural_planner_dev.infrastructure_global I1 
ON I1.tower_id::text = A.transport_centroid 
LEFT JOIN rural_planner_dev.co_clusters_greenfield_los  T 
ON T.centroid::text = A.ran_centroid 
LEFT JOIN rural_planner_dev.infrastructure_global I3 
ON I3.tower_id = T.movistar_transport 
LEFT JOIN rural_planner_dev.v_coberturas_clusters v 
ON v.centroid = A.ran_centroid 
LEFT JOIN rural_planner_dev.settlements s 
ON s.settlement_id = A.ran_centroid 
LEFT JOIN rural_planner_dev.node_table_v2 n
on n.node_id=C.centroid
WHERE LENGTH(ran_centroid) >= 8
AND c.cluster_weight>=500
)X
GROUP BY tamano, source , type
ORDER BY tamano, source, type
------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------

--QUERY 1: Análisis Segmentación Clusters por población & competidores (CÉSAR)
SELECT COUNT(1) AS num_sites, SUM(cluster_weight) AS poblacion, source, segmento, tamano 
FROM (
SELECT c.centroid, c.cluster_weight,
        CASE WHEN n.node_type IN ('SETTLEMENT 2G','VIRTUAL TOWER 2G') THEN 'SITES_TEF' ELSE source END AS source,
        cv.competitors_presence_3g, cv.competitors_presence_4g,
CASE WHEN (cv.competitors_presence_3g>=0.5 or cv.competitors_presence_4g>=0.5) then 'con 3g+ comp'
     WHEN (cv.competitors_presence_3g<0.5 and cv.competitors_presence_4g<0.5) then 'sin 3g+ comp' else  'ERROR' end as segmento, 
CASE
 WHEN c.cluster_weight > 0 AND c.cluster_weight < 1250 THEN 'pequeño' 
 WHEN c.cluster_weight >= 1250 AND c.cluster_weight < 2500 THEN 'mediano'      
 WHEN c.cluster_weight >= 2500 THEN 'grande'       
 ELSE 'ERROR' END AS tamano
from rural_planner_dev.clusters c
LEFT JOIN rural_planner_dev.v_coberturas_clusters_all cv
ON c.centroid=cv.centroid
LEFT JOIN (SELECT centroid,
        cluster_weight,
        SUM(CASE WHEN movistar_3g_corrected IS FALSE AND movistar_4g_corrected IS FALSE AND competitors_3g_corrected IS FALSE AND competitors_4g_corrected IS FALSE THEN population_corrected ELSE 0 END) AS fully_unconnected,
        SUM(CASE WHEN movistar_3g_corrected IS FALSE AND movistar_4g_corrected IS FALSE AND (competitors_3g_corrected IS TRUE OR competitors_4g_corrected IS TRUE) THEN population_corrected ELSE 0 END) AS tef_unconnected
        FROM ( SELECT DISTINCT ON (centroid, S.settlement_id)
                C.*,
                CV.*,
                S.population_corrected
                FROM (
                SELECT
                centroid, cluster_weight,
                CASE WHEN nodes = '' THEN NULL
                     ELSE TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) END AS nodes
                FROM rural_planner_dev.clusters
                
                UNION (SELECT centroid, cluster_weight, centroid AS nodes from rural_planner_dev.clusters) 
                ) C
                LEFT JOIN rural_planner_dev.coverage CV
                ON CV.settlement_id = C.nodes
                LEFT JOIN rural_planner_dev.settlements S
                ON S.settlement_id = C.nodes                
                WHERE C.nodes is not NULL) a
        GROUP BY centroid, cluster_weight) b
ON c.centroid=b.centroid
LEFT JOIN rural_planner_dev.node_table_v2 n
on n.node_id=C.centroid
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN (owner NOT LIKE '%TELEFONICA%' AND source='SITES_TEF') THEN 'THIRD PTY' ELSE source end as source
        FROM rural_planner_dev.infrastructure_global) i
ON c.centroid=i.tower_id::text
where c.cluster_weight>=500) a
group by source, segmento, tamano
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CLUSTERS 3G

SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion, 
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g, type, 
source, --segmento, 
tamano,
case when type in ('radio tef','fiber tef') then count(distinct(transport_centroid)) else 0 end as num_sites_tx
FROM (
SELECT DISTINCT ON (ran_centroid)  
A.*, I2.internal_id, CT.centroid, CT.cluster_size, CT.cluster_weight AS transport_weight, C.centroid, (C.geom), 
C.cluster_weight AS ran_weight, C.cluster_size as ran_size, T.tower_id, T.movistar_transport_id, I3.tower_id, 
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
     WHEN (I2.tech_3g IS TRUE OR I2.tech_4g IS TRUE) THEN 'radio tef'    
     ELSE 'satellite' END AS type, 
     I2.source ,
     v.competitors_presence_4g*v.cluster_weight as pop_4g,
     v.competitors_presence_3g*v.cluster_weight as pop_3g,
     case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
     else 'sin 3g+ comp' end as segmento
     FROM (
                SELECT O.centroid AS transport_centroid,
                         C.centroid AS ran_centroid         
                         FROM rural_planner_dev.clusters_3g_only C         
                         LEFT JOIN (SELECT centroid,         
                                        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node         
                                        FROM rural_planner_dev.co_mw_final_clusters_3g ) O         
                        ON C.centroid = O.node         
                        WHERE cluster_weight > 0                  
                        UNION                           
                        SELECT DISTINCT ON(O.centroid)         
                        O.centroid AS transport_centroid,         
                        C.centroid AS ran_centroid         
                        FROM rural_planner_dev.clusters C         
                        LEFT JOIN rural_planner_dev.co_mw_final_clusters_3g O         
                        ON C.centroid = O.centroid         
                        WHERE C.cluster_weight > 0        
                        AND O.centroid IS NOT NULL         
                        ORDER BY ran_centroid, transport_centroid ) A 
LEFT JOIN rural_planner_dev.co_mw_final_clusters_3g CT 
ON CT.centroid = A.transport_centroid 
LEFT JOIN rural_planner_dev.clusters_3g_only C 
ON C.centroid = A.ran_centroid 
LEFT JOIN rural_planner_dev.infrastructure_global I1 
ON I1.tower_id::text = A.transport_centroid 
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN (owner NOT LIKE '%TELEFONICA%' AND source='SITES_TEF') THEN 'THIRD PTY' ELSE source end as source, tech_3g, tech_4g
        FROM rural_planner_dev.infrastructure_global) I2 
ON I2.tower_id::text = A.ran_centroid 
LEFT JOIN rural_planner_dev.transport_by_tower_all T 
ON T.tower_id::text = A.ran_centroid 
LEFT JOIN rural_planner_dev.infrastructure_global I3 
ON I3.tower_id = T.movistar_transport_id 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_3g v 
ON v.centroid = A.ran_centroid 
WHERE LENGTH(ran_centroid) < 8
--AND (A.ran_centroid IN (SELECT centroid_3g FROM rural_planner_dev.clusters_3g_only_prioritized))
AND C.cluster_weight>0
)X
GROUP BY tamano, source, segmento, type 
UNION
SELECT  COUNT(1) AS num_sites, SUM(ran_weight) AS poblacion,
--source, segmento, tamano
SUM(ran_size) as num_ccpp, sum(pop_3g) as pop_3g, sum(pop_4g) as pop_4g,  type, 'SITES_TEF' AS source, tamano,
case when type in ('radio tef','fiber tef') then count(distinct(transport_centroid)) else 0 end as num_sites_tx
FROM (
SELECT DISTINCT ON (ran_centroid)  
A.*, S.settlement_name, CT.centroid, CT.cluster_size, CT.cluster_weight AS transport_weight, C.centroid, ST_AsText(C.geom), 
C.cluster_weight AS ran_weight,  C.cluster_size as ran_size, T.centroid, T.movistar_transport, I3.tower_id, 
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
     v.competitors_presence_4g*v.cluster_weight as pop_4g,
     v.competitors_presence_3g*v.cluster_weight as pop_3g,
     NULL::text AS source,
     case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
     else 'sin 3g+ comp' end as segmento
     FROM (
                SELECT O.centroid AS transport_centroid,
                         C.centroid AS ran_centroid         
                         FROM rural_planner_dev.clusters_3g_only C         
                         LEFT JOIN (SELECT centroid,         
                                        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node         
                                        FROM rural_planner_dev.co_mw_final_clusters_3g ) O         
                        ON C.centroid = O.node         
                        WHERE cluster_weight > 0                  
                        UNION                           
                        SELECT DISTINCT ON(O.centroid)         
                        O.centroid AS transport_centroid,         
                        C.centroid AS ran_centroid         
                        FROM rural_planner_dev.clusters_3g_only C         
                        LEFT JOIN rural_planner_dev.co_mw_final_clusters_3g O         
                        ON C.centroid = O.centroid         
                        WHERE C.cluster_weight > 0        
                        AND O.centroid IS NOT NULL         
                        ORDER BY ran_centroid, transport_centroid ) A 
LEFT JOIN rural_planner_dev.co_mw_final_clusters_3g CT 
ON CT.centroid = A.transport_centroid 
LEFT JOIN rural_planner_dev.clusters_3g_only C 
ON C.centroid = A.ran_centroid 
LEFT JOIN rural_planner_dev.infrastructure_global I1 
ON I1.tower_id::text = A.transport_centroid 
LEFT JOIN rural_planner_dev.co_clusters_greenfield_los_3g  T 
ON T.centroid::text = A.ran_centroid 
LEFT JOIN rural_planner_dev.infrastructure_global I3 
ON I3.tower_id = T.movistar_transport 
LEFT JOIN rural_planner_dev.v_coberturas_clusters_3g v 
ON v.centroid = A.ran_centroid 
LEFT JOIN rural_planner_dev.settlements s 
ON s.settlement_id = A.ran_centroid 
WHERE LENGTH(ran_centroid) >= 8
--AND (A.ran_centroid IN (SELECT centroid_3g FROM rural_planner_dev.clusters_3g_only_prioritized)) 
AND C.cluster_weight>0
)X
GROUP BY tamano, source, type
ORDER BY tamano, source, type
------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------

--QUERY 1: Análisis Segmentación Clusters por población & competidores (CÉSAR)
SELECT COUNT(1) AS num_sites, SUM(cluster_weight) AS poblacion, source, segmento, tamano 
FROM (
SELECT DISTINCT ON (c.centroid) c.centroid, c.cluster_weight, CASE WHEN i.source IS NULL THEN 'SITES_TEF' ELSE i.source END AS source, 
cv.competitors_presence_3g, cv.competitors_presence_4g,
CASE WHEN (cv.competitors_presence_3g>=0.5 or cv.competitors_presence_4g>=0.5) then 'con 3g+ comp'
     WHEN (cv.competitors_presence_3g<0.5 and cv.competitors_presence_4g<0.5) then 'sin 3g+ comp' else  'ERROR' end as segmento, 
CASE
 WHEN c.cluster_weight > 0 AND c.cluster_weight < 1250 THEN 'pequeño' 
 WHEN c.cluster_weight >= 1250 AND c.cluster_weight < 2500 THEN 'mediano'      
 WHEN c.cluster_weight >= 2500 THEN 'grande'       
 ELSE 'ERROR' END AS tamano
from rural_planner_dev.clusters_3g_only c
LEFT JOIN rural_planner_dev.v_coberturas_clusters_all_3g cv
ON c.centroid=cv.centroid
LEFT JOIN (SELECT centroid,
        cluster_weight,
        SUM(CASE WHEN movistar_3g_corrected IS FALSE AND movistar_4g_corrected IS FALSE AND competitors_3g_corrected IS FALSE AND competitors_4g_corrected IS FALSE THEN population_corrected ELSE 0 END) AS fully_unconnected,
        SUM(CASE WHEN movistar_3g_corrected IS FALSE AND movistar_4g_corrected IS FALSE AND (competitors_3g_corrected IS TRUE OR competitors_4g_corrected IS TRUE) THEN population_corrected ELSE 0 END) AS tef_unconnected
        FROM ( SELECT DISTINCT ON (centroid, S.settlement_id)
                C.*,
                CV.*,
                S.population_corrected
                FROM (
                SELECT
                centroid, cluster_weight,
                CASE WHEN nodes = '' THEN NULL
                     ELSE TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) END AS nodes
                FROM rural_planner_dev.clusters_3g_only
                
                UNION (SELECT centroid, cluster_weight, centroid AS nodes from rural_planner_dev.clusters) 
                ) C
                LEFT JOIN rural_planner_dev.coverage CV
                ON CV.settlement_id = C.nodes
                LEFT JOIN rural_planner_dev.settlements S
                ON S.settlement_id = C.nodes                
                WHERE C.nodes is not NULL) a
        GROUP BY centroid, cluster_weight) b
ON c.centroid=b.centroid
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN (owner NOT LIKE '%TELEFONICA%' AND source='SITES_TEF') THEN 'THIRD PTY' ELSE source end as source
        FROM rural_planner_dev.infrastructure_global) i
ON c.centroid=i.tower_id::text
where c.cluster_weight>0
--AND (c.centroid IN (SELECT centroid_3g FROM rural_planner_dev.clusters_3g_only_prioritized))
) a
group by source, segmento, tamano

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- QUERY 3 : GF vs OVERLAY


--QUERY 1: Análisis Segmentación Clusters por población & competidores (CÉSAR)
SELECT COUNT(1) AS num_sites, SUM(cluster_weight) AS poblacion, centroid_type, segmento, tamano 
FROM (
SELECT DISTINCT ON (c.centroid) c.centroid, c.cluster_weight, 
CASE WHEN n.node_type LIKE '%SETTLEMENT%' THEN 'VIRTUAL TOWER 3G' ELSE 'TOWER 3G' END AS centroid_type, 
cv.competitors_presence_3g, cv.competitors_presence_4g,
CASE WHEN (cv.competitors_presence_3g>=0.5 or cv.competitors_presence_4g>=0.5) then 'con 3g+ comp'
     WHEN (cv.competitors_presence_3g<0.5 and cv.competitors_presence_4g<0.5) then 'sin 3g+ comp' else  'ERROR' end as segmento, 
CASE
 WHEN c.cluster_weight > 0 AND c.cluster_weight < 1250 THEN 'pequeño' 
 WHEN c.cluster_weight >= 1250 AND c.cluster_weight < 2500 THEN 'mediano'      
 WHEN c.cluster_weight >= 2500 THEN 'grande'       
 ELSE 'ERROR' END AS tamano
from rural_planner_dev.clusters_3g_only c
LEFT JOIN rural_planner_dev.v_coberturas_clusters_all_3g cv
ON c.centroid=cv.centroid
LEFT JOIN (SELECT centroid,
        cluster_weight,
        SUM(CASE WHEN movistar_3g_corrected IS FALSE AND movistar_4g_corrected IS FALSE AND competitors_3g_corrected IS FALSE AND competitors_4g_corrected IS FALSE THEN population_corrected ELSE 0 END) AS fully_unconnected,
        SUM(CASE WHEN movistar_3g_corrected IS FALSE AND movistar_4g_corrected IS FALSE AND (competitors_3g_corrected IS TRUE OR competitors_4g_corrected IS TRUE) THEN population_corrected ELSE 0 END) AS tef_unconnected
        FROM ( SELECT DISTINCT ON (centroid, S.settlement_id)
                C.*,
                CV.*,
                S.population_corrected
                FROM (
                SELECT
                centroid, cluster_weight,
                CASE WHEN nodes = '' THEN NULL
                     ELSE TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) END AS nodes
                FROM rural_planner_dev.clusters_3g_only
                
                UNION (SELECT centroid, cluster_weight, centroid AS nodes from rural_planner_dev.clusters) 
                ) C
                LEFT JOIN rural_planner_dev.coverage CV
                ON CV.settlement_id = C.nodes
                LEFT JOIN rural_planner_dev.settlements S
                ON S.settlement_id = C.nodes                
                WHERE C.nodes is not NULL) a
        GROUP BY centroid, cluster_weight) b
ON c.centroid=b.centroid
LEFT JOIN rural_planner_dev.node_table_3g n
on n.node_id=C.centroid
where c.cluster_weight>0
AND (c.centroid IN (SELECT centroid_3g FROM rural_planner_dev.clusters_3g_only_prioritized))
) a
group by centroid_type, segmento, tamano
UNION
--QUERY 1: Análisis Segmentación Clusters por población & competidores (CÉSAR)
SELECT COUNT(1) AS num_sites, SUM(cluster_weight) AS poblacion, centroid_type, segmento, tamano 
FROM (
SELECT c.centroid, c.cluster_weight,
        CASE WHEN n.node_type LIKE '%SETTLEMENT%' OR n.node_type='TOWER' THEN NULL ELSE 'TOWER 2G' END as centroid_type,
        --n.node_type as centroid_type,
        cv.competitors_presence_3g, cv.competitors_presence_4g,
CASE WHEN (cv.competitors_presence_3g>=0.5 or cv.competitors_presence_4g>=0.5) then 'con 3g+ comp'
     WHEN (cv.competitors_presence_3g<0.5 and cv.competitors_presence_4g<0.5) then 'sin 3g+ comp' else  'ERROR' end as segmento, 
CASE
 WHEN c.cluster_weight > 0 AND c.cluster_weight < 1250 THEN 'pequeño' 
 WHEN c.cluster_weight >= 1250 AND c.cluster_weight < 2500 THEN 'mediano'      
 WHEN c.cluster_weight >= 2500 THEN 'grande'       
 ELSE 'ERROR' END AS tamano
from rural_planner_dev.clusters c
LEFT JOIN rural_planner_dev.v_coberturas_clusters_all cv
ON c.centroid=cv.centroid
LEFT JOIN (SELECT centroid,
        cluster_weight,
        SUM(CASE WHEN movistar_3g_corrected IS FALSE AND movistar_4g_corrected IS FALSE AND competitors_3g_corrected IS FALSE AND competitors_4g_corrected IS FALSE THEN population_corrected ELSE 0 END) AS fully_unconnected,
        SUM(CASE WHEN movistar_3g_corrected IS FALSE AND movistar_4g_corrected IS FALSE AND (competitors_3g_corrected IS TRUE OR competitors_4g_corrected IS TRUE) THEN population_corrected ELSE 0 END) AS tef_unconnected
        FROM ( SELECT DISTINCT ON (centroid, S.settlement_id)
                C.*,
                CV.*,
                S.population_corrected
                FROM (
                SELECT
                centroid, cluster_weight,
                CASE WHEN nodes = '' THEN NULL
                     ELSE TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) END AS nodes
                FROM rural_planner_dev.clusters
                
                UNION (SELECT centroid, cluster_weight, centroid AS nodes from rural_planner_dev.clusters) 
                ) C
                LEFT JOIN rural_planner_dev.coverage CV
                ON CV.settlement_id = C.nodes
                LEFT JOIN rural_planner_dev.settlements S
                ON S.settlement_id = C.nodes                
                WHERE C.nodes is not NULL) a
        GROUP BY centroid, cluster_weight) b
ON c.centroid=b.centroid
LEFT JOIN rural_planner_dev.node_table_v2 n
on n.node_id=C.centroid
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN (owner NOT LIKE '%TELEFONICA%' AND source='SITES_TEF') THEN 'THIRD PTY' ELSE source end as source
        FROM rural_planner_dev.infrastructure_global) i
ON c.centroid=i.tower_id::text
where c.cluster_weight>=500) a
group by centroid_type, segmento, tamano
