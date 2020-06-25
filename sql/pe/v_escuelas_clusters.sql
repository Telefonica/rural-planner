CREATE OR REPLACE VIEW
    {schema}.v_escuelas_clusters
    (
        centroide,
        nodos_cluster,
        num_escuelas_cluster,
        num_alumnos_cluster,
        num_escuelas_cluster_edu_inicial,
        num_alumnos_cluster_edu_inicial,
        num_escuelas_cluster_edu_primaria,
        num_alumnos_cluster_edu_primaria,
        num_escuelas_cluster_edu_secundaria,
        num_alumnos_cluster_edu_secundaria,
        num_escuelas_cluster_edu_superior,
        num_alumnos_cluster_edu_superior,
        num_escuelas_cluster_otros,
        num_alumnos_cluster_otros
    ) AS
SELECT DISTINCT
ON
    (
        c.centroid) c.centroid        AS centroide,
    string_agg(c.node, ' , '::text)   AS nodos_cluster,
    SUM(s.direct_total_schools)       AS num_escuelas_cluster,
    SUM(s.direct_total_students)      AS num_alumnos_cluster,
    SUM(s.direct_initial_education)   AS num_escuelas_cluster_edu_inicial,
    SUM(s.direct_initial_students)    AS num_alumnos_cluster_edu_inicial,
    SUM(s.direct_primary_education)   AS num_escuelas_cluster_edu_primaria,
    SUM(s.direct_primary_students)    AS num_alumnos_cluster_edu_primaria,
    SUM(s.direct_secondary_education) AS num_escuelas_cluster_edu_secundaria,
    SUM(s.direct_secondary_students)  AS num_alumnos_cluster_edu_secundaria,
    SUM(s.direct_superior_education)  AS num_escuelas_cluster_edu_superior,
    SUM(s.direct_superior_students)   AS num_alumnos_cluster_edu_superior,
    SUM(s.direct_other_education)     AS num_escuelas_cluster_otros,
    SUM(s.direct_other_students)      AS num_alumnos_cluster_otros
FROM
    (
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
    {schema}.schools_summary s
ON
    ((
            s.settlement_id = c.node)))
GROUP BY
    c.centroid;
