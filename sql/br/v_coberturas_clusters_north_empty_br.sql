CREATE MATERIALIZED VIEW {schema}.v_coberturas_clusters_north_empty AS
SELECT
    c.centroid,
    c.centroid_name,
    CASE
        WHEN (SUM(c.population_corrected) = 0)
        THEN (0)::NUMERIC
        ELSE ROUND(((ROUND((SUM(c.population_vivo_2g))::DOUBLE PRECISION))::NUMERIC / (SUM
            (c.population_corrected))::NUMERIC), 2)
    END AS vivo_presence_2g,
    CASE
        WHEN (SUM(c.population_corrected) = 0)
        THEN (0)::NUMERIC
        ELSE ROUND(((ROUND((SUM(c.population_vivo_3g))::DOUBLE PRECISION))::NUMERIC / (SUM
            (c.population_corrected))::NUMERIC), 2)
    END AS vivo_presence_3g,
    CASE
        WHEN (SUM(c.population_corrected) = 0)
        THEN (0)::NUMERIC
        ELSE ROUND(((ROUND((SUM(c.population_vivo_4g))::DOUBLE PRECISION))::NUMERIC / (SUM
            (c.population_corrected))::NUMERIC), 2)
    END AS vivo_presence_4g,
    CASE
        WHEN (SUM(c.population_corrected) = 0)
        THEN (0)::NUMERIC
        ELSE ROUND(((ROUND((SUM(c.population_competitors_2g))::DOUBLE PRECISION))::NUMERIC / (SUM
            (c.population_corrected))::NUMERIC), 2)
    END AS competitors_presence_2g,
    CASE
        WHEN (SUM(c.population_corrected) = 0)
        THEN (0)::NUMERIC
        ELSE ROUND(((ROUND((SUM(c.population_competitors_3g))::DOUBLE PRECISION))::NUMERIC / (SUM
            (c.population_corrected))::NUMERIC), 2)
    END AS competitors_presence_3g,
    CASE
        WHEN (SUM(c.population_corrected) = 0)
        THEN (0)::NUMERIC
        ELSE ROUND(((ROUND((SUM(c.population_competitors_4g))::DOUBLE PRECISION))::NUMERIC / (SUM
            (c.population_corrected))::NUMERIC), 2)
    END AS competitors_presence_4g
