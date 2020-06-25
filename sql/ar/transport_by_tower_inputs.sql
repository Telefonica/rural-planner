SELECT * FROM (
SELECT 
S1.tower_id AS tower_id,
S1.latitude AS latitude_1,
S1.longitude AS longitude_1,
S1.tower_height AS tower_height_1,
S1.source AS owner_1,
S1.tower_type AS tower_type_1,
S1.type AS type_1,
S1.tech_2g AS tech_2g_1,
S1.tech_3g AS tech_3g_1,
S1.tech_4g AS tech_4g_1,
S1.fiber AS fiber_1,
S1.radio AS radio_1,
S1.tx_3g as tx_3g_1,
S1.tx_third_pty as tx_third_pty_1,
S1.satellite AS satellite_1,
S2.tower_id AS tower_id_2,
S2.latitude AS latitude_2,
S2.longitude AS longitude_2,
S2.tower_height AS tower_height_2,
S2.source AS owner_2,
S2.tower_type AS tower_type_2,
S2.type AS type_2,
S2.tech_2g AS tech_2g_2,
S2.tech_3g AS tech_3g_2,
S2.tech_4g AS tech_4g_2,
S2.fiber AS fiber_2,
S2.radio AS radio_2,
S2.tx_3g as tx_3g_2,
S2.tx_third_pty as tx_third_pty_2,
S2.satellite AS satellite_2, 
0 AS owner_level, 
ST_Distance(S1.geom::geography, S2.geom::geography) AS distance
FROM {schema}.{table} S1
LEFT JOIN {schema}.{table} S2
ON ST_DWithin(S1.geom::geography, S2.geom::geography, {radius})
WHERE S2.source IN ({owners}) AND S1.source NOT IN ({sources_omit})
    AND S1.in_service IN ('IN SERVICE','AVAILABLE') and S2.in_service IN ('IN SERVICE','AVAILABLE')
ORDER BY S1.tower_id, S2.fiber DESC, S2.radio DESC, S2.tx_3g DESC, distance
) A
WHERE fiber_1 IS FALSE
AND radio_1 IS FALSE
AND tx_3g_1 IS FALSE
AND tx_third_pty_1 IS FALSE
AND (radio_2 IS TRUE OR fiber_2 IS TRUE or tx_3g_2 IS TRUE OR tx_third_pty_2 IS TRUE)
ORDER BY tower_id, fiber_2 DESC, radio_2 DESC, tx_3g_2 DESC, distance, owner_level
