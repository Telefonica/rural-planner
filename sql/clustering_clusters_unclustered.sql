SELECT
node_id AS centroid,
node_type as centroid_type,
node_weight AS centroid_weight,
'' AS nodes,
node_weight AS cluster_weight,
1 AS cluster_size
FROM {schema}.{table_nodes};