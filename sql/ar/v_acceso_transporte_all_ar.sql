CREATE OR REPLACE VIEW {schema}.v_acceso_transporte_all
 AS
SELECT distinct on (s.settlement_id)
    s.settlement_id  AS codigo_ccpp,
    s.settlement_name AS name_ccpp, 
    CASE WHEN LENGTH(c.centroid)<6 THEN c.centroid::integer ELSE p.tower_id END AS torre_acceso,
    CASE WHEN LENGTH(c.centroid)<6 THEN ROUND((ST_Length(c.geom_line::geography)::numeric/1000),2) ELSE ROUND((p.distance_m/1000)::numeric,2) END AS km_dist_torre_acceso,
    CASE WHEN LENGTH(c.centroid)<6 THEN ic.owner ELSE ip.owner  END         AS owner_torre_acceso,
    tr.line_of_sight_optimal_transport::boolean                               AS los_acceso_transporte,
    CASE WHEN LENGTH(c.centroid)<6 THEN ic.tower_height ELSE ip.tower_height END    AS altura_torre_acceso,
    CASE WHEN LENGTH(c.centroid)<6 THEN ic.type ELSE ip.type   END         AS tipo_torre_acceso,
    CASE WHEN LENGTH(c.centroid)<6 THEN ic.vendor ELSE ip.vendor END         AS vendor_torre_acceso,
    CASE
        WHEN (LENGTH(c.centroid)<6 AND (ic.tech_4g
                AND ic.tech_3g)
            AND ic.tech_2g)
        THEN '4G+3G+2G'::text
        WHEN LENGTH(c.centroid)<6 AND (ic.tech_4g
            AND ic.tech_3g)
        THEN '4G+3G'::text
        WHEN LENGTH(c.centroid)<6 AND (ic.tech_4g
            AND ic.tech_2g)
        THEN '4G+2G'::text
        WHEN LENGTH(c.centroid)<6 AND (ic.tech_3g
            AND ic.tech_2g)
        THEN '3G+2G'::text
        WHEN LENGTH(c.centroid)<6 AND ic.tech_4g
        THEN '4G'::text
        WHEN LENGTH(c.centroid)<6 AND ic.tech_3g
        THEN '3G'::text
        WHEN LENGTH(c.centroid)<6 AND ic.tech_2g
        THEN '2G'::text
        WHEN ((ip.tech_4g
                AND ip.tech_3g)
            AND ip.tech_2g)
        THEN '4G+3G+2G'::text
        WHEN (ip.tech_4g
            AND ip.tech_3g)
        THEN '4G+3G'::text
        WHEN (ip.tech_4g
            AND ip.tech_2g)
        THEN '4G+2G'::text
        WHEN (ip.tech_3g
            AND ip.tech_2g)
        THEN '3G+2G'::text
        WHEN ip.tech_4g
        THEN '4G'::text
        WHEN ip.tech_3g
        THEN '3G'::text
        WHEN ip.tech_2g
        THEN '2G'::text
        ELSE '-'::text
    END                           AS tecnologia_torre_acceso,
    CASE WHEN LENGTH(c.centroid)<6 THEN ic.tech_4g ELSE ip.tech_4g END                   AS torre_acceso_4g,
    CASE WHEN LENGTH(c.centroid)<6 THEN ic.tech_3g ELSE ip.tech_3g END                   AS torre_acceso_3g,
    CASE WHEN LENGTH(c.centroid)<6 THEN ic.tech_2g ELSE ip.tech_2g END                   AS torre_acceso_2g,
    CASE WHEN LENGTH(c.centroid)<6 THEN ic.source ELSE ip.source END                    AS torre_acceso_source,
    CASE WHEN LENGTH(c.centroid)<6 THEN ic.internal_id ELSE ip.internal_id END                AS torre_acceso_internal_id,
    CASE WHEN LENGTH(c.centroid)<6 THEN ic.latitude ELSE ip.latitude  END                AS latitude_torre_acceso,
    CASE WHEN LENGTH(c.centroid)<6 THEN ic.longitude ELSE ip.longitude END                  AS longitude_torre_acceso,
    CASE WHEN LENGTH(c.centroid)<6 THEN ic.geom::geometry ELSE ip.geom::geometry END                     AS geom_torre_acceso,
    CASE WHEN LENGTH(c.centroid)<6 THEN ST_MakeLine(s.geom::geometry,ic.geom::geometry) ELSE ST_MakeLine(s.geom::geometry,ip.geom::geometry)  END                     AS geom_line_torre_acceso,
    CASE WHEN LENGTH(c.centroid)<6 THEN ST_MakeLine(ic.geom::geometry,it.geom::geometry) ELSE ST_MakeLine(ic.geom::geometry,ip.geom::geometry)  END                     AS geom_line_trasnporte_torre_acceso,
    --tr.geom_line_access           AS geom_line_torre_acceso,
    --tr.geom_line_access_transport AS geom_line_trasnporte_torre_acceso,
    CASE WHEN LENGTH(c.centroid)<6 THEN c.centroid::integer ELSE p.tower_id END AS torre_acceso_movistar_optima,
    CASE WHEN LENGTH(c.centroid)<6 THEN ROUND(ST_Length(c.geom_line::geography)::numeric,2) ELSE ROUND(p.distance_m::numeric,2) END   AS   distancia_torre_acceso_movistar_optima,
    NULL::integer AS torre_acceso_arsat_optima,
    NULL::float   AS   distancia_torre_acceso_arsat_optima,
    NULL::integer AS torre_acceso_silica_optima,
    NULL::float   AS   distancia_torre_acceso_silica_optima,
    NULL::integer AS torre_acceso_gigared_optima,
    NULL::float   AS   distancia_torre_acceso_gigared_optima,
    NULL::integer AS torre_acceso_points_optima,
    NULL::float   AS   distancia_torre_acceso_points_optima,
    20000::float AS distancia_partners,   
    tr.optimal_transport_id         AS torre_transporte,
    ROUND(((tr.distance_optimal_transport_m)::NUMERIC / (1000)::NUMERIC), 2) AS
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
    it.geom::geometry                 AS geom_torre_transporte,
    ST_Makeline(s.geom::geometry,it.geom::geometry) AS geom_line_torre_transporte,
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
    tr.distance_others_transport_m   AS  distancia_torre_transporte_otros_optima,
    sp.torre_acceso_partners AS torre_acceso_partners 
