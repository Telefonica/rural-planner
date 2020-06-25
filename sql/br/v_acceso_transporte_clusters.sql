CREATE OR REPLACE VIEW
    {schema}.v_acceso_transporte_clusters
    (
        cluster_id,
        codigo_setor,
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
        geom_line_transporte_torre_acceso,
        torre_acceso_movistar_optima,
        distancia_torre_acceso_movistar_optima,
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
        distancia_torre_transporte_movistar_optima               
    ) AS
SELECT DISTINCT ON (c.centroid)
    c.centroid AS cluster_id,
    tr.codigo_setor,
    CASE WHEN tr.torre_acceso IS NOT NULL THEN tr.torre_acceso
     WHEN tr2.torre_acceso is NOT NULL then tr2.torre_acceso
     ELSE NULL END as torre_acceso,
    CASE WHEN tr.codigo_setor IS NOT NULL THEN ST_Distance(tr.geom_torre_acceso,c.geom)/1000:: DOUBLE PRECISION
        WHEN tr2.torre_acceso IS NOT NULL THEN (0):: DOUBLE PRECISION
        ELSE (ST_Distance(tr3.geom_torre_acceso, tr3.geom_torre_transporte)/1000):: DOUBLE PRECISION END AS km_dist_torre_acceso,
    CASE WHEN tr.owner_torre_acceso IS NOT NULL THEN tr.owner_torre_acceso
        WHEN tr2.owner_torre_acceso IS NOT NULL THEN tr2.owner_torre_acceso
        ELSE NULL END AS owner_torre_acceso,
    CASE WHEN tr.los_acceso_transporte IS NOT NULL THEN tr.los_acceso_transporte
        WHEN tr2.los_acceso_transporte IS NOT NULL THEN tr2.los_acceso_transporte
        ELSE NULL END AS los_acceso_transporte,
    CASE WHEN tr.altura_torre_acceso IS NOT NULL THEN tr.altura_torre_acceso
        WHEN tr2.altura_torre_acceso IS NOT NULL THEN tr2.altura_torre_acceso
        ELSE NULL END AS altura_torre_acceso,
    CASE WHEN tr.tipo_torre_acceso IS NOT NULL THEN tr.tipo_torre_acceso
        WHEN tr2.tipo_torre_acceso IS NOT NULL THEN tr2.tipo_torre_acceso
        ELSE NULL END AS tipo_torre_acceso,
    CASE WHEN tr.vendor_torre_acceso IS NOT NULL THEN tr.vendor_torre_acceso
        WHEN tr2.vendor_torre_acceso IS NOT NULL THEN tr2.vendor_torre_acceso
        ELSE NULL END AS vendor_torre_acceso,
    CASE WHEN tr.tecnologia_torre_acceso IS NOT NULL THEN tr.tecnologia_torre_acceso
        WHEN tr2.tecnologia_torre_acceso IS NOT NULL THEN tr2.tecnologia_torre_acceso
        ELSE NULL END AS tecnologia_torre_acceso,
    CASE WHEN tr.torre_acceso_4g IS NOT NULL THEN tr.torre_acceso_4g
        WHEN tr2.torre_acceso_4g IS NOT NULL THEN tr2.torre_acceso_4g
        ELSE NULL END AS torre_acceso_4g,
    CASE WHEN tr.torre_acceso_3g IS NOT NULL THEN tr.torre_acceso_3g
        WHEN tr2.torre_acceso_3g IS NOT NULL THEN tr2.torre_acceso_3g
        ELSE NULL END AS torre_acceso_3g,
    CASE WHEN tr.torre_acceso_2g IS NOT NULL THEN tr.torre_acceso_2g
        WHEN tr2.torre_acceso_2g IS NOT NULL THEN tr2.torre_acceso_2g
        ELSE NULL END AS torre_acceso_2g,
    CASE WHEN tr.torre_acceso_source IS NOT NULL THEN tr.torre_acceso_source
        WHEN tr2.torre_acceso_source IS NOT NULL THEN tr2.torre_acceso_source
        ELSE NULL END AS torre_acceso_source,
    CASE WHEN tr.torre_acceso_internal_id IS NOT NULL THEN tr.torre_acceso_internal_id
        WHEN tr2.torre_acceso_internal_id IS NOT NULL THEN tr2.torre_acceso_internal_id
        ELSE NULL END AS torre_acceso_internal_id,
    CASE WHEN tr.latitude_torre_acceso IS NOT NULL THEN tr.latitude_torre_acceso
        WHEN tr2.latitude_torre_acceso IS NOT NULL THEN tr2.latitude_torre_acceso
        ELSE NULL END AS latitude_torre_acceso,
    CASE WHEN tr.longitude_torre_acceso IS NOT NULL THEN tr.longitude_torre_acceso
        WHEN tr2.longitude_torre_acceso IS NOT NULL THEN tr2.longitude_torre_acceso
        ELSE NULL END AS longitude_torre_acceso,
    CASE WHEN tr.geom_torre_acceso IS NOT NULL THEN tr.geom_torre_acceso
        WHEN tr2.geom_torre_acceso IS NOT NULL THEN tr2.geom_torre_acceso
        ELSE NULL END AS geom_torre_acceso,
    CASE WHEN tr.geom_line_torre_acceso IS NOT NULL THEN tr.geom_line_torre_acceso
        WHEN tr2.geom_line_torre_acceso IS NOT NULL THEN tr2.geom_line_torre_acceso
        ELSE NULL END AS geom_line_torre_acceso,
    CASE WHEN tr.geom_line_transporte_torre_acceso IS NOT NULL THEN tr.geom_line_transporte_torre_acceso
        WHEN tr2.geom_line_transporte_torre_acceso IS NOT NULL THEN tr2.geom_line_transporte_torre_acceso
        ELSE NULL END AS geom_line_transporte_torre_acceso,
    CASE WHEN tr.torre_acceso_movistar_optima IS NOT NULL THEN tr.torre_acceso_movistar_optima
        WHEN tr2.torre_acceso_movistar_optima IS NOT NULL THEN tr2.torre_acceso_movistar_optima
        ELSE NULL END AS torre_acceso_movistar_optima,  
    CASE WHEN tr.distancia_torre_acceso_movistar_optima IS NOT NULL THEN tr.distancia_torre_acceso_movistar_optima
        WHEN tr2.distancia_torre_acceso_movistar_optima IS NOT NULL THEN tr2.distancia_torre_acceso_movistar_optima
        ELSE NULL END AS distancia_torre_acceso_movistar_optima,
     CASE WHEN tr.torre_transporte IS NOT NULL THEN tr.torre_transporte
     WHEN tr2.torre_transporte IS NOT NULL THEN tr2.torre_transporte 
     ELSE tr3.torre_transporte END as torre_transporte,
     CASE WHEN tr.codigo_setor IS NOT NULL THEN ST_Distance(tr.geom_torre_transporte,c.geom)/1000:: DOUBLE PRECISION
        WHEN tr2.torre_acceso IS NOT NULL THEN ST_Distance(tr2.geom_torre_transporte,tr2.geom_torre_acceso)/1000:: DOUBLE PRECISION
        ELSE (0):: DOUBLE PRECISION END AS km_dist_torre_transporte,
     CASE WHEN tr.owner_torre_transporte IS NOT NULL THEN tr.owner_torre_transporte
        WHEN tr2.owner_torre_transporte IS NOT NULL THEN tr2.owner_torre_transporte
        ELSE tr3.owner_torre_transporte END AS owner_torre_transporte,
     CASE WHEN tr.altura_torre_transporte IS NOT NULL THEN tr.altura_torre_transporte
        WHEN tr2.altura_torre_transporte IS NOT NULL THEN tr2.altura_torre_transporte
        ELSE tr3.altura_torre_transporte END AS altura_torre_transporte,
     CASE WHEN tr.tipo_torre_transporte IS NOT NULL THEN tr.tipo_torre_transporte
        WHEN tr2.tipo_torre_transporte IS NOT NULL THEN tr2.tipo_torre_transporte
        ELSE tr3.tipo_torre_transporte END AS tipo_torre_transporte,
     CASE WHEN tr.banda_satelite_torre_transporte IS NOT NULL THEN tr.banda_satelite_torre_transporte
        WHEN tr2.banda_satelite_torre_transporte IS NOT NULL THEN tr2.banda_satelite_torre_transporte
        ELSE tr3.banda_satelite_torre_transporte END AS banda_satelite_torre_transporte,
     CASE WHEN tr.torre_transporte_fibra IS NOT NULL THEN tr.torre_transporte_fibra
        WHEN tr2.torre_transporte_fibra IS NOT NULL THEN tr2.torre_transporte_fibra
        ELSE tr3.torre_transporte_fibra END AS torre_transporte_fibra,
     CASE WHEN tr.torre_transporte_radio IS NOT NULL THEN tr.torre_transporte_radio
        WHEN tr2.torre_transporte_radio IS NOT NULL THEN tr2.torre_transporte_radio
        ELSE tr3.torre_transporte_radio END AS torre_transporte_radio,
     CASE WHEN tr.torre_transporte_satellite IS NOT NULL THEN tr.torre_transporte_satellite
        WHEN tr2.torre_transporte_satellite IS NOT NULL THEN tr2.torre_transporte_satellite
        ELSE tr3.torre_transporte_satellite END AS torre_transporte_satellite,
     CASE WHEN tr.torre_transporte_source IS NOT NULL THEN tr.torre_transporte_source
        WHEN tr2.torre_transporte_source IS NOT NULL THEN tr2.torre_transporte_source
        ELSE tr3.torre_transporte_source END AS torre_transporte_source,
     CASE WHEN tr.torre_transporte_internal_id IS NOT NULL THEN tr.torre_transporte_internal_id
        WHEN tr2.torre_transporte_internal_id IS NOT NULL THEN tr2.torre_transporte_internal_id
        ELSE tr3.torre_transporte_internal_id END AS torre_transporte_internal_id,
     CASE WHEN tr.latitude_torre_transporte IS NOT NULL THEN tr.latitude_torre_transporte
        WHEN tr2.latitude_torre_transporte IS NOT NULL THEN tr2.latitude_torre_transporte
        ELSE tr3.latitude_torre_transporte END AS latitude_torre_transporte,
     CASE WHEN tr.longitude_torre_transporte IS NOT NULL THEN tr.longitude_torre_transporte
        WHEN tr2.longitude_torre_transporte IS NOT NULL THEN tr2.longitude_torre_transporte
        ELSE tr3.longitude_torre_transporte END AS longitude_torre_transporte,
     CASE WHEN tr.geom_torre_transporte IS NOT NULL THEN tr.geom_torre_transporte
        WHEN tr2.geom_torre_transporte IS NOT NULL THEN tr2.geom_torre_transporte
        ELSE tr3.geom_torre_transporte END AS geom_torre_transporte,
     CASE WHEN tr.geom_line_torre_transporte IS NOT NULL THEN tr.geom_line_torre_transporte
        WHEN tr2.geom_line_torre_transporte IS NOT NULL THEN tr2.geom_line_torre_transporte
        ELSE tr3.geom_line_torre_transporte END AS geom_line_torre_transporte,        
    CASE WHEN tr.torre_transporte_movistar_optima IS NOT NULL THEN tr.torre_transporte_movistar_optima
        WHEN tr2.torre_transporte_movistar_optima IS NOT NULL THEN tr2.torre_transporte_movistar_optima
        ELSE tr3.torre_transporte_movistar_optima END AS torre_transporte_movistar_optima,  
    CASE WHEN tr.distancia_torre_transporte_movistar_optima IS NOT NULL THEN tr.distancia_torre_transporte_movistar_optima
        WHEN tr2.distancia_torre_transporte_movistar_optima IS NOT NULL THEN tr2.distancia_torre_transporte_movistar_optima
        ELSE tr3.distancia_torre_transporte_movistar_optima END AS distancia_torre_transporte_movistar_optima
FROM
    ((  SELECT *
        FROM {schema}.clusters) c
        LEFT JOIN {schema}.v_acceso_transporte tr
        ON (( c.centroid = tr.codigo_setor ))
        LEFT JOIN {schema}.v_acceso_transporte tr2
        ON (( c.centroid = tr2.torre_acceso::text ))
        LEFT JOIN {schema}.v_acceso_transporte tr3
        ON (( c.centroid = tr3.torre_transporte::text ))
    )
ORDER BY c.centroid,tr.codigo_setor, tr2.torre_acceso, tr3.torre_transporte;