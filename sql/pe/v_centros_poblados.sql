CREATE OR REPLACE VIEW
    {schema}.v_centros_poblados
    (
        ubigeo,
        centro_poblado,
        distrito,
        provincia,
        region,
        clasificacion,
        orografia,
        poblacion,
        viviendas,
        ratio_acceso_agua,
        ratio_acceso_electricidad,
        ratio_trabajadores,
        ratio_desempleados,
        ratio_no_activos,
        latitude,
        longitude,
        geom
    ) AS
SELECT
    s.settlement_id                                         AS ubigeo,
    s.settlement_name                                       AS centro_poblado,
    s.admin_division_1_name                                 AS distrito,
    s.admin_division_2_name                                 AS provincia,
    s.admin_division_3_name                                 AS region,
    sk.classification AS clasificacion,
    sk.orography                                            AS orografia,
    s.population_corrected                                  AS poblacion,
    sk.household_2007                                       AS viviendas,
    ROUND((sk.houses_with_water * (100)::DOUBLE PRECISION)) AS ratio_acceso_agua,
    ROUND((sk.public_lighting * (100)::DOUBLE PRECISION))   AS ratio_acceso_electricidad,
    ROUND((sk.eap_employed * (100)::DOUBLE PRECISION))      AS ratio_trabajadores,
    ROUND((sk.eap_unemployed * (100)::DOUBLE PRECISION))    AS ratio_desempleados,
    ROUND((sk.eap_non_active * (100)::DOUBLE PRECISION))    AS ratio_no_activos,
    s.latitude,
    s.longitude,
    s.geom
FROM
    (
    {schema}.settlements s
LEFT JOIN
    {schema}.settlements_kpis sk
ON
    ((
            s.settlement_id = sk.settlement_id))
            );
