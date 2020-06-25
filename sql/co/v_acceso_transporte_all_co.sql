CREATE OR REPLACE VIEW {schema}.v_acceso_transporte
/*(
        codigo_divipola,
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
        latitude_torre_acceso,
        longitude_torre_acceso,
        geom_torre_acceso,
        geom_line_torre_acceso,
        geom_line_trasnporte_torre_acceso,
        distancia_torre_acceso_movistar_optima,
        torre_acceso_anditel_optima,
        distancia_torre_acceso_anditel_optima,
        torre_acceso_atc_optima,
        distancia_torre_acceso_atc_optima,
        torre_acceso_atp_optima,
        distancia_torre_acceso_atp_optima,
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
        distancia_torre_transporte_atp_optima
    ) */ AS
SELECT
    s.settlement_id    AS codigo_divipola,
    tr.access_tower_id AS torre_acceso,
    ROUND(((tr.distance_access_tower)::NUMERIC / (1000)::NUMERIC), 2)::numeric AS km_dist_torre_acceso,
    ia.owner           AS owner_torre_acceso,
    tr.line_of_sight_access_transport::boolean                                 AS los_acceso_transporte,
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
    tr.geom_line_access           AS geom_line_torre_acceso,
    tr.geom_line_access_transport AS geom_line_trasnporte_torre_acceso,
    tr.movistar_optimal_tower_id AS torre_acceso_movistar_optima,
    tr.distance_movistar_optimal_tower_m   AS   distancia_torre_acceso_movistar_optima,
    tr.anditel_optimal_tower_id   AS   torre_acceso_anditel_optima,
    tr.distance_anditel_optimal_tower_m    AS  distancia_torre_acceso_anditel_optima,
    tr.atc_optimal_tower_id   AS   torre_acceso_atc_optima,
    tr.distance_atc_optimal_tower_m    AS   distancia_torre_acceso_atc_optima,
    tr.atp_optimal_tower_id   AS   torre_acceso_atp_optima,
    tr.distance_atp_optimal_tower_m    AS   distancia_torre_acceso_atp_optima,
    tr.qmc_optimal_tower_id   AS   torre_acceso_qmc_optima,
    tr.distance_qmc_optimal_tower_m    AS   distancia_torre_acceso_qmc_optima,
    tr.uniti_optimal_tower_id   AS   torre_acceso_uniti_optima,
    tr.distance_uniti_optimal_tower_m    AS   distancia_torre_acceso_uniti_optima,
    tr.phoenix_optimal_tower_id   AS   torre_acceso_phoenix_optima,
    tr.distance_phoenix_optimal_tower_m    AS   distancia_torre_acceso_phoenix_optima,
    tr.transport_tower_id         AS torre_transporte,
    ROUND(((tr.distance_transport_tower)::NUMERIC / (1000)::NUMERIC), 2) AS
                km_dist_torre_transporte,
    it.owner                      AS owner_torre_transporte,
    it.tower_height               AS altura_torre_transporte,
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
    tr.geom_line_transport   AS geom_line_torre_transporte,
    tt.movistar_transport_id   AS  torre_transporte_movistar_optima,
    tt.distance_movistar_transport_m   AS  distancia_torre_transporte_movistar_optima,
    tt.anditel_transport_id   AS  torre_transporte_anditel_optima,
    tt.distance_anditel_transport_m   AS  distancia_torre_transporte_anditel_optima,
    tt.azteca_transport_id   AS  torre_transporte_azteca_optima,
    tt.distance_azteca_transport_m   AS  distancia_torre_transporte_azteca_optima,
    tt.atc_transport_id   AS  torre_transporte_atc_optima,
    tt.distance_atc_transport_m   AS  distancia_torre_transporte_atc_optima,
    tt.atp_transport_id   AS  torre_transporte_atp_optima,
    tt.distance_atp_transport_m   AS  distancia_torre_transporte_atp_optima,    
    tt.phoenix_transport_id   AS  torre_transporte_phoenix_optima,
    tt.distance_phoenix_transport_m   AS  distancia_torre_transporte_phoenix_optima,
    tt.qmc_transport_id  AS  torre_transporte_qmc_optima,
    tt.distance_qmc_transport_m   AS  distancia_torre_transporte_qmc_optima,
    tt.uniti_transport_id   AS  torre_transporte_uniti_optima,
    tt.distance_uniti_transport_m  AS  distancia_torre_transporte_uniti_optima
FROM
    (((({schema}.settlements s
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
            it.tower_id = tr.transport_tower_id)))
LEFT JOIN
    {schema}.transport_by_tower_all tt
ON
    ((
            tt.tower_id = tr.access_tower_id)))
            
            ;