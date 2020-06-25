CREATE OR REPLACE VIEW {schema}.v_clusters
    (
        centroide,
        nombre_centroide,
        tamano_cluster,
        poblacion_no_conectada_movistar,
        poblacion_total,
        poblacion_fully_unconnected,
        tipo_cluster,
        id_nodos_cluster,
        centros_poblados,
        distritos,
        municipios,
        estados,
        latitud,
        longitud,
        geom_centroid,
        geom_nodes,
        geom_links
    ) AS
SELECT  
    c.centroid              AS centroide,
    CASE WHEN cp.centro_poblado IS NOT NULL THEN cp.centro_poblado 
         ELSE i.internal_id END  
                            AS nombre_centroide,
    b.cluster_size          AS tamano_cluster,
    CASE WHEN b.cluster_weight IS NOT NULL THEN b.cluster_weight 
         ELSE 0 END              
                            AS poblacion_no_conectada_movistar,
    ROUND(SUM(k.poblacion)) AS poblacion_total,
    ROUND(SUM(CASE WHEN cov.competitors_3g_corrected IS FALSE AND cov.competitors_4g_corrected IS FALSE THEN k.poblacion 
              ELSE 0 END))  AS poblacion_fully_unconnected,
    a.node_type             AS tipo_cluster,
    string_agg(c.node, ' , '::text)                    AS id_nodos_cluster,
    string_agg(DISTINCT k.centro_poblado, ' , '::text) AS centros_poblados,
    string_agg(DISTINCT k.distrito, ' , '::text)       AS distritos,
    string_agg(DISTINCT k.municipio, ' , '::text)      AS municipios,
    string_agg(DISTINCT k.estado, ' , '::text)         AS estados,
    b.latitud,
    b.longitud,
    c.geom_centroid,
    array_agg(c.geom_node)  AS geom_nodes,
    array_agg(c.geom_line)  AS geom_links
FROM
    (((
        (SELECT
            clusters_links.centroid,
            clusters_links.geom_centroid,
            clusters_links.geom_node,
            clusters_links.geom_line,
            CASE
                WHEN (((clusters_links.node_2_id IS NULL)
                               OR (LENGTH(btrim(clusters_links.node_2_id)) = 0))
                        OR (clusters_links.node_2_id = ''::text))
                THEN clusters_links.centroid
                ELSE clusters_links.node_2_id
            END AS node
        FROM {schema}.clusters_links) c
        LEFT JOIN {schema}.v_centros_poblados k
        ON ((k.codigo_setor = c.node)))
        LEFT JOIN 
                ( SELECT
                     cl.centroid,
                     cl.cluster_size,
                     cl.cluster_weight,
                     CASE
                          WHEN (cl.centroid IN ( SELECT (infrastructure_global.tower_id)::text AS tower_id
                                                 FROM {schema}.infrastructure_global)) THEN t.latitude
                          WHEN (cl.centroid IN ( SELECT v_centros_poblados.codigo_setor
                                                 FROM {schema}.v_centros_poblados)) THEN c_1.latitude
                          ELSE NULL::DOUBLE PRECISION
                     END AS latitud,
                     CASE
                          WHEN (cl.centroid IN ( SELECT (infrastructure_global.tower_id)::text AS tower_id
                                                 FROM {schema}.infrastructure_global)) THEN t.longitude
                          WHEN (cl.centroid IN ( SELECT v_centros_poblados.codigo_setor
                                                 FROM {schema}.v_centros_poblados)) THEN c_1.longitude
                          ELSE NULL::DOUBLE PRECISION
                     END AS longitud
                  FROM (({schema}.clusters cl
                         LEFT JOIN
                                {schema}.v_centros_poblados c_1
                         ON ((
                                cl.centroid = c_1.codigo_setor)))
                         LEFT JOIN
                                {schema}.infrastructure_global t
                         ON ((
                                cl.centroid = (t.tower_id)::text)))) b
                         ON ((
                                b.centroid = c.centroid)))
    LEFT JOIN {schema}.node_table a
         ON ((
                a.node_id = c.centroid))
    LEFT JOIN {schema}.coverage cov
         ON cov.settlement_id=k.codigo_setor
    LEFT JOIN {schema}.v_centros_poblados cp
         ON cp.codigo_setor=b.centroid
    LEFT JOIN {schema}.infrastructure_global i
         ON i.tower_id::text=b.centroid)
GROUP BY
    c.centroid,
    b.cluster_size,
    b.cluster_weight,
    a.node_type,
    b.latitud,
    b.longitud,
    c.geom_centroid,
    cp.centro_poblado,
    i.internal_id;
