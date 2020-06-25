WITH nodes_edges AS (SELECT node_1
        FROM {schema}.{table_edges}
        UNION
        SELECT node_2
        FROM {schema}.{table_edges})
SELECT DISTINCT ON (node_1) *
FROM (
SELECT 
I.tower_id::numeric + (SELECT MAX(node_id::numeric) FROM {schema}.{table_nodes}) AS node_1,
N.node_id AS node_2,
ST_Distance(I.geom::geography, N.geom::geography)/1000 AS weight,
I.tower_id,
I.source
FROM (
    SELECT *
    FROM rural_planner.{table_towers} WHERE fiber IS TRUE
) I
LEFT JOIN (
        SELECT *
        FROM {schema}.{table_nodes}
        WHERE node_id IN (SELECT node_1 FROM nodes_edges)
) N
ON ST_DWithin(N.geom::geography, I.geom::geography, {radius})
) A
WHERE weight IS NOT NULL
ORDER BY node_1, weight ASC