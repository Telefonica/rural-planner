CREATE MATERIALIZED VIEW {schema}.v_coberturas_clusters_north_all AS
SELECT
    d.centroid,
    n.centroid_name,
    d.vivo_presence_2g,
    d.vivo_presence_3g,
    d.vivo_presence_4g,
    d.competitors_presence_2g,
    d.competitors_presence_3g,
    d.competitors_presence_4g
FROM
    (
    (
        SELECT DISTINCT
        ON
            (
                c.centroid) c.centroid,
            CASE
                WHEN (SUM(c.population_corrected) = (0)::DOUBLE PRECISION)
                THEN (0)::NUMERIC
                ELSE ROUND(((ROUND(SUM(c.population_vivo_2g)))::NUMERIC / (SUM
                    (c.population_corrected))::NUMERIC), 2)
            END AS vivo_presence_2g,
            CASE
                WHEN (SUM(c.population_corrected) = (0)::DOUBLE PRECISION)
                THEN (0)::NUMERIC
                ELSE ROUND(((ROUND(SUM(c.population_vivo_3g)))::NUMERIC / (SUM
                    (c.population_corrected))::NUMERIC), 2)
            END AS vivo_presence_3g,
            CASE
                WHEN (SUM(c.population_corrected) = (0)::DOUBLE PRECISION)
                THEN (0)::NUMERIC
                ELSE ROUND(((ROUND(SUM(c.population_vivo_4g)))::NUMERIC / (SUM
                    (c.population_corrected))::NUMERIC), 2)
            END AS vivo_presence_4g,
            CASE
                WHEN (SUM(c.population_corrected) = (0)::DOUBLE PRECISION)
                THEN (0)::NUMERIC
                ELSE ROUND(((ROUND(SUM(c.population_competitors_2g)))::NUMERIC / (SUM
                    (c.population_corrected))::NUMERIC), 2)
            END AS competitors_presence_2g,
            CASE
                WHEN (SUM(c.population_corrected) = (0)::DOUBLE PRECISION)
                THEN (0)::NUMERIC
                ELSE ROUND(((ROUND(SUM(c.population_competitors_3g)))::NUMERIC / (SUM
                    (c.population_corrected))::NUMERIC), 2)
            END AS competitors_presence_3g,
            CASE
                WHEN (SUM(c.population_corrected) = (0)::DOUBLE PRECISION)
                THEN (0)::NUMERIC
                ELSE ROUND(((ROUND(SUM(c.population_competitors_4g)))::NUMERIC / (SUM
                    (c.population_corrected))::NUMERIC), 2)
            END AS competitors_presence_4g
        FROM
            (
                SELECT
                    b.centroid,
                    b.settlement_id,
                    b.population_corrected,
                    CASE
                        WHEN (b.vivo_2g_corrected IS TRUE)
                        THEN b.population_corrected
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_vivo_2g,
                    CASE
                        WHEN (b.vivo_3g_corrected IS TRUE)
                        THEN b.population_corrected
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_vivo_3g,
                    CASE
                        WHEN (b.vivo_4g_corrected IS TRUE)
                        THEN b.population_corrected
                        ELSE (0)::DOUBLE PRECISION
                    END AS population_vivo_4g,
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
                                    clusters_north.centroid,
                                    clusters_north.cluster_weight,
                                    CASE
                                        WHEN (clusters_north.nodes = ''::text)
                                        THEN NULL::text
                                        ELSE btrim(unnest(string_to_array(REPLACE
                                            (clusters_north.nodes, ''''::text, ''::text), ','::text
                                            )))
                                    END AS nodes
                                FROM
                                    {schema}.clusters_north
                                UNION
                                SELECT
                                    clusters_north.centroid,
                                    clusters_north.cluster_weight,
                                    clusters_north.centroid AS nodes
                                FROM
                                    {schema}.clusters_north
                                UNION
                                SELECT
                                    clusters_north_3g.centroid,
                                    clusters_north_3g.cluster_weight,
                                    CASE
                                        WHEN (clusters_north_3g.nodes = ''::text)
                                        THEN NULL::text
                                        ELSE btrim(unnest(string_to_array(REPLACE
                                            (clusters_north_3g.nodes, ''''::text, ''::text), ','::
                                            text)))
                                    END AS nodes
                                FROM
                                    {schema}.clusters_north_3g
                                UNION
                                SELECT
                                    clusters_north_3g.centroid,
                                    clusters_north_3g.cluster_weight,
                                    clusters_north_3g.centroid AS nodes
                                FROM
                                    {schema}.clusters_north_3g) c_1
                        LEFT JOIN
                            (
                                SELECT
                                    coverage.settlement_id,
                                    coverage.claro_2g_regulator,
                                    coverage.claro_3g_regulator,
                                    coverage.claro_4g_regulator,
                                    coverage.claro_2g_indirect,
                                    coverage.claro_3g_indirect,
                                    coverage.claro_4g_indirect,
                                    coverage.claro_2g_app,
                                    coverage.claro_3g_app,
                                    coverage.claro_4g_app,
                                    coverage.claro_2g_corrected,
                                    coverage.claro_3g_corrected,
                                    coverage.claro_4g_corrected,
                                    coverage.oi_2g_regulator,
                                    coverage.oi_3g_regulator,
                                    coverage.oi_4g_regulator,
                                    coverage.oi_2g_indirect,
                                    coverage.oi_3g_indirect,
                                    coverage.oi_4g_indirect,
                                    coverage.oi_2g_app,
                                    coverage.oi_3g_app,
                                    coverage.oi_4g_app,
                                    coverage.oi_2g_corrected,
                                    coverage.oi_3g_corrected,
                                    coverage.oi_4g_corrected,
                                    coverage.tim_2g_regulator,
                                    coverage.tim_3g_regulator,
                                    coverage.tim_4g_regulator,
                                    coverage.tim_2g_indirect,
                                    coverage.tim_3g_indirect,
                                    coverage.tim_4g_indirect,
                                    coverage.tim_2g_app,
                                    coverage.tim_3g_app,
                                    coverage.tim_4g_app,
                                    coverage.tim_2g_corrected,
                                    coverage.tim_3g_corrected,
                                    coverage.tim_4g_corrected,
                                    coverage.vivo_2g_regulator,
                                    coverage.vivo_3g_regulator,
                                    coverage.vivo_4g_regulator,
                                    coverage.vivo_2g_indirect,
                                    coverage.vivo_3g_indirect,
                                    coverage.vivo_4g_indirect,
                                    coverage.vivo_2g_app,
                                    coverage.vivo_3g_app,
                                    coverage.vivo_4g_app,
                                    coverage.vivo_2g_corrected,
                                    coverage.vivo_3g_corrected,
                                    coverage.vivo_4g_corrected,
                                    coverage.competitors_2g_app,
                                    coverage.competitors_3g_app,
                                    coverage.competitors_4g_app,
                                    coverage.competitors_2g_corrected,
                                    coverage.competitors_3g_corrected,
                                    coverage.competitors_4g_corrected
                                FROM
                                    {schema}.coverage) cv
                        ON
                            ((
                                    cv.settlement_id = c_1.nodes)))
                        LEFT JOIN
                            (
                                SELECT
                                    settlements.settlement_id,
                                    settlements.settlement_name,
                                    settlements.admin_division_1_id,
                                    settlements.admin_division_1_name,
                                    settlements.admin_division_2_id,
                                    settlements.admin_division_2_name,
                                    settlements.admin_division_3_id,
                                    settlements.admin_division_3_name,
                                    settlements.population_census,
                                    settlements.population_corrected,
                                    settlements.latitude,
                                    settlements.longitude,
                                    settlements.geom
                                FROM
                                    {schema}.settlements) s
                        ON
                            ((
                                    s.settlement_id = c_1.nodes)))
                        WHERE
                            (
                                c_1.nodes IS NOT NULL)) b) c
        GROUP BY
            c.centroid) d
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
            {schema}.settlements) n
ON
    ((
            d.centroid = n.centroid_id)));
