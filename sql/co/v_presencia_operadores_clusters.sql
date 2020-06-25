CREATE OR REPLACE VIEW
    {schema}.v_presencia_operadores_clusters
    (
        centroid,
        centroid_name,
        internal_id,
        movistar_presence_2g,
        movistar_presence_3g,
        movistar_presence_4g,
        claro_presence_2g,
        claro_presence_3g,
        claro_presence_4g,
        tigo_presence_2g,
        tigo_presence_3g,
        tigo_presence_4g,
        competitors_presence_2g,
        competitors_presence_3g,
        competitors_presence_4g,
        cluster_weight
    ) AS
SELECT
    d.centroid,
    n.centroid_name,
    n.internal_id,
    d.movistar_presence_2g,
    d.movistar_presence_3g,
    d.movistar_presence_4g,
    d.claro_presence_2g,
    d.claro_presence_3g,
    d.claro_presence_4g,
    d.tigo_presence_2g,
    d.tigo_presence_3g,
    d.tigo_presence_4g,
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
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((SUM(c.population_movistar_2g))::NUMERIC / (SUM(c.population_corrected)
                    )::NUMERIC), 2)
            END AS movistar_presence_2g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((SUM(c.population_movistar_3g))::NUMERIC / (SUM(c.population_corrected)
                    )::NUMERIC), 2)
            END AS movistar_presence_3g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((SUM(c.population_movistar_4g))::NUMERIC / (SUM(c.population_corrected)
                    )::NUMERIC), 2)
            END AS movistar_presence_4g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((SUM(c.population_claro_2g))::NUMERIC / (SUM(c.population_corrected))::
                    NUMERIC), 2)
            END AS claro_presence_2g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((SUM(c.population_claro_3g))::NUMERIC / (SUM(c.population_corrected))::
                    NUMERIC), 2)
            END AS claro_presence_3g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((SUM(c.population_claro_4g))::NUMERIC / (SUM(c.population_corrected))::
                    NUMERIC), 2)
            END AS claro_presence_4g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((SUM(c.population_tigo_2g))::NUMERIC / (SUM(c.population_corrected))::
                    NUMERIC), 2)
            END AS tigo_presence_2g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((SUM(c.population_tigo_3g))::NUMERIC / (SUM(c.population_corrected))::
                    NUMERIC), 2)
            END AS tigo_presence_3g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((SUM(c.population_tigo_4g))::NUMERIC / (SUM(c.population_corrected))::
                    NUMERIC), 2)
            END AS tigo_presence_4g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((SUM(c.population_competitors_2g))::NUMERIC / (SUM
                    (c.population_corrected))::NUMERIC), 2)
            END AS competitors_presence_2g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((SUM(c.population_competitors_3g))::NUMERIC / (SUM
                    (c.population_corrected))::NUMERIC), 2)
            END AS competitors_presence_3g,
            CASE
                WHEN (SUM(c.population_corrected) = 0)
                THEN (0)::NUMERIC
                ELSE ROUND(((SUM(c.population_competitors_4g))::NUMERIC / (SUM
                    (c.population_corrected))::NUMERIC), 2)
            END AS competitors_presence_4g,
            c.cluster_weight
        FROM
            (
                SELECT
                    b.centroid,
                    b.settlement_id,
                    b.cluster_weight,
                    b.population_corrected,
                    CASE
                        WHEN (b.movistar_2g_corrected IS TRUE)
                        THEN (b.population_corrected)::DOUBLE PRECISION
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_movistar_2g,
                    CASE
                        WHEN (b.movistar_3g_corrected IS TRUE)
                        THEN (b.population_corrected)::DOUBLE PRECISION
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_movistar_3g,
                    CASE
                        WHEN (b.movistar_4g_corrected IS TRUE)
                        THEN (b.population_corrected)::DOUBLE PRECISION
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_movistar_4g,
                    CASE
                        WHEN (b.claro_2g_corrected IS TRUE)
                        THEN (b.population_corrected)::DOUBLE PRECISION
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_claro_2g,
                    CASE
                        WHEN (b.claro_3g_corrected IS TRUE)
                        THEN (b.population_corrected)::DOUBLE PRECISION
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_claro_3g,
                    CASE
                        WHEN (b.claro_4g_corrected IS TRUE)
                        THEN (b.population_corrected)::DOUBLE PRECISION
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_claro_4g,
                    CASE
                        WHEN (b.tigo_2g_corrected IS TRUE)
                        THEN (b.population_corrected)::DOUBLE PRECISION
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_tigo_2g,
                    CASE
                        WHEN (b.tigo_3g_corrected IS TRUE)
                        THEN (b.population_corrected)::DOUBLE PRECISION
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_tigo_3g,
                    CASE
                        WHEN (b.tigo_4g_corrected IS TRUE)
                        THEN (b.population_corrected)::DOUBLE PRECISION
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_tigo_4g,
                    CASE
                        WHEN (b.competitors_2g_corrected IS TRUE)
                        THEN (b.population_corrected)::DOUBLE PRECISION
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_competitors_2g,
                    CASE
                        WHEN (b.competitors_3g_corrected IS TRUE)
                        THEN (b.population_corrected)::DOUBLE PRECISION
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_competitors_3g,
                    CASE
                        WHEN (b.competitors_4g_corrected IS TRUE)
                        THEN (b.population_corrected)::DOUBLE PRECISION
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
                            cv.tigo_2g_regulator,
                            cv.tigo_3g_regulator,
                            cv.tigo_4g_regulator,
                            cv.tigo_2g_indirect,
                            cv.tigo_3g_indirect,
                            cv.tigo_4g_indirect,
                            cv.tigo_2g_app,
                            cv.tigo_3g_app,
                            cv.tigo_4g_app,
                            cv.tigo_2g_corrected,
                            cv.tigo_3g_corrected,
                            cv.tigo_4g_corrected,
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
                            cv.movistar_2g_regulator,
                            cv.movistar_3g_regulator,
                            cv.movistar_4g_regulator,
                            cv.movistar_2g_indirect,
                            cv.movistar_3g_indirect,
                            cv.movistar_4g_indirect,
                            cv.movistar_2g_app,
                            cv.movistar_3g_app,
                            cv.movistar_4g_app,
                            cv.movistar_2g_corrected,
                            cv.movistar_3g_corrected,
                            cv.movistar_4g_corrected,
                            cv.competitors_2g_app,
                            cv.competitors_3g_app,
                            cv.competitors_4g_app,
                            cv.competitors_2g_corrected,
                            cv.competitors_3g_corrected,
                            cv.competitors_4g_corrected,
                            s.population_corrected,
                            t.access_tower_id
                        FROM
                            (((
                            (
                                SELECT
                                    clusters.centroid,
                                    clusters.cluster_weight,
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
            c.cluster_weight) d
LEFT JOIN
    (
        SELECT
            (infrastructure_global.tower_id)::text AS centroid_id,
            infrastructure_global.tower_name       AS centroid_name,
            infrastructure_global.internal_id
        FROM
            {schema}.infrastructure_global
        UNION
        SELECT
            settlements.settlement_id   AS centroid_id,
            settlements.settlement_name   AS centroid_name,
            settlements.settlement_id AS internal_id
        FROM
            {schema}.settlements) n
ON
    ((
            d.centroid = n.centroid_id)));
