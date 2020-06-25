CREATE OR REPLACE VIEW
    {schema}.v_coberturas
    (
        ubigeo,
        movistar_2g,
        movistar_3g,
        movistar_4g,
        cobertura_movistar,
        claro_2g,
        claro_3g,
        claro_4g,
        cobertura_claro,
        bitel_2g,
        bitel_3g,
        bitel_4g,
        cobertura_bitel,
        entel_2g,
        entel_3g,
        entel_4g,
        cobertura_entel,
        cobertura_competidores
    ) AS
SELECT
    c.settlement_id         AS ubigeo,
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
    c.bitel_2g_corrected AS bitel_2g,
    c.bitel_3g_corrected AS bitel_3g,
    c.bitel_4g_corrected AS bitel_4g,
    CASE
        WHEN ((c.bitel_4g_corrected
                AND c.bitel_3g_corrected)
            AND c.bitel_2g_corrected)
        THEN '4G+3G+2G'::text
        WHEN (c.bitel_4g_corrected
            AND c.bitel_3g_corrected)
        THEN '4G+3G'::text
        WHEN (c.bitel_4g_corrected
            AND c.bitel_2g_corrected)
        THEN '4G+2G'::text
        WHEN (c.bitel_3g_corrected
            AND c.bitel_2g_corrected)
        THEN '3G+2G'::text
        WHEN c.bitel_4g_corrected
        THEN '4G'::text
        WHEN c.bitel_3g_corrected
        THEN '3G'::text
        WHEN c.bitel_2g_corrected
        THEN '2G'::text
        ELSE '-'::text
    END                     AS cobertura_bitel,
    c.entel_2g_corrected AS entel_2g,
    c.entel_3g_corrected AS entel_3g,
    c.entel_4g_corrected AS entel_4g,
    CASE
        WHEN ((c.entel_4g_corrected
                AND c.entel_3g_corrected)
            AND c.entel_2g_corrected)
        THEN '4G+3G+2G'::text
        WHEN (c.entel_4g_corrected
            AND c.entel_3g_corrected)
        THEN '4G+3G'::text
        WHEN (c.entel_4g_corrected
            AND c.entel_2g_corrected)
        THEN '4G+2G'::text
        WHEN (c.entel_3g_corrected
            AND c.entel_2g_corrected)
        THEN '3G+2G'::text
        WHEN c.entel_4g_corrected
        THEN '4G'::text
        WHEN c.entel_3g_corrected
        THEN '3G'::text
        WHEN c.entel_2g_corrected
        THEN '2G'::text
        ELSE '-'::text
    END AS cobertura_entel,
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
