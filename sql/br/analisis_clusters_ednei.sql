TRUNCATE TABLE {schema_dev}.analisis_clusters_ednei; 
INSERT INTO {schema_dev}.analisis_clusters_ednei
SELECT C.centroid as ran_centroid, s.centroid_name as centroid_name, s.admin_division_3_id, d.uf as admin_division_3_name, 
s.admin_division_2_id, d."município" as admin_division_2_name, d.ddd, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
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
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I5.fiber IS TRUE) THEN '2hops to fiber tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I5.radio IS TRUE) THEN '2hops to radio tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I6.fiber IS TRUE OR I7.fiber IS TRUE)) THEN '2hops to fiber 3rd pty'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I6.radio IS TRUE OR I7.radio IS TRUE)) THEN '2hops to radio 3rd pty'
     ELSE 'satellite' END AS type,
--CONCAT(COALESCE(I.source,''),' ',n.node_type) as centroid_type,
n.node_type as centroid_type,        
CASE WHEN n.node_type LIKE 'VIVO TOWER %' THEN 'OVERLAY' ELSE 'GREENFIELD' END as segment_ov_gf,
--v.competitors_presence_4g*v.cluster_weight as pop_4g,
--v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento,
I2.source as tx_movistar,
I3.source as tx_regional,
I4.source as tx_third_pty--,
--c.geom
FROM {schema_dev}.clusters_north C
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
                FROM {schema_dev}.transport_by_tower_north WHERE tower_id::TEXT IN (SELECT centroid FROM {schema_dev}.clusters_north)
                UNION 
                SELECT * FROM {schema_dev}.transport_greenfield_clusters_north) T
ON C.centroid=T.centroid
LEFT JOIN {schema_dev}.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN {schema_dev}.infrastructure_global I3
ON I3.tower_id=T.regional_transport_id
LEFT JOIN {schema_dev}.infrastructure_global I4
ON I4.tower_id=T.third_party_transport_id
LEFT JOIN {schema_dev}.transport_clusters_multihop T2
ON c.centroid=T2.centroid
LEFT JOIN {schema_dev}.infrastructure_global I5
ON I5.tower_id=T2.movistar_transport_id
LEFT JOIN {schema_dev}.infrastructure_global I6
ON I6.tower_id=T2.regional_transport_id
LEFT JOIN {schema_dev}.infrastructure_global I7
ON I7.tower_id=T2.third_party_transport_id
LEFT JOIN (SELECT tower_id, internal_id, source, tech_3g, tech_4g
        FROM {schema_dev}.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN {schema_dev}.v_coberturas_clusters_north v
on v.centroid=C.centroid
LEFT JOIN {schema_dev}.node_table_north n
on n.node_id=C.centroid
LEFT JOIN (SELECT settlement_id as centroid,
        settlement_name as centroid_name,
        admin_division_2_id, 
        admin_division_2_name,
        admin_division_3_id,
        admin_division_3_name
        FROM {schema_dev}.settlements
        UNION
        SELECT a.tower_id::text as centroid,
        a.internal_id as centroid_name,
        a.admin_division_2_id,
        s.admin_division_2_name,
        s.admin_division_3_id,
        s.admin_division_3_name
        FROM {schema_dev}.vivo_infrastructure_location_new a
        LEFT JOIN (SELECT DISTINCT ON (admin_division_2_id)
        admin_division_2_id,
        admin_division_2_name,
        admin_division_3_id,
        admin_division_3_name
        FROM {schema_dev}.settlements
        ) s
        ON a.admin_division_2_id=s.admin_division_2_id) s
ON s.centroid=c.centroid
LEFT JOIN {schema_dev}.rayo_x_vivo d
on s.admin_division_2_id=d."ibge...1"
WHERE (C.cluster_weight>=500 OR N.node_type LIKE '%VIVO TOWER 2G%')

UNION 

SELECT C.centroid as ran_centroid, s.centroid_name as centroid_name, s.admin_division_3_id, d.uf as admin_division_3_name, 
s.admin_division_2_id, d."município" as admin_division_2_name, d.ddd, C.cluster_weight as ran_weight, C.cluster_size as ran_size,
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
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I5.fiber IS TRUE) THEN '2hops to fiber tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I5.radio IS TRUE) THEN '2hops to radio tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I6.fiber IS TRUE OR I7.fiber IS TRUE)) THEN '2hops to fiber 3rd pty'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I6.radio IS TRUE OR I7.radio IS TRUE)) THEN '2hops to radio 3rd pty' 
     WHEN I.satellite IS TRUE THEN 'satellite'    
     ELSE 'radio tef' END AS type,
