-- 2G towers
SELECT DISTINCT ON (centroid) *
FROM (
SELECT 
centroid, 
centroid_type, 
centroid_weight, 
''''||string_agg(node_id_2,''' ,''' ) || '''' AS nodes,
SUM(node_weight_2) AS cluster_weight,
COUNT(node_id_2) AS cluster_size
FROM (
SELECT DISTINCT ON (N2.node_id)
N1.node_id AS centroid,
N1.node_type AS centroid_type,
N1.node_weight AS centroid_weight,
N2.node_id AS node_id_2,
N2.node_weight AS node_weight_2,
CASE WHEN I.source IN  ('TEF') THEN 0
        ELSE 2 END AS owner_level,
CASE WHEN N1.node_type LIKE '%%FIBER%%' THEN 0
        WHEN N1.node_type LIKE '%%RADIO%%' THEN 1
        ELSE 2 END AS tx_level
FROM {schema}.{table_nodes} N1
LEFT JOIN {schema}.{table_infrastructure} I 
ON N1.node_id = I.tower_id::TEXT
LEFT JOIN {schema}.{table_nodes} N2
ON ST_Within(N1.geom::geometry, COALESCE(I.coverage_area_2g, I.coverage_area_3g, I.coverage_area_4g))

LEFT JOIN {schema}.{table_coverage} C
ON N2.node_id = C.settlement_id
WHERE (N1.node_type LIKE '%%TOWER 2G%%'
OR N1.node_type LIKE '%%TOWER 3G%%')
AND N2.node_type LIKE '%%SETTLEMENT%%'
AND N1.node_id <> N2.node_id
AND C.movistar_2g_corrected = I.tech_2g
ORDER BY N2.node_id, ST_Distance(N1.geom, N2.geom), owner_level, tx_level
) A
GROUP BY centroid, centroid_type, centroid_weight
-- Add 2G Empty towers    
UNION
SELECT node_id AS centroid,
node_type AS centroid_type,
node_weight AS centroid_weight,
'' AS nodes,
0 AS cluster_weight,
0 AS cluster_size
FROM {schema}.{table_nodes}
WHERE node_type LIKE '%%TOWER 2G%%'
OR node_type LIKE '%%TOWER 3G%%') A
ORDER BY centroid, cluster_weight DESC