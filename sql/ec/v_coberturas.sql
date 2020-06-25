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
        cnt_2g,
        cnt_3g,
        cnt_4g,
        cobertura_cnt,
        cobertura_competidores
    ) AS
SELECT
    c.settlement_id         AS codigo_divipola,
    c.movistar_2g_corrected AS movistar_2g,
    c.movistar_3g_corrected AS movistar_3g,
    c.movistar_4g_corrected AS movistar_4g,
    CASE
        WHEN ((c.movistar_4g_corrected
                AND c.movistar_3g_corrected)
            AND c.movistar_2g_corrected)
        THEN '4G+3G+2G'::text
        WHEN (c.movistar_4g_corrected
            AND c.movistar_3g_corrected)
        THEN '4G+3G'::text
        WHEN (c.movistar_4g_corrected
            AND c.movistar_2g_corrected)
        THEN '4G+2G'::text
        WHEN (c.movistar_3g_corrected
            AND c.movistar_2g_corrected)
        THEN '3G+2G'::text
        WHEN c.movistar_4g_corrected
        THEN '4G'::text
        WHEN c.movistar_3g_corrected
        THEN '3G'::text
        WHEN c.movistar_2g_corrected
        THEN '2G'::text
        ELSE '-'::text
    END                  AS cobertura_movistar,
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
    c.cnt_2g_corrected AS cnt_2g,
    c.cnt_3g_corrected AS cnt_3g,
    c.cnt_4g_corrected AS cnt_4g,
    CASE
        WHEN ((c.cnt_4g_corrected
                AND c.cnt_3g_corrected)
            AND c.cnt_2g_corrected)
        THEN '4G+3G+2G'::text
        WHEN (c.cnt_4g_corrected
            AND c.cnt_3g_corrected)
        THEN '4G+3G'::text
        WHEN (c.cnt_4g_corrected
            AND c.cnt_2g_corrected)
        THEN '4G+2G'::text
        WHEN (c.cnt_3g_corrected
            AND c.cnt_2g_corrected)
        THEN '3G+2G'::text
        WHEN c.cnt_4g_corrected
        THEN '4G'::text
        WHEN c.cnt_3g_corrected
        THEN '3G'::text
        WHEN c.cnt_2g_corrected
        THEN '2G'::text
        ELSE '-'::text
    END                     AS cobertura_cnt,
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
    {schema}.coverage c;