--CONCAT(COALESCE(I.source,''),' ',n.node_type) as centroid_type,
n.node_type as centroid_type,
CASE WHEN n.node_type LIKE 'VIVO TOWER %' THEN 'OVERLAY' ELSE 'GREENFIELD' END as segment_ov_gf,
--v.competitors_presence_4g*v.cluster_weight as pop_4g,
--v.competitors_presence_3g*v.cluster_weight as pop_3g,
case when v.competitors_presence_3g>=0.5 or v.competitors_presence_4g>=0.5 then 'con 3g+ comp'
        else 'sin 3g+ comp' end as segmento,
I2.source as tx_movistar,
I3.source as tx_regional,
I4.source as tx_third_pty--,
--c.geom
FROM {schema_dev}.clusters_north_3g C
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
                FROM {schema_dev}.transport_by_tower_north WHERE tower_id::TEXT IN (SELECT centroid FROM {schema_dev}.clusters_north_3g)
                UNION                
                SELECT * FROM {schema_dev}.transport_greenfield_clusters_north_3g) T
ON C.centroid=T.centroid
LEFT JOIN (SELECT tower_id, internal_id, CASE WHEN source='VIVO' THEN owner
                                                ELSE source end as source, tech_3g, tech_4g, satellite
        FROM {schema_dev}.infrastructure_global) I 
ON C.centroid=I.tower_id::TEXT 
LEFT JOIN {schema_dev}.v_coberturas_clusters_north_3g v
on v.centroid=C.centroid
LEFT JOIN {schema_dev}.node_table_north_3g n
on n.node_id=C.centroid
LEFT JOIN (SELECT settlement_id as centroid,
        settlement_name as centroid_name,
        admin_division_2_id, 
        admin_division_2_name,
        admin_division_3_id,
        admin_division_3_name
        FROM {schema_dev}.settlements
        UNION
        SELECT a.tower_id::text as centroid,
        a.internal_id as centroid_name,
        a.admin_division_2_id,
        s.admin_division_2_name,
        s.admin_division_3_id,
        admin_division_3_name
        FROM {schema_dev}.vivo_infrastructure_location_new a
        LEFT JOIN (SELECT DISTINCT ON (admin_division_2_id)
        admin_division_2_id,
        admin_division_2_name,
        admin_division_3_id,
        admin_division_3_name
        FROM {schema_dev}.settlements
        ) s
        ON a.admin_division_2_id=s.admin_division_2_id) s
ON s.centroid=c.centroid
LEFT JOIN {schema_dev}.rayo_x_vivo d
on s.admin_division_2_id=d."ibge...1"
LEFT JOIN {schema_dev}.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN {schema_dev}.infrastructure_global I3
ON I3.tower_id=T.regional_transport_id
LEFT JOIN {schema_dev}.infrastructure_global I4
ON I4.tower_id=T.third_party_transport_id
LEFT JOIN {schema_dev}.transport_clusters_multihop T2
ON c.centroid=T2.centroid
LEFT JOIN {schema_dev}.infrastructure_global I5
ON I5.tower_id=T2.movistar_transport_id
LEFT JOIN {schema_dev}.infrastructure_global I6
ON I6.tower_id=T2.regional_transport_id
LEFT JOIN {schema_dev}.infrastructure_global I7
ON I7.tower_id=T2.third_party_transport_id
WHERE (C.cluster_weight>=500 OR N.node_type LIKE '%VIVO TOWER 3G%');

