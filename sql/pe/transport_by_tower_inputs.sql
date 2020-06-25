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
CASE WHEN S2.source IN ('GILAT', 'TORRES ANDINAS', 'EHAS','PIA') THEN 4
     WHEN S2.source IN ('REGIONAL', 'YOFC','ADVISIA') THEN 3
     WHEN S2.source IN ('AZTECA') THEN 2
     WHEN S2.source IN ('LAMBAYEQUE') THEN 1
     ELSE 0 END AS owner_level, 
ST_Distance(S1.geom, S2.geom) AS distance
FROM (SELECT * FROM {schema}.{table}
        WHERE fiber IS FALSE
        AND radio IS FALSE
        AND in_service = 'IN SERVICE'
        AND source NOT IN ({sources_omit})) S1
LEFT JOIN (SELECT * FROM {schema}.{table}
            WHERE (radio IS TRUE OR fiber IS TRUE)
             AND source IN ({owners})
             AND source NOT IN ({sources_omit})
             AND in_service = 'IN SERVICE') S2
ON ST_DWithin(S1.geom::geography, S2.geom::geography, {radius})
ORDER BY S1.tower_id, distance
) A
ORDER BY tower_id, owner_level ASC, fiber_2 DESC, distance
