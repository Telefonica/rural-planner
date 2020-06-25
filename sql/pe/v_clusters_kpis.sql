CREATE OR REPLACE VIEW
    {schema}.v_clusters_kpis
    (
        centroide,
        id_nodos_cluster,
        centros_poblados,
        orografias,
        viviendas,
        poblacion,
        ratio_acceso_agua,
        ratio_acceso_electricidad,
        ratio_trabajadores,
        ratio_desempleados,
        ratio_no_activos,
        latitud,
        longitud
    ) AS
SELECT DISTINCT
ON
    (
        c.centroid) c.centroid                         AS centroide,
    string_agg(c.node, ' , '::text)                    AS id_nodos_cluster,
    string_agg(DISTINCT k.centro_poblado, ' , '::text) AS centros_poblados,
    string_agg(DISTINCT k.orografia, ' , '::text)      AS orografias,
    SUM(k.viviendas)                                   AS viviendas,
    SUM(k.poblacion)                                   AS poblacion,
    AVG(k.ratio_acceso_agua)                           AS ratio_acceso_agua,
    AVG(k.ratio_acceso_electricidad)                   AS ratio_acceso_electricidad,
    AVG(k.ratio_trabajadores)                          AS ratio_trabajadores,
    AVG(k.ratio_desempleados)                          AS ratio_desempleados,
    AVG(k.ratio_no_activos)                            AS ratio_no_activos,
    b.latitud,
    b.longitud
FROM
    ((
    (
        SELECT
            clusters_links.centroid,
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
GROUP BY
    c.centroid,
    b.latitud,
    b.longitud;
