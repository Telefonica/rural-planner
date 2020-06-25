CREATE OR REPLACE VIEW
    {schema}.v_clusters
    (
        centroide,
        tamano_cluster,
        poblacion,
        tipo_cluster,
        id_nodos_cluster,
        centros_poblados,
        distritos,
        provincias,
        regiones,
        orografias,
        latitud,
        longitud,
        geom_centroid,
        geom_nodes,
        geom_links
    ) AS
SELECT DISTINCT
ON
    (
        c.centroid) c.centroid                         AS centroide,
    b.cluster_size                                     AS tamano_cluster,
    b.cluster_weight                                   AS poblacion,
    a.node_type                                        AS tipo_cluster,
    string_agg(c.node, ' , '::text)                    AS id_nodos_cluster,
    string_agg(DISTINCT k.centro_poblado, ' , '::text) AS centros_poblados,
    string_agg(DISTINCT k.distrito, ' , '::text)       AS distritos,
    string_agg(DISTINCT k.provincia, ' , '::text)      AS provincias,
    string_agg(DISTINCT k.region, ' , '::text)         AS regiones,
    string_agg(DISTINCT k.orografia, ' , '::text)      AS orografias,
    b.latitud,
    b.longitud,
    c.geom_centroid,
    array_agg(c.geom_node) AS geom_nodes,
    array_agg(c.geom_line) AS geom_links
