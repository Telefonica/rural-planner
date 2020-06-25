CREATE OR REPLACE VIEW
    {schema}.v_acceso_transporte_clusters
    (
        cluster_id,
        codigo_divipola,
        torre_acceso,
        km_dist_torre_acceso,
        owner_torre_acceso,
        los_acceso_transporte,
        altura_torre_acceso,
        tipo_torre_acceso,
        vendor_torre_acceso,
        tecnologia_torre_acceso,
        torre_acceso_4g,
        torre_acceso_3g,
        torre_acceso_2g,
        torre_acceso_source,
        torre_acceso_internal_id,
        latitude_torre_acceso,
        longitude_torre_acceso,
        geom_torre_acceso,
        geom_line_torre_acceso,
        geom_line_trasnporte_torre_acceso,
        torre_acceso_movistar_optima,
        distancia_torre_acceso_movistar_optima,
        torre_acceso_anditel_optima,
        distancia_torre_acceso_anditel_optima,
        torre_acceso_atc_optima,
        distancia_torre_acceso_atc_optima,
        torre_acceso_atp_optima,
        distancia_torre_acceso_atp_optima,       
        torre_acceso_phoenix_optima,
        distancia_torre_acceso_phoenix_optima,
        torre_acceso_qmc_optima,
        distancia_torre_acceso_qmc_optima,
        torre_acceso_uniti_optima,
        distancia_torre_acceso_uniti_optima,
        torre_transporte,
        km_dist_torre_transporte,
        owner_torre_transporte,
        altura_torre_transporte,
        tipo_torre_transporte,
        banda_satelite_torre_transporte,
        torre_transporte_fibra,
        torre_transporte_radio,
        torre_transporte_satellite,
        torre_transporte_source,
        torre_transporte_internal_id,
        latitude_torre_transporte,
        longitude_torre_transporte,
        geom_torre_transporte,
        geom_line_torre_transporte,
        torre_transporte_movistar_optima,
        distancia_torre_transporte_movistar_optima,
        torre_transporte_anditel_optima,
        distancia_torre_transporte_anditel_optima,
        torre_transporte_azteca_optima,
        distancia_torre_transporte_azteca_optima,
        torre_transporte_atc_optima,
        distancia_torre_transporte_atc_optima,
        torre_transporte_atp_optima,
        distancia_torre_transporte_atp_optima,
        torre_transporte_phoenix_optima,
        distancia_torre_transporte_phoenix_optima,
        torre_transporte_qmc_optima,
        distancia_torre_transporte_qmc_optima,
        torre_transporte_uniti_optima,
        distancia_torre_transporte_uniti_optima                
    ) AS
    
    --- QW & TEF TOWER CLUSTERS
    SELECT c.centroid as cluster_id,
    NULL as codigo_divipola,
    i.tower_id as torre_acceso,
    0::DOUBLE PRECISION as km_dist_torre_acceso, 
    i.owner as owner_torre_acceso,
    tr.line_of_sight_movistar as los_acceso_transporte,
        i.tower_height as altura_torre_acceso,
        i.type as tipo_torre_acceso,
        i.vendor as vendor_torre_acceso,
     CASE
        WHEN ((i.tech_4g
                AND i.tech_3g)
            AND i.tech_2g)
        THEN '4G+3G+2G'::text
        WHEN (i.tech_4g
            AND i.tech_3g)
        THEN '4G+3G'::text
        WHEN (i.tech_4g
            AND i.tech_2g)
        THEN '4G+2G'::text
        WHEN (i.tech_3g
            AND i.tech_2g)
        THEN '3G+2G'::text
        WHEN i.tech_4g
        THEN '4G'::text
        WHEN i.tech_3g
        THEN '3G'::text
        WHEN i.tech_2g
        THEN '2G'::text
        ELSE '-'::text
        END                     AS tecnologia_torre_acceso,
        i.tech_4g as torre_acceso_4g,
        i.tech_3g as torre_acceso_3g,
        i.tech_2g as torre_acceso_2g,
        i.source as torre_acceso_source,
        i.internal_id as torre_acceso_internal_id,
        i.latitude as latitude_torre_acceso,
        i.longitude as longitude_torre_acceso,
        i.geom as geom_torre_acceso,
        NULL::geometry AS geom_line_torre_acceso,
        ST_Makeline(i.geom::geometry,it.geom::geometry) AS geom_line_trasnporte_torre_acceso,        
        CASE WHEN i.source='SITES_TEF' THEN i.tower_id ELSE NULL END AS torre_acceso_movistar_optima,
        CASE WHEN i.source='SITES_TEF' THEN 0 ELSE NULL END AS distancia_torre_acceso_movistar_optima,
        CASE WHEN i.source='ANDITEL' THEN i.tower_id ELSE NULL END AS torre_acceso_anditel_optima,
        CASE WHEN i.source='ANDITEL' THEN 0 ELSE NULL END AS distancia_torre_acceso_anditel_optima,
        CASE WHEN i.source='ATC' THEN i.tower_id ELSE NULL END AS torre_acceso_atc_optima,
        CASE WHEN i.source='ATC' THEN 0 ELSE NULL END AS distancia_torre_acceso_atc_optima,
        CASE WHEN i.source='ATP' THEN i.tower_id ELSE NULL END AS torre_acceso_atp_optima,
        CASE WHEN i.source='ATP' THEN 0 ELSE NULL END AS distancia_torre_acceso_atp_optima,       
        CASE WHEN i.source='PTI' THEN i.tower_id ELSE NULL END AS torre_acceso_phoenix_optima,
        CASE WHEN i.source='PTI' THEN 0 ELSE NULL END AS distancia_torre_acceso_phoenix_optima,
        CASE WHEN i.source='QMC' THEN i.tower_id ELSE NULL END AS torre_acceso_qmc_optima,
        CASE WHEN i.source='QMC' THEN 0 ELSE NULL END AS distancia_torre_acceso_qmc_optima,
        CASE WHEN i.source='UNITI' THEN i.tower_id ELSE NULL END AS torre_acceso_uniti_optima,
        CASE WHEN i.source='UNITI' THEN 0 ELSE NULL END AS distancia_torre_acceso_uniti_optima,
        tr.movistar_transport_id as torre_transporte,
        (tr.distance_movistar_transport_m/1000)::DOUBLE PRECISION as km_dist_torre_transporte,
        it.owner as owner_torre_transporte,
        it.tower_height as altura_torre_transporte,
        CASE
        WHEN ((it.fiber
                AND it.radio)
            AND it.satellite)
        THEN 'FO+RADIO+SAT'::text
        WHEN (it.fiber
            AND it.radio)
        THEN 'FO+RADIO'::text
        WHEN (it.fiber
            AND it.satellite)
        THEN 'FO+SAT'::text
        WHEN (it.radio
            AND it.satellite)
        THEN 'RADIO+SAT'::text
        WHEN it.fiber
        THEN 'FO'::text
        WHEN it.radio
        THEN 'RADIO'::text
        WHEN it.satellite
        THEN 'SAT'::text
        ELSE '-'::text
    END AS tipo_torre_transporte,
        it.satellite_band_in_use as banda_satelite_torre_transporte,
        it.fiber as torre_transporte_fibra,
        it.radio as torre_transporte_radio,
        it.satellite as torre_transporte_satellite,
        it.source as torre_transporte_source,
        it.internal_id as torre_transporte_internal_id,
        it.latitude as latitude_torre_transporte,
        it.longitude as longitude_torre_transporte,
        it.geom as geom_torre_transporte,
        NULL::geometry as geom_line_torre_transporte,
        tr.movistar_transport_id as torre_transporte_movistar_optima,
        tr.distance_movistar_transport_m as distancia_torre_transporte_movistar_optima,
        tr.anditel_transport_id as torre_transporte_anditel_optima,
        tr.distance_anditel_transport_m as distancia_torre_transporte_anditel_optima,
        tr.azteca_transport_id as torre_transporte_azteca_optima,
        tr.distance_azteca_transport_m as distancia_torre_transporte_azteca_optima,
        tr.atc_transport_id as torre_transporte_atc_optima,
        tr.distance_atc_transport_m as distancia_torre_transporte_atc_optima,
        tr.atp_transport_id as torre_transporte_atp_optima,
        tr.distance_atp_transport_m as distancia_torre_transporte_atp_optima,
        tr.phoenix_transport_id as torre_transporte_phoenix_optima,
        tr.distance_phoenix_transport_m  as distancia_torre_transporte_phoenix_optima,
        tr.qmc_transport_id as torre_transporte_qmc_optima,
        tr.distance_qmc_transport_m as distancia_torre_transporte_qmc_optima,
        tr.phoenix_transport_id as torre_transporte_uniti_optima,
        tr.distance_phoenix_transport_m as distancia_torre_transporte_uniti_optima
