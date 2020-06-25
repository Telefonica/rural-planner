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
S2.satellite AS satellite_2,
0 AS owner_level, 
ST_Distance(S1.geom::geography, S2.geom::geography) AS distance
FROM {schema}.{table} S1
LEFT JOIN {schema}.{table} S2
ON ST_DWithin(S1.geom::geography, S2.geom::geography, {radius})
WHERE S2.source IN ({owners}) AND S2.source NOT IN ({sources_omit}) AND S1.source NOT IN ({sources_omit})
ORDER BY S1.tower_id, distance
) A
WHERE fiber_1 IS FALSE
AND radio_1 IS FALSE
AND (radio_2 IS TRUE OR fiber_2 IS TRUE)
ORDER BY tower_id, owner_level ASC, fiber_2 DESC, distance