INSERT INTO {schema_dev}.analisis_clusters_ednei (

SELECT DISTINCT ON (a.tower_id) a.tower_id::text as ran_centroid, 
s.centroid_name as centroid_name, s.admin_division_3_id, d.uf as admin_division_3_name, 
s.admin_division_2_id, d."município" as admin_division_2_name, d.ddd, 2000::integer as ran_weight, 0 as ran_size,
'mediano'::text AS tamano, 
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
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I5.fiber IS TRUE) THEN '2hops to fiber tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND I5.radio IS TRUE) THEN '2hops to radio tef'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I6.fiber IS TRUE OR I7.fiber IS TRUE)) THEN '2hops to fiber 3rd pty'
     WHEN (T2.line_of_sight_intermediate_hop IS TRUE AND (I6.radio IS TRUE OR I7.radio IS TRUE)) THEN '2hops to radio 3rd pty' 
     WHEN A.satellite IS TRUE THEN 'satellite'        
     WHEN (A.tech_3g IS TRUE OR A.tech_4g IS TRUE) THEN 'radio tef'
     ELSE 'satellite' END AS type,
--CONCAT(COALESCE(I.source,''),' ',n.node_type) as centroid_type,
CONCAT('EMPTY TOWER ', (CASE WHEN a.tech_3g IS TRUE THEN '3G' 
                                WHEN a.tech_2g IS TRUE THEN '2G'
                                ELSE '' END)) as centroid_type,
'OVERLAY'::TEXT as segment_ov_gf,
--v.competitors_presence_4g*v.cluster_weight as pop_4g,
--v.competitors_presence_3g*v.cluster_weight as pop_3g,
'sin 3G+ comp'::TEXT as segmento,
I2.source as tx_movistar,
I3.source as tx_regional,
I4.source as tx_third_pty--,
FROM (
select * from {schema_dev}.vivo_infrastructure_location_new where
(tech_2g is true or tech_3g is true) and tech_4g is false and admin_division_3_id in ('11','12','13','14','15','16','17','21')
and admin_division_2_id not in (SELECT admin_division_2_id FROM {schema_dev}.municipios_tim) AND source='VIVO') A
LEFT JOIN (SELECT * FROM {schema_dev}.infrastructure_global where source='VIVO'
AND tech_4g IS TRUE) B
ON ST_DWithin(A.geom::geography, B.geom::geography, 5000)
LEFT JOIN {schema_dev}.transport_by_tower_north T
ON a.tower_id=T.tower_id
LEFT JOIN (SELECT a.tower_id::text as centroid,
        a.internal_id as centroid_name,
        a.admin_division_2_id,
        s.admin_division_2_name,
        s.admin_division_3_id,
        admin_division_3_name
        FROM {schema_dev}.vivo_infrastructure_location_new a
        LEFT JOIN (SELECT DISTINCT ON (admin_division_2_id)
        admin_division_2_id,
        admin_division_2_name,
        admin_division_3_id,
        admin_division_3_name
        FROM {schema_dev}.settlements
        ) s
        ON a.admin_division_2_id=s.admin_division_2_id) s
ON s.centroid=a.tower_id::text
LEFT JOIN {schema_dev}.rayo_x_vivo d
on s.admin_division_2_id=d."ibge...1"
LEFT JOIN {schema_dev}.infrastructure_global I2
ON I2.tower_id=T.movistar_transport_id
LEFT JOIN {schema_dev}.infrastructure_global I3
ON I3.tower_id=T.regional_transport_id
LEFT JOIN {schema_dev}.infrastructure_global I4
ON I4.tower_id=T.third_party_transport_id
LEFT JOIN {schema_dev}.transport_clusters_multihop T2
ON a.tower_id::text=T2.centroid
LEFT JOIN {schema_dev}.infrastructure_global I5
ON I5.tower_id=T2.movistar_transport_id
LEFT JOIN {schema_dev}.infrastructure_global I6
ON I6.tower_id=T2.regional_transport_id
LEFT JOIN {schema_dev}.infrastructure_global I7
ON I7.tower_id=T2.third_party_transport_id
WHERE ST_Distance(A.geom::geography, B.geom::geography) IS NULL 
AND a.tower_id::text not in (SELECT centroid from {schema_dev}.clusters_north
union
SELECT centroid from {schema_dev}.clusters_north_3g)
ORDER BY a.tower_id, ST_Distance(A.geom::geography, B.geom::geography)
);