FROM {schema}.clusters c
LEFT JOIN (
SELECT DISTINCT ON (ran_centroid)  
A.*, I2.internal_id, CT.centroid, CT.cluster_size, CT.cluster_weight AS transport_weight, C.centroid,
C.cluster_weight AS ran_weight, C.cluster_size as ran_size, T.tower_id, T.movistar_transport_id , I3.tower_id, 
CASE
 WHEN C.cluster_weight > 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
 WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
 WHEN C.cluster_weight >= 2500 THEN 'grande'       
 ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I3.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.line_of_sight_movistar IS FALSE AND T.distance_movistar_transport_m <= 2000 and I3.fiber IS TRUE THEN 'qw fiber tef'      
     WHEN ((t.line_of_sight_anditel IS TRUE and t.distance_anditel_transport_m<=40000) or (t.line_of_sight_atc IS TRUE and t.distance_atc_transport_m<=40000) or (t.line_of_sight_atp IS TRUE and t.distance_atp_transport_m<=40000) or (t.line_of_sight_azteca IS TRUE and t.distance_azteca_transport_m<=40000)) AND CT.cluster_weight < 2500 THEN 'radio third pty'      
     WHEN ((t.line_of_sight_anditel IS FALSE and t.distance_anditel_transport_m<=2000) or (t.line_of_sight_atc IS FALSE and t.distance_atc_transport_m<=2000) or (t.line_of_sight_atp IS FALSE and t.distance_atp_transport_m<=2000) or (t.line_of_sight_azteca IS FALSE and t.distance_azteca_transport_m<=2000)) AND CT.cluster_weight < 2500 THEN 'fiber third pty'
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m<=40000 THEN 'radio tef'      
     WHEN t.line_of_sight_movistar IS FALSE and t.distance_movistar_transport_m<=2000 THEN 'fiber tef'      
     WHEN ((t.line_of_sight_anditel IS TRUE and t.distance_anditel_transport_m<=40000) or (t.line_of_sight_atc IS TRUE and t.distance_atc_transport_m<=40000) or (t.line_of_sight_atp IS TRUE and t.distance_atp_transport_m<=40000) or (t.line_of_sight_azteca IS TRUE and t.distance_azteca_transport_m<=40000)) THEN 'radio third pty'      
     WHEN ((t.line_of_sight_anditel IS FALSE and t.distance_anditel_transport_m<=2000) or (t.line_of_sight_atc IS FALSE and t.distance_atc_transport_m<=2000) or (t.line_of_sight_atp IS FALSE and t.distance_atp_transport_m<=2000) or (t.line_of_sight_azteca IS FALSE and t.distance_azteca_transport_m<=2000)) THEN 'fiber third pty'      
     ELSE 'satellite' END AS type, 
     I2.source
     FROM (
                SELECT O.centroid AS transport_centroid,
                         C.centroid AS ran_centroid         
                         FROM {schema}.clusters C         
                         LEFT JOIN (SELECT centroid,         
                                        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node         
                                        FROM {schema}.transport_clusters ) O         
                        ON C.centroid = O.node         
                        WHERE cluster_weight > 0                  
                        UNION                           
                        SELECT DISTINCT ON(O.centroid)         
                        O.centroid AS transport_centroid,         
                        C.centroid AS ran_centroid         
                        FROM {schema}.clusters C         
                        LEFT JOIN {schema}.transport_clusters O         
                        ON C.centroid = O.centroid         
                        WHERE C.cluster_weight > 0        
                        AND O.centroid IS NOT NULL         
                        ORDER BY ran_centroid, transport_centroid ) A 
LEFT JOIN {schema}.transport_clusters CT 
ON CT.centroid = A.transport_centroid 
LEFT JOIN {schema}.clusters C 
ON C.centroid = A.ran_centroid 
LEFT JOIN {schema}.infrastructure_global I1 
ON I1.tower_id::text = A.transport_centroid 
LEFT JOIN {schema}.infrastructure_global I2 
ON I2.tower_id::text = A.ran_centroid 
LEFT JOIN {schema}.transport_by_tower_all T 
ON T.tower_id::text = A.ran_centroid 
LEFT JOIN {schema}.infrastructure_global I3 
ON I3.tower_id = T.movistar_transport_id 
WHERE LENGTH(ran_centroid) < 8) A
ON A.ran_centroid=c.centroid
left join {schema}.infrastructure_global i
on c.centroid=i.tower_id::text
left join {schema}.transport_by_tower_all tr
on i.tower_id=tr.tower_id
left join {schema}.infrastructure_global it
on it.tower_id=tr.movistar_transport_id 
WHERE A.type LIKE '%tef%'


