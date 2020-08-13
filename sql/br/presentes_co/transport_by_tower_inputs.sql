SELECT * FROM (
    SELECT 
    S1.tower_id AS tower_id,
    S1.latitude AS latitude_1,
    S1.longitude AS longitude_1,
    S1.tower_height AS tower_height_1,
    S1.source AS owner_1,
    S1.tower_type AS tower_type_1,
    S1.type AS type_1,
    S1.in_service AS in_service_1,
    S1.tech_2g AS tech_2g_1,
    S1.tech_3g AS tech_3g_1,
    S1.tech_4g AS tech_4g_1,
    S1.fiber AS fiber_1,
    S1.radio AS radio_1,
    S1.satellite AS satellite_1,
    S1.source AS source_1,
    S2.tower_id AS tower_id_2,
    S2.latitude AS latitude_2,
    S2.longitude AS longitude_2,
    S2.tower_height AS tower_height_2,
    S2.source AS owner_2,
    S2.tower_type AS tower_type_2,
    S2.type AS type_2,
    S2.in_service AS in_service_2,
    S2.tech_2g AS tech_2g_2,
    S2.tech_3g AS tech_3g_2,
    S2.tech_4g AS tech_4g_2,
    S2.fiber AS fiber_2,
    S2.radio AS radio_2,
    S2.satellite AS satellite_2,
    S2.source AS source_2,
    CASE WHEN S2.source IN ('TIMLIG_POINTS','TIMLIG_LINES') THEN 1
        WHEN S2.source IN ('VIVO') THEN 0
        ELSE 2 END AS owner_level, 
    ST_Distance(S1.geom::geography, S2.geom::geography) AS distance
    FROM (SELECT * FROM {schema}.{table} 
            WHERE radio IS FALSE and fiber IS FALSE) S1
    LEFT JOIN (SELECT * FROM {schema}.{table}
                WHERE (radio IS TRUE OR fiber IS TRUE) AND source not LIKE '%%LINES%%' AND source NOT IN ({sources_omit}) AND source IN ({owners})) S2
    ON ST_DWithin(S1.geom::geography, S2.geom::geography, {radius})
    UNION
    SELECT 
    S1.tower_id AS tower_id,
    S1.latitude AS latitude_1,
    S1.longitude AS longitude_1,
    S1.tower_height AS tower_height_1,
    S1.source AS owner_1,
    S1.tower_type AS tower_type_1,
    S1.type AS type_1,
    S1.in_service AS in_service_1,
    S1.tech_2g AS tech_2g_1,
    S1.tech_3g AS tech_3g_1,
    S1.tech_4g AS tech_4g_1,
    S1.fiber AS fiber_1,
    S1.radio AS radio_1,
    S1.satellite AS satellite_1,
    S1.source AS source_1,
    S2.tower_id AS tower_id_2,
    ST_Y(ST_ClosestPoint(S2.geom, S1.geom)) AS latitude_2,
    ST_X(ST_ClosestPoint(S2.geom, S1.geom)) AS longitude_2,
    S2.tower_height AS tower_height_2,
    S2.source AS owner_2,
    S2.tower_type AS tower_type_2,
    S2.type AS type_2,
    S2.in_service AS in_service_2,
    S2.tech_2g AS tech_2g_2,
    S2.tech_3g AS tech_3g_2,
    S2.tech_4g AS tech_4g_2,
    S2.fiber AS fiber_2,
    S2.radio AS radio_2,
    S2.satellite AS satellite_2,
    S2.source AS source_2,
    CASE WHEN S2.source IN ('TIMLIG_POINTS','TIMLIG_LINES') THEN 1
        WHEN S2.source IN ('VIVO') THEN 0
        ELSE 2 END AS owner_level, 
    ST_Distance(S1.geom::geography, ST_ClosestPoint(S2.geom, S1.geom)::geography) AS distance
    FROM (SELECT * FROM {schema}.{table} 
            WHERE radio IS FALSE and fiber IS FALSE) S1
    LEFT JOIN (SELECT * FROM {schema}.{table}
                WHERE (radio IS TRUE OR fiber IS TRUE) AND source LIKE '%%LINES%%' AND source NOT IN ({sources_omit}) AND source IN ({owners})
               ) S2
    ON ST_DWithin(S1.geom::geography, ST_ClosestPoint(S2.geom, S1.geom)::geography, {radius})
    ) A
WHERE tower_id_2 IS NOT NULL
ORDER BY tower_id, fiber_2 DESC, distance, owner_level