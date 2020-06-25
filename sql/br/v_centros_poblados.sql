CREATE OR REPLACE VIEW
    {schema}.v_centros_poblados
    (
        codigo_setor,
        centro_poblado,
        distrito,
        municipio,
        estado,
        poblacion,
        latitude,
        longitude,
        geom
    ) AS
SELECT
    s.settlement_id         AS codigo_setor,
    CASE WHEN s.settlement_name  IS NOT NULL 
         THEN s.settlement_name 
    ELSE CONCAT('CLUSTER ',s.settlement_id) END AS centro_poblado,
    s.admin_division_1_name AS distrito,
    s.admin_division_2_name AS municipio,
    s.admin_division_3_name AS estado,
    s.population_corrected  AS poblacion_estimada,
    s.latitude,
    s.longitude,
    s.geom
FROM
    {schema}.settlements s;