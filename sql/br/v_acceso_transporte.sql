CREATE OR REPLACE VIEW {schema}.v_acceso_transporte
(
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
        torre_acceso_vivo_optima,
        distancia_torre_acceso_vivo_optima,
        torre_acceso_regional_optima,
        distancia_torre_acceso_regional_optima,
        torre_acceso_terceros_optima,
        distancia_torre_acceso_terceros_optima,
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
        torre_transporte_vivo_optima,
        distancia_torre_transporte_vivo_optima,
        torre_transporte_regional_optima,
        distancia_torre_transporte_regional_optima,
        torre_transporte_terceros_optima,
        distancia_torre_transporte_terceros_optima
) AS
SELECT
    s.settlement_id    AS codigo_setor,
    CASE WHEN LENGTH(tr.centroid)<15 THEN tr.centroid::INTEGER ELSE NULL END AS torre_acceso,
    ROUND((ST_Distance(tr.geom_centroid::geography, tr.geom_node::geography) / (1000)::NUMERIC), 2)::numeric 
                       AS km_dist_torre_acceso,
    ia.owner           AS owner_torre_acceso,
    tr.line_of_sight_access_transport::boolean
                       AS los_acceso_transporte,
    ia.tower_height    AS altura_torre_acceso,
    ia.type            AS tipo_torre_acceso,
    ia.vendor          AS vendor_torre_acceso,
    CASE
        WHEN ((ia.tech_4g
                AND ia.tech_3g)
            AND ia.tech_2g)
        THEN '4G+3G+2G'::text
        WHEN (ia.tech_4g
            AND ia.tech_3g)
        THEN '4G+3G'::text
        WHEN (ia.tech_4g
            AND ia.tech_2g)
        THEN '4G+2G'::text
        WHEN (ia.tech_3g
            AND ia.tech_2g)
        THEN '3G+2G'::text
        WHEN ia.tech_4g
        THEN '4G'::text
        WHEN ia.tech_3g
        THEN '3G'::text
        WHEN ia.tech_2g
        THEN '2G'::text
        ELSE '-'::text
    END                           AS tecnologia_torre_acceso,
    ia.tech_4g                    AS torre_acceso_4g,
    ia.tech_3g                    AS torre_acceso_3g,
    ia.tech_2g                    AS torre_acceso_2g,
    ia.source                     AS torre_acceso_source,
    ia.internal_id                AS torre_acceso_internal_id,
    ia.latitude                   AS latitude_torre_acceso,
    ia.longitude                  AS longitude_torre_acceso,
    ia.geom                       AS geom_torre_acceso,
    tr.geom_line_access                      AS geom_line_torre_acceso,
    ST_MakeLine(c.geom_centroid::geometry, it.geom::geometry)            AS geom_line_transporte_torre_acceso,    
    tr.transport_tower_id                    AS torre_transporte,
    ROUND(((tr.distance_transport_tower)::NUMERIC / (1000)::NUMERIC), 2) 
                                             AS km_dist_torre_transporte,
    it.owner                 AS owner_torre_transporte,
    it.tower_height          AS altura_torre_transporte,
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
    it.satellite_band_in_use AS banda_satelite_torre_transporte,
    it.fiber                 AS torre_transporte_fibra,
    it.radio                 AS torre_transporte_radio,
    it.satellite             AS torre_transporte_satellite,
    it.source                AS torre_transporte_source,
    it.internal_id           AS torre_transporte_internal_id,
    it.latitude              AS latitude_torre_transporte,
    it.longitude             AS longitude_torre_transporte,
    it.geom                  AS geom_torre_transporte,
    ST_MakeLine(s.geom::geometry, COALESCE(tt.geom_vivo, tt.geom_regional, tt.geom_third_party))   AS geom_line_torre_transporte,
    tt.vivo_transport_id             AS torre_transporte_vivo_optima,
    tt.distance_vivo_transport_m     AS distancia_torre_transporte_vivo_optima,
    tt.regional_transport_id             AS torre_transporte_regional_optima,
    tt.distance_regional_transport_m     AS distancia_torre_transporte_regional_optima,
    tt.third_party_transport_id          AS torre_transporte_terceros_optima,
    tt.distance_third_party_transport_m  AS distancia_torre_transporte_third_party_optima

FROM {schema}.settlements s
         LEFT JOIN {schema}.clusters_links tr
              ON (CASE WHEN tr.node_2_id='' THEN tr.centroid ELSE tr.node_2_id END) = s.settlement_id
         LEFT JOIN {schema}.infrastructure_global ia
              ON ia.tower_id::TEXT = tr.centroid
         LEFT JOIN {schema}.transport_by_tower tt
              ON tt.tower_id = tr.centroid
         LEFT JOIN {schema}.infrastructure_global it
              ON it.tower_id = COALESCE(tt.vivo_transport_id, tt.regional_transport_id, tt.third_party_transport_id);  