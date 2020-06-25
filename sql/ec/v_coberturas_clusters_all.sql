CREATE OR REPLACE VIEW {schema}.v_coberturas_clusters_all ( 
centroid,
centroid_name,
competitors_presence_2g,
competitors_presence_3g,
competitors_presence_4g,
ccpp_competitors_2g,
ccpp_competitors_3g,
ccpp_competitors_4g,
cluster_weight,
cluster_size)
AS 
SELECT
    d.centroid,
    n.centroid_name,
    d.competitors_presence_2g,
    d.competitors_presence_3g,
    d.competitors_presence_4g,
    d.ccpp_competitors_2g,
    d.ccpp_competitors_3g,
    d.ccpp_competitors_4g,
    d.cluster_weight, 
    d.cluster_size
FROM
    (
    (
        SELECT DISTINCT
        ON
            (
                c.centroid) c.centroid,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((ROUND(SUM(c.population_competitors_2g)))::NUMERIC / ROUND(SUM(c.population_corrected))
                    ::NUMERIC), 2)
            END AS competitors_presence_2g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((ROUND(SUM(c.population_competitors_3g)))::NUMERIC / ROUND(SUM(c.population_corrected))
                    ::NUMERIC), 2)
            END AS competitors_presence_3g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((ROUND(SUM(c.population_competitors_4g)))::NUMERIC / ROUND(SUM(c.population_corrected))
                    ::NUMERIC), 2)
            END AS competitors_presence_4g,
            SUM(c.competitors_2g) as ccpp_competitors_2g,
            SUM(c.competitors_3g) as ccpp_competitors_3g,
            SUM(c.competitors_4g) as ccpp_competitors_4g,            
            c.cluster_weight,
            c.cluster_size
        FROM
            (
                SELECT
                    b.centroid,
                    b.settlement_id,
                    b.cluster_weight,
                    b.cluster_size,
                    b.population_corrected,
                    CASE
                        WHEN (b.competitors_2g_corrected IS TRUE)
                        THEN b.population_corrected
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_competitors_2g,
                    CASE
                        WHEN (b.competitors_3g_corrected IS TRUE)
                        THEN b.population_corrected
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_competitors_3g,
                    CASE
                        WHEN (b.competitors_4g_corrected IS TRUE)
                        THEN b.population_corrected
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_competitors_4g,
                    CASE WHEN b.competitors_2g_corrected is true then 1 else 0 end as competitors_2g,
                    CASE WHEN b.competitors_3g_corrected is true then 1 else 0 end as competitors_3g,
                    CASE WHEN b.competitors_4g_corrected is true then 1 else 0 end as competitors_4g
                FROM
                    (
                        SELECT DISTINCT
                        ON
                            (
                                c_1.centroid, s.settlement_id) c_1.centroid,
                            c_1.cluster_weight,
                            c_1.cluster_size,
                            c_1.nodes,
                            cv.settlement_id,
                            cv.competitors_2g_corrected,
                            cv.competitors_3g_corrected,
                            cv.competitors_4g_corrected,
                            s.population_corrected,
                            t.access_tower_id
                        FROM
                            ((((
                                SELECT
                                    clusters.centroid,
                                    clusters.cluster_weight,
                                    clusters.cluster_size,
                                    CASE
                                        WHEN (clusters.nodes = ''::text)
                                        THEN NULL::text
                                        ELSE btrim(unnest(string_to_array(REPLACE(clusters.nodes,
                                            ''''::text, ''::text), ','::text)))
                                    END AS nodes
                                FROM
                                    {schema}.clusters
                                UNION
                                SELECT
                                    clusters.centroid,
                                    clusters.cluster_weight,
                                    clusters.cluster_size,
                                    clusters.centroid AS nodes
                                FROM
                                    {schema}.clusters) c_1
                        LEFT JOIN
                            {schema}.coverage cv
                        ON
                            ((
                                    cv.settlement_id = c_1.nodes)))
                        LEFT JOIN
                            {schema}.settlements s
                        ON
                            ((
                                    s.settlement_id = c_1.nodes)))
                        LEFT JOIN
                            {schema}.transport_by_settlement t
                        ON
                            ((
                                    c_1.nodes = t.settlement_id)))
                        WHERE
                            (
                                c_1.nodes IS NOT NULL)) b) c
        GROUP BY
            c.centroid,
            c.cluster_weight,
            c.cluster_size) d
LEFT JOIN
    (
        SELECT
            (infrastructure_global.tower_id)::text AS centroid_id,
            infrastructure_global.tower_name       AS centroid_name
        FROM
            {schema}.infrastructure_global
        UNION
        SELECT
            settlements.settlement_id AS centroid_id,
            settlements.settlement_name AS centroid_name
        FROM
            {schema}.settlements) n
ON
    ((
            d.centroid = n.centroid_id)));
