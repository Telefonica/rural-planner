CREATE OR REPLACE VIEW
    {schema}.v_clusters_kpis
    (
        centroide,
        nombre_centroide,
        tipo_centroide,
        id_nodos_cluster,
        centros_poblados,
        regiones,
        zona_exclusividad,
        etapas_enacom,
        plan_2019,
        poblacion_total,
        polacion_unserved,
        latitud,
        longitud
    ) AS
SELECT o.centroid                         AS centroide,
        CASE WHEN s.settlement_name IS NOT NULL THEN s.settlement_name
        ELSE I.internal_id END as nombre_centroide,
        o.centroid_type as tipo_cluster,
        string_agg(c.node, ' , '::text)                    AS id_nodos_cluster,
        string_agg(DISTINCT s2.settlement_name, ' , '::text) AS localidades,   
        string_agg(DISTINCT a.region, ' , '::text) AS regiones, 
        bool_or(a.exclusivity_zone) as zona_exclusividad, 
        string_agg(DISTINCT a.stage, ' , '::text) AS etapas_enacom,         
        bool_or(a.plan_2019) as plan_2019,
        SUM(s2.population_corrected)                                   AS poblacion_total,
        o.cluster_weight as poblacion_unserved,            
        ST_Y(o.geom_centroid::geometry) as latitud,
        ST_X(o.geom_centroid::geometry) as longitud
FROM
    {schema}.clusters o
    LEFT JOIN 
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
ON c.centroid=o.centroid
LEFT JOIN
    {schema}.settlements_kpis a
ON a.settlement_id = c.node
LEFT JOIN {schema}.infrastructure_global i
ON o.centroid=i.tower_id::text
LEFT JOIN {schema}.settlements S
on s.settlement_id=c.centroid
LEFT JOIN {schema}.settlements s2
on s2.settlement_id=c.node
GROUP BY o.centroid, o.centroid_type, o.cluster_weight, o.geom_centroid, s.settlement_name, i.internal_id;
