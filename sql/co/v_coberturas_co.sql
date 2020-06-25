CREATE OR REPLACE VIEW
    {schema}.v_coberturas
    (
        codigo_divipola,
        movistar_2g,
        movistar_3g,
        movistar_4g,
        cobertura_movistar,
        claro_2g,
        claro_3g,
        claro_4g,
        cobertura_claro,
        claro_roaming_2g,
        claro_roaming_3g,
        claro_roaming_4g,
        roaming_claro,
        tigo_2g,
        tigo_3g,
        tigo_4g,
        cobertura_tigo,
        tigo_roaming_2g,
        tigo_roaming_3g,
        tigo_roaming_4g,
        roaming_tigo,
        cobertura_competidores
    ) AS
SELECT
    c.settlement_id         AS codigo_divipola,
    c.movistar_2g_corrected AS movistar_2g,
    c.movistar_3g_corrected AS movistar_3g,
    c.movistar_4g_corrected AS movistar_4g,
    concat_ws(' , ', z.cobertura_movistar_2g, z.cobertura_movistar_3g, z.cobertura_movistar_4g) AS cobertura_movistar,
    c.claro_2g_corrected AS claro_2g,
    c.claro_3g_corrected AS claro_3g,
    c.claro_4g_corrected AS claro_4g,
    CASE
        WHEN ((c.claro_4g_corrected
                AND c.claro_3g_corrected)
            AND c.claro_2g_corrected)
        THEN '4G+3G+2G'::text
        WHEN (c.claro_4g_corrected
            AND c.claro_3g_corrected)
        THEN '4G+3G'::text
        WHEN (c.claro_4g_corrected
            AND c.claro_2g_corrected)
        THEN '4G+2G'::text
        WHEN (c.claro_3g_corrected
            AND c.claro_2g_corrected)
        THEN '3G+2G'::text
        WHEN c.claro_4g_corrected
        THEN '4G'::text
        WHEN c.claro_3g_corrected
        THEN '3G'::text
        WHEN c.claro_2g_corrected
        THEN '2G'::text
        ELSE '-'::text
    END                   AS cobertura_claro,
    r.claro_roaming_2g AS claro_roaming_2g,
    r.claro_roaming_3g AS claro_roaming_3g,
    r.claro_roaming_4g AS claro_roaming_4g,
    CASE
        WHEN ((r.claro_roaming_4g
                AND r.claro_roaming_3g)
            AND r.claro_roaming_2g)
        THEN '4G+3G+2G'::text
        WHEN (r.claro_roaming_4g
            AND  r.claro_roaming_3g)
        THEN '4G+3G'::text
        WHEN (r.claro_roaming_4g
            AND r.claro_roaming_2g)
        THEN '4G+2G'::text
        WHEN (r.claro_roaming_3g
            AND r.claro_roaming_2g)
        THEN '3G+2G'::text
        WHEN r.claro_roaming_4g
        THEN '4G'::text
        WHEN r.claro_roaming_3g
        THEN '3G'::text
        WHEN r.claro_roaming_2g
        THEN '2G'::text
        ELSE '-'::text
    END                   AS roaming_claro,
    c.tigo_2g_corrected AS tigo_2g,
    c.tigo_3g_corrected AS tigo_3g,
    c.tigo_4g_corrected AS tigo_4g,
    CASE
        WHEN ((c.tigo_4g_corrected
                AND c.tigo_3g_corrected)
            AND c.tigo_2g_corrected)
        THEN '4G+3G+2G'::text
        WHEN (c.tigo_4g_corrected
            AND c.tigo_3g_corrected)
        THEN '4G+3G'::text
        WHEN (c.tigo_4g_corrected
            AND c.tigo_2g_corrected)
        THEN '4G+2G'::text
        WHEN (c.tigo_3g_corrected
            AND c.tigo_2g_corrected)
        THEN '3G+2G'::text
        WHEN c.tigo_4g_corrected
        THEN '4G'::text
        WHEN c.tigo_3g_corrected
        THEN '3G'::text
        WHEN c.tigo_2g_corrected
        THEN '2G'::text
        ELSE '-'::text
    END                     AS cobertura_tigo,
    r.tigo_roaming_2g AS tigo_roaming_2g,
    r.tigo_roaming_3g AS tigo_roaming_3g,
    r.tigo_roaming_4g AS tigo_roaming_4g,
    CASE
        WHEN ((r.tigo_roaming_4g
                AND r.tigo_roaming_3g)
            AND r.tigo_roaming_2g)
        THEN '4G+3G+2G'::text
        WHEN (r.tigo_roaming_4g
            AND  r.tigo_roaming_3g)
        THEN '4G+3G'::text
        WHEN (r.tigo_roaming_4g
            AND r.tigo_roaming_2g)
        THEN '4G+2G'::text
        WHEN (r.tigo_roaming_3g
            AND r.tigo_roaming_2g)
        THEN '3G+2G'::text
        WHEN r.tigo_roaming_4g
        THEN '4G'::text
        WHEN r.tigo_roaming_3g
        THEN '3G'::text
        WHEN r.tigo_roaming_2g
        THEN '2G'::text
        ELSE '-'::text
    END                   AS roaming_claro,
    CASE
        WHEN ((c.competitors_4g_corrected
                AND c.competitors_3g_corrected)
            AND c.competitors_2g_corrected)
        THEN '4G+3G+2G'::text
        WHEN (c.competitors_4g_corrected
            AND c.competitors_3g_corrected)
        THEN '4G+3G'::text
        WHEN (c.competitors_4g_corrected
            AND c.competitors_2g_corrected)
        THEN '4G+2G'::text
        WHEN (c.competitors_3g_corrected
            AND c.competitors_2g_corrected)
        THEN '3G+2G'::text
        WHEN c.competitors_4g_corrected
        THEN '4G'::text
        WHEN c.competitors_3g_corrected
        THEN '3G'::text
        WHEN c.competitors_2g_corrected
        THEN '2G'::text
        ELSE '-'::text
    END AS cobertura_competidores
FROM
    {schema}.coverage c
LEFT JOIN
    {schema}.coverage_roaming r
ON
    c.settlement_id=r.settlement_id
LEFT JOIN ( SELECT c.settlement_id as codigo_divipola,
            CASE WHEN (cy.movistar_2g_regulator IS TRUE) THEN '2G(-90dBm)'
                    WHEN (c.movistar_2g_corrected IS TRUE) THEN '2G(-105dBm)'
                    ELSE NULL END AS cobertura_movistar_2g,
            CASE WHEN (cy.movistar_3g_regulator IS TRUE) THEN '3G(-95dBm)'
                    WHEN (c.movistar_3g_corrected IS TRUE) THEN '3G(-110dBm)'
                    ELSE NULL END AS cobertura_movistar_3g,
            CASE WHEN (cy.movistar_4g_regulator IS TRUE) THEN '4G(-100dBm)'
                    WHEN (c.movistar_4g_corrected IS TRUE) THEN '4G(-115dBm)'
                    ELSE NULL END AS cobertura_movistar_4g
                    FROM {schema}.coverage c
                    LEFT JOIN {schema}.coverage_yellow cy
                    on c.settlement_id=cy.settlement_id) Z
ON z.codigo_divipola=c.settlement_id;