UNION 
 --- 3rd pty TOWER CLUSTERS
    SELECT c.centroid as cluster_id,
    NULL as codigo_divipola,
    i.tower_id as torre_acceso,
    0::DOUBLE PRECISION as km_dist_torre_acceso, 
    i.owner as owner_torre_acceso,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN tr.line_of_sight_anditel
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN tr.line_of_sight_azteca
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN tr.line_of_sight_atc
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN tr.line_of_sight_atp
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN tr.line_of_sight_uniti::bool
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN tr.line_of_sight_qmc::bool
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN tr.line_of_sight_phoenix::bool
         ELSE NULL END AS los_acceso_transporte,
        i.tower_height as altura_torre_acceso,
        i.type as tipo_torre_acceso,
        i.vendor as vendor_torre_acceso,
     CASE
        WHEN ((i.tech_4g
                AND i.tech_3g)
            AND i.tech_2g)
        THEN '4G+3G+2G'::text
        WHEN (i.tech_4g
            AND i.tech_3g)
        THEN '4G+3G'::text
        WHEN (i.tech_4g
            AND i.tech_2g)
        THEN '4G+2G'::text
        WHEN (i.tech_3g
            AND i.tech_2g)
        THEN '3G+2G'::text
        WHEN i.tech_4g
        THEN '4G'::text
        WHEN i.tech_3g
        THEN '3G'::text
        WHEN i.tech_2g
        THEN '2G'::text
        ELSE '-'::text
        END                     AS tecnologia_torre_acceso,
        i.tech_4g as torre_acceso_4g,
        i.tech_3g as torre_acceso_3g,
        i.tech_2g as torre_acceso_2g,
        i.source as torre_acceso_source,
        i.internal_id as torre_acceso_internal_id,
        i.latitude as latitude_torre_acceso,
        i.longitude as longitude_torre_acceso,
        i.geom as geom_torre_acceso,
        NULL::geometry AS geom_line_torre_acceso,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it1.geom::geometry)
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it2.geom::geometry)
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it3.geom::geometry)
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it4.geom::geometry)
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it5.geom::geometry)
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it6.geom::geometry)
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it7.geom::geometry)
         ELSE NULL END AS geom_line_trasnporte_torre_acceso,                 
        CASE WHEN i.source='SITES_TEF' THEN i.tower_id ELSE NULL END AS torre_acceso_movistar_optima,
        CASE WHEN i.source='SITES_TEF' THEN 0 ELSE NULL END AS distancia_torre_acceso_movistar_optima,
        CASE WHEN i.source='ANDITEL' THEN i.tower_id ELSE NULL END AS torre_acceso_anditel_optima,
        CASE WHEN i.source='ANDITEL' THEN 0 ELSE NULL END AS distancia_torre_acceso_anditel_optima,
        CASE WHEN i.source='ATC' THEN i.tower_id ELSE NULL END AS torre_acceso_atc_optima,
        CASE WHEN i.source='ATC' THEN 0 ELSE NULL END AS distancia_torre_acceso_atc_optima,
        CASE WHEN i.source='ATP' THEN i.tower_id ELSE NULL END AS torre_acceso_atp_optima,
        CASE WHEN i.source='ATP' THEN 0 ELSE NULL END AS distancia_torre_acceso_atp_optima,       
        CASE WHEN i.source='PTI' THEN i.tower_id ELSE NULL END AS torre_acceso_phoenix_optima,
        CASE WHEN i.source='PTI' THEN 0 ELSE NULL END AS distancia_torre_acceso_phoenix_optima,
        CASE WHEN i.source='QMC' THEN i.tower_id ELSE NULL END AS torre_acceso_qmc_optima,
        CASE WHEN i.source='QMC' THEN 0 ELSE NULL END AS distancia_torre_acceso_qmc_optima,
        CASE WHEN i.source='UNITI' THEN i.tower_id ELSE NULL END AS torre_acceso_uniti_optima,
        CASE WHEN i.source='UNITI' THEN 0 ELSE NULL END AS distancia_torre_acceso_uniti_optima,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN tr.anditel_transport_id
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN tr.azteca_transport_id
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN tr.atc_transport_id
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN tr.atp_transport_id
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN tr.uniti_transport_id
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN tr.qmc_transport_id
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN tr.phoenix_transport_id
         ELSE NULL END AS torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN (tr.distance_anditel_transport_m/1000)::DOUBLE PRECISION
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN (tr.distance_azteca_transport_m/1000)::DOUBLE PRECISION
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN (tr.distance_atc_transport_m/1000)::DOUBLE PRECISION
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN (tr.distance_atp_transport_m/1000)::DOUBLE PRECISION
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN (tr.distance_uniti_transport_m/1000)::DOUBLE PRECISION
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN (tr.distance_qmc_transport_m/1000)::DOUBLE PRECISION
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN (tr.distance_phoenix_transport_m/1000)::DOUBLE PRECISION
         ELSE NULL END AS km_dist_torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.owner
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.owner
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.owner
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.owner
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.owner
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.owner
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.owner
         ELSE NULL END AS owner_torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.tower_height
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.tower_height
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.tower_height
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.tower_height
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.tower_height
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.tower_height
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.tower_height
         ELSE NULL END AS altura_torre_transporte,
    CASE WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.fiber AND it1.radio AND it1.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.fiber AND it1.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.fiber AND it1.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.satellite AND it1.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.satellite)) THEN 'SAT'::text
                
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.fiber AND it2.radio AND it2.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.fiber AND it2.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.fiber AND it2.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.satellite AND it2.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.satellite)) THEN 'SAT'::text
                
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.fiber AND it3.radio AND it3.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.fiber AND it3.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.fiber AND it3.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.satellite AND it3.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.satellite)) THEN 'SAT'::text
                
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.fiber AND it4.radio AND it4.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.fiber AND it4.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.fiber AND it4.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.satellite AND it4.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.satellite)) THEN 'SAT'::text
                
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.fiber AND it5.radio AND it5.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.fiber AND it5.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.fiber AND it5.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.satellite AND it5.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.satellite)) THEN 'SAT'::text
                
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.fiber AND it6.radio AND it6.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.fiber AND it6.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.fiber AND it6.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.satellite AND it6.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.satellite)) THEN 'SAT'::text
                
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.fiber AND it7.radio AND it7.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.fiber AND it7.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.fiber AND it7.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.satellite AND it7.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.satellite)) THEN 'SAT'::text
        
        ELSE '-'::text
    END AS tipo_torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.satellite_band_in_use
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.satellite_band_in_use
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.satellite_band_in_use
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.satellite_band_in_use
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.satellite_band_in_use
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.satellite_band_in_use
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.satellite_band_in_use
         ELSE NULL END AS banda_satelite_torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.fiber
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.fiber
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.fiber
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.fiber
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.fiber
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.fiber
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.fiber
         ELSE NULL END AS torre_transporte_fibra,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.radio
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.radio
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.radio
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.radio
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.radio
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.radio
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.radio
         ELSE NULL END AS torre_transporte_radio,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.satellite
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.satellite
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.satellite
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.satellite
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.satellite
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.satellite
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.satellite
         ELSE NULL END AS torre_transporte_satellite,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.source
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.source
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.source
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.source
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.source
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.source
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.source
         ELSE NULL END AS torre_transporte_source,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.internal_id
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.internal_id
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.internal_id
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.internal_id
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.internal_id
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.internal_id
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.internal_id
         ELSE NULL END AS torre_transporte_internal_id,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.longitude
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.longitude
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.longitude
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.longitude
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.longitude
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.longitude
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.longitude
         ELSE NULL END AS longitude_torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.latitude
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.latitude
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.latitude
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.latitude
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.latitude
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.latitude
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.latitude
         ELSE NULL END AS latitude_torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.geom
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.geom
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.geom
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.geom
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.geom
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.geom
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.geom
         ELSE NULL END AS geom_torre_transporte,
        NULL::geometry as geom_line_torre_transporte,
        tr.movistar_transport_id  as torre_transporte_movistar_optima,
        tr.distance_movistar_transport_m as distancia_torre_transporte_movistar_optima,
        tr.anditel_transport_id as torre_transporte_anditel_optima,
        tr.distance_anditel_transport_m as distancia_torre_transporte_anditel_optima,
        tr.azteca_transport_id as torre_transporte_azteca_optima,
        tr.distance_azteca_transport_m as distancia_torre_transporte_azteca_optima,
        tr.atc_transport_id as torre_transporte_atc_optima,
        tr.distance_atc_transport_m as distancia_torre_transporte_atc_optima,
        tr.atp_transport_id as torre_transporte_atp_optima,
        tr.distance_atp_transport_m as distancia_torre_transporte_atp_optima,
        tr.phoenix_transport_id as torre_transporte_phoenix_optima,
        tr.distance_phoenix_transport_m  as distancia_torre_transporte_phoenix_optima,
        tr.qmc_transport_id as torre_transporte_qmc_optima,
        tr.distance_qmc_transport_m as distancia_torre_transporte_qmc_optima,
        tr.phoenix_transport_id as torre_transporte_uniti_optima,
        tr.distance_phoenix_transport_m as distancia_torre_transporte_uniti_optima
FROM {schema}.clusters c
LEFT JOIN (
SELECT DISTINCT ON (ran_centroid)  
A.*, I2.internal_id, CT.centroid, CT.cluster_size, CT.cluster_weight AS transport_weight, C.centroid,
C.cluster_weight AS ran_weight, C.cluster_size as ran_size, T.tower_id, T.movistar_transport_id , I3.tower_id, 
CASE
 WHEN C.cluster_weight > 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
 WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
 WHEN C.cluster_weight >= 2500 THEN 'grande'       
 ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I3.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.line_of_sight_movistar IS FALSE AND T.distance_movistar_transport_m <= 2000 and I3.fiber IS TRUE THEN 'qw fiber tef'      
     WHEN ((t.line_of_sight_anditel IS TRUE and t.distance_anditel_transport_m<=40000) or (t.line_of_sight_atc IS TRUE and t.distance_atc_transport_m<=40000) or (t.line_of_sight_atp IS TRUE and t.distance_atp_transport_m<=40000) or (t.line_of_sight_azteca IS TRUE and t.distance_azteca_transport_m<=40000)) AND CT.cluster_weight < 2500 THEN 'radio third pty'      
     WHEN ((t.line_of_sight_anditel IS FALSE and t.distance_anditel_transport_m<=2000) or (t.line_of_sight_atc IS FALSE and t.distance_atc_transport_m<=2000) or (t.line_of_sight_atp IS FALSE and t.distance_atp_transport_m<=2000) or (t.line_of_sight_azteca IS FALSE and t.distance_azteca_transport_m<=2000)) AND CT.cluster_weight < 2500 THEN 'fiber third pty'
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m<=40000 THEN 'radio tef'      
     WHEN t.line_of_sight_movistar IS FALSE and t.distance_movistar_transport_m<=2000 THEN 'fiber tef'      
     WHEN ((t.line_of_sight_anditel IS TRUE and t.distance_anditel_transport_m<=40000) or (t.line_of_sight_atc IS TRUE and t.distance_atc_transport_m<=40000) or (t.line_of_sight_atp IS TRUE and t.distance_atp_transport_m<=40000) or (t.line_of_sight_azteca IS TRUE and t.distance_azteca_transport_m<=40000)) THEN 'radio third pty'      
     WHEN ((t.line_of_sight_anditel IS FALSE and t.distance_anditel_transport_m<=2000) or (t.line_of_sight_atc IS FALSE and t.distance_atc_transport_m<=2000) or (t.line_of_sight_atp IS FALSE and t.distance_atp_transport_m<=2000) or (t.line_of_sight_azteca IS FALSE and t.distance_azteca_transport_m<=2000)) THEN 'fiber third pty'      
     ELSE 'satellite' END AS type, 
     I2.source
     FROM (
                SELECT O.centroid AS transport_centroid,
                         C.centroid AS ran_centroid         
                         FROM {schema}.clusters C         
                         LEFT JOIN (SELECT centroid,         
                                        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node         
                                        FROM {schema}.transport_clusters ) O         
                        ON C.centroid = O.node         
                        WHERE cluster_weight > 0                  
                        UNION                           
                        SELECT DISTINCT ON(O.centroid)         
                        O.centroid AS transport_centroid,         
                        C.centroid AS ran_centroid         
                        FROM {schema}.clusters C         
                        LEFT JOIN {schema}.transport_clusters O         
                        ON C.centroid = O.centroid         
                        WHERE C.cluster_weight > 0        
                        AND O.centroid IS NOT NULL         
                        ORDER BY ran_centroid, transport_centroid ) A 
LEFT JOIN {schema}.transport_clusters CT 
ON CT.centroid = A.transport_centroid 
LEFT JOIN {schema}.clusters C 
ON C.centroid = A.ran_centroid 
LEFT JOIN {schema}.infrastructure_global I1 
ON I1.tower_id::text = A.transport_centroid 
LEFT JOIN {schema}.infrastructure_global I2 
ON I2.tower_id::text = A.ran_centroid 
LEFT JOIN {schema}.transport_by_tower_all T 
ON T.tower_id::text = A.ran_centroid 
LEFT JOIN {schema}.infrastructure_global I3 
ON I3.tower_id = T.movistar_transport_id 
WHERE LENGTH(ran_centroid) < 8) A
ON A.ran_centroid=c.centroid
left join {schema}.infrastructure_global i
on c.centroid=i.tower_id::text
left join {schema}.transport_by_tower_all tr
on c.centroid=tr.tower_id::text
left join {schema}.infrastructure_global it1
on it1.tower_id=tr.anditel_transport_id
left join {schema}.infrastructure_global it2
on it2.tower_id=tr.azteca_transport_id
left join {schema}.infrastructure_global it3
on it3.tower_id=tr.atc_transport_id
left join {schema}.infrastructure_global it4
on it4.tower_id=tr.atp_transport_id
left join {schema}.infrastructure_global it5
on it5.tower_id=tr.uniti_transport_id
left join {schema}.infrastructure_global it6
on it6.tower_id=tr.qmc_transport_id
left join {schema}.infrastructure_global it7
on it7.tower_id=tr.phoenix_transport_id
WHERE A.type LIKE '%third%'

