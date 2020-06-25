CREATE OR REPLACE VIEW
    {schema}.v_centros_poblados
    (
        codigo_divipola,
        centro_poblado,
        municipio,
        departamento,
        poblacion,
        latitude,
        longitude,
        geom
    ) AS
SELECT
    s.settlement_id         AS codigo_divipola,
    CASE WHEN s.settlement_name  IS NOT NULL THEN s.settlement_name ELSE CONCAT('CLUSTER ',s.settlement_id) END AS centro_poblado,
    s.admin_division_1_name AS municipio,
    s.admin_division_2_name AS departamento,
    s.population_corrected  AS poblacion_estimada,
    s.latitude,
    s.longitude,
    s.geom
FROM
    settlements s;
