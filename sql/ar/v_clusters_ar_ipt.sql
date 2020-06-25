CREATE OR REPLACE VIEW
    {schema}.v_clusters_ipt
    (
        centroide,
        nombre_centroide,
        tipo_cluster,
        tamano_cluster,
        poblacion_total,
        poblacion_unserved,
        id_nodos_cluster,
        localidades,
        departamentos,
        provincias,
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
        CASE WHEN s.settlement_name IS NOT NULL THEN s.settlement_name
        ELSE I.internal_id END as nombre_centroide,
        o.centroid_type as tipo_cluster,
    o.cluster_size                                     AS tamano_cluster,
    SUM(k.poblacion)                                   AS poblacion_total,
    o.cluster_weight as poblacion_unserved,       
    string_agg(c.node, ' , '::text)                    AS id_nodos_cluster,
    string_agg(DISTINCT k.localidad, ' , '::text) AS localidades,
    string_agg(DISTINCT k.departamento, ' , '::text)       AS departamentos,
    string_agg(DISTINCT k.provincia, ' , '::text)      AS provincias,
    ST_Y(o.geom_centroid::geometry) as latitud,
    ST_X(o.geom_centroid::geometry) as longitud,
    o.geom_centroid,
    array_agg(c.geom_node) AS geom_nodes,
    array_agg(c.geom_line) AS geom_links
FROM
    {schema}.clusters_ipt o
    LEFT JOIN 
    (
        SELECT
            clusters_ipt_links.centroid,
            CASE
                WHEN (((clusters_ipt_links.node_2_id IS NULL)
                        OR  (LENGTH(btrim(clusters_ipt_links.node_2_id)) = 0))
                    OR  (clusters_ipt_links.node_2_id = ''::text))
                THEN clusters_ipt_links.centroid
                ELSE clusters_ipt_links.node_2_id
            END AS node,
             geom_node,
             geom_line
        FROM
            {schema}.clusters_ipt_links) c
ON c.centroid=o.centroid
LEFT JOIN
    {schema}.v_centros_poblados k
ON k.id_localidad = c.node
LEFT JOIN {schema}.infrastructure_global i
ON o.centroid=i.tower_id::text
LEFT JOIN {schema}.settlements S
on s.settlement_id=c.centroid
GROUP BY c.centroid, o.centroid, o.centroid_type, o.cluster_weight, o.cluster_size, o.geom_centroid, s.settlement_name, i.internal_id;