FROM
    (((
    (
        SELECT
            clusters_links.centroid,
            clusters_links.geom_centroid,
            clusters_links.geom_node,
            clusters_links.geom_line,
            CASE
                WHEN (((clusters_links.node_2_id IS NULL)
                        OR  (LENGTH(btrim(clusters_links.node_2_id)) = 0))
                    OR  (clusters_links.node_2_id = ''::text))
                THEN clusters_links.centroid
                ELSE clusters_links.node_2_id
            END AS node
        FROM
            {schema}.clusters_links) c
LEFT JOIN
    {schema}.v_centros_poblados k
ON
    ((
            k.ubigeo = c.node)))
LEFT JOIN
    (
        SELECT
            cl.centroid,
            cl.cluster_size,
            cl.cluster_weight,
            CASE
                WHEN (cl.centroid IN
                        (
                            SELECT
                                (infrastructure_global.tower_id)::text AS tower_id
                            FROM
                                {schema}.infrastructure_global))
                THEN t.latitude
                WHEN (cl.centroid IN
                        (
                            SELECT
                                v_centros_poblados.ubigeo
                            FROM
                                {schema}.v_centros_poblados))
                THEN c_1.latitude
                ELSE NULL::DOUBLE PRECISION
            END AS latitud,
            CASE
                WHEN (cl.centroid IN
                        (
                            SELECT
                                (infrastructure_global.tower_id)::text AS tower_id
                            FROM
                                {schema}.infrastructure_global))
                THEN t.longitude
                WHEN (cl.centroid IN
                        (
                            SELECT
                                v_centros_poblados.ubigeo
                            FROM
                                {schema}.v_centros_poblados))
                THEN c_1.longitude
                ELSE NULL::DOUBLE PRECISION
            END AS longitud
        FROM
            (({schema}.clusters cl
        LEFT JOIN
            {schema}.v_centros_poblados c_1
        ON
            ((
                    cl.centroid = c_1.ubigeo)))
        LEFT JOIN
            {schema}.infrastructure_global t
        ON
            ((
                    cl.centroid = (t.tower_id)::text)))) b
ON
    ((
            b.centroid = c.centroid)))
LEFT JOIN
    (
        SELECT
            cl.centroid AS centroid_id,
            CASE
                WHEN (((i.tech_3g IS TRUE)
                        OR  (i.tech_4g IS TRUE))
                    AND (i.fiber IS TRUE))
                THEN 'TOWER 3G+ FIBER'::text
                WHEN (((i.tech_3g IS TRUE)
                        OR  (i.tech_4g IS TRUE))
                    AND (i.fiber IS FALSE))
                THEN 'TOWER 3G+ NOT FIBER'::text
                WHEN ((i.tech_2g IS TRUE)
                    AND (i.fiber IS TRUE))
                THEN 'TOWER 2G FIBER'::text
                WHEN ((i.tech_2g IS TRUE)
                    AND (i.radio IS TRUE))
                THEN 'TOWER 2G RADIO'::text
                WHEN ((i.tech_2g IS TRUE)
                    AND (i.satellite IS TRUE))
                THEN 'TOWER 2G SATELLITE'::text
                ELSE 'TOWER'::text
            END AS node_type
        FROM
            ((({schema}.clusters cl
        JOIN
            {schema}.infrastructure_global i
        ON
            ((
                    cl.centroid = (i.tower_id)::text)))
        LEFT JOIN
            {schema}.transport_by_settlement t
        ON
            ((
                    i.tower_id = t.access_tower_id)))
        LEFT JOIN
            {schema}.coverage c_1
        ON
            ((
                    t.settlement_id = c_1.settlement_id)))
        WHERE
            ((
                    i.tower_id IS NOT NULL)
            AND ((
                        c_1.movistar_3g_corrected IS FALSE)
                AND (
                        c_1.movistar_4g_corrected IS FALSE)))
        GROUP BY
            cl.centroid,
            CASE
                WHEN (((i.tech_3g IS TRUE)
                        OR  (i.tech_4g IS TRUE))
                    AND (i.fiber IS TRUE))
                THEN 'TOWER 3G+ FIBER'::text
                WHEN (((i.tech_3g IS TRUE)
                        OR  (i.tech_4g IS TRUE))
                    AND (i.fiber IS FALSE))
                THEN 'TOWER 3G+ NOT FIBER'::text
                WHEN ((i.tech_2g IS TRUE)
                    AND (i.fiber IS TRUE))
                THEN 'TOWER 2G FIBER'::text
                WHEN ((i.tech_2g IS TRUE)
                    AND (i.radio IS TRUE))
                THEN 'TOWER 2G RADIO'::text
                WHEN ((i.tech_2g IS TRUE)
                    AND (i.satellite IS TRUE))
                THEN 'TOWER 2G SATELLITE'::text
                ELSE 'TOWER'::text
            END
        UNION
        SELECT
            cl.centroid AS centroid_id,
            CASE
                WHEN (((i.tech_3g IS TRUE)
                        OR  (i.tech_4g IS TRUE))
                    AND (i.fiber IS TRUE))
                THEN 'TOWER 3G+ FIBER'::text
                WHEN (((i.tech_3g IS TRUE)
                        OR  (i.tech_4g IS TRUE))
                    AND (i.fiber IS FALSE))
                THEN 'TOWER 3G+ NOT FIBER'::text
                WHEN ((i.tech_2g IS TRUE)
                    AND (i.fiber IS TRUE))
                THEN 'TOWER 2G FIBER'::text
                WHEN ((i.tech_2g IS TRUE)
                    AND (i.radio IS TRUE))
                THEN 'TOWER 2G RADIO'::text
                WHEN ((i.tech_2g IS TRUE)
                    AND (i.satellite IS TRUE))
                THEN 'TOWER 2G SATELLITE'::text
                ELSE 'TOWER'::text
            END AS node_type
        FROM
            ({schema}.infrastructure_global i
        JOIN
            {schema}.clusters cl
        ON
            ((
                    cl.centroid = (i.tower_id)::text)))
        WHERE
            ((
                    NOT (
                        i.tower_id IN
                        (
                            SELECT
                                i_1.tower_id
                            FROM
                                ((({schema}.transport_by_settlement t
                            LEFT JOIN
                                {schema}.settlements s
                            ON
                                ((
                                        s.settlement_id = t.settlement_id)))
                            LEFT JOIN
                                {schema}.infrastructure_global i_1
                            ON
                                ((
                                        i_1.tower_id = t.access_tower_id)))
                            LEFT JOIN
                                {schema}.coverage c_1
                            ON
                                ((
                                        s.settlement_id = c_1.settlement_id)))
                            WHERE
                                ((
                                        i_1.tower_id IS NOT NULL)
                                AND ((
                                            c_1.movistar_3g_corrected IS FALSE)
                                    AND (
                                            c_1.movistar_4g_corrected IS FALSE))))))
            AND (
                    i.owner <> ALL (ARRAY['GILAT'::text, 'AZTECA'::text, 'EHAS'::text])))
        UNION
        SELECT
            cl.centroid AS centroid_id,
            CASE
                WHEN ((c_1.movistar_3g_corrected IS TRUE)
                    OR  (c_1.movistar_4g_corrected IS TRUE))
                THEN 'SETTLEMENT 3G+'::text
                WHEN (c_1.movistar_2g_corrected IS TRUE)
                THEN 'SETTLEMENT 2G'::text
                WHEN (c_1.movistar_2g_corrected IS FALSE)
                THEN 'SETTLEMENT GREENFIELD'::text
                ELSE NULL::text
            END AS node_type
        FROM
            ((({schema}.clusters cl
        JOIN
            {schema}.settlements s
        ON
            ((
                    cl.centroid = s.settlement_id)))
        LEFT JOIN
            {schema}.coverage c_1
        ON
            ((
                    s.settlement_id = c_1.settlement_id)))
        LEFT JOIN
            {schema}.transport_by_settlement t
        ON
            ((
                    s.settlement_id = t.settlement_id)))) a
ON
    ((
            a.centroid_id = c.centroid)))
GROUP BY
    c.centroid,
    b.cluster_size,
    b.cluster_weight,
    a.node_type,
    b.latitud,
    b.longitud,
    c.geom_centroid;
