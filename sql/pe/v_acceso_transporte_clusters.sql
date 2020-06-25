CREATE OR REPLACE VIEW
    {schema}.v_acceso_transporte_clusters
    (
        cluster_id,
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
    tr.ubigeo AS cluster_id,
    tr.ubigeo,
    tr.torre_acceso,
    tr.km_dist_torre_acceso,
    tr.los_acceso_transporte,
    tr.owner_torre_acceso,
    tr.altura_torre_acceso,
    tr.tipo_torre_acceso,
    tr.vendor_torre_acceso,
    tr.tecnologia_torre_acceso,
    tr.torre_acceso_4g,
    tr.torre_acceso_3g,
    tr.torre_acceso_2g,
    tr.torre_acceso_source,
    tr.torre_acceso_internal_id,
    tr.torre_acceso_perimetro_ipt,
    tr.torre_acceso_tower_name,
    tr.latitude_torre_acceso,
    tr.longitude_torre_acceso,
    tr.geom_torre_acceso,
    tr.geom_line_torre_acceso,
    tr.geom_line_trasnporte_torre_acceso,
    tr.torre_transporte,
    tr.km_dist_torre_transporte,
    tr.owner_torre_transporte,
    tr.altura_torre_transporte,
    tr.tipo_torre_transporte,
    tr.banda_satelite_torre_transporte,
    tr.torre_transporte_fibra,
    tr.torre_transporte_radio,
    tr.torre_transporte_satellite,
    tr.torre_transporte_source,
    tr.torre_transporte_internal_id,
    tr.torre_transporte_perimetro_ipt,
    tr.torre_transporte_tower_name,
    tr.latitude_torre_transporte,
    tr.longitude_torre_transporte,
    tr.geom_torre_transporte,
    tr.geom_line_torre_transporte
FROM
    (
    (
        SELECT
            clusters.centroid,
            clusters.centroid_weight,
            clusters.nodes,
            clusters.cluster_weight,
            clusters.cluster_size
        FROM
            {schema}.clusters
        WHERE
            (
                clusters.centroid IN
                (
                    SELECT
                        v_acceso_transporte.ubigeo
                    FROM
                        {schema}.v_acceso_transporte))) c
LEFT JOIN
    {schema}.v_acceso_transporte tr
ON
    ((
            c.centroid = tr.ubigeo)))
UNION
SELECT DISTINCT
ON
    (
        c.centroid) c.centroid AS cluster_id,
    NULL::text                 AS ubigeo,
    tr.torre_acceso,
    (0)::DOUBLE PRECISION AS km_dist_torre_acceso,
    tr.los_acceso_transporte,
    tr.owner_torre_acceso,
    tr.altura_torre_acceso,
    tr.tipo_torre_acceso,
    tr.vendor_torre_acceso,
    tr.tecnologia_torre_acceso,
    tr.torre_acceso_4g,
    tr.torre_acceso_3g,
    tr.torre_acceso_2g,
    tr.torre_acceso_source,
    tr.torre_acceso_internal_id,
    tr.torre_acceso_perimetro_ipt,
    tr.torre_acceso_tower_name,
    tr.latitude_torre_acceso,
    tr.longitude_torre_acceso,
    tr.geom_torre_acceso,
    tr.geom_line_torre_acceso,
    tr.geom_line_trasnporte_torre_acceso,
    tr.torre_transporte,
    tr.km_dist_torre_transporte,
    tr.owner_torre_transporte,
    tr.altura_torre_transporte,
    tr.tipo_torre_transporte,
    tr.banda_satelite_torre_transporte,
    tr.torre_transporte_fibra,
    tr.torre_transporte_radio,
    tr.torre_transporte_satellite,
    tr.torre_transporte_source,
    tr.torre_transporte_internal_id,
    tr.torre_transporte_perimetro_ipt,
    tr.torre_transporte_tower_name,
    tr.latitude_torre_transporte,
    tr.longitude_torre_transporte,
    tr.geom_torre_transporte,
    tr.geom_line_torre_transporte
FROM
    (
    (
        SELECT
            clusters.centroid,
            clusters.centroid_weight,
            clusters.nodes,
            clusters.cluster_weight,
            clusters.cluster_size
        FROM
            {schema}.clusters
        WHERE
            (
                clusters.centroid IN
                (
                    SELECT
                        (v_acceso_transporte.torre_acceso)::text AS torre_acceso
                    FROM
                        {schema}.v_acceso_transporte))) c
LEFT JOIN
    {schema}.v_acceso_transporte tr
ON
    ((
            c.centroid = (tr.torre_acceso)::text)));