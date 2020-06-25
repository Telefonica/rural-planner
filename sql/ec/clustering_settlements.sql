SELECT 
N1.node_id AS centroid,
N1.node_type as centroid_type,
N1.node_weight AS centroid_weight,
''''||string_agg(N2.node_id,''' ,''' ) || '''' AS nodes,
N1.node_weight + SUM(N2.node_weight) AS cluster_weight,
COUNT(N2.node_id) + 1 AS cluster_size
FROM {schema}.{table_nodes} N1
LEFT JOIN {schema}.{table_nodes} N2
ON ST_DWithin(N1.geom, N2.geom, {radius})
LEFT JOIN {schema}.{table_franchises} F1
ON N1.node_id = F1.centroid
LEFT JOIN {schema}.{table_franchises} F2
ON N2.node_id = F2.centroid
WHERE N1.node_id <> N2.node_id
AND F1.franchise = F2.franchise
AND N1.node_type LIKE '%%SETTLEMENT%%'
AND N2.node_type LIKE '%%SETTLEMENT%%'
GROUP BY N1.node_id,N1.node_type, N1.node_weight
ORDER BY cluster_weight DESC
LIMIT 1