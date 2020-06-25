CREATE MATERIALIZED VIEW {schema}.v_coberturas_clusters_north_zrd AS
SELECT
    d.centroid,
    n.centroid_name,
    d.competitors_presence_2g,
    d.competitors_presence_3g,
    d.competitors_presence_4g,
    d.cluster_weight
FROM
    (
    (
        SELECT DISTINCT
        ON
            (
                c.centroid) c.centroid,
            CASE
                WHEN (c.cluster_weight = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((ROUND(SUM(c.population_competitors_2g)))::NUMERIC / (c.cluster_weight)
                    ::NUMERIC), 2)
            END AS competitors_presence_2g,
            CASE
                WHEN (c.cluster_weight = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((ROUND(SUM(c.population_competitors_3g)))::NUMERIC / (c.cluster_weight)
                    ::NUMERIC), 2)
            END AS competitors_presence_3g,
            CASE
                WHEN (c.cluster_weight = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((ROUND(SUM(c.population_competitors_4g)))::NUMERIC / (c.cluster_weight)
                    ::NUMERIC), 2)
            END AS competitors_presence_4g,
            c.cluster_weight
        FROM
            (
                SELECT
                    b.centroid,
                    b.settlement_id,
                    b.cluster_weight,
                    CASE
                        WHEN (b.vivo_4g_corrected IS TRUE)
                        THEN (0)::DOUBLE PRECISION
                        WHEN (b.competitors_2g_corrected IS TRUE)
                        THEN b.population_corrected
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_competitors_2g,
                    CASE
                        WHEN (b.vivo_4g_corrected IS TRUE)
                        THEN (0)::DOUBLE PRECISION
                        WHEN (b.competitors_3g_corrected IS TRUE)
                        THEN b.population_corrected
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_competitors_3g,
                    CASE
                        WHEN (b.vivo_4g_corrected IS TRUE)
                        THEN (0)::DOUBLE PRECISION
                        WHEN (b.competitors_4g_corrected IS TRUE)
                        THEN b.population_corrected
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_competitors_4g
                FROM
                    (
                        SELECT DISTINCT
                        ON
                            (
                                c_1.centroid, s.settlement_id) c_1.centroid,
                            c_1.cluster_weight,
                            c_1.nodes,
                            cv.settlement_id,
                            cv.claro_2g_regulator,
                            cv.claro_3g_regulator,
                            cv.claro_4g_regulator,
                            cv.claro_2g_indirect,
                            cv.claro_3g_indirect,
                            cv.claro_4g_indirect,
                            cv.claro_2g_app,
                            cv.claro_3g_app,
                            cv.claro_4g_app,
                            cv.claro_2g_corrected,
                            cv.claro_3g_corrected,
                            cv.claro_4g_corrected,
                            cv.oi_2g_regulator,
                            cv.oi_3g_regulator,
                            cv.oi_4g_regulator,
                            cv.oi_2g_indirect,
                            cv.oi_3g_indirect,
                            cv.oi_4g_indirect,
                            cv.oi_2g_app,
                            cv.oi_3g_app,
                            cv.oi_4g_app,
                            cv.oi_2g_corrected,
                            cv.oi_3g_corrected,
                            cv.oi_4g_corrected,
                            cv.tim_2g_regulator,
                            cv.tim_3g_regulator,
                            cv.tim_4g_regulator,
                            cv.tim_2g_indirect,
                            cv.tim_3g_indirect,
                            cv.tim_4g_indirect,
                            cv.tim_2g_app,
                            cv.tim_3g_app,
                            cv.tim_4g_app,
                            cv.tim_2g_corrected,
                            cv.tim_3g_corrected,
                            cv.tim_4g_corrected,
                            cv.vivo_2g_regulator,
                            cv.vivo_3g_regulator,
                            cv.vivo_4g_regulator,
                            cv.vivo_2g_indirect,
                            cv.vivo_3g_indirect,
                            cv.vivo_4g_indirect,
                            cv.vivo_2g_app,
                            cv.vivo_3g_app,
                            cv.vivo_4g_app,
                            cv.vivo_2g_corrected,
                            cv.vivo_3g_corrected,
                            cv.vivo_4g_corrected,
                            cv.competitors_2g_app,
                            cv.competitors_3g_app,
                            cv.competitors_4g_app,
                            cv.competitors_2g_corrected,
                            cv.competitors_3g_corrected,
                            cv.competitors_4g_corrected,
                            s.population_corrected
                        FROM
                            ((
                            (
                                SELECT
                                    clusters_north_zrd.centroid,
                                    clusters_north_zrd.cluster_weight,
                                    CASE
                                        WHEN (clusters_north_zrd.nodes = ''::text)
                                        THEN NULL::text
                                        ELSE btrim(unnest(string_to_array(REPLACE
                                            (clusters_north_zrd.nodes, ''''::text, ''::text), ','::
                                            text)))
                                    END AS nodes
                                FROM
                                    {schema}.clusters_north_zrd
                                UNION
                                SELECT
                                    clusters_north_zrd.centroid,
                                    clusters_north_zrd.cluster_weight,
                                    clusters_north_zrd.centroid AS nodes
                                FROM
                                    {schema}.clusters_north_zrd) c_1
                        LEFT JOIN
                            (SELECT * FROM {schema}.coverage
                            UNION SELECT * FROM {schema}.coverage_zrd) cv
                        ON
                            ((
                                    cv.settlement_id = c_1.nodes)))
                        LEFT JOIN 
                             (SELECT * FROM {schema}.settlements
                            UNION SELECT * FROM {schema}.settlements_zrd) s
                        ON
                            ((
                                    s.settlement_id = c_1.nodes)))
                        WHERE
                            (
                                c_1.nodes IS NOT NULL)) b) c
        GROUP BY
            c.centroid,
            c.cluster_weight) d
LEFT JOIN
    (
        SELECT
            (infrastructure_global.tower_id)::text AS centroid_id,
            infrastructure_global.internal_id      AS centroid_name
        FROM
            {schema}.infrastructure_global
        UNION
        SELECT
            settlements.settlement_id AS centroid_id,
            settlements.settlement_id AS centroid_name
        FROM
            {schema}.settlements
        UNION
        SELECT
            settlements_zrd.settlement_id AS centroid_id,
            settlements_zrd.settlement_id AS centroid_name
        FROM
            {schema}.settlements_zrd) n
ON
    ((
            d.centroid = n.centroid_id)));
