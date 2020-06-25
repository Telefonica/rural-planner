CREATE OR REPLACE VIEW
    {schema}.v_presencia_operadores_torres
    (
        codigo_unico,
        nombre_bts,
        codigos_divipola,
        centros_poblados,
        num_ccpp_cubiertos,
        poblacion_cubierta,
        presencia_tigo_2g,
        presencia_tigo_3g,
        presencia_tigo_4g,
        presencia_claro_2g,
        presencia_claro_3g,
        presencia_claro_4g,
        presencia_competidores_2g,
        presencia_competidores_3g,
        presencia_competidores_4g,
        id_interno,
        altura,
        latitude,
        longitude
    ) AS
SELECT
    competitors_presence_towers.internal_id         AS codigo_unico,
    competitors_presence_towers.tower_name          AS nombre_bts,
    competitors_presence_towers.settlement_ids_distributed      AS ubigeos,
    competitors_presence_towers.settlement_names_distributed    AS centros_poblados,
    competitors_presence_towers.covered_settlements_distributed AS num_ccpp_cubiertos,
    competitors_presence_towers.covered_population_distributed  AS poblacion_cubierta,
    ((competitors_presence_towers.tigo_2g_presence)::DOUBLE PRECISION * (100)::DOUBLE PRECISION)
    AS presencia_tigo_2g,
    ((competitors_presence_towers.tigo_3g_presence)::DOUBLE PRECISION * (100)::DOUBLE PRECISION)
    AS presencia_tigo_3g,
    ((competitors_presence_towers.tigo_4g_presence)::DOUBLE PRECISION * (100)::DOUBLE PRECISION)
    AS presencia_tigo_4g,
    ((competitors_presence_towers.claro_2g_presence)::DOUBLE PRECISION * (100)::DOUBLE PRECISION)
    AS presencia_claro_2g,
    ((competitors_presence_towers.claro_3g_presence)::DOUBLE PRECISION * (100)::DOUBLE PRECISION)
    AS presencia_claro_3g,
    ((competitors_presence_towers.claro_4g_presence)::DOUBLE PRECISION * (100)::DOUBLE PRECISION)
    AS presencia_claro_4g,
    ((competitors_presence_towers.competitors_2g_presence)::DOUBLE PRECISION * (100)::DOUBLE
    PRECISION) AS presencia_competidores_2g,
    ((competitors_presence_towers.competitors_3g_presence)::DOUBLE PRECISION * (100)::DOUBLE
    PRECISION) AS presencia_competidores_3g,
    ((competitors_presence_towers.competitors_4g_presence)::DOUBLE PRECISION * (100)::DOUBLE
    PRECISION)                               AS presencia_competidores_4g,
    competitors_presence_towers.tower_id     AS id_interno,
    competitors_presence_towers.tower_height AS altura,
    competitors_presence_towers.latitude,
    competitors_presence_towers.longitude
FROM
    {schema}.competitors_presence_towers;
