SELECT S1.centroid,
ST_Y(S1.geom_centroid::geometry) AS latitude_1,
ST_X(S1.geom_centroid::geometry) AS longitude_1,
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
S2.tx_3g as tx_3g_2,
S2.tx_third_pty as tx_third_pty_2,
S2.satellite AS satellite_2, 
0 AS owner_level, 
ST_Distance(S1.geom_centroid, S2.geom) AS distance
FROM {schema}.{table_clusters} S1
LEFT JOIN {schema}.{table} S2
ON ST_DWithin(S1.geom_centroid, S2.geom, {radius})
WHERE S1.centroid_type LIKE '%%SETTLEMENT%%' AND S1.cluster_weight>0
    AND S2.source IN ({owners})
    AND S2.in_service IN ('IN SERVICE','AVAILABLE') 
    AND (S2.radio IS TRUE OR S2.fiber IS TRUE or S2.tx_3g IS TRUE)
ORDER BY S1.centroid, S2.fiber DESC, S2.radio DESC, S2.tx_3g DESC, distance
    

