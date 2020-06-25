CREATE OR REPLACE VIEW
    {schema}.v_poblacion_cubierta_indirecta
    (
        id_interno,
        codigos_divipola,
        centros_poblados,
        ccpps_cubiertos,
        poblacion_cubierta,
        codigos_divipola_distribuidos,
        centros_poblados_distribuidos,
        ccpps_cubiertos_distribuidos,
        poblacion_cubierta_distribuida,
        codigo_unico,
        nombre_bts,
        altura,
        latitud,
        longitud
    ) AS
SELECT
    indirect_covered_population.tower_id                               AS id_interno,
    indirect_covered_population.settlement_ids                         AS codigos_divipola,
    indirect_covered_population.settlement_names                       AS centros_poblados,
    indirect_covered_population.covered_settlements                    AS ccpps_cubiertos,
    indirect_covered_population.covered_population                     AS poblacion_cubierta,
    indirect_covered_population.settlement_ids_distributed   AS codigos_divipola_distribuidos,
    indirect_covered_population.settlement_names_distributed AS
    centros_poblados_distribuidos,
    indirect_covered_population.covered_settlements_distributed AS
    ccpps_cubiertos_distribuidos,
    indirect_covered_population.covered_population_distributed AS
                                               poblacion_cubierta_distribuida,
    indirect_covered_population.internal_id  AS codigo_unico,
    indirect_covered_population.tower_name   AS nombre_bts,
    indirect_covered_population.tower_height AS altura,
    indirect_covered_population.latitude     AS latitud,
    indirect_covered_population.longitude    AS longitud
FROM
    {schema}.indirect_covered_population;
