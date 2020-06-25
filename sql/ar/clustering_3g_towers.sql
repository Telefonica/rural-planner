SELECT 
centroid,
centroid_type,
centroid_weight,
''''||string_agg(node_2_id,''' ,''' ) || '''' AS nodes,
SUM(node_2_weight) AS cluster_weight,
COUNT(node_2_id) AS cluster_size
FROM (
SELECT DISTINCT ON (node_2_id) 
A.*
FROM (
SELECT 
N1.node_id AS centroid,
N1.node_type AS centroid_type,
N1.node_weight AS centroid_weight,
N2.node_id AS node_2_id,
N2.node_weight AS node_2_weight,
ST_Distance(N1.geom::GEOGRAPHY, N2.geom::GEOGRAPHY) as dist_m
FROM {schema}.{table_nodes} N1
LEFT JOIN {schema}.{table_nodes} N2
ON ST_DWithin(N1.geom::geography, N2.geom::geography, {radius})
WHERE N1.node_type LIKE '%%TOWER%%'
AND N2.node_type LIKE '%%SETTLEMENT%%' ) A
LEFT JOIN (
SELECT 
N1.node_id AS centroid,
COUNT(N2.node_id) AS cluster_size,
SUM(N2.node_weight) AS cluster_weight
FROM {schema}.{table_nodes} N1
LEFT JOIN {schema}.{table_nodes} N2
ON ST_DWithin(N1.geom::geography, N2.geom::geography, {radius})
WHERE N1.node_type LIKE '%%TOWER%%'
AND N2.node_type LIKE '%%SETTLEMENT%%' 
GROUP BY centroid) B
ON A.centroid=B.centroid
ORDER BY node_2_id, B.cluster_size DESC--, B.cluster_weight DESC, dist_m
)C
GROUP BY centroid, centroid_type, centroid_weight