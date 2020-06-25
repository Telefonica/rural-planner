CREATE OR REPLACE VIEW
    {schema}.v_centros_poblados
    (
        id_localidad,
        localidad,
        departamento,
        provincia,
        poblacion,
        region,
        zona_exclusividad,
        etapa_enacom,
        plan_2019,
        latitude,
        longitude,
        geom
    ) AS
SELECT
    s.settlement_id                                         AS id_localidad,
    s.settlement_name                                       AS localidad,
    s.admin_division_1_name                                 AS departamento,
    s.admin_division_2_name                                 AS provincia,
    s.population_corrected as poblacion,
    p.region,
    p.exclusivity_zone as zona_exclusividad,
    p.stage as etapa_enacom,
    p.plan_2019,
    s.latitude,
    s.longitude,
    s.geom
FROM
    ({schema}.settlements s
LEFT JOIN
    {schema}.settlements_kpis p
ON
    ((
            s.settlement_id = p.settlement_id)));
