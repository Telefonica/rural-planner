CREATE OR REPLACE VIEW
    {schema}.v_coberturas_ipt
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
        nextel_2g,
        nextel_3g,
        nextel_4g,
        cobertura_nextel,
        personal_2g,
        personal_3g,
        personal_4g,
        cobertura_personal,
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
    c.nextel_2g_corrected AS nextel_2g,
    c.nextel_3g_corrected AS nextel_3g,
    c.nextel_4g_corrected AS nextel_4g,
    CASE
        WHEN ((c.nextel_4g_corrected
                AND c.nextel_3g_corrected)
            AND c.nextel_2g_corrected)
        THEN '4G+3G+2G'::text
        WHEN (c.nextel_4g_corrected
            AND c.nextel_3g_corrected)
        THEN '4G+3G'::text
        WHEN (c.nextel_4g_corrected
            AND c.nextel_2g_corrected)
        THEN '4G+2G'::text
        WHEN (c.nextel_3g_corrected
            AND c.nextel_2g_corrected)
        THEN '3G+2G'::text
        WHEN c.nextel_4g_corrected
        THEN '4G'::text
        WHEN c.nextel_3g_corrected
        THEN '3G'::text
        WHEN c.nextel_2g_corrected
        THEN '2G'::text
        ELSE '-'::text
    END                     AS cobertura_nextel,
    c.personal_2g_corrected AS personal_2g,
    c.personal_3g_corrected AS personal_3g,
    c.personal_4g_corrected AS personal_4g,
    CASE
        WHEN ((c.personal_4g_corrected
                AND c.personal_3g_corrected)
            AND c.personal_2g_corrected)
        THEN '4G+3G+2G'::text
        WHEN (c.personal_4g_corrected
            AND c.personal_3g_corrected)
        THEN '4G+3G'::text
        WHEN (c.personal_4g_corrected
            AND c.personal_2g_corrected)
        THEN '4G+2G'::text
        WHEN (c.personal_3g_corrected
            AND c.personal_2g_corrected)
        THEN '3G+2G'::text
        WHEN c.personal_4g_corrected
        THEN '4G'::text
        WHEN c.personal_3g_corrected
        THEN '3G'::text
        WHEN c.personal_2g_corrected
        THEN '2G'::text
        ELSE '-'::text
    END AS cobertura_personal,
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
    {schema}.coverage_ipt c;