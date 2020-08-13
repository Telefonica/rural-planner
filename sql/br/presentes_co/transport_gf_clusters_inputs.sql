SELECT * FROM (
SELECT S1.centroid,
ST_Y(S1.geom::geometry) AS latitude_1,
ST_X(S1.geom::geometry) AS longitude_1,
50 as tower_height_1,
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
ST_Distance(S1.geom::geography, S2.geom::geography) AS distance
FROM {schema}.{table_clusters} S1
LEFT JOIN (SELECT * FROM {schema}.{table} WHERE source NOT LIKE '%%LINES%%'
    AND source IN ({owners})) S2
ON ST_DWithin(S1.geom::geography, S2.geom::geography, {radius})
WHERE (S2.fiber IS TRUE OR S2.radio IS TRUE)
AND S1.centroid_type LIKE '%%SETTLEMENT%%' AND S1.cluster_weight>0
UNION
SELECT S1.centroid,
ST_Y(S1.geom::geometry) AS latitude_1,
ST_X(S1.geom::geometry) AS longitude_1,
50 as tower_height_1,
S2.tower_id AS tower_id_2,
ST_Y(ST_ClosestPoint(S2.geom, S1.geom)) AS latitude_2,
ST_X(ST_ClosestPoint(S2.geom, S1.geom)) AS longitude_2,
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
ST_Distance(S1.geom::geography, S2.geom::geography) AS distance
FROM {schema}.{table_clusters} S1
LEFT JOIN (SELECT * FROM {schema}.{table} WHERE source LIKE '%%LINES%%' 
    AND source IN ({owners})) S2
ON ST_DWithin(S1.geom::geography, S2.geom::geography, {radius})
WHERE (S2.fiber IS TRUE OR S2.radio IS TRUE)
AND S1.centroid_type LIKE '%%SETTLEMENT%%' AND S1.cluster_weight>0) A
ORDER BY centroid, distance, fiber_2