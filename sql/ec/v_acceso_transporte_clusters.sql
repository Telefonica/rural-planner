CREATE OR REPLACE VIEW
    {schema}.v_acceso_transporte_clusters
    (
        cluster_id,
        codigo_divipola,
        torre_acceso,
        km_dist_torre_acceso,
        owner_torre_acceso,
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
        torre_acceso_regional_optima,
        distancia_torre_acceso_regional_optima,
        torre_acceso_terceros_optima,
        distancia_torre_acceso_terceros_optima,
        los_acceso_transporte,
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
        torre_transporte_regional_optima,
        distancia_torre_transporte_regional_optima,
        torre_transporte_terceros_optima,
        distancia_torre_transporte_terceros_optima
                
    ) AS
SELECT
    tr.centroid AS cluster_id,
    tr.centroid as codigo_divipola,
    NULL::integer as torre_acceso,
    0::DOUBLE PRECISION as km_dist_torre_acceso,
    NULL::TEXT AS owner_torre_acceso,
    50 as altura_torre_acceso,
    NULL::TEXT AS tipo_torre_acceso,
    NULL::TEXT AS vendor_torre_acceso,
    '-' AS tecnologia_torre_acceso,
    FALSE AS torre_acceso_4g,
    FALSE AS torre_acceso_3g,
    FALSE AS torre_acceso_2g,
    NULL::TEXT AS torre_acceso_source,
    NULL::TEXT AS torre_acceso_internal_id,
    NULL::DOUBLE PRECISION as latitude_torre_acceso,
    NULL::DOUBLE PRECISION as longitude_torre_acceso,
    NULL::GEOMETRY as geom_torre_acceso,
    NULL::GEOMETRY as geom_line_torre_acceso,
    ST_MakeLine(tr.geom_centroid::geometry,i.geom::geometry) as geom_line_trasnporte_torre_acceso,
    NULL::integer AS torre_acceso_movistar_optima,
    NULL::DOUBLE PRECISION as distancia_torre_acceso_movistar_optima,
    NULL::integer AS torre_acceso_regional_optima,
    NULL::DOUBLE PRECISION as distancia_torre_acceso_regional_optima,
    NULL::integer AS torre_acceso_terceros_optima,
    NULL::DOUBLE PRECISION as distancia_torre_acceso_terceros_optima,
    tr.line_of_sight_movistar as los_acceso_transporte,
    tr.movistar_transport as torre_transporte,
    tr.distance_movistar_transport/1000 as km_dist_torre_transporte,
    i.owner as owner_torre_transporte,
    i.tower_height as altura_torre_transporte,
        CASE
        WHEN ((i.fiber
                AND i.radio)
            AND i.satellite)
        THEN 'FO+RADIO+SAT'::text
        WHEN (i.fiber
            AND i.radio)
        THEN 'i+RADIO'::text
        WHEN (i.fiber
            AND i.satellite)
        THEN 'FO+SAT'::text
        WHEN (i.radio
            AND i.satellite)
        THEN 'RADIO+SAT'::text
        WHEN i.fiber
        THEN 'FO'::text
        WHEN i.radio
        THEN 'RADIO'::text
        WHEN i.satellite
        THEN 'SAT'::text
        ELSE '-'::text
    END                      AS tipo_torre_transporte,
    i.satellite_band_in_use as banda_satelite_torre_transporte,
    i.fiber as torre_transporte_fibra,
    i.radio as torre_transporte_radio,
    i.satellite as torre_transporte_satellite,
    i.source as torre_transporte_source,
    i.internal_id as torre_transporte_internal_id,
    i.latitude as latitude_torre_transporte,
    i.longitude as longitude_torre_transporte,
    i.geom as geom_torre_transporte,
    ST_Makeline(i.geom::geometry, tr.geom_centroid::geometry) as geom_line_torre_transporte,
    tr.movistar_transport as torre_transporte_movistar_optima,
    tr.distance_movistar_transport as distancia_torre_transporte_movistar_optima,
    NULL::INTEGER as torre_transporte_regional_optima,
    NULL::DOUBLE PRECISION as distancia_torre_transporte_regional_optima,
    tr.third_party_transport as torre_transporte_terceros_optima,
    tr.distance_third_party_transport as distancia_torre_transporte_terceros_optima
FROM
    {schema}.transport_greenfield_clusters tr
    LEFT JOIN {schema}.infrastructure_global i
    ON tr.movistar_transport=i.tower_id
    LEFT JOIN {schema}.clusters c
    ON c.centroid=tr.centroid
WHERE c.nodes IS NOT NULL

UNION

SELECT c.centroid AS cluster_id,
    NULL::text                 AS codigo_divipola,
    tr.tower_id as torre_acceso,
    (0)::DOUBLE PRECISION AS km_dist_torre_acceso,
    i.owner as owner_torre_acceso,
    i.tower_height as altura_torre_acceso,
    i.tower_type as tipo_torre_acceso,
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
    END                           AS tecnologia_torre_acceso,
    i.tech_4g as torre_acceso_4g,
    i.tech_3g as torre_acceso_3g,
    i.tech_2g as torre_acceso_2g,
    i.source as torre_acceso_source,
    i.internal_id as torre_acceso_internal_id,
    i.latitude as latitude_torre_acceso,
    i.longitude as longitude_torre_acceso,
    i.geom as geom_torre_acceso,
    NULL::GEOMETRY AS geom_line_torre_acceso,
    ST_MakeLine(i.geom::geometry, it.geom::geometry) as geom_line_trasnporte_torre_acceso,
    i.tower_id as torre_acceso_movistar_optima,
    0 as distancia_torre_acceso_movistar_optima,
    NULL::INTEGER AS torre_acceso_regional_optima,
    NULL::DOUBLE PRECISION AS distancia_torre_acceso_regional_optima,
    NULL::INTEGER as torre_acceso_terceros_optima,
    NULL::DOUBLE PRECISION AS distancia_torre_acceso_terceros_optima,
    tr.line_of_sight_movistar as los_acceso_transporte,
    tr.movistar_transport_id as torre_transporte,
    tr.distance_third_party_transport_m/1000 as km_dist_torre_transporte,
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
    END                      AS tipo_torre_transporte,
    it.satellite_band_in_use as banda_satelite_torre_transporte,
    it.fiber as torre_transporte_fibra,
    it.radio as torre_transporte_radio,
    it.satellite as torre_transporte_satellite,
    it.source as torre_transporte_source,
    it.internal_id as torre_transporte_internal_id,
    it.latitude as latitude_torre_transporte,
    it.longitude as longitude_torre_transporte,
    it.geom as geom_torre_transporte,
    ST_MakeLine(i.geom::geometry, it.geom::geometry) as geom_line_torre_transporte,
    tr.movistar_transport_id as torre_transporte_movistar_optima,
    tr.distance_movistar_transport_m as distancia_torre_transporte_movistar_optima,
    NULL::INTEGER AS torre_transporte_regional_optima,
    NULL::DOUBLE PRECISION AS distancia_torre_transporte_regional_optima,
    tr.third_party_transport_id as torre_transporte_terceros_optima,
    tr.distance_third_party_transport_m as distancia_torre_transporte_terceros_optima
FROM
        {schema}.clusters c
       LEFT JOIN  {schema}.transport_by_tower tr            
            ON c.centroid=tr.tower_id::text 
            LEFT JOIN {schema}.infrastructure_global i
            ON c.centroid=i.tower_id::TEXT
            LEFT JOIN {schema}.infrastructure_global it
            ON tr.movistar_transport_id=it.tower_id
        WHERE i.tower_id IS NOT NULL;