FROM
    (
        SELECT
            r.ran_centroid AS centroid,
            t.internal_id  AS centroid_name,
            r.ran_weight   AS population_corrected,
            CASE
                WHEN ((r.competitors_2g_regulator
                        OR  i.competitors_2g_indirect)
                    OR  b.competitors_2g_app)
                THEN r.ran_weight
                ELSE 0
            END AS population_competitors_2g,
            CASE
                WHEN ((r.competitors_3g_regulator
                        OR  i.competitors_3g_indirect)
                    OR  b.competitors_3g_app)
                THEN r.ran_weight
                ELSE 0
            END AS population_competitors_3g,
            CASE
                WHEN ((r.competitors_4g_regulator
                        OR  i.competitors_4g_indirect)
                    OR  b.competitors_4g_app)
                THEN r.ran_weight
                ELSE 0
            END AS population_competitors_4g,
            CASE
                WHEN (t.tech_2g IS TRUE)
                THEN r.ran_weight
                ELSE 0
            END AS population_vivo_2g,
            CASE
                WHEN (t.tech_3g IS TRUE)
                THEN r.ran_weight
                ELSE 0
            END AS population_vivo_3g,
            CASE
                WHEN (t.tech_4g IS TRUE)
                THEN r.ran_weight
                ELSE 0
            END AS population_vivo_4g
        FROM
            (((
            (
                SELECT
                    s.ran_centroid,
                    s.centroid_name,
                    s.admin_division_3_id,
                    s.admin_division_3_name,
                    s.admin_division_2_id,
                    s.admin_division_2_name,
                    s.ddd,
                    s.ran_weight,
                    s.ran_size,
                    s.tamano,
                    s.type,
                    s.centroid_type,
                    s.segment_ov_gf,
                    s.segmento,
                    s.tx_movistar,
                    s.tx_regional,
                    s.tx_third_pty,
                    s.geom,
                    false                            AS competitors_2g_regulator,
                    st_contains(c_1.geom_3g, s.geom) AS competitors_3g_regulator,
                    st_contains(c_1.geom_4g, s.geom) AS competitors_4g_regulator
                FROM
                    (
                        SELECT
                            a.ran_centroid,
                            a.centroid_name,
                            a.admin_division_3_id,
                            a.admin_division_3_name,
                            a.admin_division_2_id,
                            a.admin_division_2_name,
                            a.ddd,
                            a.ran_weight,
                            a.ran_size,
                            a.tamano,
                            a.type,
                            a.centroid_type,
                            a.segment_ov_gf,
                            a.segmento,
                            a.tx_movistar,
                            a.tx_regional,
                            a.tx_third_pty,
                            i_1.geom
                        FROM
                            ({schema}.analisis_clusters_ednei_v3 a
                        LEFT JOIN
                            {schema}.infrastructure_global i_1
                        ON
                            ((
                                    a.ran_centroid = (i_1.tower_id)::text)))
                        WHERE
                            (
                                a.centroid_type ~~ '%EMPTY%'::text)) s,
                    {schema}.competitors_coverage_polygons c_1) r
        LEFT JOIN
            (
                SELECT
                    s.ran_centroid,
                    s.centroid_name,
                    s.admin_division_3_id,
                    s.admin_division_3_name,
                    s.admin_division_2_id,
                    s.admin_division_2_name,
                    s.ddd,
                    s.ran_weight,
                    s.ran_size,
                    s.tamano,
                    s.type,
                    s.centroid_type,
                    s.segment_ov_gf,
                    s.segmento,
                    s.tx_movistar,
                    s.tx_regional,
                    s.tx_third_pty,
                    s.geom,
                    st_contains(i_1.coverage_area_2g, st_transform(s.geom, 3857)) AS
                    competitors_2g_indirect,
                    st_contains(i_1.coverage_area_3g, st_transform(s.geom, 3857)) AS
                    competitors_3g_indirect,
                    st_contains(i_1.coverage_area_4g, st_transform(s.geom, 3857)) AS
                    competitors_4g_indirect
                FROM
                    (
                        SELECT
                            a.ran_centroid,
                            a.centroid_name,
                            a.admin_division_3_id,
                            a.admin_division_3_name,
                            a.admin_division_2_id,
                            a.admin_division_2_name,
                            a.ddd,
                            a.ran_weight,
                            a.ran_size,
                            a.tamano,
                            a.type,
                            a.centroid_type,
                            a.segment_ov_gf,
                            a.segmento,
                            a.tx_movistar,
                            a.tx_regional,
                            a.tx_third_pty,
                            i_2.geom
                        FROM
                            ({schema}.analisis_clusters_ednei_v3 a
                        LEFT JOIN
                            {schema}.infrastructure_global i_2
                        ON
                            ((
                                    a.ran_centroid = (i_2.tower_id)::text)))
                        WHERE
                            (
                                a.centroid_type ~~ '%EMPTY%'::text)) s,
                    (
                        SELECT
                            indirect_coverage_polygons.operator_id,
                            indirect_coverage_polygons.coverage_area_2g,
                            indirect_coverage_polygons.coverage_area_3g,
                            indirect_coverage_polygons.coverage_area_4g
                        FROM
                            {schema}.indirect_coverage_polygons
                        WHERE
                            (
                                indirect_coverage_polygons.operator_id = ANY (ARRAY['CLARO'::text,
                                'TIM'::text, 'OI'::text]))) i_1) i
        ON
            ((
                    i.ran_centroid = r.ran_centroid)))
        LEFT JOIN
            (
                SELECT
                    s.ran_centroid,
                    s.centroid_name,
                    s.admin_division_3_id,
                    s.admin_division_3_name,
                    s.admin_division_2_id,
                    s.admin_division_2_name,
                    s.ddd,
                    s.ran_weight,
                    s.ran_size,
                    s.tamano,
                    s.type,
                    s.centroid_type,
                    s.segment_ov_gf,
                    s.segmento,
                    s.tx_movistar,
                    s.tx_regional,
                    s.tx_third_pty,
                    s.geom,
                    st_contains(f2.geom, s.geom) AS competitors_2g_app,
                    st_contains(f3.geom, s.geom) AS competitors_3g_app,
                    st_contains(f4.geom, s.geom) AS competitors_4g_app
                FROM
                    (
                        SELECT
                            a.ran_centroid,
                            a.centroid_name,
                            a.admin_division_3_id,
                            a.admin_division_3_name,
                            a.admin_division_2_id,
                            a.admin_division_2_name,
                            a.ddd,
                            a.ran_weight,
                            a.ran_size,
                            a.tamano,
                            a.type,
                            a.centroid_type,
                            a.segment_ov_gf,
                            a.segmento,
                            a.tx_movistar,
                            a.tx_regional,
                            a.tx_third_pty,
                            i_1.geom
                        FROM
                            ({schema}.analisis_clusters_ednei_v3 a
                        LEFT JOIN
                            {schema}.infrastructure_global i_1
                        ON
                            ((
                                    a.ran_centroid = (i_1.tower_id)::text)))
                        WHERE
                            (
                                a.centroid_type ~~ '%EMPTY%'::text)) s,
                    rural_planner.br_all_coverage_polygon_2g f2,
                    rural_planner.br_all_coverage_polygon_3g f3,
                    rural_planner.br_all_coverage_polygon_4g f4) b
        ON
            ((
                    b.ran_centroid = r.ran_centroid)))
        LEFT JOIN
            {schema}.infrastructure_global t
        ON
            (((
                        t.tower_id)::text = r.ran_centroid)))) c
GROUP BY
    c.centroid,
    c.centroid_name;