UNION 

    --- SATELLITE TOWER CLUSTERS
    SELECT c.centroid as cluster_id,
    NULL as codigo_divipola,
    i.tower_id as torre_acceso,
    0::DOUBLE PRECISION as km_dist_torre_acceso, 
    i.owner as owner_torre_acceso,
    FALSE as los_acceso_transporte,
        i.tower_height as altura_torre_acceso,
        i.type as tipo_torre_acceso,
        i.vendor as vendor_torre_acceso,
     CASE
        WHEN ((i.tech_4g
                AND i.tech_3g)
            AND i.tech_2g)
        THEN '4G+3G+2G'::text
        WHEN (i.tech_4g
            AND i.tech_3g)
        THEN '4G+3G'::text
        WHEN (i.tech_4g
            AND i.tech_2g)
        THEN '4G+2G'::text
        WHEN (i.tech_3g
            AND i.tech_2g)
        THEN '3G+2G'::text
        WHEN i.tech_4g
        THEN '4G'::text
        WHEN i.tech_3g
        THEN '3G'::text
        WHEN i.tech_2g
        THEN '2G'::text
        ELSE '-'::text
        END                     AS tecnologia_torre_acceso,
        i.tech_4g as torre_acceso_4g,
        i.tech_3g as torre_acceso_3g,
        i.tech_2g as torre_acceso_2g,
        i.source as torre_acceso_source,
        i.internal_id as torre_acceso_internal_id,
        i.latitude as latitude_torre_acceso,
        i.longitude as longitude_torre_acceso,
        i.geom as geom_torre_acceso,
        NULL::geometry AS geom_line_torre_acceso,
        ST_Makeline(i.geom::geometry,it.geom::geometry) AS geom_line_trasnporte_torre_acceso,        
        CASE WHEN i.source='SITES_TEF' THEN i.tower_id ELSE NULL END AS torre_acceso_movistar_optima,
        CASE WHEN i.source='SITES_TEF' THEN 0 ELSE NULL END AS distancia_torre_acceso_movistar_optima,
        CASE WHEN i.source='ANDITEL' THEN i.tower_id ELSE NULL END AS torre_acceso_anditel_optima,
        CASE WHEN i.source='ANDITEL' THEN 0 ELSE NULL END AS distancia_torre_acceso_anditel_optima,
        CASE WHEN i.source='ATC' THEN i.tower_id ELSE NULL END AS torre_acceso_atc_optima,
        CASE WHEN i.source='ATC' THEN 0 ELSE NULL END AS distancia_torre_acceso_atc_optima,
        CASE WHEN i.source='ATP' THEN i.tower_id ELSE NULL END AS torre_acceso_atp_optima,
        CASE WHEN i.source='ATP' THEN 0 ELSE NULL END AS distancia_torre_acceso_atp_optima,       
        CASE WHEN i.source='PTI' THEN i.tower_id ELSE NULL END AS torre_acceso_phoenix_optima,
        CASE WHEN i.source='PTI' THEN 0 ELSE NULL END AS distancia_torre_acceso_phoenix_optima,
        CASE WHEN i.source='QMC' THEN i.tower_id ELSE NULL END AS torre_acceso_qmc_optima,
        CASE WHEN i.source='QMC' THEN 0 ELSE NULL END AS distancia_torre_acceso_qmc_optima,
        CASE WHEN i.source='UNITI' THEN i.tower_id ELSE NULL END AS torre_acceso_uniti_optima,
        CASE WHEN i.source='UNITI' THEN 0 ELSE NULL END AS distancia_torre_acceso_uniti_optima,
        NULL as torre_transporte,
        NULL::DOUBLE PRECISION as km_dist_torre_transporte,
        NULL as owner_torre_transporte,
        NULL as altura_torre_transporte,
        'SAT' as tipo_torre_transporte,
        '-' as banda_satelite_torre_transporte,
        FALSE as torre_transporte_fibra,
        FALSE as torre_transporte_radio,
        TRUE as torre_transporte_satellite,
        NULL as torre_transporte_source,
        NULL as torre_transporte_internal_id,
        NULL as latitude_torre_transporte,
        NULL as longitude_torre_transporte,
        NULL as geom_torre_transporte,
        NULL::geometry as geom_line_torre_transporte,
        NULL as torre_transporte_movistar_optima,
        NULL as distancia_torre_transporte_movistar_optima,
        NULL as torre_transporte_anditel_optima,
        NULL as distancia_torre_transporte_anditel_optima,
        NULL as torre_transporte_azteca_optima,
        NULL as distancia_torre_transporte_azteca_optima,
        NULL as torre_transporte_atc_optima,
        NULL as distancia_torre_transporte_atc_optima,
        NULL as torre_transporte_atp_optima,
        NULL as distancia_torre_transporte_atp_optima,
        NULL as torre_transporte_phoenix_optima,
        NULL  as distancia_torre_transporte_phoenix_optima,
        NULL as torre_transporte_qmc_optima,
        NULL as distancia_torre_transporte_qmc_optima,
        NULL as torre_transporte_uniti_optima,
        NULL as distancia_torre_transporte_uniti_optima
FROM {schema}.clusters c
LEFT JOIN (
SELECT DISTINCT ON (ran_centroid)  
A.*, I2.internal_id, CT.centroid, CT.cluster_size, CT.cluster_weight AS transport_weight, C.centroid,
C.cluster_weight AS ran_weight, C.cluster_size as ran_size, T.tower_id, T.movistar_transport_id , I3.tower_id, 
CASE
 WHEN C.cluster_weight > 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
 WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
 WHEN C.cluster_weight >= 2500 THEN 'grande'       
 ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m <= 40000 AND I3.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.line_of_sight_movistar IS FALSE AND T.distance_movistar_transport_m <= 2000 and I3.fiber IS TRUE THEN 'qw fiber tef'      
     WHEN ((t.line_of_sight_anditel IS TRUE and t.distance_anditel_transport_m<=40000) or (t.line_of_sight_atc IS TRUE and t.distance_atc_transport_m<=40000) or (t.line_of_sight_atp IS TRUE and t.distance_atp_transport_m<=40000) or (t.line_of_sight_azteca IS TRUE and t.distance_azteca_transport_m<=40000)) AND CT.cluster_weight < 2500 THEN 'radio third pty'      
     WHEN ((t.line_of_sight_anditel IS FALSE and t.distance_anditel_transport_m<=2000) or (t.line_of_sight_atc IS FALSE and t.distance_atc_transport_m<=2000) or (t.line_of_sight_atp IS FALSE and t.distance_atp_transport_m<=2000) or (t.line_of_sight_azteca IS FALSE and t.distance_azteca_transport_m<=2000)) AND CT.cluster_weight < 2500 THEN 'fiber third pty'
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m<=40000 THEN 'radio tef'      
     WHEN t.line_of_sight_movistar IS FALSE and t.distance_movistar_transport_m<=2000 THEN 'fiber tef'      
     WHEN ((t.line_of_sight_anditel IS TRUE and t.distance_anditel_transport_m<=40000) or (t.line_of_sight_atc IS TRUE and t.distance_atc_transport_m<=40000) or (t.line_of_sight_atp IS TRUE and t.distance_atp_transport_m<=40000) or (t.line_of_sight_azteca IS TRUE and t.distance_azteca_transport_m<=40000)) THEN 'radio third pty'      
     WHEN ((t.line_of_sight_anditel IS FALSE and t.distance_anditel_transport_m<=2000) or (t.line_of_sight_atc IS FALSE and t.distance_atc_transport_m<=2000) or (t.line_of_sight_atp IS FALSE and t.distance_atp_transport_m<=2000) or (t.line_of_sight_azteca IS FALSE and t.distance_azteca_transport_m<=2000)) THEN 'fiber third pty'      
     ELSE 'satellite' END AS type, 
     I2.source
     FROM (
                SELECT O.centroid AS transport_centroid,
                         C.centroid AS ran_centroid         
                         FROM {schema}.clusters C         
                         LEFT JOIN (SELECT centroid,         
                                        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node         
                                        FROM {schema}.transport_clusters ) O         
                        ON C.centroid = O.node         
                        WHERE cluster_weight > 0                  
                        UNION                           
                        SELECT DISTINCT ON(O.centroid)         
                        O.centroid AS transport_centroid,         
                        C.centroid AS ran_centroid         
                        FROM {schema}.clusters C         
                        LEFT JOIN {schema}.transport_clusters O         
                        ON C.centroid = O.centroid         
                        WHERE C.cluster_weight > 0        
                        AND O.centroid IS NOT NULL         
                        ORDER BY ran_centroid, transport_centroid ) A 
LEFT JOIN {schema}.transport_clusters CT 
ON CT.centroid = A.transport_centroid 
LEFT JOIN {schema}.clusters C 
ON C.centroid = A.ran_centroid 
LEFT JOIN {schema}.infrastructure_global I1 
ON I1.tower_id::text = A.transport_centroid 
LEFT JOIN {schema}.infrastructure_global I2 
ON I2.tower_id::text = A.ran_centroid 
LEFT JOIN {schema}.transport_by_tower_all T 
ON T.tower_id::text = A.ran_centroid 
LEFT JOIN {schema}.infrastructure_global I3 
ON I3.tower_id = T.movistar_transport_id 
WHERE LENGTH(ran_centroid) < 8) A
ON A.ran_centroid=c.centroid
left join {schema}.infrastructure_global i
on c.centroid=i.tower_id::text
left join {schema}.transport_by_tower_all tr
on i.tower_id=tr.tower_id
left join {schema}.infrastructure_global it
on it.tower_id=tr.movistar_transport_id 
WHERE A.type LIKE '%satellite%'

