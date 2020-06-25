CREATE OR REPLACE VIEW
    {schema}.v_acceso_transporte_clusters
    AS
SELECT c.centroid AS cluster_id,
    c.centroid_name,
    ia.tower_id as torre_acceso,
    CASE WHEN ia.tower_id IS NOT NULL THEN 0
        ELSE NULL END AS km_dist_torre_acceso,
    ia.owner as owner_torre_acceso,
    tr.line_of_sight_optimal_transport AS los_acceso_transporte,
    ia.tower_height AS altura_torre_acceso,
    ia.type AS tipo_torre_acceso,
    ia.vendor AS vendor_torre_acceso,
    CASE WHEN ((ia.tech_4g
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
    ia.tech_4g AS torre_acceso_4g,
    ia.tech_3g AS torre_acceso_3g,
    ia.tech_2g AS torre_acceso_2g,
    ia.source AS torre_acceso_source,
    ia.internal_id AS torre_acceso_internal_id,
    ia.latitude AS latitude_torre_acceso,
    ia.longitude AS longitude_torre_acceso,
    ia.geom AS geom_torre_acceso,
    NULL::geometry AS geom_line_torre_acceso,
    ST_MakeLine(c.geom_centroid::geometry,it.geom::geometry) AS geom_line_trasnporte_torre_acceso,
    CASE WHEN LENGTH(c.centroid)<6 THEN c.centroid::integer ELSE NULL END AS torre_acceso_movistar_optima,
    CASE WHEN LENGTH(c.centroid)<6 THEN 0 ELSE NULL END   AS   distancia_torre_acceso_movistar_optima, 
    NULL::integer AS torre_acceso_arsat_optima,
    NULL::float   AS   distancia_torre_acceso_arsat_optima,
    NULL::integer AS torre_acceso_silica_optima,
    NULL::float   AS   distancia_torre_acceso_silica_optima,
    NULL::integer AS torre_acceso_gigared_optima,
    NULL::float   AS   distancia_torre_acceso_gigared_optima,
    NULL::integer AS torre_acceso_points_optima,
    NULL::float   AS   distancia_torre_acceso_points_optima,
        d.torre_acceso_partners,
     tr.optimal_transport_id as torre_transporte,
     ROUND(tr.distance_optimal_transport_m::numeric,2) AS km_dist_torre_transporte,
     it.owner AS owner_torre_transporte,
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
    it.latitude              AS latitude_torre_transporte,
    it.longitude             AS longitude_torre_transporte,
    it.geom                  AS geom_torre_transporte,
    ST_Makeline(c.geom_centroid::geometry,it.geom::geometry) AS geom_line_torre_transporte,
    --tr.geom_line_transport   AS geom_line_torre_transporte,
    tr.movistar_transport_id   AS  torre_transporte_movistar_optima,
    tr.distance_movistar_transport_m   AS  distancia_torre_transporte_movistar_optima,
    tr.arsat_transport_id   AS  torre_transporte_arsat_optima,
    tr.distance_arsat_transport_m   AS  distancia_torre_transporte_arsat_optima,
    tr.silica_transport_id   AS  torre_transporte_silica_optima,
    tr.distance_silica_transport_m   AS  distancia_torre_transporte_silica_optima,
    tr.gigared_transport_id   AS  torre_transporte_gigared_optima,
    tr.distance_gigared_transport_m   AS  distancia_torre_transporte_gigared_optima,
    tr.points_transport_id   AS  torre_transporte_points_optima,
    tr.distance_points_transport_m   AS  distancia_torre_transporte_points_optima,
    tr.others_transport_id   AS  torre_transporte_otros_optima,
    tr.distance_others_transport_m   AS  distancia_torre_transporte_otros_optima
FROM (SELECT c.*, CASE WHEN s.settlement_id is not null then s.settlement_name
                        ELSE i.internal_id END AS centroid_name 
                FROM {schema}.clusters c
                LEFT JOIN {schema}.infrastructure_global i
                ON i.tower_id::text=c.centroid
                LEFT JOIN {schema}.settlements s
                ON s.settlement_id=c.centroid ) c
LEFT JOIN ( SELECT tower_id::TEXT as centroid,
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
                geom_line_others
    FROM {schema}.transport_by_tower_all
    UNION
    SELECT * FROM {schema}.transport_greenfield_clusters) tr
ON
    ((
            c.centroid = tr.centroid))
LEFT JOIN
    {schema}.infrastructure_global ia
ON
    ((
            c.centroid = ia.tower_id::text))
            LEFT JOIN
    {schema}.infrastructure_global it
ON
    ((
            tr.optimal_transport_id = it.tower_id))
LEFT JOIN
      (select c.centroid, string_agg(distinct(sp.partners),' ; ') AS torre_acceso_partners
        from {schema}.clusters_ipt_links c
        left join (
                     select s.settlement_id, s.geom, 
                     CASE WHEN (sp.partners IS NULL OR sp.partners LIKE '%%Sin presencia aliado%%') THEN NULL::text ELSE sp.partners END
                        from {schema}.settlements s
                        left join {schema}.settlements_partners sp
                        on ST_DWithin(sp.geom::geography, s.geom::geography, 20000)
                        order by s.settlement_id, s.admin_division_1_id, sp.admin_division_1_id) sp
        on c.node_2_id=sp.settlement_id
        group by centroid) d
ON d.centroid=c.centroid
ORDER BY c.centroid