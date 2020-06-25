CREATE OR REPLACE VIEW
    {schema}.v_acceso_transporte
    (
        ubigeo,
        torre_acceso,
        km_dist_torre_acceso,
        los_acceso_transporte,
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
        torre_acceso_perimetro_ipt,
        torre_acceso_tower_name,
        latitude_torre_acceso,
        longitude_torre_acceso,
        geom_torre_acceso,
        geom_line_torre_acceso,
        geom_line_trasnporte_torre_acceso,
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
        torre_transporte_perimetro_ipt,
        torre_transporte_tower_name,
        latitude_torre_transporte,
        longitude_torre_transporte,
        geom_torre_transporte,
        geom_line_torre_transporte
    ) AS
SELECT
    s.settlement_id                                                   AS ubigeo,
    tr.access_tower_id                                                AS torre_acceso,
    ROUND(((tr.distance_access_tower)::NUMERIC / (1000)::NUMERIC), 2) AS km_dist_torre_acceso,
    tr.line_of_sight_access_transport                                 AS los_acceso_transporte,
    ia.owner                                                          AS owner_torre_acceso,
    ia.tower_height                                                   AS altura_torre_acceso,
    ia.type                                                           AS tipo_torre_acceso,
    ia.vendor                                                         AS vendor_torre_acceso,
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
    END                                        AS tecnologia_torre_acceso,
    ia.tech_4g                                                AS torre_acceso_4g,
    ia.tech_3g                                                AS torre_acceso_3g,
    ia.tech_2g                                                AS torre_acceso_2g,
    ia.source                                             AS torre_acceso_source,
    ia.internal_id                                       AS torre_acceso_internal_id,
    ia.ipt_perimeter AS torre_acceso_perimetro_ipt,
    ia.tower_name AS torre_acceso_tower_name,
    ia.latitude                                             AS latitude_torre_acceso,
    ia.longitude                                           AS longitude_torre_acceso,
    ia.geom                                                     AS geom_torre_acceso,
    tr.geom_line_access                                         AS geom_line_torre_acceso,
    tr.geom_line_access_transport                              AS geom_line_trasnporte_torre_acceso,
    tr.transport_tower_id                                                AS torre_transporte,
    ROUND(((tr.distance_transport_tower)::NUMERIC / (1000)::NUMERIC), 2) AS
                km_dist_torre_transporte,
    it.owner        AS owner_torre_transporte,
    it.tower_height AS altura_torre_transporte,
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
    it.ipt_perimeter AS torre_transporte_perimetro_ipt,
    it.tower_name AS torre_transporte_tower_name,
    it.latitude              AS latitude_torre_transporte,
    it.longitude             AS longitude_torre_transporte,
    it.geom                  AS geom_torre_transporte,
    tr.geom_line_transport   AS geom_line_torre_transporte
FROM
    ((({schema}.settlements s
LEFT JOIN
    {schema}.transport_by_settlement tr
ON
    ((
            tr.settlement_id = s.settlement_id)))
LEFT JOIN
    {schema}.infrastructure_global ia
ON
    ((
            ia.tower_id = tr.access_tower_id)))
LEFT JOIN
    {schema}.infrastructure_global it
ON
    ((
            it.tower_id = tr.transport_tower_id)));