UNION

 --- QW & TEF GREENFIELD CLUSTERS
    SELECT c.centroid as cluster_id,
    c.centroid as codigo_divipola,
    NULL as torre_acceso,
    0::DOUBLE PRECISION as km_dist_torre_acceso, 
    NULL as owner_torre_acceso,
    tr.line_of_sight_movistar as los_acceso_transporte,
        50 as altura_torre_acceso,
        NULL as tipo_torre_acceso,
        NULL as vendor_torre_acceso,
    '-'::text AS tecnologia_torre_acceso,
       null as torre_acceso_4g,
        null as torre_acceso_3g,
        null as torre_acceso_2g,
        null as torre_acceso_source,
        null as torre_acceso_internal_id,
        s.latitude as latitude_torre_acceso,
        s.longitude as longitude_torre_acceso,
        c.geom as geom_torre_acceso,
        NULL::geometry AS geom_line_torre_acceso,
        ST_Makeline(c.geom::geometry,it.geom::geometry) AS geom_line_trasnporte_torre_acceso,        
        ts.movistar_optimal_tower_id AS torre_acceso_movistar_optima,
        ts.distance_movistar_optimal_tower_m AS distancia_torre_acceso_movistar_optima,
        ts.anditel_optimal_tower_id AS torre_acceso_anditel_optima,
        ts.distance_anditel_optimal_tower_m AS distancia_torre_acceso_anditel_optima,
        ts.atc_optimal_tower_id AS torre_acceso_atc_optima,
        ts.distance_atc_optimal_tower_m AS distancia_torre_acceso_atc_optima,
        ts.atp_optimal_tower_id AS torre_acceso_atp_optima,
        ts.distance_atp_optimal_tower_m AS  distancia_torre_acceso_atp_optima,       
        ts.phoenix_optimal_tower_id AS torre_acceso_phoenix_optima,
        ts.distance_phoenix_optimal_tower_m AS  distancia_torre_acceso_phoenix_optima,
        ts.qmc_optimal_tower_id AS torre_acceso_qmc_optima,
        ts.distance_qmc_optimal_tower_m AS  distancia_torre_acceso_qmc_optima,
        ts.uniti_optimal_tower_id AS torre_acceso_uniti_optima,
        ts.distance_uniti_optimal_tower_m AS  distancia_torre_acceso_uniti_optima,
        tr.movistar_transport_id  as torre_transporte,
        (tr.distance_movistar_transport_m/1000)::DOUBLE PRECISION as km_dist_torre_transporte,
        it.owner as owner_torre_transporte,
        it.tower_height as altura_torre_transporte,
        CASE
        WHEN ((it.fiber
                AND it.radio)
            AND it.satellite)
        THEN 'FO+RADIO+SAT'::text
        WHEN (it.fiber
            AND it.radio)
        THEN 'FO+RADIO'::text
        WHEN (it.fiber
            AND it.satellite)
        THEN 'FO+SAT'::text
        WHEN (it.radio
            AND it.satellite)
        THEN 'RADIO+SAT'::text
        WHEN it.fiber
        THEN 'FO'::text
        WHEN it.radio
        THEN 'RADIO'::text
        WHEN it.satellite
        THEN 'SAT'::text
        ELSE '-'::text
    END AS tipo_torre_transporte,
        it.satellite_band_in_use as banda_satelite_torre_transporte,
        it.fiber as torre_transporte_fibra,
        it.radio as torre_transporte_radio,
        it.satellite as torre_transporte_satellite,
        it.source as torre_transporte_source,
        it.internal_id as torre_transporte_internal_id,
        it.latitude as latitude_torre_transporte,
        it.longitude as longitude_torre_transporte,
        it.geom as geom_torre_transporte,
        NULL::geometry as geom_line_torre_transporte,
        tr.movistar_transport_id  as torre_transporte_movistar_optima,
        tr.distance_movistar_transport_m as distancia_torre_transporte_movistar_optima,
        tr.anditel_transport_id as torre_transporte_anditel_optima,
        tr.distance_anditel_transport_m as distancia_torre_transporte_anditel_optima,
        tr.azteca_transport_id as torre_transporte_azteca_optima,
        tr.distance_azteca_transport_m as distancia_torre_transporte_azteca_optima,
        tr.atc_transport_id as torre_transporte_atc_optima,
        tr.distance_atc_transport_m as distancia_torre_transporte_atc_optima,
        tr.atp_transport_id as torre_transporte_atp_optima,
        tr.distance_atp_transport_m as distancia_torre_transporte_atp_optima,
        tr.phoenix_transport_id as torre_transporte_phoenix_optima,
        tr.distance_phoenix_transport_m  as distancia_torre_transporte_phoenix_optima,
        tr.qmc_transport_id as torre_transporte_qmc_optima,
        tr.distance_qmc_transport_m as distancia_torre_transporte_qmc_optima,
        tr.phoenix_transport_id as torre_transporte_uniti_optima,
        tr.distance_phoenix_transport_m as distancia_torre_transporte_uniti_optima
