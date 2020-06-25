SELECT 
N1.tower_id_2::TEXT AS centroid,
''''||string_agg(N1.node_id::TEXT,''' ,''' ) || '''' AS nodes,
C1.cluster_weight + SUM(C2.cluster_weight) AS cluster_weight,
COUNT(N1.node_id) + 1 AS cluster_size
FROM {schema}.{table_nodes} N1
LEFT JOIN {schema}.{table_clusters} C1
ON N1.tower_id_2::TEXT=C1.centroid
LEFT JOIN {schema}.{table_clusters} C2
ON N1.node_id=C2.centroid
WHERE line_of_sight_movistar IS TRUE
GROUP BY N1.tower_id_2, C1.cluster_weight