SELECT DISTINCT ON (n.node_id) n.*
FROM {schema}.{table_nodes} n
LEFT JOIN {schema}.{table_cluster_node_map} c
ON n.node_id=c.node_id 
LEFT JOIN {schema}.{table_clusters} c2
ON c.centroid=c2.centroid
LEFT JOIN {schema}.{table_towers} i
ON i.tower_id::text=c2.centroid
LEFT JOIN {schema}.{table_initial_quick_wins} p
ON p.centroid=i.tower_id
WHERE ipt_perimeter = 'IPT'
AND p.centroid IS NULL