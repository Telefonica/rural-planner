SELECT 
S1.centroid,
ST_Y(S1.geom_centroid::geometry) AS latitude_1,
ST_X(S1.geom_centroid::geometry) AS longitude_1,
0 as tower_height_1,
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
ST_Distance(S1.geom_centroid::GEOGRAPHY, S2.geom::GEOGRAPHY) AS distance
FROM {schema}.{table_clusters} S1
LEFT JOIN {schema}.{table} S2
ON ST_DWithin(S1.geom_centroid::GEOGRAPHY, S2.geom::GEOGRAPHY, {radius})
WHERE S2.source IN ({owners}) AND (S2.fiber IS TRUE OR S2.radio IS TRUE) 
AND S1.centroid_type LIKE '%%SETTLEMENT%%' AND S1.cluster_weight>0
ORDER BY S1.centroid, distance