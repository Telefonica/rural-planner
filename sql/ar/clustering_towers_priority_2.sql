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
CASE WHEN N1.node_type LIKE '%%VIVO%%' THEN 0
        WHEN N1.node_type LIKE 'TIM%%' THEN 1
        ELSE 2 END AS owner_level,
CASE WHEN N1.node_type LIKE '%%FIBER%%' THEN 0
        WHEN N1.node_type LIKE '%%RADIO%%' THEN 1
        ELSE 2 END AS tx_level
FROM {schema}.{table_nodes} N1
LEFT JOIN {schema_2}.{table_infrastructure} I 
ON N1.node_id = I.tower_id::TEXT
LEFT JOIN {schema}.{table_nodes} N2
ON ST_DWithin(N1.geom, N2.geom, CASE WHEN I.tower_height<15 THEN 1500
                                                            WHEN I.tower_height>50 THEN 5000
                                                            ELSE I.tower_height*100 END)
WHERE N1.node_type LIKE '%%TOWER%%'
AND N2.node_type LIKE '%%SETTLEMENT%%'
AND N1.node_id <> N2.node_id
ORDER BY N2.node_id, ST_Distance(N1.geom, N2.geom), owner_level, tx_level
) A
GROUP BY centroid, centroid_type, centroid_weight