FROM {schema}.clusters c
LEFT JOIN (SELECT DISTINCT ON (ran_centroid)  
A.*, CT.centroid, CT.cluster_size, CT.cluster_weight AS transport_weight, C.centroid,
C.cluster_weight AS ran_weight,  C.cluster_size as ran_size, T.centroid, T.movistar_transport_id , I3.tower_id, 
CASE
 WHEN C.cluster_weight > 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
 WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
 WHEN C.cluster_weight >= 2500 THEN 'grande'       
 ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m  <= 40000 AND I3.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.line_of_sight_movistar IS FALSE AND T.distance_movistar_transport_m <= 2000 and I3.fiber IS TRUE THEN 'qw fiber tef'      
     WHEN ((T.line_of_sight_anditel IS TRUE and T.distance_anditel_transport_m<=40000) or (T.line_of_sight_atc IS TRUE and T.distance_atc_transport_m<=40000) or (T.line_of_sight_atp IS TRUE and T.distance_atp_transport_m<=40000) or (T.line_of_sight_azteca IS TRUE and T.distance_azteca_transport_m<=40000)) AND CT.cluster_weight < 2500 THEN 'radio third pty'      
     WHEN ((T.line_of_sight_anditel IS FALSE and T.distance_anditel_transport_m<=2000) or (T.line_of_sight_atc IS FALSE and T.distance_atc_transport_m<=2000) or (T.line_of_sight_atp IS FALSE and T.distance_atp_transport_m<=2000) or (T.line_of_sight_azteca IS FALSE and T.distance_azteca_transport_m<=2000)) AND CT.cluster_weight < 2500 THEN 'fiber third pty'
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m<=40000 THEN 'radio tef'      
     WHEN T.line_of_sight_movistar IS FALSE and T.distance_movistar_transport_m<=2000 THEN 'fiber tef'      
     WHEN ((T.line_of_sight_anditel IS TRUE and T.distance_anditel_transport_m<=40000) or (T.line_of_sight_atc IS TRUE and T.distance_atc_transport_m<=40000) or (T.line_of_sight_atp IS TRUE and T.distance_atp_transport_m<=40000) or (T.line_of_sight_azteca IS TRUE and T.distance_azteca_transport_m<=40000)) THEN 'radio third pty'      
     WHEN ((T.line_of_sight_anditel IS FALSE and T.distance_anditel_transport_m<=2000) or (T.line_of_sight_atc IS FALSE and T.distance_atc_transport_m<=2000) or (T.line_of_sight_atp IS FALSE and T.distance_atp_transport_m<=2000) or (T.line_of_sight_azteca IS FALSE and T.distance_azteca_transport_m<=2000)) THEN 'fiber third pty' 
     ELSE 'satellite' END AS type
     FROM (
                SELECT O.centroid AS transport_centroid,
                         C.centroid AS ran_centroid         
                         FROM {schema}.clusters C         
                         LEFT JOIN (SELECT centroid,         
                                        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node         
                                        FROM {schema}.transport_clusters ) O         
                        ON C.centroid = O.node         
                        WHERE cluster_weight > 0                  
                        UNION                           
                        SELECT DISTINCT ON(O.centroid)         
                        O.centroid AS transport_centroid,         
                        C.centroid AS ran_centroid         
                        FROM {schema}.clusters C         
                        LEFT JOIN {schema}.transport_clusters O         
                        ON C.centroid = O.centroid         
                        WHERE C.cluster_weight > 0        
                        AND O.centroid IS NOT NULL         
                        ORDER BY ran_centroid, transport_centroid ) A 
LEFT JOIN {schema}.transport_clusters CT 
ON CT.centroid = A.transport_centroid 
LEFT JOIN {schema}.clusters C 
ON C.centroid = A.ran_centroid 
LEFT JOIN {schema}.infrastructure_global I1 
ON I1.tower_id::text = A.transport_centroid 
LEFT JOIN {schema}.transport_greenfield_clusters  T 
ON T.centroid::text = A.ran_centroid 
LEFT JOIN {schema}.infrastructure_global I3 
ON I3.tower_id = T.movistar_transport_id  
WHERE LENGTH(ran_centroid) >= 8) A
ON A.ran_centroid=c.centroid
left join {schema}.infrastructure_global i
on c.centroid=i.tower_id::text
left join {schema}.transport_greenfield_clusters tr
on c.centroid=tr.centroid
left join {schema}.transport_by_settlement_all ts
on ts.settlement_id=c.centroid
left join {schema}.settlements s
on s.settlement_id=c.centroid
left join {schema}.infrastructure_global it
on it.tower_id=tr.movistar_transport_id 
WHERE A.type LIKE '%tef%'

UNION 
 --- 3rd pty GREENFIELD CLUSTERS
    SELECT c.centroid as cluster_id,
    c.centroid as codigo_divipola,
    NULL as torre_acceso,
    0::DOUBLE PRECISION as km_dist_torre_acceso, 
    NULL as owner_torre_acceso,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN tr.line_of_sight_anditel
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN tr.line_of_sight_azteca
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN tr.line_of_sight_atc
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN tr.line_of_sight_atp
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN tr.line_of_sight_uniti::bool
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN tr.line_of_sight_qmc
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN tr.line_of_sight_phoenix
         ELSE NULL END AS los_acceso_transporte,
        50 as altura_torre_acceso,
        NULL as tipo_torre_acceso,
        NULL as vendor_torre_acceso,
        '-'::text AS tecnologia_torre_acceso,
       null as torre_acceso_4g,
        null as torre_acceso_3g,
        null as torre_acceso_2g,
        null as torre_acceso_source,
        null as torre_acceso_internal_id,
        s.latitude as latitude_torre_acceso,
        s.longitude as longitude_torre_acceso,
        c.geom as geom_torre_acceso,
        NULL::geometry AS geom_line_torre_acceso,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it1.geom::geometry)
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it2.geom::geometry)
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it3.geom::geometry)
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it4.geom::geometry)
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it5.geom::geometry)
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it6.geom::geometry)
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN ST_Makeline(c.geom::geometry,it7.geom::geometry)
         ELSE NULL END AS geom_line_trasnporte_torre_acceso,   
        ts.movistar_optimal_tower_id AS torre_acceso_movistar_optima,
        ts.distance_movistar_optimal_tower_m AS distancia_torre_acceso_movistar_optima,
        ts.anditel_optimal_tower_id AS torre_acceso_anditel_optima,
        ts.distance_anditel_optimal_tower_m AS distancia_torre_acceso_anditel_optima,
        ts.atc_optimal_tower_id AS torre_acceso_atc_optima,
        ts.distance_atc_optimal_tower_m AS distancia_torre_acceso_atc_optima,
        ts.atp_optimal_tower_id AS torre_acceso_atp_optima,
        ts.distance_atp_optimal_tower_m AS  distancia_torre_acceso_atp_optima,       
        ts.phoenix_optimal_tower_id AS torre_acceso_phoenix_optima,
        ts.distance_phoenix_optimal_tower_m AS  distancia_torre_acceso_phoenix_optima,
        ts.qmc_optimal_tower_id AS torre_acceso_qmc_optima,
        ts.distance_qmc_optimal_tower_m AS  distancia_torre_acceso_qmc_optima,
        ts.uniti_optimal_tower_id AS torre_acceso_uniti_optima,
        ts.distance_uniti_optimal_tower_m AS  distancia_torre_acceso_uniti_optima,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN tr.anditel_transport_id
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN tr.azteca_transport_id
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN tr.atc_transport_id
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN tr.atp_transport_id
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN tr.uniti_transport_id
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN tr.qmc_transport_id
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN tr.phoenix_transport_id
         ELSE NULL END AS torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN (tr.distance_anditel_transport_m/1000)::DOUBLE PRECISION
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN (tr.distance_azteca_transport_m/1000)::DOUBLE PRECISION
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN (tr.distance_atc_transport_m/1000)::DOUBLE PRECISION
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN (tr.distance_atp_transport_m/1000)::DOUBLE PRECISION
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN (tr.distance_uniti_transport_m/1000)::DOUBLE PRECISION
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN (tr.distance_qmc_transport_m/1000)::DOUBLE PRECISION
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN (tr.distance_phoenix_transport_m/1000)::DOUBLE PRECISION
         ELSE NULL END AS km_dist_torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.owner
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.owner
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.owner
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.owner
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.owner
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.owner
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.owner
         ELSE NULL END AS owner_torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.tower_height
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.tower_height
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.tower_height
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.tower_height
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.tower_height
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.tower_height
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.tower_height
         ELSE NULL END AS altura_torre_transporte,
    CASE WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.fiber AND it1.radio AND it1.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.fiber AND it1.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.fiber AND it1.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.satellite AND it1.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) 
                AND (it1.satellite)) THEN 'SAT'::text
                
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.fiber AND it2.radio AND it2.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.fiber AND it2.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.fiber AND it2.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.satellite AND it2.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) 
                AND (it2.satellite)) THEN 'SAT'::text
                
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.fiber AND it3.radio AND it3.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.fiber AND it3.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.fiber AND it3.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.satellite AND it3.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) 
                AND (it3.satellite)) THEN 'SAT'::text
                
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.fiber AND it4.radio AND it4.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.fiber AND it4.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.fiber AND it4.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.satellite AND it4.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) 
                AND (it4.satellite)) THEN 'SAT'::text
                
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.fiber AND it5.radio AND it5.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.fiber AND it5.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.fiber AND it5.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.satellite AND it5.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) 
                AND (it5.satellite)) THEN 'SAT'::text
                
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.fiber AND it6.radio AND it6.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.fiber AND it6.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.fiber AND it6.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.satellite AND it6.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) 
                AND (it6.satellite)) THEN 'SAT'::text
                
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.fiber AND it7.radio AND it7.satellite)) THEN 'FO+RADIO+SAT'::text
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.fiber AND it7.radio)) THEN 'FO+RADIO'::text
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.fiber AND it7.satellite)) THEN 'FO+SAT'::text
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.satellite AND it7.radio)) THEN 'RADIO+SAT'::text
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.fiber)) THEN 'FO'::text
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.radio)) THEN 'RADIO'::text
        WHEN ((tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) 
                AND (it7.satellite)) THEN 'SAT'::text
        
        ELSE '-'::text
    END AS tipo_torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.satellite_band_in_use
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.satellite_band_in_use
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.satellite_band_in_use
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.satellite_band_in_use
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.satellite_band_in_use
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.satellite_band_in_use
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.satellite_band_in_use
         ELSE NULL END AS banda_satelite_torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.fiber
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.fiber
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.fiber
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.fiber
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.fiber
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.fiber
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.fiber
         ELSE NULL END AS torre_transporte_fibra,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.radio
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.radio
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.radio
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.radio
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.radio
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.radio
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.radio
         ELSE NULL END AS torre_transporte_radio,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.satellite
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.satellite
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.satellite
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.satellite
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.satellite
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.satellite
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.satellite
         ELSE NULL END AS torre_transporte_satellite,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.source
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.source
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.source
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.source
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.source
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.source
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.source
         ELSE NULL END AS torre_transporte_source,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.internal_id
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.internal_id
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.internal_id
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.internal_id
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.internal_id
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.internal_id
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.internal_id
         ELSE NULL END AS torre_transporte_internal_id,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.longitude
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.longitude
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.longitude
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.longitude
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.longitude
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.longitude
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.longitude
         ELSE NULL END AS longitude_torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.latitude
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.latitude
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.latitude
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.latitude
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.latitude
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.latitude
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.latitude
         ELSE NULL END AS latitude_torre_transporte,
    CASE WHEN (tr.line_of_sight_anditel IS TRUE or tr.distance_anditel_transport_m<=2000) THEN it1.geom
         WHEN (tr.line_of_sight_azteca IS TRUE or tr.distance_azteca_transport_m<=2000) THEN it2.geom
         WHEN (tr.line_of_sight_atc IS TRUE or tr.distance_atc_transport_m<=2000) THEN it3.geom
         WHEN (tr.line_of_sight_atp IS TRUE or tr.distance_atp_transport_m<=2000) THEN it4.geom
         WHEN (tr.line_of_sight_uniti::bool IS TRUE or tr.distance_uniti_transport_m<=2000) THEN it5.geom
         WHEN (tr.line_of_sight_qmc::bool IS TRUE or tr.distance_qmc_transport_m<=2000) THEN it6.geom
         WHEN (tr.line_of_sight_phoenix::bool IS TRUE or tr.distance_phoenix_transport_m<=2000) THEN it7.geom
         ELSE NULL END AS geom_torre_transporte,
        NULL::geometry as geom_line_torre_transporte,
        tr.movistar_transport_id  as torre_transporte_movistar_optima,
        tr.distance_movistar_transport_m as distancia_torre_transporte_movistar_optima,
        tr.anditel_transport_id as torre_transporte_anditel_optima,
        tr.distance_anditel_transport_m as distancia_torre_transporte_anditel_optima,
        tr.azteca_transport_id as torre_transporte_azteca_optima,
        tr.distance_azteca_transport_m as distancia_torre_transporte_azteca_optima,
        tr.atc_transport_id as torre_transporte_atc_optima,
        tr.distance_atc_transport_m as distancia_torre_transporte_atc_optima,
        tr.atp_transport_id as torre_transporte_atp_optima,
        tr.distance_atp_transport_m as distancia_torre_transporte_atp_optima,
        tr.phoenix_transport_id as torre_transporte_phoenix_optima,
        tr.distance_phoenix_transport_m  as distancia_torre_transporte_phoenix_optima,
        tr.qmc_transport_id as torre_transporte_qmc_optima,
        tr.distance_qmc_transport_m as distancia_torre_transporte_qmc_optima,
        tr.phoenix_transport_id as torre_transporte_uniti_optima,
        tr.distance_phoenix_transport_m as distancia_torre_transporte_uniti_optima
