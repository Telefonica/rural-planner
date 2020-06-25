CREATE OR REPLACE VIEW
    {schema}.v_centros_poblados_kpis
    (
        codigo_divipola,
        centro_poblado,
        municipio,
        departamento,
        poblacion,
        escuelas,
        b2bcoffee,
        lluvias,
        latitude,
        longitude,
        geom
    ) AS
SELECT
    s.settlement_id AS codigo_divipola,
    CASE
        WHEN (s.settlement_name IS NOT NULL)
        THEN s.settlement_name
        ELSE concat('CLUSTER ', s.settlement_id)
    END                     AS centro_poblado,
    s.admin_division_1_name AS municipio,
    s.admin_division_2_name AS departamento,
    s.population_corrected  AS poblacion,
    COUNT(sch.internal_id)  AS escuelas,
    CASE WHEN s.settlement_id IN ('73026000','73043000','73067000','73124000','73152000','73168000','73236000','73347000','73408000','73461000','73504000',
                '73555000','73563000','73616000','73622000','73624000','73675000','73686000','73861000',
                '73870000','73873000') THEN TRUE ELSE FALSE END AS b2bcoffee,
    p.precipitations as lluvias,
    s.latitude,
    s.longitude,
    s.geom
FROM
    {schema}.settlements s
    LEFT JOIN {schema}.schools sch
    ON s.settlement_id=sch.settlement_id
    LEFT JOIN {schema}.settlements_precipitations p
    ON s.settlement_id=p.settlement_id
GROUP BY s.settlement_id,s.settlement_name, s.admin_division_1_name, s.admin_division_2_name, s.population_corrected, p.precipitations, s.latitude, s.longitude, s.geom;