FROM
    {schema}.settlements s
LEFT JOIN
    (SELECT * FROM {schema}.clusters_links) c
ON
    c.node_2_id = s.settlement_id
LEFT JOIN 
     (SELECT p.*,
        ST_Distance(i.geom::geography, s.geom::geography) as distance_m
        FROM ( SELECT tower_id, UNNEST(string_to_array(settlement_ids_distributed,', ')) as settlement_id
        FROM {schema}.indirect_covered_population) p
        LEFT JOIN {schema}.settlements s 
        on p.settlement_id=s.settlement_id
        left join {schema}.infrastructure_global i 
        on i.tower_id=p.tower_id)   p
ON 
        p.settlement_id=s.settlement_id
LEFT JOIN
    {schema}.infrastructure_global ic
ON
     ic.tower_id::TEXT = c.centroid
LEFT JOIN
    {schema}.infrastructure_global ip
ON
    ip.tower_id = p.tower_id
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
    (c.centroid::TEXT = tr.centroid OR ip.tower_id::TEXT = tr.centroid)
LEFT JOIN
    {schema}.infrastructure_global it
ON
    it.tower_id = tr.optimal_transport_id
LEFT JOIN
(SELECT  string_agg(distinct(partners),';') as torre_acceso_partners, n.geom
        FROM (select s.settlement_id,s.geom, sp.settlement_name, sp.admin_division_2_id,
           CASE WHEN (sp.partners IS NULL OR sp.partners LIKE '%%Sin presencia aliado%%') THEN NULL::text ELSE sp.partners END AS partners
           FROM {schema}.settlements s         
           LEFT JOIN {schema}.settlements_partners sp
           on ST_DWithin(sp.geom::geography, s.geom::geography, 20000) ) n 
GROUP BY  n.geom) sp 
on  sp.geom = s.geom;