FROM {schema}.clusters c
LEFT JOIN (SELECT DISTINCT ON (ran_centroid)  
A.*, CT.centroid, CT.cluster_size, CT.cluster_weight AS transport_weight, C.centroid,
C.cluster_weight AS ran_weight,  C.cluster_size as ran_size, T.centroid, T.movistar_transport_id , I3.tower_id, 
CASE
 WHEN C.cluster_weight > 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
 WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
 WHEN C.cluster_weight >= 2500 THEN 'grande'       
 ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m  <= 40000 AND I3.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.line_of_sight_movistar IS FALSE AND T.distance_movistar_transport_m <= 2000 and I3.fiber IS TRUE THEN 'qw fiber tef'      
     WHEN ((T.line_of_sight_anditel IS TRUE and T.distance_anditel_transport_m<=40000) or (T.line_of_sight_atc IS TRUE and T.distance_atc_transport_m<=40000) or (T.line_of_sight_atp IS TRUE and T.distance_atp_transport_m<=40000) or (T.line_of_sight_azteca IS TRUE and T.distance_azteca_transport_m<=40000)) AND CT.cluster_weight < 2500 THEN 'radio third pty'      
     WHEN ((T.line_of_sight_anditel IS FALSE and T.distance_anditel_transport_m<=2000) or (T.line_of_sight_atc IS FALSE and T.distance_atc_transport_m<=2000) or (T.line_of_sight_atp IS FALSE and T.distance_atp_transport_m<=2000) or (T.line_of_sight_azteca IS FALSE and T.distance_azteca_transport_m<=2000)) AND CT.cluster_weight < 2500 THEN 'fiber third pty'
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m<=40000 THEN 'radio tef'      
     WHEN T.line_of_sight_movistar IS FALSE and T.distance_movistar_transport_m<=2000 THEN 'fiber tef'      
     WHEN ((T.line_of_sight_anditel IS TRUE and T.distance_anditel_transport_m<=40000) or (T.line_of_sight_atc IS TRUE and T.distance_atc_transport_m<=40000) or (T.line_of_sight_atp IS TRUE and T.distance_atp_transport_m<=40000) or (T.line_of_sight_azteca IS TRUE and T.distance_azteca_transport_m<=40000)) THEN 'radio third pty'      
     WHEN ((T.line_of_sight_anditel IS FALSE and T.distance_anditel_transport_m<=2000) or (T.line_of_sight_atc IS FALSE and T.distance_atc_transport_m<=2000) or (T.line_of_sight_atp IS FALSE and T.distance_atp_transport_m<=2000) or (T.line_of_sight_azteca IS FALSE and T.distance_azteca_transport_m<=2000)) THEN 'fiber third pty' 
     ELSE 'satellite' END AS type
     FROM (
                SELECT O.centroid AS transport_centroid,
                         C.centroid AS ran_centroid         
                         FROM {schema}.clusters C         
                         LEFT JOIN (SELECT centroid,         
                                        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node         
                                        FROM {schema}.transport_clusters ) O         
                        ON C.centroid = O.node         
                        WHERE cluster_weight > 0                  
                        UNION                           
                        SELECT DISTINCT ON(O.centroid)         
                        O.centroid AS transport_centroid,         
                        C.centroid AS ran_centroid         
                        FROM {schema}.clusters C         
                        LEFT JOIN {schema}.transport_clusters O         
                        ON C.centroid = O.centroid         
                        WHERE C.cluster_weight > 0        
                        AND O.centroid IS NOT NULL         
                        ORDER BY ran_centroid, transport_centroid ) A 
LEFT JOIN {schema}.transport_clusters CT 
ON CT.centroid = A.transport_centroid 
LEFT JOIN {schema}.clusters C 
ON C.centroid = A.ran_centroid 
LEFT JOIN {schema}.infrastructure_global I1 
ON I1.tower_id::text = A.transport_centroid 
LEFT JOIN {schema}.transport_greenfield_clusters  T 
ON T.centroid::text = A.ran_centroid 
LEFT JOIN {schema}.infrastructure_global I3 
ON I3.tower_id = T.movistar_transport_id  
WHERE LENGTH(ran_centroid) >= 8) A
ON A.ran_centroid=c.centroid
left join {schema}.infrastructure_global i
on c.centroid=i.tower_id::text
left join {schema}.transport_greenfield_clusters tr
on c.centroid=tr.centroid
left join {schema}.transport_by_settlement_all ts
on ts.settlement_id=c.centroid
left join {schema}.settlements s
on s.settlement_id=c.centroid
left join {schema}.infrastructure_global it1
on it1.tower_id=tr.anditel_transport_id
left join {schema}.infrastructure_global it2
on it2.tower_id=tr.azteca_transport_id
left join {schema}.infrastructure_global it3
on it3.tower_id=tr.atc_transport_id
left join {schema}.infrastructure_global it4
on it4.tower_id=tr.atp_transport_id
left join {schema}.infrastructure_global it5
on it5.tower_id=tr.uniti_transport_id
left join {schema}.infrastructure_global it6
on it6.tower_id=tr.qmc_transport_id
left join {schema}.infrastructure_global it7
on it7.tower_id=tr.phoenix_transport_id
WHERE A.type LIKE '%third%'


