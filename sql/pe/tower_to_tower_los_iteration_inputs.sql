SELECT 
    S1.tower_id AS tower_id_1,
    S1.latitude AS latitude_1,
    S1.longitude AS longitude_1,
    S1.tower_height AS tower_height_1,
    S2.tower_id AS tower_id_2,
    S2.latitude AS latitude_2,
    S2.longitude AS longitude_2,
    S2.tower_height AS tower_height_2,
    ST_Distance(S1.geom, S2.geom) AS distance
    FROM {schema}.{table_towers} S1
    JOIN {schema}.{table_towers} S2
    ON ST_DWithin(S1.geom, S2.geom, {radius})
    AND S1.tower_id < S2.tower_id
    WHERE S1.latitude <> 0
    AND S2.latitude <> 0
    AND S1.latitude IS NOT NULL
    AND S2.latitude IS NOT NULL
    AND S1.tower_id = {tower_id_1}
    AND S1.source NOT IN ({sources_omit})
    AND S2.source NOT IN ({sources_omit})
    ORDER BY tower_id_1, distance