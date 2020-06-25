SELECT
N1.node_id AS node_1,
N2.node_id AS node_2,
CASE WHEN distance < 10 THEN 0
     ELSE RI.distance/1000 END AS weight
FROM {schema}.{table_intersections} RI
LEFT JOIN {schema}.{table_nodes_roads} N1
ON (RI.stretch_id = N1.stretch_id AND RI.division = N1.division)
LEFT JOIN {schema}.{table_nodes_roads} N2
ON (RI.stretch_id_2 = N2.stretch_id AND RI.division_2 = N2.division)

UNION 

SELECT
N2.node_id AS node_1,
N1.node_id AS node_2,
CASE WHEN distance < 10 THEN 0
     ELSE RI.distance/1000 END AS weight
FROM {schema}.{table_intersections} RI
LEFT JOIN {schema}.{table_nodes_roads} N1
ON (RI.stretch_id = N1.stretch_id AND RI.division = N1.division)
LEFT JOIN {schema}.{table_nodes_roads} N2
ON (RI.stretch_id_2 = N2.stretch_id AND RI.division_2 = N2.division)