UNION

 --- SATELLITE GREENFIELD CLUSTERS
    SELECT c.centroid as cluster_id,
    c.centroid as codigo_divipola,
    NULL as torre_acceso,
    0::DOUBLE PRECISION as km_dist_torre_acceso, 
    NULL as owner_torre_acceso,
    tr.line_of_sight_movistar as los_acceso_transporte,
        50 as altura_torre_acceso,
        NULL as tipo_torre_acceso,
        NULL as vendor_torre_acceso,
    '-'::text AS tecnologia_torre_acceso,
       null as torre_acceso_4g,
        null as torre_acceso_3g,
        null as torre_acceso_2g,
        null as torre_acceso_source,
        null as torre_acceso_internal_id,
        s.latitude as latitude_torre_acceso,
        s.longitude as longitude_torre_acceso,
        c.geom as geom_torre_acceso,
        NULL::geometry AS geom_line_torre_acceso,
        ST_Makeline(c.geom::geometry,it.geom::geometry) AS geom_line_trasnporte_torre_acceso,        
        ts.movistar_optimal_tower_id AS torre_acceso_movistar_optima,
        ts.distance_movistar_optimal_tower_m AS distancia_torre_acceso_movistar_optima,
        ts.anditel_optimal_tower_id AS torre_acceso_anditel_optima,
        ts.distance_anditel_optimal_tower_m AS distancia_torre_acceso_anditel_optima,
        ts.atc_optimal_tower_id AS torre_acceso_atc_optima,
        ts.distance_atc_optimal_tower_m AS distancia_torre_acceso_atc_optima,
        ts.atp_optimal_tower_id AS torre_acceso_atp_optima,
        ts.distance_atp_optimal_tower_m AS  distancia_torre_acceso_atp_optima,       
        ts.phoenix_optimal_tower_id AS torre_acceso_phoenix_optima,
        ts.distance_phoenix_optimal_tower_m AS  distancia_torre_acceso_phoenix_optima,
        ts.qmc_optimal_tower_id AS torre_acceso_qmc_optima,
        ts.distance_qmc_optimal_tower_m AS  distancia_torre_acceso_qmc_optima,
        ts.uniti_optimal_tower_id AS torre_acceso_uniti_optima,
        ts.distance_uniti_optimal_tower_m AS  distancia_torre_acceso_uniti_optima,        
        NULL as torre_transporte,
        NULL::DOUBLE PRECISION as km_dist_torre_transporte,
        NULL as owner_torre_transporte,
        NULL as altura_torre_transporte,
        'SAT' as tipo_torre_transporte,
        '-' as banda_satelite_torre_transporte,
        FALSE as torre_transporte_fibra,
        FALSE as torre_transporte_radio,
        TRUE as torre_transporte_satellite,
        NULL as torre_transporte_source,
        NULL as torre_transporte_internal_id,
        NULL as latitude_torre_transporte,
        NULL as longitude_torre_transporte,
        NULL as geom_torre_transporte,
        NULL::geometry as geom_line_torre_transporte,
        NULL as torre_transporte_movistar_optima,
        NULL as distancia_torre_transporte_movistar_optima,
        NULL as torre_transporte_anditel_optima,
        NULL as distancia_torre_transporte_anditel_optima,
        NULL as torre_transporte_azteca_optima,
        NULL as distancia_torre_transporte_azteca_optima,
        NULL as torre_transporte_atc_optima,
        NULL as distancia_torre_transporte_atc_optima,
        NULL as torre_transporte_atp_optima,
        NULL as distancia_torre_transporte_atp_optima,
        NULL as torre_transporte_phoenix_optima,
        NULL  as distancia_torre_transporte_phoenix_optima,
        NULL as torre_transporte_qmc_optima,
        NULL as distancia_torre_transporte_qmc_optima,
        NULL as torre_transporte_uniti_optima,
        NULL as distancia_torre_transporte_uniti_optima
FROM {schema}.clusters c
LEFT JOIN (SELECT DISTINCT ON (ran_centroid)  
A.*, CT.centroid, CT.cluster_size, CT.cluster_weight AS transport_weight, C.centroid,
C.cluster_weight AS ran_weight,  C.cluster_size as ran_size, T.centroid, T.movistar_transport_id , I3.tower_id, 
CASE
 WHEN C.cluster_weight > 0 AND C.cluster_weight < 1250 THEN 'pequeño' 
 WHEN C.cluster_weight >= 1250 AND C.cluster_weight < 2500 THEN 'mediano'      
 WHEN C.cluster_weight >= 2500 THEN 'grande'       
 ELSE 'ERROR' END AS tamano, 
CASE WHEN T.line_of_sight_movistar IS TRUE AND T.distance_movistar_transport_m  <= 40000 AND I3.fiber IS TRUE THEN 'qw radio tef'
     WHEN T.line_of_sight_movistar IS FALSE AND T.distance_movistar_transport_m <= 2000 and I3.fiber IS TRUE THEN 'qw fiber tef'      
     WHEN ((T.line_of_sight_anditel IS TRUE and T.distance_anditel_transport_m<=40000) or (T.line_of_sight_atc IS TRUE and T.distance_atc_transport_m<=40000) or (T.line_of_sight_atp IS TRUE and T.distance_atp_transport_m<=40000) or (T.line_of_sight_azteca IS TRUE and T.distance_azteca_transport_m<=40000)) AND CT.cluster_weight < 2500 THEN 'radio third pty'      
     WHEN ((T.line_of_sight_anditel IS FALSE and T.distance_anditel_transport_m<=2000) or (T.line_of_sight_atc IS FALSE and T.distance_atc_transport_m<=2000) or (T.line_of_sight_atp IS FALSE and T.distance_atp_transport_m<=2000) or (T.line_of_sight_azteca IS FALSE and T.distance_azteca_transport_m<=2000)) AND CT.cluster_weight < 2500 THEN 'fiber third pty'
     WHEN T.line_of_sight_movistar IS TRUE and T.distance_movistar_transport_m<=40000 THEN 'radio tef'      
     WHEN T.line_of_sight_movistar IS FALSE and T.distance_movistar_transport_m<=2000 THEN 'fiber tef'      
     WHEN ((T.line_of_sight_anditel IS TRUE and T.distance_anditel_transport_m<=40000) or (T.line_of_sight_atc IS TRUE and T.distance_atc_transport_m<=40000) or (T.line_of_sight_atp IS TRUE and T.distance_atp_transport_m<=40000) or (T.line_of_sight_azteca IS TRUE and T.distance_azteca_transport_m<=40000)) THEN 'radio third pty'      
     WHEN ((T.line_of_sight_anditel IS FALSE and T.distance_anditel_transport_m<=2000) or (T.line_of_sight_atc IS FALSE and T.distance_atc_transport_m<=2000) or (T.line_of_sight_atp IS FALSE and T.distance_atp_transport_m<=2000) or (T.line_of_sight_azteca IS FALSE and T.distance_azteca_transport_m<=2000)) THEN 'fiber third pty' 
     ELSE 'satellite' END AS type  
     FROM (
                SELECT O.centroid AS transport_centroid,
                         C.centroid AS ran_centroid         
                         FROM {schema}.clusters C         
                         LEFT JOIN (SELECT centroid,         
                                        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node         
                                        FROM {schema}.transport_clusters ) O         
                        ON C.centroid = O.node         
                        WHERE cluster_weight > 0                  
                        UNION                           
                        SELECT DISTINCT ON(O.centroid)         
                        O.centroid AS transport_centroid,         
                        C.centroid AS ran_centroid         
                        FROM {schema}.clusters C         
                        LEFT JOIN {schema}.transport_clusters O         
                        ON C.centroid = O.centroid         
                        WHERE C.cluster_weight > 0        
                        AND O.centroid IS NOT NULL         
                        ORDER BY ran_centroid, transport_centroid ) A 
LEFT JOIN {schema}.transport_clusters CT 
ON CT.centroid = A.transport_centroid 
LEFT JOIN {schema}.clusters C 
ON C.centroid = A.ran_centroid 
LEFT JOIN {schema}.infrastructure_global I1 
ON I1.tower_id::text = A.transport_centroid 
LEFT JOIN {schema}.transport_greenfield_clusters  T 
ON T.centroid::text = A.ran_centroid 
LEFT JOIN {schema}.infrastructure_global I3 
ON I3.tower_id = T.movistar_transport_id  
WHERE LENGTH(ran_centroid) >= 8) A
ON A.ran_centroid=c.centroid
left join {schema}.infrastructure_global i
on c.centroid=i.tower_id::text
left join {schema}.transport_greenfield_clusters tr
on c.centroid=tr.centroid
left join {schema}.transport_by_settlement_all ts
on ts.settlement_id=c.centroid
left join {schema}.settlements s
on s.settlement_id=c.centroid
left join {schema}.infrastructure_global it
on it.tower_id=tr.movistar_transport_id 
WHERE A.type LIKE '%satellite%'
