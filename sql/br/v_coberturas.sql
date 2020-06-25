CREATE OR REPLACE VIEW
    {schema}.v_coberturas
    (
        codigo_setor,
        claro_2g,
        claro_3g,
        claro_4g,
        cobertura_claro,
        oi_2g,
        oi_3g,
        oi_4g,
        cobertura_oi,
        vivo_2g,
        vivo_3g,
        vivo_4g,
        cobertura_vivo,
        tim_2g,
        tim_3g,
        tim_4g,
        cobertura_tim,
        cobertura_competidores
    ) AS
SELECT
    c.settlement_id      AS codigo_setor,
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
    END               AS cobertura_claro,
    c.oi_2g_corrected AS claro_roaming_2g,
    c.oi_3g_corrected AS claro_roaming_3g,
    c.oi_4g_corrected AS claro_roaming_4g,
    CASE
        WHEN ((c.oi_4g_corrected
                AND c.oi_3g_corrected)
            AND c.oi_2g_corrected)
        THEN '4G+3G+2G'::text
        WHEN (c.oi_4g_corrected
            AND  c.oi_3g_corrected)
        THEN '4G+3G'::text
        WHEN (c.oi_4g_corrected
            AND c.oi_2g_corrected)
        THEN '4G+2G'::text
        WHEN (c.oi_3g_corrected
            AND c.oi_2g_corrected)
        THEN '3G+2G'::text
        WHEN c.oi_4g_corrected
        THEN '4G'::text
        WHEN c.oi_3g_corrected
        THEN '3G'::text
        WHEN c.oi_2g_corrected
        THEN '2G'::text
        ELSE '-'::text
    END                 AS cobertura_oi,
    c.vivo_2g_corrected AS vivo_2g,
    c.vivo_3g_corrected AS vivo_3g,
    c.vivo_4g_corrected AS vivo_4g,
    CASE
        WHEN ((c.vivo_4g_corrected
                AND c.vivo_3g_corrected)
            AND c.vivo_2g_corrected)
        THEN '4G+3G+2G'::text
        WHEN (c.vivo_4g_corrected
            AND c.vivo_3g_corrected)
        THEN '4G+3G'::text
        WHEN (c.vivo_4g_corrected
            AND c.vivo_2g_corrected)
        THEN '4G+2G'::text
        WHEN (c.vivo_3g_corrected
            AND c.vivo_2g_corrected)
        THEN '3G+2G'::text
        WHEN c.vivo_4g_corrected
        THEN '4G'::text
        WHEN c.vivo_3g_corrected
        THEN '3G'::text
        WHEN c.vivo_2g_corrected
        THEN '2G'::text
        ELSE '-'::text
    END                     AS cobertura_vivo,
    c.tim_2g_corrected AS tim_2g,
    c.tim_3g_corrected AS tim_3g,
    c.tim_4g_corrected AS tim_4g,
    CASE
        WHEN ((c.tim_4g_corrected
                AND c.tim_3g_corrected)
            AND c.tim_2g_corrected)
        THEN '4G+3G+2G'::text
        WHEN (c.tim_4g_corrected
            AND  c.tim_3g_corrected)
        THEN '4G+3G'::text
        WHEN (c.tim_4g_corrected
            AND c.tim_2g_corrected)
        THEN '4G+2G'::text
        WHEN (c.tim_3g_corrected
            AND c.tim_2g_corrected)
        THEN '3G+2G'::text
        WHEN c.tim_4g_corrected
        THEN '4G'::text
        WHEN c.tim_3g_corrected
        THEN '3G'::text
        WHEN c.tim_2g_corrected
        THEN '2G'::text
        ELSE '-'::text
    END                   AS cobertura_tim,
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