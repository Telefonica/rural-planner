DROP TABLE IF EXISTS {schema}.{table_nodes_roads};
CREATE TABLE {schema}.{table_nodes_roads} AS
SELECT DISTINCT
RC.centroid,
RC.stretch_id,
RC.division,
RC.distance AS distance_centroid_road,
RC.score,
C.cluster_weight,
CASE WHEN RC.distance <= {threshold_distance} THEN C.cluster_weight
     ELSE C.cluster_weight*{penalty} END AS node_weight,
R.stretch_length,
R.geom_point AS geom,
ST_MakeLine(R.geom_point::geometry, C.geom_centroid::geometry) AS geom_line_centroid
FROM {schema}.{table_cluster_points} RC
LEFT JOIN {schema}.{auxiliary_table} C
ON C.centroid = RC.centroid
LEFT JOIN {schema}.{table_roads_points} R
ON (R.stretch_id = RC.stretch_id AND ABS(R.division - RC.division) < 0.001);

DROP TABLE {schema}.{auxiliary_table};
