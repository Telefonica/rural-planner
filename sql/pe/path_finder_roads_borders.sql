INSERT INTO {schema}.{table_nodes_roads}

SELECT 
centroid,
stretch_id,
division,
distance_centroid_road,
score,
cluster_weight,
node_weight,
stretch_length,
geom,
geom_line_centroid
FROM (
        SELECT
        'BORDER' AS centroid,
        R.stretch_id,
        R.division,
        0 AS distance_centroid_road,
        -1 AS score,
        0 AS cluster_weight,
        0 AS node_weight,
        N.stretch_id AS stretch_id_match,
        R.stretch_length,
        R.geom_point AS geom,
        ST_MakeLine(R.geom_point::geometry, R.geom_point::geometry) AS geom_line_centroid
        FROM {schema}.{table_roads_points} R
        LEFT JOIN {schema}.{table_nodes_roads} N
        ON (R.stretch_id = N.stretch_id AND ABS(R.division::numeric - N.division::numeric) < 0.001)
        WHERE R.division IN (0,1)
) A
WHERE stretch_id_match IS NULL;

INSERT INTO {schema}.{table_nodes_roads}

SELECT DISTINCT ON (RI.stretch_id_2, RI.division_2)
'BORDER' AS centroid,
RI.stretch_id_2 AS stretch_id,
RI.division_2 AS division,
0 AS distance_centroid_road,
-1 AS score,
0 AS cluster_weight,
0 AS node_weight,
R.stretch_length,
R.geom_point AS geom,
ST_MakeLine(R.geom_point::geometry, R.geom_point::geometry) AS geom_line_centroid
FROM {schema}.{table_intersections} RI
LEFT JOIN {schema}.{table_roads_points} R
ON (RI.stretch_id_2 = R.stretch_id AND ABS(RI.division_2 - R.division) < 0.001)
WHERE RI.division_2 NOT IN (0,1)
AND RI.stretch_id_2::text||'+'||RI.division_2::text NOT IN (
        SELECT
        RI.stretch_id::text||'+'||RI.division::text
        FROM {schema}.{table_nodes_roads}
);